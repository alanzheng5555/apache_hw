// Testbench for Enhanced PE Top Module - Standard Verilog

`timescale 1ns/1ps

module tb_pe_enhanced;
    
    localparam DATA_WIDTH = 32;
    localparam VECTOR_WIDTH = 4;
    localparam MAC_ROWS = 4;
    localparam MAC_COLS = 4;
    
    reg clk;
    reg rst_n;
    reg valid_in;
    wire ready_out;
    reg [31:0] instruction;
    
    reg [(DATA_WIDTH*VECTOR_WIDTH)-1:0] data_a_packed;
    reg [(DATA_WIDTH*VECTOR_WIDTH)-1:0] data_b_packed;
    reg [(DATA_WIDTH*VECTOR_WIDTH)-1:0] weight_packed;
    reg [(DATA_WIDTH*VECTOR_WIDTH)-1:0] k_cache_packed;
    reg [(DATA_WIDTH*VECTOR_WIDTH)-1:0] v_cache_packed;
    
    reg [VECTOR_WIDTH-1:0] sparse_mask_a;
    reg [VECTOR_WIDTH-1:0] sparse_mask_b;
    reg [7:0] sparsity_ratio;
    reg [7:0] scale_a;
    reg [7:0] scale_b;
    reg [7:0] scale_o;
    
    reg [31:0] addr_i;
    wire [255:0] data_o;
    reg [255:0] data_i;
    wire mem_req_o;
    reg mem_ack_i;
    reg cache_flush;
    wire cache_hit;
    wire [(DATA_WIDTH*VECTOR_WIDTH)-1:0] result_packed;
    wire valid_out;
    wire [(DATA_WIDTH*VECTOR_WIDTH)-1:0] attention_packed;
    wire [31:0] perf_counter;
    wire perf_overflow;
    
    integer test_count;
    integer passed_count;
    integer failed_count;
    
    // Instantiate DUT
    pe_top_enhanced #(
        .DATA_WIDTH(DATA_WIDTH),
        .VECTOR_WIDTH(VECTOR_WIDTH),
        .MAC_ARRAY_ROWS(MAC_ROWS),
        .MAC_ARRAY_COLS(MAC_COLS),
        .QUANT_MODE("INT8"),
        .SPARSE_ENABLE(1),
        .ATTN_ENABLE(1)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ready_out(ready_out),
        .instruction(instruction),
        .data_a_packed(data_a_packed),
        .data_b_packed(data_b_packed),
        .weight_packed(weight_packed),
        .k_cache_packed(k_cache_packed),
        .v_cache_packed(v_cache_packed),
        .sparse_mask_a(sparse_mask_a),
        .sparse_mask_b(sparse_mask_b),
        .sparsity_ratio(sparsity_ratio),
        .scale_a(scale_a),
        .scale_b(scale_b),
        .scale_o(scale_o),
        .addr_i(addr_i),
        .data_o(data_o),
        .data_i(data_i),
        .mem_req_o(mem_req_o),
        .mem_ack_i(mem_ack_i),
        .cache_flush(cache_flush),
        .cache_hit(cache_hit),
        .result_packed(result_packed),
        .valid_out(valid_out),
        .attention_packed(attention_packed),
        .perf_counter(perf_counter),
        .perf_overflow(perf_overflow)
    );
    
    // Clock
    always #5 clk = ~clk;
    
    // Initialize
    initial begin
        clk = 0;
        rst_n = 0;
        valid_in = 0;
        instruction = 32'd0;
        
        // Pack test data
        data_a_packed = {16'h3C00, 16'hC000, 16'h4000, 16'h0000};  // 1.0, -2.0, 2.0, 0.0
        data_b_packed = {16'h3C00, 16'h3C00, 16'h3C00, 16'h3C00};  // All 1.0
        weight_packed = {16'h3C00, 16'h3C00, 16'h3C00, 16'h3C00};   // All 1.0
        k_cache_packed = data_a_packed;
        v_cache_packed = data_b_packed;
        
        sparse_mask_a = 4'b1111;
        sparse_mask_b = 4'b1111;
        sparsity_ratio = 8'd0;
        scale_a = 8'd1;
        scale_b = 8'd1;
        scale_o = 8'd1;
        
        addr_i = 32'd0;
        data_i = 256'd0;
        mem_ack_i = 1'b0;
        cache_flush = 1'b0;
        
        test_count = 0;
        passed_count = 0;
        failed_count = 0;
        
        #10 rst_n = 1;
        
        #10 run_mac_test;
        #10 run_activation_test;
        #10 run_norm_test;
        #10 run_attention_test;
        
        #10 report_results;
        
        #100 $finish;
    end
    
    task run_mac_test;
        begin
            $display("=== Running MAC Test ===");
            test_count = test_count + 1;
            
            valid_in = 1;
            instruction = {4'h1, 28'd0};
            
            #10;
            if (valid_out) begin
                $display("PASS: MAC operation completed");
                passed_count = passed_count + 1;
            end else begin
                $display("FAIL: MAC operation failed");
                failed_count = failed_count + 1;
            end
            valid_in = 0;
            #10;
        end
    endtask
    
    task run_activation_test;
        begin
            $display("=== Running Activation Test ===");
            test_count = test_count + 1;
            
            valid_in = 1;
            instruction = {4'h2, 8'd0, 20'd0};  // ReLU
            instruction[7:0] = 8'd0;
            
            #10;
            if (valid_out) begin
                $display("PASS: Activation operation completed");
                passed_count = passed_count + 1;
            end else begin
                $display("FAIL: Activation operation failed");
                failed_count = failed_count + 1;
            end
            valid_in = 0;
            #10;
        end
    endtask
    
    task run_norm_test;
        begin
            $display("=== Running Normalization Test ===");
            test_count = test_count + 1;
            
            valid_in = 1;
            instruction = {4'h3, 28'd0};
            
            #10;
            if (valid_out) begin
                $display("PASS: Normalization operation completed");
                passed_count = passed_count + 1;
            end else begin
                $display("FAIL: Normalization operation failed");
                failed_count = failed_count + 1;
            end
            valid_in = 0;
            #10;
        end
    endtask
    
    task run_attention_test;
        begin
            $display("=== Running Attention Test ===");
            test_count = test_count + 1;
            
            valid_in = 1;
            instruction = {4'h5, 28'd0};
            
            #10;
            if (valid_out) begin
                $display("PASS: Attention operation completed");
                passed_count = passed_count + 1;
            end else begin
                $display("FAIL: Attention operation failed");
                failed_count = failed_count + 1;
            end
            valid_in = 0;
            #10;
        end
    endtask
    
    task report_results;
        begin
            $display("========================================");
            $display("Test Summary:");
            $display("========================================");
            $display("Total tests: %0d", test_count);
            $display("Passed: %0d", passed_count);
            $display("Failed: %0d", failed_count);
            $display("========================================");
            
            if (failed_count == 0) begin
                $display("ALL TESTS PASSED!");
            end else begin
                $display("SOME TESTS FAILED!");
            end
        end
    endtask
    
endmodule