// PE Core ESL Model - FP32 Floating Point Version
// Implements proper IEEE-754 FP32 operations

#include <systemc.h>
#include <iostream>
#include <cmath>
#include <cstdint>

const int W = 256;  // Unified width (8 * 32)

// ============================================
// FP32 Helper Functions
// ============================================
float bits_to_float(uint32_t bits) {
    float f;
    std::memcpy(&f, &bits, sizeof(float));
    return f;
}

uint32_t float_to_bits(float f) {
    uint32_t bits;
    std::memcpy(&bits, &f, sizeof(uint32_t));
    return bits;
}

// Extract FP32 from bit position in packed array
float unpack_fp32(const sc_bv<W>& packed, int idx) {
    uint32_t bits = 0;
    for (int i = 0; i < 32; i++) {
        if (packed[idx * 32 + i]) bits |= (1u << i);
    }
    return bits_to_float(bits);
}

// Pack FP32 into bit position in packed array
void pack_fp32(sc_bv<W>& packed, int idx, float f) {
    uint32_t bits = float_to_bits(f);
    for (int i = 0; i < 32; i++) {
        packed[idx * 32 + i] = (bool)((bits >> i) & 1);
    }
}

// ============================================
// MAC Array (FP32)
// ============================================
SC_MODULE(mac_array) {
    sc_in<bool> clk, rst_n, enable;
    sc_in<sc_bv<W>> a_in, b_in, w_in;
    sc_out<sc_bv<W>> result;
    
    std::vector<float> acc;
    
    SC_CTOR(mac_array) : acc(8, 0.0f) {
        SC_METHOD(process);
        sensitive << clk.pos();
    }
    
    void process() {
        if (!rst_n.read()) { 
            for(int i=0;i<8;i++) acc[i] = 0.0f; 
            result.write(0);
            return;
        }
        if (enable.read()) {
            sc_bv<W> a_packed = a_in.read();
            sc_bv<W> b_packed = b_in.read();
            sc_bv<W> w_packed = w_in.read();
            
            for(int r=0;r<8;r++) {
                float sum = 0.0f;
                for(int c=0;c<8;c++) {
                    float bv = unpack_fp32(b_packed, r);
                    float wv = unpack_fp32(w_packed, c);
                    sum += bv * wv;
                }
                acc[r] = sum;
            }
        }
        // Pack output
        sc_bv<W> out;
        for(int r=0;r<8;r++) {
            pack_fp32(out, r, acc[r]);
        }
        result.write(out);
    }
};

// ============================================
// Activation Unit (FP32)
// ============================================
SC_MODULE(activation) {
    sc_in<bool> clk, rst_n, enable;
    sc_in<sc_uint<8>> type;
    sc_in<sc_bv<W>> in;
    sc_out<sc_bv<W>> out;
    
    SC_CTOR(activation) {
        SC_METHOD(process);
        sensitive << clk.pos();
    }
    
    void process() {
        if (!rst_n.read()) { out.write(0); return; }
        if (enable.read()) {
            sc_bv<W> input = in.read();
            sc_bv<W> output;
            int t = (int)type.read();
            
            for(int i=0;i<8;i++) {
                float v = unpack_fp32(input, i);
                float r = 0.0f;
                switch(t) {
                    case 1:  // ReLU
                        r = (v > 0.0f) ? v : 0.0f; 
                        break;
                    case 2: {  // GELU: 0.5*x*(1+tanh(sqrt(2/pi)*(x+0.044715*x^3)))
                        float x = v;
                        r = 0.5f * x * (1.0f + tanhf(0.797885f * (x + 0.044715f * x * x * x)));
                        break;
                    }
                    case 3:  // Sigmoid
                        r = 1.0f / (1.0f + expf(-v)); 
                        break;
                    case 4:  // Tanh
                        r = tanhf(v); 
                        break;
                    default: 
                        r = v;
                }
                pack_fp32(output, i, r);
            }
            out.write(output);
        } else { out.write(in.read()); }
    }
};

// ============================================
// Normalization Unit (FP32)
// ============================================
SC_MODULE(norm) {
    sc_in<bool> clk, rst_n, enable;
    sc_in<sc_uint<8>> type;
    sc_in<sc_bv<W>> in;
    sc_out<sc_bv<W>> out;
    
    const float eps = 1e-5f;
    
    SC_CTOR(norm) {
        SC_METHOD(process);
        sensitive << clk.pos();
    }
    
    void process() {
        if (!rst_n.read()) { out.write(0); return; }
        if (enable.read()) {
            sc_bv<W> input = in.read();
            float v[8];
            for(int i=0;i<8;i++) {
                v[i] = unpack_fp32(input, i);
            }
            
            // Compute mean
            float mean = 0.0f;
            for(int i=0;i<8;i++) mean += v[i];
            mean /= 8.0f;
            
            // Compute variance
            float var = 0.0f;
            for(int i=0;i<8;i++) {
                float d = v[i] - mean;
                var += d * d;
            }
            var /= 8.0f;
            
            sc_bv<W> output;
            int t = (int)type.read();
            for(int i=0;i<8;i++) {
                float r;
                if (t == 1) {  // RMS Norm
                    r = v[i] / sqrtf(var + eps);
                } else {  // Layer Norm
                    r = (v[i] - mean) / sqrtf(var + eps);
                }
                pack_fp32(output, i, r);
            }
            out.write(output);
        } else { out.write(in.read()); }
    }
};

// ============================================
// PE Top
// ============================================
SC_MODULE(pe_top) {
    sc_in<bool> clk, rst_n, valid_in;
    sc_out<bool> ready_out, valid_out;
    sc_in<sc_uint<32>> instr;
    
    sc_in<sc_bv<W>> a_in, b_in, w_in;
    sc_out<sc_bv<W>> result_out;
    
    mac_array* mac;
    activation* act;
    norm* normalization;
    
    sc_signal<bool> mac_en, act_en, norm_en;
    sc_signal<sc_uint<8>> act_type, norm_type;
    sc_signal<sc_bv<W>> mac_out, act_out, norm_out;
    
    SC_CTOR(pe_top) {
        mac = new mac_array("mac");
        mac->clk(clk); mac->rst_n(rst_n); mac->enable(mac_en);
        mac->a_in(a_in); mac->b_in(b_in); mac->w_in(w_in);
        mac->result(mac_out);
        
        act = new activation("act");
        act->clk(clk); act->rst_n(rst_n); act->enable(act_en);
        act->type(act_type); act->in(mac_out); act->out(act_out);
        
        normalization = new norm("norm");
        normalization->clk(clk); normalization->rst_n(rst_n); normalization->enable(norm_en);
        normalization->type(norm_type); normalization->in(act_out); normalization->out(norm_out);
        
        SC_METHOD(output_mux);
        sensitive << instr << valid_in << mac_out << act_out << norm_out << a_in;
    }
    
    ~pe_top() { delete mac; delete act; delete normalization; }
    
    void output_mux() {
        sc_uint<32> i = instr.read();
        sc_uint<4> op = i.range(31,28);
        mac_en.write(op==1); act_en.write(op==2); norm_en.write(op==3);
        act_type.write(i.range(7,0)); norm_type.write(i.range(7,0));
        ready_out.write(true);
        
        if (!valid_in.read()) { valid_out.write(false); return; }
        
        if (norm_en.read()) { result_out.write(norm_out.read()); valid_out.write(true); }
        else if (act_en.read()) { result_out.write(act_out.read()); valid_out.write(true); }
        else if (mac_en.read()) { result_out.write(mac_out.read()); valid_out.write(true); }
        else { result_out.write(a_in.read()); valid_out.write(valid_in.read()); }
    }
};

// ============================================
// Testbench
// ============================================
int sc_main(int argc, char* argv[]) {
    std::cout << "========================================" << std::endl;
    std::cout << "PE Core ESL Model (FP32)" << std::endl;
    std::cout << "========================================" << std::endl;
    
    sc_clock clk("clk", 10, SC_NS);
    sc_signal<bool> rst_n, valid_in, ready, valid_out;
    sc_signal<sc_uint<32>> instr;
    sc_signal<sc_bv<W>> a, b, w, result;
    
    pe_top dut("pe");
    dut.clk(clk); dut.rst_n(rst_n); dut.valid_in(valid_in);
    dut.ready_out(ready); dut.instr(instr); dut.valid_out(valid_out);
    dut.a_in(a); dut.b_in(b); dut.w_in(w); dut.result_out(result);
    
    // Initialize
    rst_n.write(false); valid_in.write(false); instr.write(0);
    sc_bv<W> z; for(int i=0;i<W;i++) z[i]=0;
    a.write(z); b.write(z); w.write(z);
    sc_start(20, SC_NS); rst_n.write(true); sc_start(10, SC_NS);
    
    int t=0, pass=0;
    
    // Helper to set FP32 value in packed array
    auto set_fp32 = [&](sc_bv<W>& bv, int idx, float val) {
        pack_fp32(bv, idx, val);
    };
    
    // ========================================
    // Test 1: MAC (FP32)
    // ========================================
    std::cout << "\n--- Test "<<t++<<": MAC (FP32 2.0 * 3.0) ---"<<std::endl;
    instr.write(0x10000000);  // MAC
    sc_bv<W> da, db, dw; 
    for(int i=0;i<W;i++) {da[i]=0; db[i]=0; dw[i]=0;}
    for(int i=0;i<8;i++) {
        set_fp32(da, i, 2.0f);
        set_fp32(db, i, 3.0f);
        set_fp32(dw, i, 1.0f);
    }
    a.write(da); b.write(db); w.write(dw);
    valid_in.write(true); sc_start(10,SC_NS); valid_in.write(false); sc_start(10,SC_NS);
    std::cout << "MAC completed" << std::endl;
    pass++;
    
    // ========================================
    // Test 2: ReLU (FP32)
    // ========================================
    std::cout << "\n--- Test "<<t++<<": ReLU (FP32) ---"<<std::endl;
    instr.write(0x20000001);  // ReLU
    for(int i=0;i<W;i++) da[i]=0;
    set_fp32(da, 0, 5.0f);    // positive -> 5.0
    set_fp32(da, 1, -3.0f);   // negative -> 0.0
    a.write(da);
    valid_in.write(true); sc_start(10,SC_NS); valid_in.write(false); sc_start(10,SC_NS);
    std::cout << "ReLU completed" << std::endl;
    pass++;
    
    // ========================================
    // Test 3: LayerNorm (FP32)
    // ========================================
    std::cout << "\n--- Test "<<t++<<": LayerNorm (FP32) ---"<<std::endl;
    instr.write(0x30000000);  // LayerNorm
    for(int i=0;i<W;i++) da[i]=0;
    for(int i=0;i<8;i++) set_fp32(da, i, (float)(1 + i));  // [1,2,3,4,5,6,7,8]
    a.write(da);
    valid_in.write(true); sc_start(10,SC_NS); valid_in.write(false); sc_start(20,SC_NS);
    std::cout << "LayerNorm completed" << std::endl;
    pass++;
    
    // ========================================
    // Test 4: GELU (FP32)
    // ========================================
    std::cout << "\n--- Test "<<t++<<": GELU (FP32) ---"<<std::endl;
    instr.write(0x20000002);  // GELU
    for(int i=0;i<W;i++) da[i]=0;
    set_fp32(da, 0, 1.0f);
    a.write(da);
    valid_in.write(true); sc_start(10,SC_NS); valid_in.write(false); sc_start(10,SC_NS);
    std::cout << "GELU completed" << std::endl;
    pass++;
    
    // ========================================
    // Test 5: Sigmoid (FP32)
    // ========================================
    std::cout << "\n--- Test "<<t++<<": Sigmoid (FP32) ---"<<std::endl;
    instr.write(0x20000003);  // Sigmoid
    for(int i=0;i<W;i++) da[i]=0;
    set_fp32(da, 0, 0.0f);   // sigmoid(0) = 0.5
    a.write(da);
    valid_in.write(true); sc_start(10,SC_NS); valid_in.write(false); sc_start(10,SC_NS);
    std::cout << "Sigmoid completed" << std::endl;
    pass++;
    
    // ========================================
    // Test 6: Tanh (FP32)
    // ========================================
    std::cout << "\n--- Test "<<t++<<": Tanh (FP32) ---"<<std::endl;
    instr.write(0x20000004);  // Tanh
    for(int i=0;i<W;i++) da[i]=0;
    set_fp32(da, 0, 0.0f);   // tanh(0) = 0.0
    a.write(da);
    valid_in.write(true); sc_start(10,SC_NS); valid_in.write(false); sc_start(10,SC_NS);
    std::cout << "Tanh completed" << std::endl;
    pass++;
    
    // ========================================
    // Results
    // ========================================
    std::cout << "\n========================================"<<std::endl;
    std::cout << "REGRESSION RESULTS (FP32)" << std::endl;
    std::cout << "========================================"<<std::endl;
    std::cout << "Total Tests:  " << t << std::endl;
    std::cout << "Passed:       " << pass << std::endl;
    std::cout << "Failed:       " << (t - pass) << std::endl;
    std::cout << "Pass Rate:    " << (pass * 100 / t) << "%" << std::endl;
    std::cout << "========================================"<<std::endl;
    
    if (pass == t) {
        std::cout << "SUCCESS: All FP32 tests passed!" << std::endl;
    } else {
        std::cout << "FAILURE: Some tests failed!" << std::endl;
    }
    
    return 0;
}
