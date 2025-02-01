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


void command(uint8_t c)
{
	char buffer[] = {0x04, c};
	set_cs_creset(0, 1);
	usleep(100);
	mpsse_send_spi(buffer, sizeof(buffer));
	usleep(100);	
	set_cs_creset(1, 1);
	

}

void data(uint8_t c)
{

	char buffer[] = {0x06, c};
	set_cs_creset(0, 1);
	usleep(100);
	mpsse_send_spi(buffer, sizeof(buffer));
	usleep(100);	
	set_cs_creset(1, 1);
	

}

void reset()
{
	char buffer[] = {0x00};
	set_cs_creset(0, 1);
	usleep(1000);
	mpsse_send_spi(buffer, sizeof(buffer));
	usleep(1000);	
	set_cs_creset(1, 1);

	usleep(100000);

	buffer[0] = 0x40;

	set_cs_creset(0, 1);
	usleep(1000);
	mpsse_send_spi(buffer, sizeof(buffer));
	usleep(1000);	
	set_cs_creset(1, 1);


}

void init_oled()
{

	command(0xAE); //Set Display OFF
	command(0xA8); //Set MUX ratio
	data(0x7F);
	//
	command(0xA2); //Set Display offset
	data(0x00);
	command(0xA1); //Set display start line
	data(0x00);
	command(0xA4); //Normal display
	command(0xA0); //Set Re-map, color depth
	data(0x66);
	//
	command(0x81); //Set Contrast for color"A" segment
	data(0x75);
	//Red contrast set for VCC:17V
	command(0x82); //Set Contrast for color"B" segment
	data(0x60);
	//Green contrast set for VCC:17V
	command(0x83); //Set Contrast for color"C" segment
	data(0x6A);
	//Blue contrast set for VCC:17V
	command(0x87); //Master Contrast Current Control
	data(0x0F);
	//reset value for VCC:17V
	command(0xB9); //use linear grayscale table
	command(0xB1); //Set Phase1 and phase2 period adjustment
	data(0x22);
	command(0xB3); //Set Display Clock Divide Ratio (internal clock selection)
	data(0x40);
	command(0xBB); //Set Pre-charge Voltage
	data(0x08);
	command(0xBE); //Set VCOMH
	data(0x2F);
	command(0xAF); //Set Display ON in mormal mode

}

void do_demo()
{

	for (int i = 0; i < 100; i++)
	{

		command(0x5c);

		int16_t col;
		
		for (int y = 0; y < 130; y++)
		{
			for (int x = 0; x < 160; x++)
			{
				data(col>> 8);
				data(col&0xff);
				col += 0x181;
			}

		}
	
	}

}



int main(int argc, char **argv)
{

	const char *devstr = NULL;
	int ifnum = 0;



	mpsse_init(ifnum, devstr, false);

	reset();

	init_oled();

	do_demo();


	mpsse_close();
	return 0;
}
