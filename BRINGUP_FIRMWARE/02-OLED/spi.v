/* vim: set et ts=4 sw=4: */

/*
	1-bit AM radio

spi.v: SPI configuration

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

module spi
(
    input CLK,
    input RSTb,
    input MOSI,
    input SCK,
    input CS,

    output reg DCb,
    output reg RESb,

    output OLED_CSb,
    output reg OLED_SDOUT,
    output reg OLED_SCK

);

localparam state_idle = 2'b00;
localparam state_rx   = 2'b01;
localparam state_done = 2'b10;

reg [1:0] state = state_idle;

reg CS_q;
reg CS_qq;
reg CS_qqq;

reg SCK_q;
reg SCK_qq;
reg SCK_qqq;

reg MOSI_q;
reg MOSI_qq;

reg [3:0] count = 4'd0;

//assign OLED_SDOUT = (count > 4'd7) ? MOSI_qq : 1'b0;
//assign OLED_SCK   = (count > 4'd7) ? SCK_qq  : 1'b0;
assign OLED_CSb   = (count > 4'd6) ? 1'b0 : 1'b1;


always @(posedge CLK)
begin
    if (RSTb == 1'b0) begin
        state       <= state_idle;

        CS_q    <= 1'b0;
        CS_qq   <= 1'b0;
        CS_qqq  <= 1'b0;

        SCK_q   <= 1'b0;
        SCK_qq  <= 1'b0;
        SCK_qqq <= 1'b0;

        MOSI_q  <= 1'b0;
        MOSI_qq <= 1'b0;

        count <= 4'd0;

    end
    else begin
        CS_q    <= CS;
        CS_qq   <= CS_q;
        CS_qqq  <= CS_qq;

        SCK_q   <= SCK;
        SCK_qq  <= SCK_q;
        SCK_qqq <= SCK_qq;

        MOSI_q  <= MOSI;
        MOSI_qq <= MOSI_q;

        OLED_SDOUT <= 1'b1;
        OLED_SCK   <= 1'b1;


        case (state)
            state_idle:
                if (CS_qq == 1'b0 && CS_qqq == 1'b1) begin // falling edge of chip select
                    state       <= state_rx;
                    shift_reg   <= 32'd0;
                    count       <= 4'd0;
                end
            state_rx: begin
                if (SCK_qq == 1'b1 && SCK_qqq == 1'b0) begin // rising edge
                    count <= count + 1;
                    if (count == 4'd5)
                        RESb <= MOSI_qq;
                    if (count == 4'd6)
                        DCb <= MOSI_qq;

                end

                if (CS_qq == 1'b1 && CS_qqq == 1'b0) begin
                    state <= state_done;
                end

                if (count > 4'd7)
                begin
                    OLED_SDOUT <= MOSI_qq;
                    OLED_SCK   <= SCK_qq;
                end
            end
            state_done: begin
                phase_inc <= shift_reg[25:0];
                gain      <= shift_reg[29:26];
                state <= state_idle;
            end
            default:
                state <= state_idle;
        endcase
    end        
end

endmodule
