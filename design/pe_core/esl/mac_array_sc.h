// MAC Array SystemC Model
// Electronic System Level (ESL) model for PE Core

#include <systemc.h>
#include <vector>
#include <cmath>

template <int DATA_WIDTH, int ARRAY_ROWS, int ARRAY_COLS>
class mac_array_sc : public sc_module {
public:
    sc_in<bool> clk;
    sc_in<bool> rst_n;
    sc_in<bool> enable;
    
    // Packed data inputs
    sc_in<sc_bv<DATA_WIDTH * ARRAY_COLS>> data_a_i;
    sc_in<sc_bv<DATA_WIDTH * ARRAY_ROWS>> data_b_i;
    sc_in<sc_bv<DATA_WIDTH * ARRAY_COLS>> weight_i;
    
    // Output
    sc_out<sc_bv<DATA_WIDTH * ARRAY_ROWS>> mac_result;
    
    // Constructor
    SC_CTOR(mac_array_sc) {
        SC_METHOD(mac_process);
        sensitive << clk.pos();
        dont_initialize();
        
        // Initialize accumulators
        for (int i = 0; i < ARRAY_ROWS; i++) {
            accumulators[i] = 0;
        }
    }
    
private:
    sc_int<DATA_WIDTH * 2 + 8> accumulators[ARRAY_ROWS];
    
    void mac_process() {
        if (!rst_n.read()) {
            for (int i = 0; i < ARRAY_ROWS; i++) {
                accumulators[i] = 0;
            }
            mac_result.write(0);
            return;
        }
        
        if (enable.read()) {
            sc_bv<DATA_WIDTH * ARRAY_COLS> a_packed = data_a_i.read();
            sc_bv<DATA_WIDTH * ARRAY_ROWS> b_packed = data_b_i.read();
            sc_bv<DATA_WIDTH * ARRAY_COLS> w_packed = weight_i.read();
            
            sc_int<DATA_WIDTH * 2 + 8> acc[ARRAY_ROWS] = {0};
            
            // Unpack and compute
            for (int row = 0; row < ARRAY_ROWS; row++) {
                for (int col = 0; col < ARRAY_COLS; col++) {
                    // Extract b_vec[row]
                    int b_val = 0;
                    for (int bit = 0; bit < DATA_WIDTH; bit++) {
                        if (b_packed.read()[row * DATA_WIDTH + bit])
                            b_val |= (1 << bit);
                    }
                    
                    // Extract w_vec[col]
                    int w_val = 0;
                    for (int bit = 0; bit < DATA_WIDTH; bit++) {
                        if (w_packed.read()[col * DATA_WIDTH + bit])
                            w_val |= (1 << bit);
                    }
                    
                    // Multiply and accumulate
                    acc[row] += b_val * w_val;
                }
            }
            
            // Store results
            for (int i = 0; i < ARRAY_ROWS; i++) {
                accumulators[i] = acc[i];
            }
        }
        
        // Pack output
        sc_bv<DATA_WIDTH * ARRAY_ROWS> result_packed;
        for (int row = 0; row < ARRAY_ROWS; row++) {
            int val = (int)accumulators[row];
            for (int bit = 0; bit < DATA_WIDTH; bit++) {
                result_packed.write()[row * DATA_WIDTH + bit] = (val >> bit) & 1;
            }
        }
        mac_result.write(result_packed);
    }
};

#endif // MAC_ARRAY_SC_H
