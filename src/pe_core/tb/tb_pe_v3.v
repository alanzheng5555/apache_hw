// PE Core v3 - Complete Regression Test
`timescale 1ns/1ps

module tb_pe_v3;
    reg clk, rst_n;
    reg [31:0] opcode, op1, op2, op3;
    reg valid_in;
    wire [31:0] result_out;
    wire result_valid;
    
    integer pass_count;
    integer total_count;
    reg [80:0] test_name;
    reg [31:0] test_expected;
    
    pe_core_v3 dut (clk, rst_n, opcode, op1, op2, op3, valid_in, result_out, result_valid);
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        // 初始化
        rst_n = 0; opcode = 0; op1 = 0; op2 = 0; op3 = 0; valid_in = 0;
        pass_count = 0; total_count = 0;
        
        #50;  // 等待复位稳定
        rst_n = 1;
        #20;  // 等待几个周期
        
        // ==================== Arithmetic Tests ====================
        $display("\n=== Arithmetic Instructions ===");
        
        // ADD
        total_count = total_count + 1;
        opcode = {7'b0000001, 5'b00001, 20'd0}; op1 = 10; op2 = 20; op3 = 0; valid_in = 1;
        #20;
        if (result_valid && result_out == 30) begin $display("PASS: ADD"); pass_count = pass_count + 1; end
        else $display("FAIL: ADD (exp=30 got=%0d)", result_out);
        
        // SUB
        total_count = total_count + 1;
        opcode = {7'b0000001, 5'b00010, 20'd0}; op1 = 50; op2 = 20; valid_in = 1;
        #20;
        if (result_valid && result_out == 30) begin $display("PASS: SUB"); pass_count = pass_count + 1; end
        else $display("FAIL: SUB (exp=30 got=%0d)", result_out);
        
        // MUL
        total_count = total_count + 1;
        opcode = {7'b0000001, 5'b00011, 20'd0}; op1 = 10; op2 = 5; valid_in = 1;
        #20;
        if (result_valid && result_out == 50) begin $display("PASS: MUL"); pass_count = pass_count + 1; end
        else $display("FAIL: MUL (exp=50 got=%0d)", result_out);
        
        // DIV
        total_count = total_count + 1;
        opcode = {7'b0000001, 5'b00100, 20'd0}; op1 = 100; op2 = 4; valid_in = 1;
        #20;
        if (result_valid && result_out == 25) begin $display("PASS: DIV"); pass_count = pass_count + 1; end
        else $display("FAIL: DIV (exp=25 got=%0d)", result_out);
        
        // MAD
        total_count = total_count + 1;
        opcode = {7'b0000001, 5'b00101, 20'd0}; op1 = 10; op2 = 5; op3 = 3; valid_in = 1;
        #20;
        if (result_valid && result_out == 53) begin $display("PASS: MAD"); pass_count = pass_count + 1; end
        else $display("FAIL: MAD (exp=53 got=%0d)", result_out);
        
        // AND
        total_count = total_count + 1;
        opcode = {7'b0000001, 5'b01001, 20'd0}; op1 = 'hFF00; op2 = 'h0F0F; valid_in = 1;
        #20;
        if (result_valid && result_out == 'h0F00) begin $display("PASS: AND"); pass_count = pass_count + 1; end
        else $display("FAIL: AND (exp=3840 got=%0d)", result_out);
        
        // OR
        total_count = total_count + 1;
        opcode = {7'b0000001, 5'b01010, 20'd0}; op1 = 'hF0F0; op2 = 'h0F0F; valid_in = 1;
        #20;
        if (result_valid && result_out == 'hFFFF) begin $display("PASS: OR"); pass_count = pass_count + 1; end
        else $display("FAIL: OR (exp=65535 got=%0d)", result_out);
        
        // XOR
        total_count = total_count + 1;
        opcode = {7'b0000001, 5'b01011, 20'd0}; op1 = 'hAAAA; op2 = 'h5555; valid_in = 1;
        #20;
        if (result_valid && result_out == 'hFFFF) begin $display("PASS: XOR"); pass_count = pass_count + 1; end
        else $display("FAIL: XOR (exp=65535 got=%0d)", result_out);
        
        // SHL
        total_count = total_count + 1;
        opcode = {7'b0000001, 5'b01100, 20'd0}; op1 = 1; op2 = 4; valid_in = 1;
        #20;
        if (result_valid && result_out == 16) begin $display("PASS: SHL"); pass_count = pass_count + 1; end
        else $display("FAIL: SHL (exp=16 got=%0d)", result_out);
        
        // SHR
        total_count = total_count + 1;
        opcode = {7'b0000001, 5'b01101, 20'd0}; op1 = 64; op2 = 3; valid_in = 1;
        #20;
        if (result_valid && result_out == 8) begin $display("PASS: SHR"); pass_count = pass_count + 1; end
        else $display("FAIL: SHR (exp=8 got=%0d)", result_out);
        
        // ==================== FPU Tests ====================
        $display("\n=== FPU Instructions ===");
        
        // FMA
        total_count = total_count + 1;
        opcode = {7'b0000010, 5'b00001, 20'd0}; op1 = 2; op2 = 3; op3 = 10; valid_in = 1;
        #20;
        if (result_valid && result_out == 16) begin $display("PASS: FMA"); pass_count = pass_count + 1; end
        else $display("FAIL: FMA (exp=16 got=%0d)", result_out);
        
        // RELU+
        total_count = total_count + 1;
        opcode = {7'b0000010, 5'b01011, 20'd0}; op1 = 10; op2 = 0; valid_in = 1;
        #20;
        if (result_valid && result_out == 10) begin $display("PASS: RELU+"); pass_count = pass_count + 1; end
        else $display("FAIL: RELU+ (exp=10 got=%0d)", result_out);
        
        // RELU-
        total_count = total_count + 1;
        opcode = {7'b0000010, 5'b01011, 20'd0}; op1 = -10; op2 = 0; valid_in = 1;
        #20;
        if (result_valid && result_out == 0) begin $display("PASS: RELU-"); pass_count = pass_count + 1; end
        else $display("FAIL: RELU- (exp=0 got=%0d)", result_out);
        
        // ABS
        total_count = total_count + 1;
        opcode = {7'b0000010, 5'b01101, 20'd0}; op1 = -100; op2 = 0; valid_in = 1;
        #20;
        if (result_valid && result_out == 100) begin $display("PASS: ABS"); pass_count = pass_count + 1; end
        else $display("FAIL: ABS (exp=100 got=%0d)", result_out);
        
        // NEG
        total_count = total_count + 1;
        opcode = {7'b0000010, 5'b01110, 20'd0}; op1 = 50; op2 = 0; valid_in = 1;
        #20;
        if (result_valid && result_out == -50) begin $display("PASS: NEG"); pass_count = pass_count + 1; end
        else $display("FAIL: NEG (exp=-50 got=%0d)", result_out);
        
        // MIN
        total_count = total_count + 1;
        opcode = {7'b0000010, 5'b10000, 20'd0}; op1 = 10; op2 = 20; valid_in = 1;
        #20;
        if (result_valid && result_out == 10) begin $display("PASS: MIN"); pass_count = pass_count + 1; end
        else $display("FAIL: MIN (exp=10 got=%0d)", result_out);
        
        // MAX
        total_count = total_count + 1;
        opcode = {7'b0000010, 5'b10001, 20'd0}; op1 = 10; op2 = 20; valid_in = 1;
        #20;
        if (result_valid && result_out == 20) begin $display("PASS: MAX"); pass_count = pass_count + 1; end
        else $display("FAIL: MAX (exp=20 got=%0d)", result_out);
        
        // ==================== Compare Tests ====================
        $display("\n=== Compare Instructions ===");
        
        // EQ True
        total_count = total_count + 1;
        opcode = {7'b0010000, 5'b00001, 20'd0}; op1 = 10; op2 = 10; valid_in = 1;
        #20;
        if (result_valid && result_out == 1) begin $display("PASS: EQ_T"); pass_count = pass_count + 1; end
        else $display("FAIL: EQ_T (exp=1 got=%0d)", result_out);
        
        // EQ False
        total_count = total_count + 1;
        opcode = {7'b0010000, 5'b00001, 20'd0}; op1 = 10; op2 = 20; valid_in = 1;
        #20;
        if (result_valid && result_out == 0) begin $display("PASS: EQ_F"); pass_count = pass_count + 1; end
        else $display("FAIL: EQ_F (exp=0 got=%0d)", result_out);
        
        // NE
        total_count = total_count + 1;
        opcode = {7'b0010000, 5'b00010, 20'd0}; op1 = 10; op2 = 20; valid_in = 1;
        #20;
        if (result_valid && result_out == 1) begin $display("PASS: NE"); pass_count = pass_count + 1; end
        else $display("FAIL: NE (exp=1 got=%0d)", result_out);
        
        // LT
        total_count = total_count + 1;
        opcode = {7'b0010000, 5'b00011, 20'd0}; op1 = 10; op2 = 20; valid_in = 1;
        #20;
        if (result_valid && result_out == 1) begin $display("PASS: LT"); pass_count = pass_count + 1; end
        else $display("FAIL: LT (exp=1 got=%0d)", result_out);
        
        // LE
        total_count = total_count + 1;
        opcode = {7'b0010000, 5'b00100, 20'd0}; op1 = 10; op2 = 10; valid_in = 1;
        #20;
        if (result_valid && result_out == 1) begin $display("PASS: LE"); pass_count = pass_count + 1; end
        else $display("FAIL: LE (exp=1 got=%0d)", result_out);
        
        // GT
        total_count = total_count + 1;
        opcode = {7'b0010000, 5'b00101, 20'd0}; op1 = 20; op2 = 10; valid_in = 1;
        #20;
        if (result_valid && result_out == 1) begin $display("PASS: GT"); pass_count = pass_count + 1; end
        else $display("FAIL: GT (exp=1 got=%0d)", result_out);
        
        // GE
        total_count = total_count + 1;
        opcode = {7'b0010000, 5'b00110, 20'd0}; op1 = 20; op2 = 10; valid_in = 1;
        #20;
        if (result_valid && result_out == 1) begin $display("PASS: GE"); pass_count = pass_count + 1; end
        else $display("FAIL: GE (exp=1 got=%0d)", result_out);
        
        // ==================== Summary ====================
        #20;
        $display("\n========================================");
        $display("REGRESSION RESULTS");
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
        
        $finish;
    end
endmodule