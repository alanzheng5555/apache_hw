// ============================================
// PE Monitor
// ============================================

class pe_monitor extends uvm_monitor;
    
    `uvm_component_utils(pe_monitor)
    
    virtual pe_if vif;
    
    uvm_analysis_port#(pe_transaction) item_collected_port;
    
    function new(string name = "pe_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(virtual pe_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Cannot get PE interface")
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        forever begin
            @(posedge vif.clk);
            
            if (vif.pe_we || vif.pe_re) begin
                pe_transaction tr;
                tr = pe_transaction::type_id::create("tr");
                
                tr.addr = vif.pe_addr;
                tr.wdata = vif.pe_wdata;
                tr.rdata = vif.pe_rdata;
                tr.grant = vif.pe_grant;
                
                item_collected_port.write(tr);
            end
        end
    endtask
    
endclass
