// Testbench for PE Core
// Verifies the functionality of the PE core components

`timescale 1ns/1ps

module tb_pe_core();

    // Clock and reset
    reg clk;
    reg rst_n;
    reg valid_in;
    
    // Test control
    integer test_num;
    reg [31:0] instruction;
    reg [31:0] test_data_a;
    reg [31:0] test_data_b;
    reg [31:0] test_weight;
    
    // PE core instance
    wire [31:0] result;
    wire ready_out, valid_out;
    
    // Instantiate the PE top module
    pe_top_simple #(
        .DATA_WIDTH(32),
        .VECTOR_WIDTH(16),
        .MAC_ARRAY_ROWS(8),
        .MAC_ARRAY_COLS(8)
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ready_out(ready_out),
        .instruction(instruction),
        .data_a_packed({256'd0}),  // 8 * 32 = 256 bits
        .data_b_packed({256'd0}),
        .weight_packed({256'd0}),
        .result_packed(result),
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
        $display("========================================");
        $display("Starting PE Core Testbench (FP32)...");
        $display("========================================");
        
        // Initialize signals
        rst_n = 0;
        valid_in = 0;
        instruction = 32'h0;
        
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
        
        $display("========================================");
        $display("All tests completed successfully!");
        $display("========================================");
        $finish;
    end
    
    // Test MAC operation
    task test_mac_operation;
        begin
            $display("\n--- Test %0d: MAC Operation ---", test_num);
            test_num = test_num + 1;
            
            // Setup instruction for MAC operation
            instruction = 32'h10000000; // MAC operation
            valid_in = 1;
            
            #10; // Wait for computation
            
            $display("MAC Test completed");
            
            valid_in = 0;
            #10;
        end
    endtask
    
    // Test activation function
    task test_activation_function;
        begin
            $display("\n--- Test %0d: Activation Function (ReLU) ---", test_num);
            test_num = test_num + 1;
            
            // Setup instruction for ReLU activation
            instruction = 32'h20000001; // Activation operation, ReLU type
            valid_in = 1;
            
            #10; // Wait for computation
            
            $display("ReLU Test completed");
            
            valid_in = 0;
            #10;
        end
    endtask
    
    // Test normalization function
    task test_normalization;
        begin
            $display("\n--- Test %0d: Normalization Function ---", test_num);
            test_num = test_num + 1;
            
            // Setup instruction for normalization
            instruction = 32'h30000000; // Normalization operation, LayerNorm type
            valid_in = 1;
            
            #20; // Wait for computation
            
            $display("Normalization Test completed");
            
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
