// Simplified Matrix Multiplication Testbench
// Can run small tests (8×8) for quick verification
// or full tests (64×64) for performance estimation

`timescale 1ns/1ps

module tb_matrix_mult_simple;

    parameter CLK_PERIOD = 10;  // 100 MHz
    
    // Test configuration
    parameter TEST_SIZE = 64;   // Change to 64 for full test
    parameter CORES_2D = 8;     // 8×8 core grid
    parameter BLOCK_SIZE = TEST_SIZE / CORES_2D;  // 8 for 64×64
    
    localparam MATRIX_SIZE = TEST_SIZE;
    localparam NUM_BLOCKS = CORES_2D;
    
    // Signals
    reg clk;
    reg rst_n;
    
    // Simplified chip interface (memory-mapped)
    reg [31:0] s_addr;
    reg [63:0] s_wdata;
    reg        s_write;
    reg        s_read;
    wire [63:0] s_rdata;
    wire       s_ready;
    
    wire [63:0] pe_done;
    reg  [63:0] pe_start;
    reg  [31:0] pe_instruction;
    
    // Simulation control
    integer i, j, k;
    integer cycle_count;
    integer start_time;
    integer end_time;
    
    // Test status
    integer errors;
    reg test_passed;
    
    // Memory for test data
    reg [31:0] matrix_a [0:MATRIX_SIZE*MATRIX_SIZE-1];
    reg [31:0] matrix_b [0:MATRIX_SIZE*MATRIX_SIZE-1];
    reg [31:0] matrix_c_ref [0:MATRIX_SIZE*MATRIX_SIZE-1];
    reg [31:0] matrix_c_result [0:MATRIX_SIZE*MATRIX_SIZE-1];
    
    // Simplified chip model
    reg [31:0] core_memory [0:(8*8*64*64)-1];  // 64 cores × 64×64 memory each
    reg [63:0] core_status [0:63];  // Status per core
    reg [63:0] core_done_reg;
    
    // Instantiate simplified chip
    simplifed_chip #(
        .CORES_X(CORES_2D),
        .CORES_Y(CORES_2D),
        .DATA_W(64),
        .ADDR_W(32)
    ) u_chip (
        .clk(clk),
        .rst_n(rst_n),
        .s_addr(s_addr),
        .s_wdata(s_wdata),
        .s_write(s_write),
        .s_read(s_read),
        .s_rdata(s_rdata),
        .s_ready(s_ready),
        .pe_start(pe_start),
        .pe_instruction(pe_instruction),
        .pe_done(core_done_reg)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Main test
    initial begin
        $display("=================================================");
        $display(" Matrix Multiplication Testbench");
        $display(" Size: %0dx%0d, Cores: %0dx%0d", 
                 MATRIX_SIZE, MATRIX_SIZE, CORES_2D, CORES_2D);
        $display(" Block size: %0dx%0d", BLOCK_SIZE, BLOCK_SIZE);
        $display("=================================================");
        
        // Initialize
        rst_n = 1'b0;
        s_addr = 0;
        s_wdata = 0;
        s_write = 0;
        s_read = 0;
        pe_start = 0;
        pe_instruction = 32'd0;
        errors = 0;
        cycle_count = 0;
        
        #100;
        rst_n = 1'b1;
        
        // Generate matrices
        $display("[%0t] Generating matrices...", $time);
        generate_matrices;
        
        // Load data
        $display("[%0t] Loading data to cores...", $time);
        load_data;
        
        // Start computation
        $display("[%0t] Starting computation...", $time);
        start_computation;
        
        // Wait and collect results
        $display("[%0t] Waiting for completion...", $time);
        wait_and_collect;
        
        // Verify
        $display("[%0t] Verifying results...", $time);
        verify;
        
        // Summary
        $display("");
        $display("=================================================");
        $display(" TEST SUMMARY");
        $display("=================================================");
        $display("Total cycles: %0d", cycle_count);
        $display("Errors: %0d", errors);
        if (errors == 0) begin
            $display("TEST PASSED!");
        end else begin
            $display("TEST FAILED!");
        end
        $display("=================================================");
        
        #100;
        $finish;
    end
    
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
    end
    
    // ==========================================
    // Tasks
    // ==========================================
    
    task generate_matrices;
        begin
            // Simple pattern for easy verification
            // A[i][j] = i + j
            // B[i][j] = i * j + 1
            
            for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
                for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                    matrix_a[i*MATRIX_SIZE + j] = $realtobits($itor(i + j));
                    matrix_b[i*MATRIX_SIZE + j] = $realtobits($itor(i * j + 1));
                end
            end
            
            // Reference computation
            $display("  Computing reference...");
            for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
                for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                    automatic real sum = 0.0;
                    for (k = 0; k < MATRIX_SIZE; k = k + 1) begin
                        automatic real a_val = $bitstoreal(matrix_a[i*MATRIX_SIZE + k]);
                        automatic real b_val = $bitstoreal(matrix_b[k*MATRIX_SIZE + j]);
                        sum = sum + a_val * b_val;
                    end
                    matrix_c_ref[i*MATRIX_SIZE + j] = $realtobits(sum);
                end
            end
            
            $display("  Generated %0dx%0d matrices", MATRIX_SIZE, MATRIX_SIZE);
        end
    endtask
    
    task load_data;
        begin
            // Distribute blocks to cores
            for (i = 0; i < NUM_BLOCKS; i = i + 1) begin
                for (j = 0; j < NUM_BLOCKS; j = j + 1) begin
                    automatic integer core_id = j * CORES_2D + i;
                    automatic integer base_addr = core_id * BLOCK_SIZE * BLOCK_SIZE * 4;
                    
                    $display("  Loading block [%0d,%0d] to core %0d", i, j, core_id);
                    
                    // Load A block (rows)
                    for (k = 0; k < BLOCK_SIZE; k = k + 1) begin
                        for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
                            automatic integer a_i = i*BLOCK_SIZE + k;
                            automatic integer a_j = j;
                            automatic integer mem_addr = base_addr + (k * BLOCK_SIZE + j) * 4;
                            automatic reg [31:0] value = matrix_a[a_i*MATRIX_SIZE + a_j];
                            
                            // Write to core memory
                            wait(s_ready);
                            s_addr = mem_addr;
                            s_wdata = {32'd0, value};
                            s_write = 1;
                            @(posedge clk);
                            s_write = 0;
                        end
                    end
                    
                    // Load B block (columns)
                    for (k = 0; k < BLOCK_SIZE; k = k + 1) begin
                        for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
                            automatic integer b_i = k;
                            automatic integer b_j = j*BLOCK_SIZE + j;
                            automatic integer mem_addr = base_addr + 16384 + (k * BLOCK_SIZE + j) * 4;
                            automatic reg [31:0] value = matrix_b[b_i*MATRIX_SIZE + b_j];
                            
                            wait(s_ready);
                            s_addr = mem_addr;
                            s_wdata = {32'd0, value};
                            s_write = 1;
                            @(posedge clk);
                            s_write = 0;
                        end
                    end
                end
            end
            
            $display("  Data loaded");
        end
    endtask
    
    task start_computation;
        begin
            pe_start = 64'hFFFF_FFFF_FFFF_FFFF;
            #10;
            pe_start = 0;
            start_time = cycle_count;
            $display("  Computation started");
        end
    endtask
    
    task wait_and_collect;
        begin
            // Wait for all cores to finish
            wait(core_done_reg == 64'hFFFF_FFFF_FFFF_FFFF);
            end_time = cycle_count;
            
            $display("  Completed in %0d cycles", end_time - start_time);
            
            // Collect results
            for (i = 0; i < NUM_BLOCKS; i = i + 1) begin
                for (j = 0; j < NUM_BLOCKS; j = j + 1) begin
                    automatic integer core_id = j * CORES_2D + i;
                    automatic integer base_addr = core_id * BLOCK_SIZE * BLOCK_SIZE * 4 + 32768;
                    
                    for (k = 0; k < BLOCK_SIZE; k = k + 1) begin
                        for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
                            automatic integer c_i = i*BLOCK_SIZE + k;
                            automatic integer c_j = j*BLOCK_SIZE + j;
                            automatic integer mem_addr = base_addr + (k * BLOCK_SIZE + j) * 4;
                            
                            // Read result
                            wait(s_ready);
                            s_addr = mem_addr;
                            s_read = 1;
                            @(posedge clk);
                            s_read = 0;
                            #1;
                            matrix_c_result[c_i*MATRIX_SIZE + c_j] = s_rdata[31:0];
                        end
                    end
                end
            end
            
            $display("  Results collected");
        end
    endtask
    
    task verify;
        begin
            errors = 0;
            
            for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
                for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                    automatic real result = $bitstoreal(matrix_c_result[i*MATRIX_SIZE + j]);
                    automatic real expected = $bitstoreal(matrix_c_ref[i*MATRIX_SIZE + j]);
                    automatic real diff = result - expected;
                    
                    if (diff < -0.01 || diff > 0.01) begin
                        errors = errors + 1;
                        if (errors <= 5) begin
                            $display("  Error at [%0d,%0d]: got %f, expected %f",
                                     i, j, result, expected);
                        end
                    end
                end
            end
            
            $display("  Verified %0d elements, %0d errors", 
                     MATRIX_SIZE*MATRIX_SIZE, errors);
        end
    endtask

endmodule

// Simplified chip model
module simplifed_chip #(
    parameter CORES_X = 8,
    parameter CORES_Y = 8,
    parameter DATA_W = 64,
    parameter ADDR_W = 32
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [ADDR_W-1:0] s_addr,
    input  wire [DATA_W-1:0] s_wdata,
    input  wire s_write,
    input  wire s_read,
    output wire [DATA_W-1:0] s_rdata,
    output wire s_ready,
    input  wire [CORES_X*CORES_Y-1:0] pe_start,
    input  wire [31:0] pe_instruction,
    output wire [CORES_X*CORES_Y-1:0] pe_done
);

    localparam NUM_CORES = CORES_X * CORES_Y;
    
    reg [DATA_W-1:0] memory [0:65535];
    reg [31:0] mac_result;
    reg [15:0] mac_counter;
    reg [63:0] done_reg;
    
    assign s_rdata = memory[s_addr[15:0]];
    assign s_ready = 1'b1;
    assign pe_done = done_reg;
    
    // Simplified MAC operation
    always @(posedge clk) begin
        if (!rst_n) begin
            mac_counter <= 16'd0;
            done_reg <= 64'd0;
        end else begin
            if (pe_start != 0) begin
                // Start computation
                done_reg <= 64'd0;
                mac_counter <= 16'd0;
            end else if (mac_counter < 4096) begin
                mac_counter <= mac_counter + 1;
                // Simplified MAC
                memory[s_addr[15:0]] <= s_wdata;
            end else begin
                done_reg <= {NUM_CORES{1'b1}};
            end
        end
    end

endmodule
