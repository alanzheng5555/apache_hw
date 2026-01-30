// Testbench for Clock Mux
`timescale 1ns/1ps

module tb_clk_mux();

    reg [1:0] clk_in;
    reg [0:0] sel;
    wire clk_out;

    // Generate different frequency clocks
    initial begin
        clk_in[0] = 0;
        forever #5 clk_in[0] = ~clk_in[0];  // 10ns period = 100MHz
    end

    initial begin
        clk_in[1] = 0;
        forever #2.5 clk_in[1] = ~clk_in[1];  // 5ns period = 200MHz
    end

    // Instantiate the module
    clk_mux #(.NUM_INPUTS(2)) uut (
        .clk_in(clk_in),
        .sel(sel),
        .clk_out(clk_out)
    );

    // Test stimulus
    initial begin
        $display("Starting clock mux test...");
        $monitor("Time: %0t, clk_in[0]: %b, clk_in[1]: %b, sel: %b, clk_out: %b", 
                 $time, clk_in[0], clk_in[1], sel, clk_out);

        // Initialize
        sel = 0;
        #20;
        
        // Switch to input 1
        sel = 1;
        #20;
        
        // Switch back to input 0
        sel = 0;
        #20;
        
        $display("Clock mux test completed.");
        $finish;
    end

    // Dump waves
    initial begin
        $dumpfile("tb_clock_mux.vcd");
        $dumpvars(0, tb_clk_mux);
    end

endmodule