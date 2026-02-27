// ============================================
// Scoreboard
// ============================================

class apache_hw_scoreboard extends uvm_scoreboard;
    
    `uvm_component_utils(apache_hw_scoreboard)
    
    uvm_tlm_analysis_fifo#(axi_transaction) m_axi_fifo;
    uvm_tlm_analysis_fifo#(axi_transaction) s_axi_fifo;
    uvm_tlm_analysis_fifo#(pe_transaction)  pe_fifo;
    
    int m_write_count;
    int m_read_count;
    int error_count;
    
    function new(string name = "apache_hw_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        m_axi_fifo = new("m_axi_fifo", this);
        s_axi_fifo = new("s_axi_fifo", this);
        pe_fifo = new("pe_fifo", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        axi_transaction axi_tr;
        pe_transaction pe_tr;
        
        forever begin
            fork
                begin
                    m_axi_fifo.get(axi_tr);
                    if (axi_tr.trans_kind == AXI_WRITE)
                        m_write_count++;
                    else
                        m_read_count++;
                end
                begin
                    pe_fifo.get(pe_tr);
                    // Check PE operations
                end
            join_any
        end
    endtask
    
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("SCOREBOARD", $sformatf("Write transactions: %0d", m_write_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Read transactions: %0d", m_read_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Errors: %0d", error_count), UVM_LOW)
    endfunction
    
endclass
