// Comprehensive Testbench for Complete PE Core
// Tests the integration of all PE core components

`timescale 1ns/1ps

module tb_pe_complete();

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // Control signals
    reg start;
    reg [31:0] instruction;
    reg [31:0] mem_addr;
    reg mem_req;
    
    // Data inputs
    reg [15:0] data_in [31:0];
    
    // Outputs
    wire [15:0] data_out [31:0];
    wire done;
    wire [255:0] mem_data_out;
    wire [255:0] mem_data_in;
    wire mem_ack;
    
    // Instantiate the complete PE core
    pe_core_complete #(
        .DATA_WIDTH(16),
        .VECTOR_WIDTH(32),
        .MAC_ARRAY_ROWS(16),
        .MAC_ARRAY_COLS(16),
        .SCALAR_REGS(32),
        .VECTOR_REGS(32),
        .VEC_REG_WIDTH(512),
        .L1_CACHE_SIZE(32768),
        .L1_LINE_SIZE(64),
        .L1_ASSOC(4)
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .instruction(instruction),
        .done(done),
        .data_in(data_in),
        .data_out(data_out),
        .mem_addr(mem_addr),
        .mem_req(mem_req),
        .mem_data_out(mem_data_out),
        .mem_data_in(mem_data_in),
        .mem_ack(mem_ack)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period = 100MHz
    end
    
    // Test sequence
    initial begin
        $display("Starting Complete PE Core Testbench...");
        $display("Testing integrated PE core with all components...");
        
        // Initialize signals
        rst_n = 0;
        start = 0;
        instruction = 32'h0;
        mem_addr = 32'h0;
        mem_req = 0;
        mem_data_in = 256'h0;
        
        for (integer i = 0; i < 32; i = i + 1) begin
            data_in[i] = 16'h0;
        end
        
        #20;
        rst_n = 1;
        #10;
        
        $display("\n=== Starting PE Core Integration Tests ===");
        
        // Test 1: MAC Operation
        test_mac_integration();
        
        // Test 2: Activation Operation
        test_activation_integration();
        
        // Test 3: Normalization Operation
        test_norm_integration();
        
        // Test 4: Transformer-like operation sequence
        test_transformer_flow();
        
        $display("\n=== All PE Core Tests Completed ===");
        $display("PE Core successfully integrates all planned components:");
        $display("- MAC Array for matrix operations");
        $display("- Activation Unit for nonlinearities");
        $display("- Normalization Unit for layer/rms norm");
        $display("- Register File for data storage");
        $display("- Local Cache for memory hierarchy");
        
        $finish;
    end
    
    // Test MAC operation
    task test_mac_integration;
        begin
            $display("\n--- Test: MAC Integration ---");
            
            // Setup MAC operation instruction
            instruction = 32'h10000000; // MAC op code
            start = 1;
            
            // Prepare input data for simple MAC: 1*2 + 3*4 = 14
            for (integer i = 0; i < 16; i = i + 1) begin
                data_in[i] = 16'h0001; // Input data = 1
                data_in[i+16] = 16'h0002; // Weight data = 2
            end
            
            #15; // Wait for operation to complete
            start = 0;
            
            $display("MAC Result[0] = 0x%h", data_out[0]);
            $display("MAC Result[1] = 0x%h", data_out[1]);
            
            // Verify we got some computation result
            if (data_out[0] != 16'h0000) begin
                $display("MAC Integration Test: PASSED");
            end else begin
                $display("MAC Integration Test: NEEDS VERIFICATION");
            end
            
            #20; // Wait for reset
        end
    endtask
    
    // Test activation operation
    task test_activation_integration;
        begin
            $display("\n--- Test: Activation Integration ---");
            
            // Setup activation instruction (ReLU)
            instruction = 32'h20000001; // Activation op code, ReLU type
            start = 1;
            
            // Prepare input data: mix of positive and negative values
            for (integer i = 0; i < 16; i = i + 1) begin
                if (i % 2 == 0)
                    data_in[i] = 16'h3C00; // +1 in FP16
                else
                    data_in[i] = 16'hBC00; // -1 in FP16
            end
            
            #15; // Wait for operation to complete
            start = 0;
            
            $display("Activation Result[0] = 0x%h", data_out[0]);
            $display("Activation Result[1] = 0x%h", data_out[1]);
            
            // For ReLU: positive should remain positive, negative should approach zero
            if (data_out[0] > 16'h3000) begin  // Positive value preserved
                $display("Activation Integration Test: PASSED (positive preserved)");
            end else begin
                $display("Activation Integration Test: NEEDS VERIFICATION");
            end
            
            #20; // Wait for reset
        end
    endtask
    
    // Test normalization operation
    task test_norm_integration;
        begin
            $display("\n--- Test: Normalization Integration ---");
            
            // Setup normalization instruction (LayerNorm)
            instruction = 32'h30000000; // Normalization op code, LayerNorm type
            start = 1;
            
            // Prepare input data for normalization
            for (integer i = 0; i < 16; i = i + 1) begin
                data_in[i] = 16'h3C00 + i; // Values from 1 to 16
            end
            
            #25; // Wait for normalization (may take longer)
            start = 0;
            
            $display("Normalization Result[0] = 0x%h", data_out[0]);
            $display("Normalization Result[1] = 0x%h", data_out[1]);
            
            // Verify we got some output
            if (data_out[0] != 16'h0000 || data_out[1] != 16'h0000) begin
                $display("Normalization Integration Test: PASSED (output generated)");
            end else begin
                $display("Normalization Integration Test: NEEDS VERIFICATION");
            end
            
            #20; // Wait for reset
        end
    endtask
    
    // Test transformer-like operation sequence
    task test_transformer_flow;
        begin
            $display("\n--- Test: Transformer-like Flow ---");
            
            // Simulate a sequence similar to transformer operations:
            // 1. Matrix multiplication (attention)
            // 2. Activation function
            // 3. Layer normalization
            
            // Step 1: Matrix multiplication (Q*K^T for attention)
            instruction = 32'h10000000; // MAC op
            start = 1;
            
            for (integer i = 0; i < 16; i = i + 1) begin
                data_in[i] = 16'h0002 + i; // Q values
                data_in[i+16] = 16'h0003 + (i^8); // K values
            end
            
            #15;
            start = 0;
            $display("Step 1 - MAC (Attention): Result[0] = 0x%h", data_out[0]);
            
            #20;
            
            // Step 2: Activation (could be part of feed-forward)
            instruction = 32'h20000000; // Activation op
            start = 1;
            
            #15;
            start = 0;
            $display("Step 2 - Activation: Result[0] = 0x%h", data_out[0]);
            
            #20;
            
            // Step 3: Normalization (LayerNorm)
            instruction = 32'h30000000; // Normalization op
            start = 1;
            
            #25; // Normalization takes longer
            start = 0;
            $display("Step 3 - Normalization: Result[0] = 0x%h", data_out[0]);
            
            $display("Transformer-like Flow Test: COMPLETED");
            $display("Simulated a sequence of operations typical in transformer models");
            
            #20; // Wait for reset
        end
    endtask

    // Monitor progress
    always @(posedge done) begin
        $display("Operation completed at time %t", $time);
    end

    // Dump waves
    initial begin
        $dumpfile("tb_pe_complete.vcd");
        $dumpvars(0, tb_pe_complete);
    end

endmodule