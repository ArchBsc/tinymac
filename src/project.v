`default_nettype none

module tt_um_archbsc_tinymac (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire ena,
    input  wire clk,
    input  wire rst_n
);

  wire [1:0] opcode;
  wire [1:0] read_sel;
  wire strobe;

  wire signed [3:0] x;
  wire signed [3:0] w;
  wire signed [7:0] bias;

  wire signed [15:0] acc;

  wire [1:0] opcode;
  wire [1:0] read_sel;
  wire strobe;

  wire signed [3:0] x;
  wire signed [3:0] w;
  wire signed [7:0] bias;

  wire signed [15:0] acc;


  mac_core u_mac_core (
    .clk    (clk),
    .rst_n  (rst_n),
    .opcode (opcode),
    .strobe (strobe),
    .x      (x),
    .w      (w),
    .bias   (bias),
    .acc    (acc)
);
  assign uo_out = (read_sel == 2'b00) ? acc[7:0]  :
                (read_sel == 2'b01) ? acc[15:8] :
                                     8'b0;

  assign uio_oe  = 8'b0;
  assign uio_out = 8'b0;

endmodule

`default_nettype wire