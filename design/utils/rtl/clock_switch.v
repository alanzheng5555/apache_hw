// Clock Switch Module
module clk_switch (
    input  wire clk_primary,
    input  wire clk_backup,
    input  wire switch_en,
    output wire clk_out
);

    reg clk_switch_reg;

    always @(*) begin
        if (switch_en)
            clk_switch_reg = clk_backup;
        else
            clk_switch_reg = clk_primary;
    end

    assign clk_out = clk_switch_reg;

endmodule