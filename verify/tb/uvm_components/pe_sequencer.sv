// ============================================
// PE Sequencer
// ============================================

class pe_sequencer extends uvm_sequencer#(pe_transaction);
    
    `uvm_component_utils(pe_sequencer)
    
    function new(string name = "pe_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
endclass
