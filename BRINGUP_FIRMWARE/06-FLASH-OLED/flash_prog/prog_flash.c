/*
 *  iceprog -- simple programming tool for FTDI-based Lattice iCE programmers
 *
 *  Copyright (C) 2015  Clifford Wolf <clifford@clifford.at>
 *  Copyright (C) 2018  Piotr Esden-Tempski <piotr@esden.net>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *  Relevant Documents:
 *  -------------------
 *  http://www.latticesemi.com/~/media/Documents/UserManuals/EI/icestickusermanual.pdf
 *  http://www.micron.com/~/media/documents/products/data-sheet/nor-flash/serial-nor/n25q/n25q_32mb_3v_65nm.pdf
 *
 *  Repurposed by JRS on 25/4/25
 *
 *
 *
 *
 *
 */

#define _GNU_SOURCE

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <getopt.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>

#ifdef _WIN32
#include <io.h> /* _setmode() */
#include <fcntl.h> /* _O_BINARY */
#endif

#include "mpsse.h"

static bool verbose = false;

// ---------------------------------------------------------
// FLASH definitions
// ---------------------------------------------------------

// ---------------------------------------------------------
// Hardware specific CS, CReset, CDone functions
// ---------------------------------------------------------

static void set_cs_creset(int cs_b, int creset_b)
{
	uint8_t gpio = 0;
	uint8_t direction = 0x93;

	if (cs_b) {
		// ADBUS4 (GPIOL0)
		gpio |= 0x10;
	}

	if (creset_b) {
		// ADBUS7 (GPIOL3)
		gpio |= 0x80;
	}

	mpsse_set_gpio(gpio, direction);
}

static bool get_cdone(void)
{
	// ADBUS6 (GPIOL2)
	return (mpsse_readb_low() & 0x40) != 0;
}




// ---------------------------------------------------------
// FLASH function implementations
// ---------------------------------------------------------

void wake()
{
	char buffer[] = {0xab, 0, 0, 0, 0};
	set_cs_creset(0, 1);
	usleep(1000);
	mpsse_xfer_spi(buffer, sizeof(buffer));
	usleep(1000);	
	set_cs_creset(1, 1);
	
	printf("ID: %02x\n", buffer[4]);
}


void command()
{
	unsigned char buffer[] = {0x9f, 0, 0, 0};
	set_cs_creset(0, 1);
	usleep(1000);
	mpsse_xfer_spi(buffer, sizeof(buffer));
	usleep(1000);	
	set_cs_creset(1, 1);
	
	printf("ID: %02x %02x %02x\n", buffer[1], buffer[2], buffer[3]);
}

void write_enable()
{
	unsigned char buffer[] = {0x06};
	set_cs_creset(0, 1);
	usleep(1000);
	mpsse_xfer_spi(buffer, sizeof(buffer));
	usleep(1000);	
	set_cs_creset(1, 1);
	usleep(1000);	
}

bool is_busy()
{
    unsigned char buffer[] = {0x05, 0x00};

    set_cs_creset(0, 1);
    usleep(1000);
    mpsse_xfer_spi(buffer, sizeof(buffer));
    usleep(1000);   
    set_cs_creset(1, 1);
   
	usleep(1000);	

    return buffer[1] & 1;
}

void sector_erase(uint32_t address)
{
	unsigned char buffer[] = {0x20, (address & 0xff0000) >> 16, (address & 0xff00) >> 8, (address & 0xff)};
	set_cs_creset(0, 1);
	usleep(100);
	mpsse_xfer_spi(buffer, sizeof(buffer));
	usleep(100);	
	set_cs_creset(1, 1);
	usleep(100);	

    while (is_busy())
	    usleep(100);	

}

void write_page(uint32_t address, uint8_t* page)
{
	unsigned char buffer[] = {0x02, (address & 0xff0000) >> 16, (address & 0xff00) >> 8, (address & 0xff)};

	set_cs_creset(0, 1);
	usleep(100);
	mpsse_xfer_spi(buffer, sizeof(buffer));
	mpsse_send_spi(page, 256);
	usleep(100);	
	set_cs_creset(1, 1);
	usleep(100);	

    while (is_busy())
	    usleep(100);	

}

void read_flash(uint32_t address, uint8_t* data, int n)
{
	unsigned char buffer[] = {0x03, (address & 0xff0000) >> 16, (address & 0xff00) >> 8, (address & 0xff)};

	set_cs_creset(0, 1);
	usleep(100);
	mpsse_xfer_spi(buffer, sizeof(buffer));
	mpsse_xfer_spi(data, n);
	usleep(100);	
	set_cs_creset(1, 1);
	usleep(100);	

}


#define SECTOR_SIZE 4096
#define PAGE_SIZE   256


int main(int argc, char **argv)
{

	const char *devstr = NULL;
	int ifnum = 0;
    FILE* fil = NULL;

    if (argc != 2)
    {
        printf("Usage: %s <filename>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    fil = fopen(argv[1], "rb");

    if (fil == NULL) 
    {
        printf("Could not open %s\n", argv[1]);
        exit(EXIT_FAILURE);
    }


	mpsse_init(ifnum, devstr, false);

	wake();
	command();

    uint32_t address = 0;

    bool done = false;

    while (!done)
    {
        
        write_enable();
        sector_erase(address);
        
        for (int i = 0; i < SECTOR_SIZE / PAGE_SIZE; i++)
        {
 
            uint8_t page_buf[PAGE_SIZE];
            uint8_t veri_buf[PAGE_SIZE];

            write_enable();

            if (fread(page_buf, 1, PAGE_SIZE, fil) < PAGE_SIZE)
            {
                done = true;
                break;
            }

            printf("Programming page %x\n", address);

            write_page(address, page_buf);
            read_flash(address, veri_buf, PAGE_SIZE);

            if (memcmp(page_buf, veri_buf, PAGE_SIZE) != 0) 
            {
                done = true;
                printf("Page %x did not verify!\n", address);
                break;
            }
    
            address += PAGE_SIZE;
        }

    }


	mpsse_close();
	return 0;
}
