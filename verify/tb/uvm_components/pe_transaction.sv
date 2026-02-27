// ============================================
// PE Transaction
// ============================================

typedef enum {PE_MAC, PE_ACT, PE_NORM, PE_LOAD, PE_STORE, PE_NOP} pe_op_t;

class pe_transaction extends uvm_sequence_item;
    
    rand pe_op_t       op;
    rand bit [31:0]    addr;
    rand bit [31:0]    wdata;
    rand bit [7:0]     act_type;   // 0:ReLU, 1:GELU, 2:Sigmoid, 3:Tanh
    rand bit [7:0]     norm_type;  // 0:LayerNorm, 1:RMSNorm
    
    bit [31:0]         rdata;
    bit                grant;
    
    `uvm_object_utils_begin(pe_transaction)
        `uvm_field_enum(pe_op_t, op, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(act_type, UVM_ALL_ON)
        `uvm_field_int(norm_type, UVM_ALL_ON)
        `uvm_field_int(grant, UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "pe_transaction");
        super.new(name);
    endfunction
    
endclass
