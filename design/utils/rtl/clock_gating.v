// Clock Gating Cell
module clk_gating (
    input  wire clk_in,
    input  wire en,
    input  wire rst_n,
    output wire clk_out
);

    wire gated_clk;
    reg  latch_reg;

    // Latch the enable signal when reset is inactive
    always @(posedge ~rst_n or posedge en) begin
        if (!rst_n)
            latch_reg <= 1'b0;
        else
            latch_reg <= en;
    end

    assign gated_clk = clk_in & latch_reg;
    assign clk_out = gated_clk;

endmodule