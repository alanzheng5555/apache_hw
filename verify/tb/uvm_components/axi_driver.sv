// ============================================
// AXI Driver
// ============================================

class axi_driver extends uvm_driver#(axi_transaction);
    
    `uvm_component_utils(axi_driver)
    
    virtual axi_if vif;
    
    function new(string name = "axi_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Cannot get AXI interface")
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        forever begin
            seq_item_port.get_next_item(req);
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endfunction
    
    virtual task drive_transaction(axi_transaction tr);
        case (tr.trans_kind)
            AXI_WRITE: drive_write(tr);
            AXI_READ:  drive_read(tr);
        endcase
    endtask
    
    virtual task drive_write(axi_transaction tr);
        // AW Channel
        vif.awvalid <= 1'b1;
        vif.awaddr  <= tr.addr;
        vif.awlen   <= tr.len;
        vif.awsize  <= tr.size;
        vif.awburst <= tr.burst;
        
        wait(vif.awready);
        @(posedge vif.clk);
        vif.awvalid <= 1'b0;
        
        // W Channel
        for (int i = 0; i <= tr.len; i++) begin
            vif.wvalid <= 1'b1;
            vif.wdata  <= tr.data[i];
            vif.wstrb  <= tr.strb;
            vif.wlast  <= (i == tr.len);
            
            wait(vif.wready);
            @(posedge vif.clk);
        end
        vif.wvalid <= 1'b0;
        
        // B Channel
        vif.bready <= 1'b1;
        wait(vif.bvalid);
        tr.resp = vif.bresp;
        @(posedge vif.clk);
        vif.bready <= 1'b0;
    endtask
    
    virtual task drive_read(axi_transaction tr);
        // AR Channel
        vif.arvalid <= 1'b1;
        vif.araddr  <= tr.addr;
        vif.arlen   <= tr.len;
        vif.arsize  <= tr.size;
        vif.arburst <= tr.burst;
        
        wait(vif.arready);
        @(posedge vif.clk);
        vif.arvalid <= 1'b0;
        
        // R Channel
        vif.rready <= 1'b1;
        for (int i = 0; i <= tr.len; i++) begin
            wait(vif.rvalid);
            tr.data[i] = vif.rdata;
            tr.resp = vif.rresp;
            @(posedge vif.clk);
        end
        vif.rready <= 1'b0;
    endtask
    
endclass
