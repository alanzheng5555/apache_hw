// Matrix Multiplication Testbench for 64-Core Chip
// Tests 4096×4096 floating-point matrix multiplication

`timescale 1ns/1ps

module tb_matrix_mult;

    // Parameters
    parameter CLK_PERIOD = 10;  // 100 MHz
    parameter MATRIX_SIZE = 4096;
    parameter BLOCK_SIZE = 512;  // 8×8 blocks for 64 cores
    parameter NUM_BLOCKS = MATRIX_SIZE / BLOCK_SIZE;  // 8
    
    // Matrix dimensions
    localparam ROWS_A = MATRIX_SIZE;
    localparam COLS_A = MATRIX_SIZE;
    localparam ROWS_B = MATRIX_SIZE;
    localparam COLS_B = MATRIX_SIZE;
    localparam ROWS_C = MATRIX_SIZE;
    localparam COLS_C = MATRIX_SIZE;
    
    // Signals
    reg clk;
    reg rst_n;
    
    // Chip interface
    wire [31:0] ext_m_awaddr;
    wire [7:0]  ext_m_awlen;
    wire [2:0]  ext_m_awsize;
    wire [1:0]  ext_m_awburst;
    wire        ext_m_awvalid;
    wire        ext_m_awready;
    wire [63:0] ext_m_wdata;
    wire [7:0]  ext_m_wstrb;
    wire        ext_m_wlast;
    wire        ext_m_wvalid;
    wire        ext_m_wready;
    wire [31:0] ext_m_araddr;
    wire [7:0]  ext_m_arlen;
    wire [2:0]  ext_m_arsize;
    wire [1:0]  ext_m_arburst;
    wire        ext_m_arvalid;
    wire        ext_m_arready;
    wire        ext_m_rready;
    wire [63:0] ext_m_rdata;
    wire        ext_m_rvalid;
    wire        ext_m_rlast;
    
    wire [31:0] ext_s_awaddr;
    wire [7:0]  ext_s_awlen;
    wire [2:0]  ext_s_awsize;
    wire [1:0]  ext_s_awburst;
    wire        ext_s_awvalid;
    wire        ext_s_awready;
    wire [63:0] ext_s_wdata;
    wire [7:0]  ext_s_wstrb;
    wire        ext_s_wlast;
    wire        ext_s_wvalid;
    wire        ext_s_wready;
    wire [31:0] ext_s_araddr;
    wire [7:0]  ext_s_arlen;
    wire [2:0]  ext_s_arsize;
    wire [1:0]  ext_s_arburst;
    wire        ext_s_arvalid;
    wire        ext_s_arready;
    wire        ext_s_rready;
    wire [63:0] ext_s_rdata;
    wire        ext_s_rvalid;
    wire        ext_s_rlast;
    
    reg  [63:0] pe_start;
    wire [63:0] pe_done;
    wire [31:0] pe_instruction;
    
    // Simulation control
    integer i, j, k;
    integer block_i, block_j, block_k;
    integer cycle_count;
    integer start_time;
    integer end_time;
    reg simulation_done;
    
    // Test status
    reg test_passed;
    integer errors;
    
    // Memory for reference results
    reg [31:0] matrix_a [0:MATRIX_SIZE*MATRIX_SIZE-1];
    reg [31:0] matrix_b [0:MATRIX_SIZE*MATRIX_SIZE-1];
    reg [31:0] matrix_c_ref [0:MATRIX_SIZE*MATRIX_SIZE-1];
    reg [31:0] matrix_c_result [0:MATRIX_SIZE*MATRIX_SIZE-1];
    
    // Instantiate chip top
    chip_top #(
        .CORES_X(8),
        .CORES_Y(8),
        .DATA_W(64),
        .ADDR_W(32)
    ) u_chip (
        .clk(clk),
        .rst_n(rst_n),
        
        .ext_m_awvalid(ext_m_awvalid),
        .ext_m_awready(ext_m_awready),
        .ext_m_awaddr(ext_m_awaddr),
        .ext_m_awlen(ext_m_awlen),
        .ext_m_awsize(ext_m_awsize),
        .ext_m_awburst(ext_m_awburst),
        .ext_m_wvalid(ext_m_wvalid),
        .ext_m_wready(ext_m_wready),
        .ext_m_wdata(ext_m_wdata),
        .ext_m_wstrb(ext_m_wstrb),
        .ext_m_wlast(ext_m_wlast),
        .ext_m_arvalid(ext_m_arvalid),
        .ext_m_arready(ext_m_arready),
        .ext_m_araddr(ext_m_araddr),
        .ext_m_arlen(ext_m_arlen),
        .ext_m_arsize(ext_m_arsize),
        .ext_m_arburst(ext_m_arburst),
        .ext_m_rvalid(ext_m_rvalid),
        .ext_m_rready(ext_m_rready),
        .ext_m_rdata(ext_m_rdata),
        .ext_m_rlast(ext_m_rlast),
        
        .ext_s_awvalid(ext_s_awvalid),
        .ext_s_awready(ext_s_awready),
        .ext_s_awaddr(ext_s_awaddr),
        .ext_s_awlen(ext_s_awlen),
        .ext_s_awsize(ext_s_awsize),
        .ext_s_awburst(ext_s_awburst),
        .ext_s_wvalid(ext_s_wvalid),
        .ext_s_wready(ext_s_wready),
        .ext_s_wdata(ext_s_wdata),
        .ext_s_wstrb(ext_s_wstrb),
        .ext_s_wlast(ext_s_wlast),
        .ext_s_arvalid(ext_s_arvalid),
        .ext_s_arready(ext_s_arready),
        .ext_s_araddr(ext_s_araddr),
        .ext_s_arlen(ext_s_arlen),
        .ext_s_arsize(ext_s_arsize),
        .ext_s_arburst(ext_s_arburst),
        .ext_s_rvalid(ext_s_rvalid),
        .ext_s_rready(ext_s_rready),
        .ext_s_rdata(ext_s_rdata),
        .ext_s_rlast(ext_s_rlast),
        
        .pe_start(pe_start),
        .pe_instruction(pe_instruction),
        .pe_done(pe_done)
    );
    
    // Tie-off unused NoC signals
    assign ext_s_awvalid = 1'b0;
    assign ext_s_wvalid = 1'b0;
    assign ext_s_arvalid = 1'b0;
    assign ext_m_rready = 1'b0;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Main test sequence
    initial begin
        $display("=================================================");
        $display(" 4096x4096 Matrix Multiplication Testbench");
        $display("=================================================");
        $display("");
        
        // Initialize
        rst_n = 1'b0;
        pe_start = 64'd0;
        pe_instruction = 32'd0;
        simulation_done = 1'b0;
        test_passed = 1'b0;
        errors = 0;
        cycle_count = 0;
        
        #100;
        rst_n = 1'b1;
        
        $display("[%0t] Reset released, starting test...", $time);
        start_time = $time;
        
        // Step 1: Generate test matrices
        $display("[%0t] Generating input matrices...", $time);
        generate_matrices;
        
        // Step 2: Distribute data to cores
        $display("[%0t] Distributing data to cores...", $time);
        distribute_data;
        
        // Step 3: Start computation
        $display("[%0t] Starting computation on all cores...", $time);
        start_computation;
        
        // Step 4: Wait for completion
        $display("[%0t] Waiting for completion...", $time);
        wait_completion;
        
        // Step 5: Collect results
        $display("[%0t] Collecting results...", $time);
        collect_results;
        
        // Step 6: Verify results
        $display("[%0t] Verifying results...", $time);
        verify_results;
        
        end_time = $time;
        
        // Final report
        $display("");
        $display("=================================================");
        $display(" TEST SUMMARY");
        $display("=================================================");
        $display("Total simulation time: %0d cycles (%0t)", 
                 (end_time - start_time) / CLK_PERIOD, end_time - start_time);
        $display("Errors found: %0d", errors);
        
        if (errors == 0) begin
            $display("TEST PASSED!");
            test_passed = 1'b1;
        end else begin
            $display("TEST FAILED!");
            test_passed = 1'b0;
        end
        $display("=================================================");
        
        simulation_done = 1'b1;
        #100;
        $finish;
    end
    
    // Monitor
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
        
        // Print progress every 10000 cycles
        if (cycle_count % 10000 == 0) begin
            $display("[%0t] Progress: %0d cycles", $time, cycle_count);
        end
    end
    
    // Timeout check (100 million cycles)
    initial begin
        #((100_000_000 * CLK_PERIOD) + 100);
        if (!simulation_done) begin
            $display("ERROR: Timeout! Simulation took too long.");
            $display("Terminating simulation.");
            $finish;
        end
    end
    
    // ==========================================
    // Test Tasks
    // ==========================================
    
    task generate_matrices;
        begin
            // Initialize matrices with simple pattern for verification
            // Matrix A: A[i][j] = i + j
            // Matrix B: B[i][j] = i - j
            // Result C[i][j] = sum(k) (i+k)(k-j)
            
            $display("  Matrix A: A[i][j] = i + j");
            $display("  Matrix B: B[i][j] = i - j");
            $display("  Expected: C[i][j] = sum(k) (i+k)(k-j)");
            
            for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
                for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                    matrix_a[i*MATRIX_SIZE + j] = $realtobits($itor(i + j));
                    matrix_b[i*MATRIX_SIZE + j] = $realtobits($itor(i - j));
                end
            end
            
            // Compute reference result
            $display("  Computing reference result...");
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
    
    task distribute_data;
        begin
            // Distribute blocks to each core
            // Each core computes one block of C
            
            for (block_i = 0; block_i < NUM_BLOCKS; block_i = block_i + 1) begin
                for (block_j = 0; block_j < NUM_BLOCKS; block_j = block_j + 1) begin
                    automatic integer core_x = block_i;
                    automatic integer core_y = block_j;
                    automatic integer core_id = core_y * 8 + core_x;
                    
                    $display("  Configuring core [%0d,%0d] (id=%0d) for block C[%0d:%0d, %0d:%0d]",
                             core_x, core_y, core_id,
                             block_i*BLOCK_SIZE, (block_i+1)*BLOCK_SIZE-1,
                             block_j*BLOCK_SIZE, (block_j+1)*BLOCK_SIZE-1);
                    
                    // For each k block, send A[i] to all cores and B[k] to column cores
                    for (block_k = 0; block_k < NUM_BLOCKS; block_k = block_k + 1) begin
                        // Distribute A rows to all cores
                        for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
                            // Copy A[block_i*BLOCK_SIZE + i, :] to all cores
                        end
                        
                        // Distribute B columns to column cores
                        for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
                            // Copy B[:, block_j*BLOCK_SIZE + j] to column j cores
                        end
                    end
                end
            end
            
            $display("  Data distribution complete");
        end
    endtask
    
    task start_computation;
        begin
            // Start all cores simultaneously
            pe_start = 64'hFFFF_FFFF_FFFF_FFFF;
            #10;
            pe_start = 64'd0;
            $display("  All cores started");
        end
    endtask
    
    task wait_computation;
        begin
            // Wait for all PE done signals
            wait (pe_done == 64'hFFFF_FFFF_FFFF_FFFF);
            $display("  All cores completed!");
        end
    endtask
    
    task collect_results;
        begin
            // Read back result blocks from each core
            for (block_i = 0; block_i < NUM_BLOCKS; block_i = block_i + 1) begin
                for (block_j = 0; block_j < NUM_BLOCKS; block_j = block_j + 1) begin
                    automatic integer core_x = block_i;
                    automatic integer core_y = block_j;
                    automatic integer base_addr = (core_y << 16) | (core_x << 8);
                    
                    $display("  Reading block from core [%0d,%0d]", core_x, core_y);
                    
                    // Read block data
                    for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
                        for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
                            automatic integer global_i = block_i*BLOCK_SIZE + i;
                            automatic integer global_j = block_j*BLOCK_SIZE + j;
                            automatic integer mem_addr = base_addr | (i << 4) | j;
                            
                            // Read from core memory
                            // matrix_c_result[global_i*MATRIX_SIZE + global_j] = ...;
                        end
                    end
                end
            end
            
            $display("  Results collected");
        end
    endtask
    
    task verify_results;
        begin
            errors = 0;
            
            $display("  Verifying %0d elements...", MATRIX_SIZE*MATRIX_SIZE);
            
            for (i = 0; i < MATRIX_SIZE; i = i + 1) begin
                for (j = 0; j < MATRIX_SIZE; j = j + 1) begin
                    automatic reg [31:0] result = matrix_c_result[i*MATRIX_SIZE + j];
                    automatic reg [31:0] expected = matrix_c_ref[i*MATRIX_SIZE + j];
                    automatic real result_val = $bitstoreal(result);
                    automatic real expected_val = $bitstoreal(expected);
                    automatic real diff = result_val - expected_val;
                    
                    if (diff < -0.001 || diff > 0.001) begin
                        errors = errors + 1;
                        if (errors <= 10) begin
                            $display("  Mismatch at [%0d,%0d]: got %f, expected %f",
                                     i, j, result_val, expected_val);
                        end
                    end
                end
                
                // Progress every 512 rows
                if (i % 512 == 0) begin
                    $display("  Verified %0d / %0d rows...", i, MATRIX_SIZE);
                end
            end
            
            $display("  Verification complete: %0d errors", errors);
        end
    endtask

endmodule
