// Testbench for Edge Detector
`timescale 1ns/1ps

module tb_edge_detector();

    reg clk;
    reg rst_n;
    reg sig_in;
    wire pos_edge, neg_edge, any_edge;

    // Generate clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period = 100MHz
    end

    // Instantiate the module
    edge_detector uut (
        .clk(clk),
        .rst_n(rst_n),
        .sig_in(sig_in),
        .pos_edge(pos_edge),
        .neg_edge(neg_edge),
        .any_edge(any_edge)
    );

    // Test stimulus
    initial begin
        $display("Starting edge detector test...");
        $monitor("Time: %0t, sig_in: %b, pos_edge: %b, neg_edge: %b, any_edge: %b", 
                 $time, sig_in, pos_edge, neg_edge, any_edge);

        // Initialize
        rst_n = 0;
        sig_in = 0;
        #20;
        rst_n = 1;
        #10;
        
        // Test various signal transitions
        sig_in = 0; #10;
        sig_in = 1; #10;  // Positive edge
        sig_in = 1; #10;
        sig_in = 0; #10;  // Negative edge
        sig_in = 1; #10;  // Positive edge
        sig_in = 1; #10;
        sig_in = 0; #10;  // Negative edge
        sig_in = 1; #10;  // Positive edge
        
        $display("Edge detector test completed.");
        $finish;
    end

    // Dump waves
    initial begin
        $dumpfile("tb_edge_detector.vcd");
        $dumpvars(0, tb_edge_detector);
    end

endmodule