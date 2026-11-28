
`default_nettype none

module mac_core (
    input  logic               clk,
    input  logic               rst_n,
    input  logic [1:0]         opcode,
    input  logic               strobe,

    input  logic signed [3:0]  x,
    input  logic signed [3:0]  w,
    input  logic signed [7:0]  bias,

    output logic signed [15:0] acc
);

    // Εσωτερικά control signals
    logic acc_we;
    logic mac_en;
    logic load_bias;

    // Controller instance
    mac_controller u_controller (
        .clk       (clk),
        .rst_n     (rst_n),
        .opcode    (opcode),
        .strobe    (strobe),
        .acc_we    (acc_we),
        .mac_en    (mac_en),
        .load_bias (load_bias)
    );

    // Datapath instance
    mac_datapath u_datapath (
        .clk       (clk),
        .rst_n     (rst_n),
        .x         (x),
        .w         (w),
        .bias      (bias),
        .acc_we    (acc_we),
        .mac_en    (mac_en),
        .load_bias (load_bias),
        .acc       (acc)
    );

endmodule

`default_nettype wire
