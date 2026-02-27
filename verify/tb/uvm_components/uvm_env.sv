// ============================================
// UVM Environment
// ============================================

class apache_hw_env extends uvm_env;
    
    `uvm_component_utils(apache_hw_env)
    
    // Agents
    axi_agent        m_axi_agent;
    axi_agent        s_axi_agent;
    pe_agent         pe_agent;
    ucie_agent       ucie_agent[];
    
    // Scoreboard
    apache_hw_scoreboard scoreboard;
    
    // Coverage
    apache_hw_coverage coverage;
    
    // Configuration
    env_config_t cfg;
    
    int num_pe = 64;
    int num_ucie = 8;
    
    function new(string name = "apache_hw_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get configuration
        if (!uvm_config_db#(env_config_t)::get(this, "", "cfg", cfg))
            `uvm_fatal("NO_CFG", "Cannot get configuration")
        
        // Create agents
        m_axi_agent = axi_agent::type_id::create("m_axi_agent", this);
        m_axi_agent.cfg = cfg.m_axi_cfg;
        
        s_axi_agent = axi_agent::type_id::create("s_axi_agent", this);
        s_axi_agent.cfg = cfg.s_axi_cfg;
        
        pe_agent = pe_agent::type_id::create("pe_agent", this);
        pe_agent.cfg = cfg.pe_cfg;
        
        // Create UCIe agents
        ucie_agent = new[num_ucie];
        for (int i = 0; i < num_ucie; i++) begin
            ucie_agent[i] = ucie_agent::type_id::create($sformatf("ucie_agent[%0d]", i), this);
            ucie_agent[i].cfg = cfg.ucie_cfg;
        end
        
        // Create scoreboard
        scoreboard = apache_hw_scoreboard::type_id::create("scoreboard", this);
        
        // Create coverage
        coverage = apache_hw_coverage::type_id::create("coverage", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect agents to scoreboard
        m_axi_agent.monitor.item_collected_port.connect(scoreboard.m_axi_fifo.analysis_export);
        s_axi_agent.monitor.item_collected_port.connect(scoreboard.s_axi_fifo.analysis_export);
        pe_agent.monitor.item_collected_port.connect(scoreboard.pe_fifo.analysis_export);
        
        // Connect coverage
        m_axi_agent.monitor.item_collected_port.connect(coverage.axi_export);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        // Wait for reset
        @(posedge cfg.rst_n);
        
        // Run tests
        `uvm_info("ENV", "Starting verification", UVM_LOW)
        
        phase.drop_objection(this);
    endtask
    
endclass
