// Clock Mux Module
module clk_mux #(
    parameter NUM_INPUTS = 2
)(
    input  wire [NUM_INPUTS-1:0] clk_in,
    input  wire [$clog2(NUM_INPUTS)-1:0] sel,
    output wire clk_out
);

    reg clk_mux_reg;

    always @(*) begin
        clk_mux_reg = clk_in[sel];
    end

    assign clk_out = clk_mux_reg;

endmodule