// ============================================
// Base Sequence
// ============================================

class base_sequence extends uvm_sequence;
    
    `uvm_object_utils(base_sequence)
    
    function new(string name = "base_sequence");
        super.new(name);
    endfunction
    
endclass

// ============================================
// PE MAC Sequence
// ============================================

class pe_mac_sequence extends base_sequence;
    
    `uvm_object_utils(pe_mac_sequence)
    `uvm_declare_p_sequencer(pe_sequencer)
    
    rand int num_trans = 10;
    rand bit [31:0] start_addr = 32'h1000;
    
    function new(string name = "pe_mac_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        for (int i = 0; i < num_trans; i++) begin
            pe_transaction tr;
            tr = pe_transaction::type_id::create("tr");
            
            start_item(tr);
            tr.op = PE_MAC;
            tr.addr = start_addr + (i * 4);
            tr.wdata = $random;
            finish_item(tr);
        end
    endtask
    
endclass

// ============================================
// PE Activation Sequence
// ============================================

class pe_act_sequence extends base_sequence;
    
    `uvm_object_utils(pe_act_sequence)
    `uvm_declare_p_sequencer(pe_sequencer)
    
    rand int num_trans = 10;
    rand bit [7:0] act_type = 0; // 0:ReLU
    
    function new(string name = "pe_act_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        for (int i = 0; i < num_trans; i++) begin
            pe_transaction tr;
            tr = pe_transaction::type_id::create("tr");
            
            start_item(tr);
            tr.op = PE_ACT;
            tr.addr = 32'h2000 + (i * 4);
            tr.wdata = $random;
            tr.act_type = act_type;
            finish_item(tr);
        end
    endtask
    
endclass

// ============================================
// PE Normalization Sequence
// ============================================

class pe_norm_sequence extends base_sequence;
    
    `uvm_object_utils(pe_norm_sequence)
    `uvm_declare_p_sequencer(pe_sequencer)
    
    rand int num_trans = 10;
    rand bit [7:0] norm_type = 0;
    
    function new(string name = "pe_norm_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        for (int i = 0; i < num_trans; i++) begin
            pe_transaction tr;
            tr = pe_transaction::type_id::create("tr");
            
            start_item(tr);
            tr.op = PE_NORM;
            tr.addr = 32'h3000 + (i * 4);
            tr.wdata = $random;
            tr.norm_type = norm_type;
            finish_item(tr);
        end
    endtask
    
endclass

// ============================================
// AXI Write Sequence
// ============================================

class axi_write_sequence extends base_sequence;
    
    `uvm_object_utils(axi_write_sequence)
    `uvm_declare_p_sequencer(axi_sequencer)
    
    rand int num_trans = 10;
    rand bit [31:0] start_addr = 32'h8000_0000;
    rand bit [7:0] burst_len = 0;
    
    function new(string name = "axi_write_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        for (int i = 0; i < num_trans; i++) begin
            axi_transaction tr;
            tr = axi_transaction::type_id::create("tr");
            
            start_item(tr);
            tr.trans_kind = AXI_WRITE;
            tr.addr = start_addr + (i * 64);
            tr.len = burst_len;
            tr.size = 3'b011; // 64-bit
            tr.burst = 2'b01; // INCR
            tr.strb = 8'hFF;
            
            tr.data = new[burst_len + 1];
            for (int j = 0; j <= burst_len; j++)
                tr.data[j] = $random;
            
            finish_item(tr);
        end
    endtask
    
endclass

// ============================================
// AXI Read Sequence
// ============================================

class axi_read_sequence extends base_sequence;
    
    `uvm_object_utils(axi_read_sequence)
    `uvm_declare_p_sequencer(axi_sequencer)
    
    rand int num_trans = 10;
    rand bit [31:0] start_addr = 32'h8000_0000;
    rand bit [7:0] burst_len = 0;
    
    function new(string name = "axi_read_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        for (int i = 0; i < num_trans; i++) begin
            axi_transaction tr;
            tr = axi_transaction::type_id::create("tr");
            
            start_item(tr);
            tr.trans_kind = AXI_READ;
            tr.addr = start_addr + (i * 64);
            tr.len = burst_len;
            tr.size = 3'b011;
            tr.burst = 2'b01;
            finish_item(tr);
        end
    endtask
    
endclass
