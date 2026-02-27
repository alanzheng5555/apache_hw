// ============================================
// AXI Transaction
// ============================================

typedef enum {AXI_WRITE, AXI_READ} axi_trans_kind_t;

class axi_transaction extends uvm_sequence_item;
    
    rand axi_trans_kind_t trans_kind;
    rand bit [31:0]       addr;
    rand bit [7:0]        len;
    rand bit [2:0]        size;
    rand bit [1:0]        burst;
    rand bit [1:0]        resp;
    rand bit [7:0]        strb;
    rand bit [63:0]       data[];
    
    `uvm_object_utils_begin(axi_transaction)
        `uvm_field_enum(axi_trans_kind_t, trans_kind, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(len, UVM_ALL_ON)
        `uvm_field_int(size, UVM_ALL_ON)
        `uvm_field_int(burst, UVM_ALL_ON)
        `uvm_field_int(resp, UVM_ALL_ON)
        `uvm_field_int(strb, UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "axi_transaction");
        super.new(name);
    endfunction
    
    virtual function void do_copy(uvm_object rhs);
        axi_transaction tr;
        super.do_copy(rhs);
        $cast(tr, rhs);
        trans_kind = tr.trans_kind;
        addr = tr.addr;
        len = tr.len;
        size = tr.size;
        burst = tr.burst;
        resp = tr.resp;
        strb = tr.strb;
        data = tr.data;
    endfunction
    
endclass
