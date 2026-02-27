// ============================================
// PE Driver
// ============================================

class pe_driver extends uvm_driver#(pe_transaction);
    
    `uvm_component_utils(pe_driver)
    
    virtual pe_if vif;
    
    function new(string name = "pe_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(virtual pe_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Cannot get PE interface")
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        forever begin
            seq_item_port.get_next_item(req);
            drive_pe(req);
            seq_item_port.item_done();
        end
    endtask
    
    virtual task drive_pe(pe_transaction tr);
        vif.pe_we  <= 1'b0;
        vif.pe_re  <= 1'b0;
        
        case (tr.op)
            PE_MAC: begin
                vif.pe_we <= 1'b1;
                vif.pe_addr <= tr.addr;
                vif.pe_wdata <= tr.wdata;
            end
            
            PE_ACT: begin
                vif.pe_we <= 1'b1;
                vif.pe_addr <= tr.addr;
                vif.pe_wdata <= tr.wdata;
            end
            
            PE_NORM: begin
                vif.pe_we <= 1'b1;
                vif.pe_addr <= tr.addr;
                vif.pe_wdata <= tr.wdata;
            end
            
            PE_LOAD, PE_STORE: begin
                vif.pe_addr <= tr.addr;
                if (tr.op == PE_LOAD)
                    vif.pe_re <= 1'b1;
                else
                    vif.pe_we <= 1'b1;
            end
            
            PE_NOP: begin
                // No operation
            end
        endcase
        
        @(posedge vif.clk);
        
        wait(vif.pe_grant);
        tr.grant = vif.pe_grant;
    endtask
    
endclass
