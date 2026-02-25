// Testbench for PE Core with Compiler Binary Loading
// Loads instructions from compiler-generated hex file and executes

`timescale 1ns/1ps

module tb_pe_compiler;

    // Clock and reset
    reg clk;
    reg rst_n;
    reg valid_in;
    reg [31:0] instruction;
    reg [255:0] data_a_packed;
    reg [255:0] data_b_packed;
    reg [255:0] weight_packed;
    
    // Results
    wire [255:0] result_packed;
    wire ready_out;
    wire valid_out;
    
    // Instruction ROM
    reg [31:0] instruction_rom [0:255];
    integer inst_count;
    integer pc;
    integer errors;
    integer i;
    
    // Test control
    reg executing;
    
    // PE core instance
    pe_top_simple #(
        .DATA_WIDTH(32),
        .VECTOR_WIDTH(8),
        .MAC_ARRAY_ROWS(8),
        .MAC_ARRAY_COLS(8)
    ) u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ready_out(ready_out),
        .instruction(instruction),
        .data_a_packed(data_a_packed),
        .data_b_packed(data_b_packed),
        .weight_packed(weight_packed),
        .result_packed(result_packed),
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
        forever #5 clk = ~clk;
    end
    
    // Initialize
    initial begin
        inst_count = 0;
        pc = 0;
        errors = 0;
        executing = 0;
        
        // Initialize ROM to NOP
        for (i = 0; i < 256; i = i + 1) begin
            instruction_rom[i] = 32'h70000000;
        end
        
        // Load hex file
        $display("Loading instructions from simple.hex...");
        $readmemh("simple.hex", instruction_rom);
        
        // Count valid instructions
        for (i = 0; i < 256; i = i + 1) begin
            if (instruction_rom[i] != 32'h70000000) begin
                inst_count = inst_count + 1;
            end
        end
        
        $display("Loaded %0d instructions\n", inst_count);
        
        // Display instructions
        $display("Compiler Output:");
        for (i = 0; i < inst_count && i < 16; i = i + 1) begin
            $display("  [%02d] 0x%08H", i, instruction_rom[i]);
        end
        $display("");
    end
    
    // Test stimulus
    initial begin
        $display("========================================");
        $display("PE Core Compiler Testbench");
        $display("========================================");
        
        // Reset
        rst_n = 0;
        valid_in = 0;
        instruction = 32'h0;
        data_a_packed = 256'h0;
        data_b_packed = 256'h0;
        weight_packed = 256'h0;
        
        #20;
        rst_n = 1;
        #20;
        
        // Execute each instruction
        for (pc = 0; pc < inst_count; pc = pc + 1) begin
            instruction = instruction_rom[pc];
            
            // Decode and display
            $display("[PC=%0d] Instruction: 0x%08H", pc, instruction);
            case (instruction[31:28])
                4'h1: $display("       -> MAC Operation");
                4'h2: $display("       -> ACT Operation (type=%0d)", instruction[7:0]);
                4'h3: $display("       -> NORM Operation (type=%0d)", instruction[7:0]);
                4'h7: $display("       -> NOP");
                default: $display("       -> Unknown");
            endcase
            
            // Set test data for MAC
            if (instruction[31:28] == 4'h1) begin
                // For MAC: data_a * data_b + weight
                // Simple test: all ones
                data_a_packed = {8{32'h00000001}};  // 8 values of 1
                data_b_packed = {8{32'h00000002}};  // 8 values of 2
                weight_packed = {8{32'h00000003}};  // 8 values of 3
                // Expected: 1*2 + 3 = 5 for each
            end else begin
                data_a_packed = 256'h0;
                data_b_packed = 256'h0;
                weight_packed = 256'h0;
            end
            
            // Execute
            valid_in = 1;
            #10;
            
            // Wait for ready or valid out
            begin : wait_loop
                for (i = 0; i < 50; i = i + 1) begin
                    #10;
                    if (valid_out) begin
                        $display("       -> Result: 0x%H", result_packed[31:0]);
                        $display("       -> Full result: 0x%H", result_packed);
                        disable wait_loop;
                    end
                end
            end
            
            valid_in = 0;
            #30;
        end
        
        #100;
        
        $display("\n========================================");
        $display("Test Summary:");
        $display("  Executed: %0d instructions", inst_count);
        $display("  Status: COMPLETED");
        $display("========================================");
        
        $finish;
    end
    
    // Timeout
    initial begin
        #100000;
        $display("WARNING: Timeout!");
        $finish;
    end
    
    // Waveform
    initial begin
        $dumpfile("tb_pe_compiler.vcd");
        $dumpvars(0, tb_pe_compiler);
    end
    
endmodule
