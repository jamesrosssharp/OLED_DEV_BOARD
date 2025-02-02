/* vim: set et ts=4 sw=4: */

/*
 *	(C) 2022 J. R. Sharp
 *
 *	Top level for ulx3s board
 *
 *	See LICENSE.txt for software license
 */

//`define TEST_GENERATOR

module my_top (
	input	CLK12,

	input UP_BUTTON,
	input DOWN_BUTTON,
	input LEFT_BUTTON,
	input RIGHT_BUTTON,
	input A_BUTTON,
	input B_BUTTON,

	output OLED_RESb,
	output OLED_CSb,
	output [7:0] OLED_DB,

	output OLED_E,			
	output OLED_RWb,
	output OLED_DCb,

	output RGB0,
	output RGB1,
	output RGB2,

    input  SCK,
    input  MOSI,
    input  CSb 

);

oled o0 (
    CLK12,
    1'b1,

    OLED_DCb,
    OLED_RESb,
    OLED_CSb,
    OLED_DB[1], // SDIN
    OLED_DB[0]  // SCLK
);


assign OLED_E = 1'b0;
assign OLED_DB[7:3] = 5'd0;
assign OLED_DB[2] = 1'bz;   // This might be MISO?
assign OLED_RWb = 1'b0;

wire clk;

SB_RGBA_DRV RGBA_DRIVER (
  .CURREN(1'b1),
  .RGBLEDEN(1'b1),
  .RGB0PWM(| {UP_BUTTON, DOWN_BUTTON}),
  .RGB1PWM(| {A_BUTTON, B_BUTTON}),
  .RGB2PWM(| {LEFT_BUTTON, RIGHT_BUTTON, OLED_RESb}),
  .RGB0(RGB0),
  .RGB1(RGB1),
  .RGB2(RGB2)
);

defparam RGBA_DRIVER.CURRENT_MODE = "0b1";
defparam RGBA_DRIVER.RGB0_CURRENT = "0b000111";
defparam RGBA_DRIVER.RGB1_CURRENT = "0b000111";
defparam RGBA_DRIVER.RGB2_CURRENT = "0b000111";

endmodule
