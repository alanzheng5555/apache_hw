// ============================================
// Configuration Classes
// ============================================

// AXI Configuration
class axi_config extends uvm_object;
    `uvm_object_utils(axi_config)
    
    bit is_active = 1;
    bit enable_coverage = 1;
    bit enable_assertions = 1;
    
    function new(string name = "axi_config");
        super.new(name);
    endfunction
endclass

// PE Configuration
class pe_config extends uvm_object;
    `uvm_object_utils(pe_config)
    
    bit is_active = 1;
    bit enable_coverage = 1;
    int num_pe = 64;
    
    function new(string name = "pe_config");
        super.new(name);
    endfunction
endclass

// UCIe Configuration
class ucie_config extends uvm_object;
    `uvm_object_utils(ucie_config)
    
    bit is_active = 1;
    int num_lanes = 16;
    int data_width = 256;
    
    function new(string name = "ucie_config");
        super.new(name);
    endfunction
endclass

// Environment Configuration
class env_config_t extends uvm_object;
    `uvm_object_utils(env_config_t)
    
    axi_config m_axi_cfg;
    axi_config s_axi_cfg;
    pe_config  pe_cfg;
    ucie_config ucie_cfg;
    
    bit rst_n;
    
    function new(string name = "env_config_t");
        super.new(name);
        m_axi_cfg = axi_config::type_id::create("m_axi_cfg");
        s_axi_cfg = axi_config::type_id::create("s_axi_cfg");
        pe_cfg = pe_config::type_id::create("pe_cfg");
        ucie_cfg = ucie_config::type_id::create("ucie_cfg");
    endfunction
endclass
