// Normalization Unit SystemC Model
// Supports Layer Normalization and RMS Normalization

#ifndef NORMALIZATION_UNIT_SC_H
#define NORMALIZATION_UNIT_SC_H

#include <systemc.h>
#include <cmath>

template <int DATA_WIDTH, int VECTOR_WIDTH>
class normalization_unit_sc : public sc_module {
public:
    sc_in<bool> clk;
    sc_in<bool> rst_n;
    sc_in<bool> enable;
    sc_in<sc_uint<8>> norm_type;
    
    // Input/Output (packed)
    sc_in<sc_bv<DATA_WIDTH * VECTOR_WIDTH>> data_i;
    sc_out<sc_bv<DATA_WIDTH * VECTOR_WIDTH>> data_o;
    
    // Normalization type constants
    static const sc_uint8> NORM_LAYER = 0;
    static const sc_uint8> NORM_RMS = 1;
    
    SC_CTOR(normalization_unit_sc) {
        SC_METHOD(norm_process);
        sensitive << clk.pos();
        dont_initialize();
    }
    
private:
    void norm_process() {
        if (!rst_n.read()) {
            data_o.write(0);
            return;
        }
        
        if (enable.read()) {
            sc_bv<DATA_WIDTH * VECTOR_WIDTH> input_packed = data_i.read();
            sc_bv<DATA_WIDTH * VECTOR_WIDTH>> output_packed;
            
            // Extract elements
            double values[VECTOR_WIDTH];
            for (int i = 0; i < VECTOR_WIDTH; i++) {
                int val = 0;
                for (int bit = 0; bit < DATA_WIDTH; bit++) {
                    if (input_packed.read()[i * DATA_WIDTH + bit])
                        val |= (1 << bit);
                }
                values[i] = (double)val;
            }
            
            // Compute statistics
            double mean = 0.0;
            double variance = 0.0;
            
            for (int i = 0; i < VECTOR_WIDTH; i++) {
                mean += values[i];
            }
            mean /= VECTOR_WIDTH;
            
            for (int i = 0; i < VECTOR_WIDTH; i++) {
                double diff = values[i] - mean;
                variance += diff * diff;
            }
            variance /= VECTOR_WIDTH;
            
            sc_uint<8> type = norm_type.read();
            
            // Apply normalization
            for (int i = 0; i < VECTOR_WIDTH; i++) {
                double result;
                
                if (type == NORM_RMS) {
                    // RMS Norm: x / sqrt(mean(x^2) + eps)
                    double rms = sqrt(variance + 1e-8);
                    result = values[i] / rms;
                } else {
                    // Layer Norm: (x - mean) / sqrt(variance + eps)
                    result = (values[i] - mean) / sqrt(variance + 1e-8);
                }
                
                // Pack result
                int int_result = (int)result;
                for (int bit = 0; bit < DATA_WIDTH; bit++) {
                    output_packed.write()[i * DATA_WIDTH + bit] = (int_result >> bit) & 1;
                }
            }
            
            data_o.write(output_packed);
        } else {
            data_o.write(data_i.read());
        }
    }
};

#endif // NORMALIZATION_UNIT_SC_H
