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
    input  MOSI, /* host (PC) to iCE */
    output MISO, /* device (iCE) to PC */
    input  CSb,

    output FLASH_CSb,
    output FLASH_SCK,
    inout  FLASH_D0,
    inout  FLASH_D1,
    inout  FLASH_D2,
    inout  FLASH_D3

);


wire   [1:0] flash_clk_ddr;
wire   [1:0] flash_out_d0_ddr;
wire   [1:0] flash_out_d1_ddr;
wire   [1:0] flash_out_d2_ddr;
wire   [1:0] flash_out_d3_ddr;
wire   [1:0] flash_in_d0_ddr;
wire   [1:0] flash_in_d1_ddr;
wire   [1:0] flash_in_d2_ddr;
wire   [1:0] flash_in_d3_ddr;
wire   [3:0] flash_pin_dir;


SB_IO #(
    .PIN_TYPE(6'b 1100_00), // ddr output with register enable signal, ddr input
    .PULLUP(1'b 0)
) flash_io_buf [3:0] (
    .PACKAGE_PIN({FLASH_D3, FLASH_D2, FLASH_D1, FLASH_D0}),
    .OUTPUT_ENABLE({flash_pin_dir[3], flash_pin_dir[2], flash_pin_dir[1], flash_pin_dir[0]}),
    .D_OUT_0({flash_out_d3_ddr[0], flash_out_d2_ddr[0], flash_out_d1_ddr[0], flash_out_d0_ddr[0]}),
    .D_OUT_1({flash_out_d3_ddr[1], flash_out_d2_ddr[1], flash_out_d1_ddr[1], flash_out_d0_ddr[1]}),
    .D_IN_0({flash_in_d3_ddr[0], flash_in_d2_ddr[0], flash_in_d1_ddr[0], flash_in_d0_ddr[0]}),
    .D_IN_1({flash_in_d3_ddr[1], flash_in_d2_ddr[1], flash_in_d1_ddr[1], flash_in_d0_ddr[1]}),
    .OUTPUT_CLK(CLK12),
    .INPUT_CLK(CLK12)
);

SB_IO #(
    .PIN_TYPE(6'b 0100_01), // ddr output, simple input
    .PULLUP(1'b 0)
) flash_clk_buf  (
    .PACKAGE_PIN(FLASH_SCK),
    .D_OUT_0(flash_clk_ddr[0]),
    .D_OUT_1(flash_clk_ddr[1]),
    .OUTPUT_CLK(CLK12),
    .INPUT_CLK(CLK12)
);

assign OLED_E = 1'b0;
assign OLED_DB[7:3] = 5'd0;
assign OLED_DB[2] = 1'bz;   // This might be MISO?
assign OLED_RWb = 1'b0;


oled o0 (
    CLK12,
    1'b1,

    OLED_DCb,
    OLED_RESb,
    OLED_CSb,
    OLED_DB[1], // SDIN
    OLED_DB[0],  // SCLK

    FLASH_CSb,
    flash_clk_ddr,
    flash_out_d0_ddr,
    flash_out_d1_ddr,
    flash_out_d2_ddr,
    flash_out_d3_ddr,
    flash_in_d0_ddr,
    flash_in_d1_ddr,
    flash_in_d2_ddr,
    flash_in_d3_ddr,
    flash_pin_dir  
);




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
