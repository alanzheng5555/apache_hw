// Testbench for Clock Switch
`timescale 1ns/1ps

module tb_clk_switch();

    reg clk_primary;
    reg clk_backup;
    reg switch_en;
    wire clk_out;

    // Generate different clocks
    initial begin
        clk_primary = 0;
        forever #5 clk_primary = ~clk_primary;  // 10ns period = 100MHz
    end

    initial begin
        clk_backup = 0;
        forever #2.5 clk_backup = ~clk_backup;  // 5ns period = 200MHz
    end

    // Instantiate the module
    clk_switch uut (
        .clk_primary(clk_primary),
        .clk_backup(clk_backup),
        .switch_en(switch_en),
        .clk_out(clk_out)
    );

    // Test stimulus
    initial begin
        $display("Starting clock switch test...");
        $monitor("Time: %0t, primary: %b, backup: %b, switch_en: %b, clk_out: %b", 
                 $time, clk_primary, clk_backup, switch_en, clk_out);

        // Initialize
        switch_en = 0;
        #20;
        
        // Switch to backup
        switch_en = 1;
        #20;
        
        // Switch back to primary
        switch_en = 0;
        #20;
        
        $display("Clock switch test completed.");
        $finish;
    end

    // Dump waves
    initial begin
        $dumpfile("tb_clock_switch.vcd");
        $dumpvars(0, tb_clk_switch);
    end

endmodule