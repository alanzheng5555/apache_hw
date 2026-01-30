// Testbench for Clock Gating
`timescale 1ns/1ps

module tb_clk_gating();

    reg clk_in;
    reg en;
    reg rst_n;
    wire clk_out;

    // Generate clock
    initial begin
        clk_in = 0;
        forever #1 clk_in = ~clk_in;  // 2ns period = 500MHz
    end

    // Instantiate the module
    clk_gating uut (
        .clk_in(clk_in),
        .en(en),
        .rst_n(rst_n),
        .clk_out(clk_out)
    );

    // Test stimulus
    initial begin
        $display("Starting clock gating test...");
        $monitor("Time: %0t, clk_in: %b, en: %b, rst_n: %b, clk_out: %b", 
                 $time, clk_in, en, rst_n, clk_out);

        // Initialize
        rst_n = 0;
        en = 0;
        #10;
        rst_n = 1;
        #10;
        
        // Enable clock
        en = 1;
        #50;
        
        // Disable clock
        en = 0;
        #50;
        
        // Re-enable clock
        en = 1;
        #50;
        
        $display("Clock gating test completed.");
        $finish;
    end

    // Dump waves
    initial begin
        $dumpfile("tb_clock_gating.vcd");
        $dumpvars(0, tb_clk_gating);
    end

endmodule