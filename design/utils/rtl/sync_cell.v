// 2-Level Synchronization Cell
module sync_cell (
    input  wire clk,
    input  wire rst_n,
    input  wire async_in,
    output reg  sync_out
);

    reg stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1 <= 1'b0;
            sync_out <= 1'b0;
        end
        else begin
            stage1 <= async_in;
            sync_out <= stage1;
        end
    end

endmodule