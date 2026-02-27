// ============================================
// AXI Agent
// ============================================

class axi_agent extends uvm_agent;
    
    `uvm_component_utils(axi_agent)
    
    axi_driver     driver;
    axi_monitor    monitor;
    axi_sequencer sequencer;
    axi_config     cfg;
    
    uvm_analysis_port#(axi_transaction) item_collected_port;
    
    function new(string name = "axi_agent", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        monitor = axi_monitor::type_id::create("monitor", this);
        
        if (cfg.is_active) begin
            driver = axi_driver::type_id::create("driver", this);
            sequencer = axi_sequencer::type_id::create("sequencer", this);
        end
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        if (cfg.is_active) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
        
        monitor.item_collected_port.connect(item_collected_port);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        if (cfg.is_active) begin
            fork
                sequencer.run();
            join_none
        end
        
        phase.drop_objection(this);
    endtask
    
endclass
