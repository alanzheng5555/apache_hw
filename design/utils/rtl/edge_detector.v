// Edge Detector Module
module edge_detector (
    input  wire clk,
    input  wire rst_n,
    input  wire sig_in,
    output wire pos_edge,
    output wire neg_edge,
    output wire any_edge
);

    reg sig_delayed;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sig_delayed <= 1'b0;
        end
        else begin
            sig_delayed <= sig_in;
        end
    end

    assign pos_edge = sig_in & ~sig_delayed;
    assign neg_edge = ~sig_in & sig_delayed;
    assign any_edge = sig_in ^ sig_delayed;

endmodule