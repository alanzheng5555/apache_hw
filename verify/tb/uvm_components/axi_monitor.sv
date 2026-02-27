// ============================================
// AXI Monitor
// ============================================

class axi_monitor extends uvm_monitor;
    
    `uvm_component_utils(axi_monitor)
    
    virtual axi_if vif;
    
    uvm_analysis_port#(axi_transaction) item_collected_port;
    
    function new(string name = "axi_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Cannot get AXI interface")
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        forever begin
            @(posedge vif.clk);
            
            // Monitor AW channel
            if (vif.awvalid && vif.awready) begin
                axi_transaction tr;
                tr = axi_transaction::type_id::create("tr");
                tr.trans_kind = AXI_WRITE;
                tr.addr = vif.awaddr;
                tr.len = vif.awlen;
                tr.size = vif.awsize;
                tr.burst = vif.awburst;
                
                // Collect write data
                tr.data = new[vif.awlen + 1];
                for (int i = 0; i <= vif.awlen; i++) begin
                    @(posedge vif.clk);
                    if (vif.wvalid)
                        tr.data[i] = vif.wdata;
                end
                
                item_collected_port.write(tr);
            end
            
            // Monitor AR channel
            if (vif.arvalid && vif.arready) begin
                axi_transaction tr;
                tr = axi_transaction::type_id::create("tr");
                tr.trans_kind = AXI_READ;
                tr.addr = vif.araddr;
                tr.len = vif.arlen;
                tr.size = vif.arsize;
                tr.burst = vif.arburst;
                
                // Collect read data
                tr.data = new[vif.arlen + 1];
                for (int i = 0; i <= vif.arlen; i++) begin
                    @(posedge vif.clk);
                    if (vif.rvalid) begin
                        tr.data[i] = vif.rdata;
                        tr.resp = vif.rresp;
                    end
                end
                
                item_collected_port.write(tr);
            end
        end
    endtask
    
endclass
