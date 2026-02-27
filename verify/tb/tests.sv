// ============================================
// Base Test
// ============================================

class base_test extends uvm_test;
    
    `uvm_component_utils(base_test)
    
    apache_hw_env env;
    env_config_t cfg;
    
    function new(string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create configuration
        cfg = env_config_t::type_id::create("cfg");
        
        // Set up interfaces via config_db
        // (In real environment, would set virtual interfaces here)
        
        // Create environment
        env = apache_hw_env::type_id::create("env", this);
        uvm_config_db#(env_config_t)::set(this, "env", "cfg", cfg);
    endfunction
    
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        
        print_config();
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        uvm_report_server server = get_report_server();
        `uvm_info("TEST", $sformatf("Test completed with %0d errors", server.get_severity_count(UVM_ERROR)), UVM_LOW)
    endfunction
    
endclass

// ============================================
// PE MAC Test
// ============================================

class pe_mac_test extends base_test;
    
    `uvm_component_utils(pe_mac_test)
    
    function new(string name = "pe_mac_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        pe_mac_sequence seq;
        
        phase.raise_objection(this);
        
        seq = pe_mac_sequence::type_id::create("seq");
        seq.num_trans = 100;
        
        `uvm_info("TEST", "Starting PE MAC test", UVM_LOW)
        
        // Fork sequence execution
        fork
            seq.start(env.pe_agent.sequencer);
        join
        
        #1000;
        
        phase.drop_objection(this);
    endtask
    
endclass

// ============================================
// PE Activation Test
// ============================================

class pe_act_test extends base_test;
    
    `uvm_component_utils(pe_act_test)
    
    function new(string name = "pe_act_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        pe_act_sequence seq;
        
        phase.raise_objection(this);
        
        seq = pe_act_sequence::type_id::create("seq");
        seq.num_trans = 50;
        seq.act_type = 0; // ReLU
        
        `uvm_info("TEST", "Starting PE Activation test", UVM_LOW)
        
        fork
            seq.start(env.pe_agent.sequencer);
        join
        
        #1000;
        
        phase.drop_objection(this);
    endtask
    
endclass

// ============================================
// AXI Write/Read Test
// ============================================

class axi_test extends base_test;
    
    `uvm_component_utils(axi_test)
    
    function new(string name = "axi_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        axi_write_sequence wr_seq;
        axi_read_sequence rd_seq;
        
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting AXI test", UVM_LOW)
        
        fork
            begin
                wr_seq = axi_write_sequence::type_id::create("wr_seq");
                wr_seq.num_trans = 20;
                wr_seq.start(env.m_axi_agent.sequencer);
            end
            
            begin
                rd_seq = axi_read_sequence::type_id::create("rd_seq");
                rd_seq.num_trans = 20;
                rd_seq.start(env.m_axi_agent.sequencer);
            end
        join
        
        #1000;
        
        phase.drop_objection(this);
    endtask
    
endclass

// ============================================
// Full Integration Test
// ============================================

class full_test extends base_test;
    
    `uvm_component_utils(full_test)
    
    function new(string name = "full_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        pe_mac_sequence   mac_seq;
        pe_act_sequence  act_seq;
        pe_norm_sequence norm_seq;
        axi_write_sequence wr_seq;
        
        phase.raise_objection(this);
        
        `uvm_info("TEST", "Starting Full Integration test", UVM_LOW)
        
        fork
            begin
                mac_seq = pe_mac_sequence::type_id::create("mac_seq");
                mac_seq.num_trans = 100;
                mac_seq.start(env.pe_agent.sequencer);
            end
            
            begin
                act_seq = pe_act_sequence::type_id::create("act_seq");
                act_seq.num_trans = 50;
                act_seq.start(env.pe_agent.sequencer);
            end
            
            begin
                norm_seq = pe_norm_sequence::type_id::create("norm_seq");
                norm_seq.num_trans = 50;
                norm_seq.start(env.pe_agent.sequencer);
            end
            
            begin
                wr_seq = axi_write_sequence::type_id::create("wr_seq");
                wr_seq.num_trans = 20;
                wr_seq.start(env.m_axi_agent.sequencer);
            end
        join
        
        #1000;
        
        phase.drop_objection(this);
    endtask
    
endclass
