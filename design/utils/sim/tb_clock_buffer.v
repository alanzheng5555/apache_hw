// Testbench for Clock Buffer
`timescale 1ns/1ps

module tb_clk_buffer();

    reg clk_in;
    wire clk_out;

    // Instantiate the module
    clk_buffer uut (
        .clk_in(clk_in),
        .clk_out(clk_out)
    );

    // Clock generation
    initial begin
        clk_in = 0;
        forever #5 clk_in = ~clk_in;  // 10ns period = 100MHz
    end

    // Test stimulus
    initial begin
        $display("Starting clock buffer test...");
        $monitor("Time: %0t, clk_in: %b, clk_out: %b", $time, clk_in, clk_out);

        // Initialize
        #10;
        
        // Run for several cycles
        #100;
        
        $display("Clock buffer test completed.");
        $finish;
    end

    // Dump waves
    initial begin
        $dumpfile("tb_clock_buffer.vcd");
        $dumpvars(0, tb_clk_buffer);
    end

endmodule