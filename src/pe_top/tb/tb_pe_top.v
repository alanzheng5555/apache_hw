//===================================================================
// PE Top Testbench - Fixed timing
//===================================================================
`timescale 1ns/1ps

module tb_pe_top;
    reg clk, rst_n;
    
    //----------------------------------------------------------------
    // Test signals
    //----------------------------------------------------------------
    reg  [31:0]  test_opcode;
    reg  [31:0]  test_op1;
    reg  [31:0]  test_op2;
    reg  [31:0]  test_op3;
    reg          test_valid;
    wire [31:0]  test_result;
    wire         test_valid_out;
    
    reg  [4:0]   rf_wr_addr;
    reg  [31:0]  rf_wr_data;
    reg          rf_wr_en;
    wire [31:0]  rf_r1, rf_r2;
    
    //----------------------------------------------------------------
    // Instantiate PE Top Simple
    //----------------------------------------------------------------
    pe_top_simple u_pe_top (
        .clk(clk),
        .rst_n(rst_n),
        .test_opcode(test_opcode),
        .test_op1(test_op1),
        .test_op2(test_op2),
        .test_op3(test_op3),
        .test_valid(test_valid),
        .test_result(test_result),
        .test_valid_out(test_valid_out),
        .rf_r1(rf_r1),
        .rf_r2(rf_r2),
        .rf_wr_addr(rf_wr_addr),
        .rf_wr_data(rf_wr_data),
        .rf_wr_en(rf_wr_en)
    );
    
    //----------------------------------------------------------------
    // Clock generator
    //----------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    //----------------------------------------------------------------
    // Test variables
    //----------------------------------------------------------------
    integer pass_count;
    integer total_count;
    
    //----------------------------------------------------------------
    // Test task - fixed timing
    //----------------------------------------------------------------
    task run_test;
        input [80:0] name;
        input [31:0] opcode;
        input [31:0] a, b, c;
        input [31:0] expected;
        input        write_back;
        input [4:0]  dest_reg;
        begin
            total_count = total_count + 1;
            
            // Wait for next falling edge
            @(negedge clk);
            
            // Set inputs
            test_opcode = opcode;
            test_op1 = a;
            test_op2 = b;
            test_op3 = c;
            test_valid = 1;
            rf_wr_en = write_back;
            rf_wr_addr = dest_reg;
            
            // Wait for 2 clock cycles
            @(posedge clk);
            @(posedge clk);
            
            // Check result
            if (test_valid_out && test_result == expected) begin
                $display("PASS: %s", name);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s (exp=%0d got=%0d valid=%b)", 
                        name, expected, test_result, test_valid_out);
            end
            
            test_valid = 0;
            #10;
        end
    endtask
    
    //----------------------------------------------------------------
    // Main test
    //----------------------------------------------------------------
    initial begin
        $display("========================================");
        $display("PE Top Integration Test - Fixed Timing");
        $display("========================================");
        
        // Initialize
        rst_n = 0;
        test_opcode = 0;
        test_op1 = 0;
        test_op2 = 0;
        test_op3 = 0;
        test_valid = 0;
        rf_wr_addr = 0;
        rf_wr_data = 0;
        rf_wr_en = 0;
        pass_count = 0;
        total_count = 0;
        
        #100;
        rst_n = 1;
        #50;
        
        // ==================== Test 1: Direct ADD ====================
        $display("\n=== Test 1: Direct ADD ===");
        run_test("ADD", 
                 {7'b0000001, 5'b00001, 5'd1, 5'd2, 5'd0}, 
                 10, 20, 0, 30, 0, 5'd0);
        
        // ==================== Test 2: ADD with register write ====================
        $display("\n=== Test 2: ADD with register write ===");
        run_test("ADD_REG", 
                 {7'b0000001, 5'b00001, 5'd3, 5'd4, 5'd5}, 
                 15, 25, 0, 40, 1, 5'd5);
        
        #20;
        $display("Register 5 = %0d", rf_r1);
        
        // ==================== Test 3: SUB ====================
        $display("\n=== Test 3: SUB ===");
        run_test("SUB", 
                 {7'b0000001, 5'b00010, 5'd0, 5'd0, 5'd0}, 
                 100, 30, 0, 70, 0, 5'd0);
        
        // ==================== Test 4: MUL ====================
        $display("\n=== Test 4: MUL ===");
        run_test("MUL", 
                 {7'b0000001, 5'b00011, 5'd0, 5'd0, 5'd0}, 
                 12, 5, 0, 60, 0, 5'd0);
        
        // ==================== Test 5: FPU RELU ====================
        $display("\n=== Test 5: FPU RELU ===");
        run_test("RELU+", 
                 {7'b0000010, 5'b01011, 5'd0, 5'd0, 5'd0}, 
                 25, 0, 0, 25, 0, 5'd0);
        
        run_test("RELU-", 
                 {7'b0000010, 5'b01011, 5'd0, 5'd0, 5'd0}, 
                 -25, 0, 0, 0, 0, 5'd0);
        
        // ==================== Test 6: Compare ====================
        $display("\n=== Test 6: Compare ===");
        run_test("EQ_T", 
                 {7'b0010000, 5'b00001, 5'd0, 5'd0, 5'd0}, 
                 42, 42, 0, 1, 0, 5'd0);
        
        run_test("EQ_F", 
                 {7'b0010000, 5'b00001, 5'd0, 5'd0, 5'd0}, 
                 42, 0, 0, 0, 0, 5'd0);
        
        // ==================== Summary ====================
        #50;
        $display("\n========================================");
        $display("TEST RESULTS");
        $display("========================================");
        $display("Total:  %0d tests", total_count);
        $display("Passed: %0d tests", pass_count);
        $display("Failed: %0d tests", total_count - pass_count);
        $display("Pass Rate: %0d%%", (total_count > 0) ? (pass_count * 100 / total_count) : 0);
        $display("========================================");
        
        if (pass_count == total_count) begin
            $display("SUCCESS: All tests passed!");
        end else begin
            $display("FAILURE: %0d tests failed!", total_count - pass_count);
        end
        
        #100;
        $finish;
    end
    
endmodule