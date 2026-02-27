// ============================================
// Functional Coverage
// ============================================

class apache_hw_coverage extends uvm_component;
    
    `uvm_component_utils(apache_hw_coverage)
    
    uvm_analysis_export#(axi_transaction) axi_export;
    uvm_analysis_export#(pe_transaction)  pe_export;
    
    // AXI Coverage
    covergroup axi_cg;
        option.per_instance = 1;
        
        trans_kind: coverpoint tr.trans_kind {
            bins WRITE = {AXI_WRITE};
            bins READ  = {AXI_READ};
        }
        
        addr: coverpoint tr.addr {
            bins LOW    = {[0:32'h0FFFFFFF]};
            bins MID    = {[32'h10000000:32'h7FFFFFFF]};
            bins HIGH   = {[32'h80000000:32'hFFFFFFFF]};
        }
        
        len: coverpoint tr.len {
            bins SINGLE = {0};
            bins BURST4 = {[1:4]};
            bins BURST8 = {[5:8]};
            bins BURST16 = {[9:16]};
        }
    endgroup
    
    // PE Coverage
    covergroup pe_cg;
        option.per_instance = 1;
        
        op: coverpoint tr.op {
            bins MAC   = {PE_MAC};
            bins ACT   = {PE_ACT};
            bins NORM  = {PE_NORM};
            bins LOAD  = {PE_LOAD};
            bins STORE = {PE_STORE};
            bins NOP   = {PE_NOP};
        }
        
        act_type: coverpoint tr.act_type {
            bins RELU    = {0};
            bins GELU    = {1};
            bins SIGMOID = {2};
            bins TANH    = {3};
        }
        
        norm_type: coverpoint tr.norm_type {
            bins LAYERNORM = {0};
            bins RMSNORM   = {1};
        }
    endgroup
    
    axi_transaction tr;
    pe_transaction pe_tr;
    
    function new(string name = "apache_hw_coverage", uvm_component parent = null);
        super.new(name, parent);
        axi_cg = new();
        pe_cg = new();
        
        axi_export = new("axi_export", this);
        pe_export = new("pe_export", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction
    
endclass
