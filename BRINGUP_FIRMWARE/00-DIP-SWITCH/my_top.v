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

	input BS1,
	input BS2,
	
	output RGB0,
	output RGB1,
	output RGB2
);

wire clk;

SB_RGBA_DRV RGBA_DRIVER (
  .CURREN(1'b1),
  .RGBLEDEN(1'b1),
  .RGB0PWM(BS1),
  .RGB1PWM(BS2),
  .RGB2PWM(1'b0),
  .RGB0(RGB0),
  .RGB1(RGB1),
  .RGB2(RGB2)
);

defparam RGBA_DRIVER.CURRENT_MODE = "0b1";
defparam RGBA_DRIVER.RGB0_CURRENT = "0b000111";
defparam RGBA_DRIVER.RGB1_CURRENT = "0b000111";
defparam RGBA_DRIVER.RGB2_CURRENT = "0b000111";

endmodule
