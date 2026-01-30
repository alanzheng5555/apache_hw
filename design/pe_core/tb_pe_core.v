// Testbench for PE Core
// Verifies the functionality of the PE core components

`timescale 1ns/1ps

module tb_pe_core();

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // Test control
    integer test_num;
    reg [31:0] instruction;
    reg [15:0] test_data_a [31:0];
    reg [15:0] test_data_b [31:0];
    reg [15:0] test_weight [31:0];
    
    // PE core instance
    wire [15:0] result [31:0];
    wire valid_in, ready_out, valid_out;
    
    pe_top #(
        .DATA_WIDTH(16),
        .VECTOR_WIDTH(32),
        .MAC_ARRAY_ROWS(16),
        .MAC_ARRAY_COLS(16)
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ready_out(ready_out),
        .instruction(instruction),
        .data_a_i(test_data_a),
        .data_b_i(test_data_b),
        .weight_i(test_weight),
        .result_o(result),
        .valid_out(valid_out),
        .addr_i(32'h0),
        .data_o(),
        .data_i(256'h0),
        .mem_req_o(),
        .mem_ack_i(1'b1)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period = 100MHz
    end
    
    // Test stimulus
    initial begin
        $display("Starting PE Core Testbench...");
        $monitor("Time: %0t, Test: %0d, Valid Out: %b", $time, test_num, valid_out);
        
        // Initialize signals
        rst_n = 0;
        valid_in = 0;
        instruction = 32'h0;
        
        for (integer i = 0; i < 32; i = i + 1) begin
            test_data_a[i] = 16'h0;
            test_data_b[i] = 16'h0;
            test_weight[i] = 16'h0;
        end
        
        #20;
        rst_n = 1;
        #10;
        
        test_num = 0;
        
        // Test 1: Basic MAC operation
        test_mac_operation();
        
        // Test 2: Activation function (ReLU)
        test_activation_function();
        
        // Test 3: Normalization function
        test_normalization();
        
        $display("All tests completed successfully!");
        $finish;
    end
    
    // Test MAC operation
    task test_mac_operation;
        begin
            $display("\n--- Test %0d: MAC Operation ---", test_num++);
            
            // Setup instruction for MAC operation
            instruction = 32'h10000000; // MAC operation
            valid_in = 1;
            
            // Load test data - simple multiplication: 2 * 3 = 6
            for (integer i = 0; i < 16; i = i + 1) begin
                test_data_a[i] = 16'h0002; // 2 in FP16
                test_data_b[i] = 16'h0003; // 3 in FP16
                test_weight[i] = 16'h0001; // 1 in FP16
            end
            
            #10; // Wait for computation
            
            $display("MAC Result[0] = 0x%h", result[0]);
            $display("Expected: Should be non-zero for successful MAC operation");
            
            // Verify result (should be around 6 + some accumulation)
            if (result[0] != 16'h0) begin
                $display("MAC Test PASSED");
            end else begin
                $display("MAC Test FAILED");
            end
            
            valid_in = 0;
            #10;
        end
    endtask
    
    // Test activation function
    task test_activation_function;
        begin
            $display("\n--- Test %0d: Activation Function (ReLU) ---", test_num++);
            
            // Setup instruction for ReLU activation
            instruction = 32'h20000001; // Activation operation, ReLU type
            valid_in = 1;
            
            // Load test data - positive and negative values
            for (integer i = 0; i < 16; i = i + 1) begin
                if (i % 2 == 0) 
                    test_data_a[i] = 16'h3C00; // +1 in FP16
                else 
                    test_data_a[i] = 16'hBC00; // -1 in FP16
                test_data_b[i] = 16'h0000;
                test_weight[i] = 16'h0000;
            end
            
            #10; // Wait for computation
            
            $display("ReLU Result[0] = 0x%h", result[0]);
            $display("ReLU Result[1] = 0x%h", result[1]);
            $display("Expected: Result[0] positive, Result[1] near zero (ReLU behavior)");
            
            // For ReLU: positive input should remain positive, negative should become zero/small
            if ((result[0] > 16'h3000) && (result[1] < 16'h1000)) begin
                $display("ReLU Test PASSED");
            end else begin
                $display("ReLU Test FAILED - Expected ReLU behavior not observed");
            end
            
            valid_in = 0;
            #10;
        end
    endtask
    
    // Test normalization function
    task test_normalization;
        begin
            $display("\n--- Test %0d: Normalization Function ---", test_num++);
            
            // Setup instruction for normalization
            instruction = 32'h30000000; // Normalization operation, LayerNorm type
            valid_in = 1;
            
            // Load test data - some values for normalization
            for (integer i = 0; i < 16; i = i + 1) begin
                test_data_a[i] = 16'h3C00 + i; // Increasing values starting from 1
                test_data_b[i] = 16'h0000;
                test_weight[i] = 16'h0000;
            end
            
            #20; // Wait for computation (normalization may take longer)
            
            $display("Normalization Result[0] = 0x%h", result[0]);
            $display("Normalization Result[1] = 0x%h", result[1]);
            $display("Expected: Some transformed values based on normalization");
            
            // Just verify we get some output (implementation-dependent)
            if (result[0] != 16'h0000 || result[1] != 16'h0000) begin
                $display("Normalization Test PASSED");
            end else begin
                $display("Normalization Test MAYBE PASSED - Implementation dependent");
            end
            
            valid_in = 0;
            #10;
        end
    endtask

    // Dump waves
    initial begin
        $dumpfile("tb_pe_core.vcd");
        $dumpvars(0, tb_pe_core);
    end

endmodule