/* vim: set et ts=4 sw=4: */

/*
	$PROJECT

$FILE: $DESC

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

module oled (
    input CLK,
    input RSTb,

    output reg OLED_DCb = 1'b0,
    output reg OLED_RESb = 1'b1,
    output reg OLED_CSb = 1'b1,
    output reg OLED_SDOUT = 1'b1,
    output reg OLED_SDCLK = 1'b1,

    output reg flash_csb,
    output reg [1:0] flash_clk_ddr,
    output reg [1:0] flash_out_d0_ddr,
    output reg [1:0] flash_out_d1_ddr,
    output reg [1:0] flash_out_d2_ddr,
    output reg [1:0] flash_out_d3_ddr,
    input  [1:0] flash_in_d0_ddr,
    input  [1:0] flash_in_d1_ddr,
    input  [1:0] flash_in_d2_ddr,
    input  [1:0] flash_in_d3_ddr,
    output reg [3:0] flash_pin_dir  /* 1'b1 == output, 1'b0 == input */
);

reg [8:0] init_seq [27:0];

initial init_seq [0] = 9'h0ae;
initial init_seq [1] = 9'h0a8;
initial init_seq [2] = 9'h17f;
initial init_seq [3] = 9'h0a2;
initial init_seq [4] = 9'h100;
initial init_seq [5] = 9'h0a1;
initial init_seq [6] = 9'h100;
initial init_seq [7] = 9'h0a4;
initial init_seq [8] = 9'h0a0;
initial init_seq [9] = 9'h164;
initial init_seq [10] = 9'h081;
initial init_seq [11] = 9'h175;
initial init_seq [12] = 9'h082;
initial init_seq [13] = 9'h160;
initial init_seq [14] = 9'h083;
initial init_seq [15] = 9'h16a;
initial init_seq [16] = 9'h087;
initial init_seq [17] = 9'h10f;
initial init_seq [18] = 9'h0b9;
initial init_seq [19] = 9'h0b1;
initial init_seq [20] = 9'h122;
initial init_seq [21] = 9'h0b3;
initial init_seq [22] = 9'h140;
initial init_seq [23] = 9'h0bb;
initial init_seq [24] = 9'h108;
initial init_seq [25] = 9'h0be;
initial init_seq [26] = 9'h12f;
initial init_seq [27] = 9'h0af;

localparam state_begin = 4'd0;
localparam state_reset = 4'd1;
localparam state_wait  = 4'd2;
localparam state_init             = 4'd3;
localparam state_init_wait        = 4'd4; 
localparam state_patt_start       = 4'd5;
localparam state_do_patt1         = 4'd6;
localparam state_do_patt1_wait    = 4'd7;
localparam state_do_patt2         = 4'd8;
localparam state_do_patt2_wait    = 4'd9;
localparam state_done             = 4'd10;



reg [3:0] state = state_begin;

reg [4:0] count = 5'd0;

reg [8:0] dat;
reg go;
reg done;

localparam dat_state_idle  = 2'd0;
localparam dat_state_dcb   = 2'd1;
localparam dat_state_shift = 2'd2;
localparam dat_state_done  = 2'd3;

reg [7:0] shift;
reg [3:0] dat_count;
reg [1:0] dat_state = dat_state_idle;

reg [15:0] col;
reg [15:0] col2;
reg [3:0] col3;

always @(posedge CLK)
begin
    if (RSTb == 1'b0) begin
        dat_state  <= dat_state_idle;
        shift       <= 8'd0;
        dat_count   <= 4'd0;
        OLED_DCb <= 1'b0;
    end
    else begin
        done <= 1'b0;
        OLED_SDCLK <= 1'b1;
        OLED_SDOUT <= 1'b1;
        OLED_CSb   <= 1'b1;
        case (dat_state)
            dat_state_idle: begin
                if (go == 1'b1) begin
                    dat_state <= dat_state_dcb;
                    OLED_DCb <= dat[8];
                    dat_count <= 4'd0;
                    shift <= dat[7:0];
                end    
            end
            dat_state_dcb: begin
                OLED_CSb <= 1'b0;
                OLED_SDOUT <= shift[7];
                dat_state <= dat_state_shift;
            end
            dat_state_shift: begin
                dat_count <= dat_count + 1;
                OLED_CSb <= 1'b0;
                OLED_SDCLK <= dat_count[0];
                OLED_SDOUT <= shift[7];
                if (dat_count[0] == 1'b1) begin
                    shift <= {shift[6:0], 1'b0};
                end
                if (dat_count == 4'd15)
                    dat_state <= dat_state_done;
            end
            dat_state_done: begin
                done <= 1'b1;
                dat_state <= dat_state_idle;
            end
        endcase            
    end
end


always @(posedge CLK)
begin
    if (RSTb == 1'b0) begin
        state   <= state_begin;
        count   <= 4'd0;
        address <= 24'd0;
    end else begin
        OLED_RESb <= 1'b1;
        go <= 1'b0;

        case (state)
            state_begin: begin
                state <= state_reset;
                count <= 5'd0;
            end
            state_reset: begin
                OLED_RESb <= 1'b0;
                count <= count + 1;
                if (count == 5'd31) begin
                    state <= state_wait;
                    count <= 5'd0;
                end    
            end    
            state_wait: begin
                count <= count + 1; 
                if (count == 5'd31) begin
                    state <= state_init;
                    count <= 5'd0;
                end  
            end
            state_init: begin
                dat <= init_seq[count];  
                go <= 1'b1;
                state <= state_init_wait;
            end    
            state_init_wait: begin
                if (done == 1'b1) begin
                    state <= state_init;
                    count <= count + 1;
                    if (count == 5'd27)
                        state <= state_patt_start;
                end
            end
            state_patt_start: begin
                fsr_go <= 1'b1;
                state <= state_do_patt1;    
            end
            state_do_patt1: begin
                if (fsr_rd_done == 1'b1) begin
                    dat <= data_out[15:8];
                    state <= state_do_patt1_wait;
                    go <= 1'b1;
                end
            end
            state_do_patt1_wait: begin
                if (done == 1'b1) begin
                    dat <= data_out[7:0];
                    state <= state_do_patt2;
                    go <= 1'b1;
                end
            end
            state_do_patt2: begin
                if (done == 1'b1) begin
                    address <= address + 2;
                    state <= state_patt_start;
                end    
            end

        endcase    
    end    
end

// At start of frame, begin to read 160*128 = 40960 16 bit words from flash
// and stream to OLED 

localparam fsr_idle                = 4'd0;
localparam fsr_shift_command       = 4'd1;
localparam fsr_shift_address       = 4'd2;
localparam fsr_shift_flash_word    = 4'd3;
localparam fsr_done                = 4'd4;

reg [23:0] address = 24'd0;
reg [23:0] shift_reg;
reg [23:0] continue_reg;
reg [3:0]  fsr_state = fsr_idle;

reg fsr_go = 1'b0;
reg fsr_rd_done = 1'b0;

reg [15:0] data_out;

always @(posedge CLK)
begin
    if (RSTb == 1'b0) begin
        flash_csb    <= 1'b1;
        flash_clk_ddr    <= 2'b00;
        flash_out_d0_ddr <= 2'b00;
        flash_out_d1_ddr <= 2'b00;
        flash_out_d2_ddr <= 2'b00;
        flash_out_d3_ddr <= 2'b00;
        flash_pin_dir    <= 4'b0001; 
        shift_reg        <= 24'd0;
        fsr_state        <= fsr_idle;
        fsr_rd_done         <= 1'b0;
    end else begin
        flash_csb       <= 1'b1;
        flash_clk_ddr   <= 2'b00;
        fsr_rd_done     <= 1'b0;

        case (fsr_state)
                  fsr_idle: begin
                if (fsr_go == 1'b1) begin
                    flash_csb <= 1'b0;
                    fsr_state <= fsr_shift_command;
                    shift_reg <= {8'h3, 16'd0};
                    continue_reg <= {8'hff, 16'd0};
                end
            end    
            fsr_shift_command: begin
                flash_csb     <= 1'b0;
                flash_clk_ddr <= 2'b01;
                flash_out_d0_ddr <= {2{shift_reg[23]}};
                shift_reg <= {shift_reg[22:0], 1'b0};
                continue_reg <= {continue_reg[22:0], 1'b0};
                if (continue_reg[23] == 1'b0) begin
                    fsr_state <= fsr_shift_address;
                    shift_reg <= address;
                    continue_reg <= 24'hffffff;
                end
            end
            fsr_shift_address: begin
                flash_csb     <= 1'b0;
                flash_clk_ddr <= 2'b01;
                flash_out_d0_ddr <= {2{shift_reg[23]}};
                shift_reg <= {shift_reg[22:0], 1'b0};
                continue_reg <= {continue_reg[22:0], 1'b0};
                if (continue_reg[23] == 1'b0) begin
                    fsr_state <= fsr_shift_flash_word;
                    continue_reg <= 24'hffff00;
                end
            end
            fsr_shift_flash_word: begin
                flash_csb     <= 1'b0;
                flash_clk_ddr <= 2'b01;
                flash_out_d0_ddr <= {2{shift_reg[23]}};
                shift_reg <= {shift_reg[22:0], flash_in_d1_ddr[1]};
                continue_reg <= {continue_reg[22:0], 1'b0};
                if (continue_reg[23] == 1'b0) begin
                    fsr_state <= fsr_done;
                end
            end
            fsr_done: begin
               fsr_state <= fsr_idle;
               data_out <= shift_reg[15:0];
               fsr_rd_done <= 1'b1; 
           end
        endcase
    end 
end

endmodule
