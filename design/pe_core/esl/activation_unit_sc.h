// Activation Unit SystemC Model
// Supports ReLU, GELU, Sigmoid, Tanh activation functions

#ifndef ACTIVATION_UNIT_SC_H
#define ACTIVATION_UNIT_SC_H

#include <systemc.h>
#include <cmath>

template <int DATA_WIDTH, int VECTOR_WIDTH>
class activation_unit_sc : public sc_module {
public:
    sc_in<bool> clk;
    sc_in<bool> rst_n;
    sc_in<bool> enable;
    sc_in<sc_uint<8>> activation_type;
    
    // Input/Output (packed)
    sc_in<sc_bv<DATA_WIDTH * VECTOR_WIDTH>> data_i;
    sc_out<sc_bv<DATA_WIDTH * VECTOR_WIDTH>> data_o;
    
    // Activation type constants
    static const sc_uint8> ACT_RELU = 1;
    static const sc_uint8> ACT_GELU = 2;
    static const sc_uint8> ACT_SIGMOID = 3;
    static const sc_uint8> ACT_TANH = 4;
    
    SC_CTOR(activation_unit_sc) {
        SC_METHOD(activation_process);
        sensitive << clk.pos();
        dont_initialize();
    }
    
private:
    void activation_process() {
        if (!rst_n.read()) {
            data_o.write(0);
            return;
        }
        
        if (enable.read()) {
            sc_bv<DATA_WIDTH * VECTOR_WIDTH> input_packed = data_i.read();
            sc_bv<DATA_WIDTH * VECTOR_WIDTH> output_packed;
            
            for (int i = 0; i < VECTOR_WIDTH; i++) {
                // Extract element
                int val = 0;
                for (int bit = 0; bit < DATA_WIDTH; bit++) {
                    if (input_packed.read()[i * DATA_WIDTH + bit])
                        val |= (1 << bit);
                }
                
                // Apply activation
                int result = 0;
                sc_uint<8> type = activation_type.read();
                
                switch (type) {
                    case ACT_RELU:
                        result = (val > 0) ? val : 0;
                        break;
                    case ACT_GELU:
                        // Approximate GELU: 0.5 * x * (1 + tanh(sqrt(2/pi) * (x + 0.044715 * x^3)))
                        result = (int)(0.5 * val * (1.0 + tanh(0.797885 * (val + 0.044715 * val * val * val))));
                        break;
                    case ACT_SIGMOID:
                        result = (int)(1.0 / (1.0 + exp(-val)));
                        break;
                    case ACT_TANH:
                        result = (int)tanh(val);
                        break;
                    default:
                        result = val; // Passthrough
                }
                
                // Pack result
                for (int bit = 0; bit < DATA_WIDTH; bit++) {
                    output_packed.write()[i * DATA_WIDTH + bit] = (result >> bit) & 1;
                }
            }
            
            data_o.write(output_packed);
        } else {
            data_o.write(data_i.read());
        }
    }
};

#endif // ACTIVATION_UNIT_SC_H
