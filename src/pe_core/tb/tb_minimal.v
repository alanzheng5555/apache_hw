// Minimal pipeline test
`timescale 1ns/1ps

module tb_minimal;
    reg clk, rst_n;
    reg [31:0] inp;
    wire [31:0] pipe_out;
    
    // Simple pipeline
    reg [31:0] pipe_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) pipe_reg <= 0;
        else pipe_reg <= inp;
    end
    
    assign pipe_out = pipe_reg;
    
    initial begin
        clk = 0; rst_n = 0; inp = 0;
        
        #30 rst_n = 1;
        #10;
        
        $display("Setting inp=42");
        inp = 42;
        #10;
        
        $display("After 10ns: pipe_out=%0d", pipe_out);
        
        @(posedge clk);
        $display("After 1 clk: pipe_out=%0d", pipe_out);
        
        @(posedge clk);
        $display("After 2 clk: pipe_out=%0d", pipe_out);
        
        $finish;
    end
    
    always #5 clk = ~clk;
endmodule