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


`timescale 1 ns / 1 ps
module tb;

reg CLK = 1'b1;

always #50 CLK <= !CLK; // ~ 10MHz

reg RSTb = 1'b1;

reg UP_BUTTON;
reg DOWN_BUTTON;
reg LEFT_BUTTON;
reg RIGHT_BUTTON;
reg A_BUTTON;
reg B_BUTTON;

wire        OLED_RESb;
wire	    OLED_CSb;
wire [7:0]	OLED_DB;

wire OLED_E;		
wire OLED_RWb;
wire OLED_DCb;

wire RGB0;
wire RGB1;
wire RGB2;

reg SCK;
reg MOSI;
reg CSb;

wire OLED_SDOUT;
wire OLED_SDCLK;

oled o0 (
    CLK,
    RSTb,

    OLED_DCb,
    OLED_RESb,
    OLED_CSb,
    OLED_SDOUT,
    OLED_SDCLK
);

 initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
	# 1500000 $finish;
end




endmodule
