// Testbench for Clock Divider
`timescale 1ns/1ps

module tb_clk_divider();

    reg clk_in;
    reg rst_n;
    wire clk_out;

    // Instantiate the module
    clk_divider #(.DIV_FACTOR(4)) uut (
        .clk_in(clk_in),
        .rst_n(rst_n),
        .clk_out(clk_out)
    );

    // Clock generation
    initial begin
        clk_in = 0;
        forever #1 clk_in = ~clk_in;  // 2ns period = 500MHz
    end

    // Test stimulus
    initial begin
        $display("Starting clock divider test...");
        $monitor("Time: %0t, clk_in: %b, clk_out: %b", $time, clk_in, clk_out);

        // Initialize
        rst_n = 0;
        #10;
        rst_n = 1;
        
        // Run for several cycles
        #200;
        
        $display("Clock divider test completed.");
        $finish;
    end

    // Dump waves
    initial begin
        $dumpfile("tb_clock_divider.vcd");
        $dumpvars(0, tb_clk_divider);
    end

endmodule