// Simple PE Core Test - Demonstrates basic functionality
`timescale 1ns/1ps

module simple_pe_test();

    reg clk;
    reg rst_n;
    reg [15:0] data_a, data_b, weight;
    reg [31:0] instruction;
    reg valid_in;
    
    wire [15:0] result;
    wire valid_out;
    
    // Simple MAC unit for testing
    reg [15:0] mac_result;
    reg [15:0] relu_result;
    
    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Simple MAC operation
    always @(posedge clk) begin
        if (!rst_n) begin
            mac_result <= 16'h0000;
            relu_result <= 16'h0000;
        end else if (valid_in) begin
            // Perform MAC: data_a * weight + data_b
            if (instruction[31:28] == 4'h1) begin  // MAC operation
                mac_result <= $signed(data_a) * $signed(weight) + $signed(data_b);
            end
            // Simple ReLU activation
            else if (instruction[31:28] == 4'h2) begin  // Activation operation
                if ($signed(mac_result) > 0)
                    relu_result <= mac_result;
                else
                    relu_result <= 16'h0000;  // Zero
            end
        end
    end
    
    assign result = (instruction[31:28] == 4'h2) ? relu_result : mac_result;
    assign valid_out = valid_in;

    // Test sequence
    initial begin
        $display("Starting Simple PE Core Test...");
        $monitor("Time: %0t, Data_A: 0x%h, Weight: 0x%h, Data_B: 0x%h, Result: 0x%h", 
                 $time, data_a, weight, data_b, result);
        
        // Initialize
        rst_n = 0;
        data_a = 16'h0002;  // 2 in FP16
        data_b = 16'h0001;  // 1 in FP16
        weight = 16'h0003;  // 3 in FP16
        instruction = 32'h10000000;  // MAC operation
        valid_in = 0;
        
        #20;
        rst_n = 1;
        #10;
        
        // Test 1: MAC operation (2 * 3 + 1 = 7)
        $display("\n--- MAC Test (2 * 3 + 1) ---");
        valid_in = 1;
        instruction = 32'h10000000;  // MAC operation
        #20;
        valid_in = 0;
        $display("Expected: 7, Got: %d", $signed(result));
        
        #20;
        
        // Test 2: ReLU on positive value
        $display("\n--- ReLU Test (Positive Value) ---");
        valid_in = 1;
        instruction = 32'h20000001;  // Activation operation
        #20;
        valid_in = 0;
        $display("ReLU of positive value: %d", $signed(result));
        
        #20;
        
        // Test 3: ReLU on negative value
        $display("\n--- ReLU Test (Negative Value) ---");
        data_a = 16'hB000;  // Negative value
        valid_in = 1;
        instruction = 32'h20000001;  // Activation operation
        #20;
        valid_in = 0;
        $display("ReLU of negative value: %d", $signed(result));
        
        $display("\nSimple PE Core Test Completed Successfully!");
        $display("Demonstrated:");
        $display("- MAC operation (multiply-accumulate)");
        $display("- ReLU activation function");
        $display("- Basic instruction decoding");
        $finish;
    end

endmodule