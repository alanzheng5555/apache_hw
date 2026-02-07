// PE Top SystemC Model (ESL)
// Top-level module integrating MAC array, activation unit, and normalization unit

#ifndef PE_TOP_SC_H
#define PE_TOP_SC_H

#include <systemc.h>
#include "mac_array_sc.h"
#include "activation_unit_sc.h"
#include "normalization_unit_sc.h"

template <int DATA_WIDTH, int VECTOR_WIDTH, int MAC_ROWS, int MAC_COLS>
class pe_top_sc : public sc_module {
public:
    // Clock and reset
    sc_in<bool> clk;
    sc_in<bool> rst_n;
    
    // Control interface
    sc_in<bool> valid_in;
    sc_out<bool> ready_out;
    sc_in<sc_uint<32>> instruction;
    
    // Data inputs (packed)
    sc_in<sc_bv<DATA_WIDTH * VECTOR_WIDTH>> data_a_i;
    sc_in<sc_bv<DATA_WIDTH * VECTOR_WIDTH>> data_b_i;
    sc_in<sc_bv<DATA_WIDTH * VECTOR_WIDTH>> weight_i;
    
    // Data outputs (packed)
    sc_out<sc_bv<DATA_WIDTH * VECTOR_WIDTH>> result_o;
    sc_out<bool> valid_out;
    
    // Instruction decode signals
    sc_signal<bool> mac_enable;
    sc_signal<bool> activation_enable;
    sc_signal<bool> norm_enable;
    sc_signal<sc_uint<8>> activation_type;
    sc_signal<sc_uint<8>> norm_type;
    
    // Internal signals
    sc_signal<sc_bv<DATA_WIDTH * MAC_ROWS>> mac_result_sig;
    sc_signal<sc_bv<DATA_WIDTH * MAC_ROWS>> activation_input;
    sc_signal<sc_bv<DATA_WIDTH * MAC_ROWS>> activation_result_sig;
    sc_signal<sc_bv<DATA_WIDTH * MAC_ROWS>> norm_result_sig;
    
    // Sub-modules
    mac_array_sc<DATA_WIDTH, MAC_ROWS, MAC_COLS>* u_mac_array;
    activation_unit_sc<DATA_WIDTH, MAC_ROWS>* u_activation;
    normalization_unit_sc<DATA_WIDTH, MAC_ROWS>* u_normalization;
    
    SC_CTOR(pe_top_sc) {
        // Instantiate sub-modules
        u_mac_array = new mac_array_sc<DATA_WIDTH, MAC_ROWS, MAC_COLS>("mac_array");
        u_mac_array->clk(clk);
        u_mac_array->rst_n(rst_n);
        u_mac_array->enable(mac_enable);
        u_mac_array->data_a_i(data_a_i);
        u_mac_array->data_b_i(data_b_i);
        u_mac_array->weight_i(weight_i);
        u_mac_array->mac_result(mac_result_sig);
        
        u_activation = new activation_unit_sc<DATA_WIDTH, MAC_ROWS>("activation");
        u_activation->clk(clk);
        u_activation->rst_n(rst_n);
        u_activation->enable(activation_enable);
        u_activation->activation_type(activation_type);
        u_activation->data_i(activation_input);
        u_activation->data_o(activation_result_sig);
        
        u_normalization = new normalization_unit_sc<DATA_WIDTH, MAC_ROWS>("normalization");
        u_normalization->clk(clk);
        u_normalization->rst_n(rst_n);
        u_normalization->enable(norm_enable);
        u_normalization->norm_type(norm_type);
        u_normalization->data_i(activation_result_sig);
        u_normalization->data_o(norm_result_sig);
        
        SC_METHOD(decode_instruction);
        sensitive << instruction;
        dont_initialize();
        
        SC_METHOD(output_mux);
        sensitive << valid_in << norm_enable << activation_enable << mac_enable 
                  << norm_result_sig << activation_result_sig << mac_result_sig << data_a_i;
        dont_initialize();
    }
    
    ~pe_top_sc() {
        delete u_mac_array;
        delete u_activation;
        delete u_normalization;
    }
    
private:
    void decode_instruction() {
        sc_uint<32> instr = instruction.read();
        sc_uint<4> opcode = instr.range(31, 28);
        
        mac_enable.write(opcode == 1);
        activation_enable.write(opcode == 2);
        norm_enable.write(opcode == 3);
        
        activation_type.write(instr.range(7, 0));
        norm_type.write(instr.range(7, 0));
        
        // Connect MAC result to activation input when MAC is enabled
        if (opcode == 1 && valid_in.read()) {
            // Pad or truncate MAC result to fit activation input width
            sc_bv<DATA_WIDTH * MAC_ROWS> mac_out = mac_result_sig.read();
            activation_input.write(mac_out);
        } else {
            activation_input.write(mac_result_sig.read());
        }
        
        ready_out.write(true);
    }
    
    void output_mux() {
        if (!valid_in.read()) {
            valid_out.write(false);
            return;
        }
        
        sc_bv<DATA_WIDTH * VECTOR_WIDTH> output_packed;
        
        // Zero initialize
        for (int i = 0; i < DATA_WIDTH * VECTOR_WIDTH; i++) {
            output_packed.write()[i] = 0;
        }
        
        if (norm_enable.read()) {
            // Output from normalization unit
            sc_bv<DATA_WIDTH * MAC_ROWS> norm_out = norm_result_sig.read();
            for (int i = 0; i < MAC_ROWS && i < VECTOR_WIDTH; i++) {
                for (int bit = 0; bit < DATA_WIDTH; bit++) {
                    output_packed.write()[i * DATA_WIDTH + bit] = norm_out.read()[i * DATA_WIDTH + bit];
                }
            }
            valid_out.write(true);
        } else if (activation_enable.read()) {
            // Output from activation unit
            sc_bv<DATA_WIDTH * MAC_ROWS> act_out = activation_result_sig.read();
            for (int i = 0; i < MAC_ROWS && i < VECTOR_WIDTH; i++) {
                for (int bit = 0; bit < DATA_WIDTH; bit++) {
                    output_packed.write()[i * DATA_WIDTH + bit] = act_out.read()[i * DATA_WIDTH + bit];
                }
            }
            valid_out.write(true);
        } else if (mac_enable.read()) {
            // Output from MAC array
            sc_bv<DATA_WIDTH * MAC_ROWS> mac_out = mac_result_sig.read();
            for (int i = 0; i < MAC_ROWS && i < VECTOR_WIDTH; i++) {
                for (int bit = 0; bit < DATA_WIDTH; bit++) {
                    output_packed.write()[i * DATA_WIDTH + bit] = mac_out.read()[i * DATA_WIDTH + bit];
                }
            }
            valid_out.write(true);
        } else {
            // Passthrough
            result_o.write(data_a_i.read());
            valid_out.write(valid_in.read());
        }
    }
};

#endif // PE_TOP_SC_H
