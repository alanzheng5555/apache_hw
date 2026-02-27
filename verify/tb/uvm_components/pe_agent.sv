// ============================================
// PE Agent
// ============================================

class pe_agent extends uvm_agent;
    
    `uvm_component_utils(pe_agent)
    
    pe_driver     driver;
    pe_monitor    monitor;
    pe_sequencer  sequencer;
    pe_config     cfg;
    
    uvm_analysis_port#(pe_transaction) item_collected_port;
    
    function new(string name = "pe_agent", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        monitor = pe_monitor::type_id::create("monitor", this);
        
        if (cfg.is_active) begin
            driver = pe_driver::type_id::create("driver", this);
            sequencer = pe_sequencer::type_id::create("sequencer", this);
        end
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        if (cfg.is_active) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
        
        monitor.item_collected_port.connect(item_collected_port);
    endfunction
    
endclass
