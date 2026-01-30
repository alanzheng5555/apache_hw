// Testbench for Sync Cell
`timescale 1ns/1ps

module tb_sync_cell();

    reg clk;
    reg rst_n;
    reg async_in;
    wire sync_out;

    // Generate clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period = 100MHz
    end

    // Instantiate the module
    sync_cell uut (
        .clk(clk),
        .rst_n(rst_n),
        .async_in(async_in),
        .sync_out(sync_out)
    );

    // Test stimulus
    initial begin
        $display("Starting sync cell test...");
        $monitor("Time: %0t, clk: %b, async_in: %b, sync_out: %b", 
                 $time, clk, async_in, sync_out);

        // Initialize
        rst_n = 0;
        async_in = 0;
        #20;
        rst_n = 1;
        #10;
        
        // Toggle async input
        async_in = 1;
        #30;
        async_in = 0;
        #30;
        async_in = 1;
        #30;
        async_in = 0;
        #30;
        
        $display("Sync cell test completed.");
        $finish;
    end

    // Dump waves
    initial begin
        $dumpfile("tb_sync_cell.vcd");
        $dumpvars(0, tb_sync_cell);
    end

endmodule