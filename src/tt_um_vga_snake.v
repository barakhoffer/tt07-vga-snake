/*
 * Copyright (c) 2024 Barak Hoffer
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_snake (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in, ui_in[7:4], 1'b0};

  wire [5:0] rrggbb, rrggbb_snake;
  wire [9:0] x_px;  // X position for actual pixel.
  wire [9:0] y_px;  // Y position for actual pixel.
  wire hsync, vsync, activevideo;

  assign uo_out[0] = rrggbb[5]; // R[1]
  assign uo_out[1] = rrggbb[3]; // G[1]
  assign uo_out[2] = rrggbb[1]; // B[1]
  assign uo_out[3] = vsync;
  assign uo_out[4] = rrggbb[4]; // R[0]
  assign uo_out[5] = rrggbb[2]; // G[1]
  assign uo_out[6] = rrggbb[0]; // B[0]
  assign uo_out[7] = hsync;

  assign rrggbb = activevideo ? rrggbb_snake : 6'b0;

  VgaSyncGen vga_0 (
      .px_clk(clk),
      .hsync(hsync),
      .vsync(vsync),
      .x_px(x_px),
      .y_px(y_px),
      .activevideo(activevideo),
      .reset(~rst_n)
  );

  snake u_snake (
        .clk(clk),
        .rst_n(rst_n),
        .x_px(x_px),
        .y_px(y_px),
        .left(ui_in[0]),
        .right(ui_in[1]),
        .up(ui_in[2]),
        .down(ui_in[3]),
        .rrggbb(rrggbb_snake)
  );

endmodule
