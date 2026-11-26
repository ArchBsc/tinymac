`default_nettype none
module mac_controller(
    input  logic       clk,
    input  logic       rst_n,
    input  logic [1:0] opcode,
    input  logic       strobe,

    output logic       acc_we,
    output logic       mac_en,
    output logic       load_bias
);
typedef enum logic{
    READY        = 1'b0,
        WAIT_RELEASE = 1'b1
}state_t;

state_t state, next_state;

localparam logic [1:0] OP_IDLE      = 2'b00;
localparam logic [1:0] OP_LOAD_BIAS = 2'b01;
localparam logic [1:0] OP_MAC       = 2'b10;
localparam logic [1:0] OP_RESERVED  = 2'b11;

always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= READY;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
    next_state = state;

    case (state)
        READY:
            if (strobe) next_state = WAIT_RELEASE;

        WAIT_RELEASE:
            if (!strobe) next_state = READY;

        default:
            next_state = READY;
    endcase
end

always_comb begin
    // Default: όλα 0 (καλύπτει WAIT_RELEASE, reset, IDLE και RESERVED)
    acc_we    = 1'b0;
    mac_en    = 1'b0;
    load_bias = 1'b0;

    // Ενεργοποίηση ΜΟΝΟ όταν ισχύουν και τα 3 μαζί
    if (state == READY && strobe && rst_n) begin
        case (opcode)
            OP_LOAD_BIAS: begin
                acc_we    = 1'b1;
                load_bias = 1'b1;
            end

            OP_MAC: begin
                acc_we = 1'b1;
                mac_en = 1'b1;
            end

            default: begin
                // OP_IDLE (00) και OP_RESERVED (11): μένουν όλα 0
            end
        endcase
    end
end
endmodule
`default_nettype wire