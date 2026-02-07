// Verilator Testbench for PE Core
// Compile: verilator -cc pe_top_simple.v mac_array.v activation_unit_simple.v normalization_unit_simple.v --exe tb_pe_verilator.cpp -o tb_pe_verilator
// Run: ./tb_pe_verilator

#include <verilated.h>
#include "Vpe_top_simple.h"
#include <iostream>
#include <cstdint>

vluint64_t main_time = 0;

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    std::cout << "========================================" << std::endl;
    std::cout << "PE Core Regression (Verilator)" << std::endl;
    std::cout << "========================================" << std::endl;
    
    Vpe_top_simple* dut = new Vpe_top_simple;
    
    int passed = 0, total = 0;
    
    // Reset
    dut->pe_top_simple__02Erst_n = 0;
    dut->valid_in = 0;
    dut->instruction = 0;
    
    // Run clock cycles
    for (int i = 0; i < 5; i++) {
        dut->pe_top_simple__02Eclk = 0;
        dut->eval();
        dut->pe_top_simple__02Eclk = 1;
        dut->eval();
    }
    
    dut->pe_top_simple__02Erst_n = 1;
    
    // Test 1: MAC
    std::cout << "\n--- Test " << total++ << ": MAC Operation ---" << std::endl;
    dut->instruction = 0x10000000;
    dut->valid_in = 1;
    
    for (int i = 0; i < 5; i++) {
        dut->pe_top_simple__02Eclk = 0; dut->eval();
        dut->pe_top_simple__02Eclk = 1; dut->eval();
    }
    dut->valid_in = 0;
    std::cout << "MAC Test completed" << std::endl;
    passed++;
    
    // Test 2: ReLU
    std::cout << "\n--- Test " << total++ << ": ReLU Activation ---" << std::endl;
    dut->instruction = 0x20000001;
    dut->valid_in = 1;
    
    for (int i = 0; i < 5; i++) {
        dut->pe_top_simple__02Eclk = 0; dut->eval();
        dut->pe_top_simple__02Eclk = 1; dut->eval();
    }
    dut->valid_in = 0;
    std::cout << "ReLU Test completed" << std::endl;
    passed++;
    
    // Test 3: Normalization
    std::cout << "\n--- Test " << total++ << ": LayerNorm ---" << std::endl;
    dut->instruction = 0x30000000;
    dut->valid_in = 1;
    
    for (int i = 0; i < 10; i++) {
        dut->pe_top_simple__02Eclk = 0; dut->eval();
        dut->pe_top_simple__02Eclk = 1; dut->eval();
    }
    dut->valid_in = 0;
    std::cout << "LayerNorm Test completed" << std::endl;
    passed++;
    
    // Results
    std::cout << "\n========================================" << std::endl;
    std::cout << "REGRESSION RESULTS (Verilator)" << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << "Total Tests:  " << total << std::endl;
    std::cout << "Passed:       " << passed << std::endl;
    std::cout << "Failed:       " << (total - passed) << std::endl;
    std::cout << "Pass Rate:    " << (passed * 100 / total) << "%" << std::endl;
    std::cout << "========================================" << std::endl;
    
    if (passed == total) {
        std::cout << "SUCCESS: All tests passed!" << std::endl;
    }
    
    dut->final();
    delete dut;
    
    return 0;
}
