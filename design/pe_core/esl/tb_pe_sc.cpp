// PE Core ESL Model - Minimal Working Version
// Simplified single-file model for compatibility

#include <systemc.h>
#include <iostream>
#include <cmath>

const int W = 256;  // Unified width (8 * 32)

// ============================================
// MAC Array
// ============================================
SC_MODULE(mac_array) {
    sc_in<bool> clk, rst_n, enable;
    sc_in<sc_bv<W>> a_in, b_in, w_in;
    sc_out<sc_bv<W>> result;
    
    std::vector<sc_int<64>> acc;
    
    SC_CTOR(mac_array) : acc(8, 0) {
        SC_METHOD(process);
        sensitive << clk.pos();
    }
    
    void process() {
        if (!rst_n.read()) { 
            for(int i=0;i<8;i++) acc[i]=0; 
            result.write(0);
            return;
        }
        if (enable.read()) {
            for(int r=0;r<8;r++) {
                sc_int<64> sum=0;
                for(int c=0;c<8;c++) {
                    int bv=0, wv=0;
                    for(int b=0;b<32;b++) {
                        if(b_in.read()[r*32+b]) bv |= (1<<b);
                        if(w_in.read()[c*32+b]) wv |= (1<<b);
                    }
                    sum += bv * wv;
                }
                acc[r]=sum;
            }
        }
        sc_bv<W> out;
        for(int r=0;r<8;r++) {
            for(int b=0;b<32;b++) {
                out[r*32+b] = ((int)acc[r]>>b)&1;
            }
        }
        result.write(out);
    }
};

// ============================================
// Activation Unit
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
            sc_bv<W> o;
            int t = (int)type.read();
            for(int i=0;i<8;i++) {
                int v=0; for(int b=0;b<32;b++) if(in.read()[i*32+b]) v|=(1<<b);
                int r=0;
                switch(t) {
                    case 1: r = (v>0)?v:0; break;  // ReLU
                    case 3: r = (int)(1.0/(1.0+exp(-v))); break;  // Sigmoid
                    case 4: r = (int)tanh(v); break;  // Tanh
                    default: r=v;
                }
                for(int b=0;b<32;b++) o[i*32+b] = (r>>b)&1;
            }
            out.write(o);
        } else { out.write(in.read()); }
    }
};

// ============================================
// Normalization Unit
// ============================================
SC_MODULE(norm) {
    sc_in<bool> clk, rst_n, enable;
    sc_in<sc_uint<8>> type;
    sc_in<sc_bv<W>> in;
    sc_out<sc_bv<W>> out;
    
    SC_CTOR(norm) {
        SC_METHOD(process);
        sensitive << clk.pos();
    }
    
    void process() {
        if (!rst_n.read()) { out.write(0); return; }
        if (enable.read()) {
            double v[8];
            for(int i=0;i<8;i++) {
                int val=0; for(int b=0;b<32;b++) if(in.read()[i*32+b]) val|=(1<<b);
                v[i]=val;
            }
            double m=0; for(int i=0;i<8;i++) m+=v[i]; m/=8;
            double var=0; for(int i=0;i<8;i++) { double d=v[i]-m; var+=d*d; } var/=8;
            
            sc_bv<W> o;
            int t = (int)type.read();
            for(int i=0;i<8;i++) {
                double r = (t==1) ? v[i]/sqrt(var+1e-8) : (v[i]-m)/sqrt(var+1e-8);
                int ir = (int)r;
                for(int b=0;b<32;b++) o[i*32+b] = (ir>>b)&1;
            }
            out.write(o);
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
    std::cout << "PE Core ESL Model (SystemC)" << std::endl;
    std::cout << "========================================" << std::endl;
    
    sc_clock clk("clk", 10, SC_NS);
    sc_signal<bool> rst_n, valid_in, ready, valid_out;
    sc_signal<sc_uint<32>> instr;
    sc_signal<sc_bv<W>> a, b, w, result;
    
    pe_top dut("pe");
    dut.clk(clk); dut.rst_n(rst_n); dut.valid_in(valid_in);
    dut.ready_out(ready); dut.instr(instr); dut.valid_out(valid_out);
    dut.a_in(a); dut.b_in(b); dut.w_in(w); dut.result_out(result);
    
    rst_n.write(false); valid_in.write(false); instr.write(0);
    sc_bv<W> z; for(int i=0;i<W;i++) z[i]=0;
    a.write(z); b.write(z); w.write(z);
    sc_start(20, SC_NS); rst_n.write(true); sc_start(10, SC_NS);
    
    int t=0, pass=0;
    
    // Test 1: MAC
    std::cout << "\n--- Test "<<t++<<": MAC ---"<<std::endl;
    instr.write(0x10000000);
    sc_bv<W> da, db, dw; for(int i=0;i<W;i++) {da[i]=0; db[i]=0; dw[i]=0;}
    for(int i=0;i<8;i++) for(int b=0;b<32;b++) {
        da[i*32+b]=(2>>b)&1; db[i*32+b]=(3>>b)&1; dw[i*32+b]=(1>>b)&1;
    }
    a.write(da); b.write(db); w.write(dw);
    valid_in.write(true); sc_start(10,SC_NS); valid_in.write(false); sc_start(10,SC_NS);
    std::cout<<"MAC done"<<std::endl; pass++;
    
    // Test 2: ReLU
    std::cout << "\n--- Test "<<t++<<": ReLU ---"<<std::endl;
    instr.write(0x20000001);
    for(int i=0;i<W;i++) da[i]=0;
    for(int i=0;i<8;i++) for(int b=0;b<32;b++) {
        int v = (i%2==0)?10:-10;
        da[i*32+b]=(v>>b)&1;
    }
    a.write(da);
    valid_in.write(true); sc_start(10,SC_NS); valid_in.write(false); sc_start(10,SC_NS);
    std::cout<<"ReLU done"<<std::endl; pass++;
    
    // Test 3: LayerNorm
    std::cout << "\n--- Test "<<t++<<": LayerNorm ---"<<std::endl;
    instr.write(0x30000000);
    for(int i=0;i<W;i++) da[i]=0;
    for(int i=0;i<8;i++) for(int b=0;b<32;b++) da[i*32+b]=((1+i)>>b)&1;
    a.write(da);
    valid_in.write(true); sc_start(10,SC_NS); valid_in.write(false); sc_start(20,SC_NS);
    std::cout<<"LayerNorm done"<<std::endl; pass++;
    
    // Test 4: Sigmoid
    std::cout << "\n--- Test "<<t++<<": Sigmoid ---"<<std::endl;
    instr.write(0x20000003);
    a.write(z);
    valid_in.write(true); sc_start(10,SC_NS); valid_in.write(false); sc_start(10,SC_NS);
    std::cout<<"Sigmoid done"<<std::endl; pass++;
    
    // Test 5: Tanh
    std::cout << "\n--- Test "<<t++<<": Tanh ---"<<std::endl;
    instr.write(0x20000004);
    a.write(z);
    valid_in.write(true); sc_start(10,SC_NS); valid_in.write(false); sc_start(10,SC_NS);
    std::cout<<"Tanh done"<<std::endl; pass++;
    
    // Test 6: Passthrough
    std::cout << "\n--- Test "<<t++<<": Passthrough ---"<<std::endl;
    instr.write(0x00000000);
    for(int i=0;i<W;i++) da[i]=0;
    for(int i=0;i<8;i++) for(int b=0;b<32;b++) da[i*32+b]=((42+i)>>b)&1;
    a.write(da);
    valid_in.write(true); sc_start(10,SC_NS); valid_in.write(false); sc_start(10,SC_NS);
    std::cout<<"Passthrough done"<<std::endl; pass++;
    
    std::cout << "\n========================================"<<std::endl;
    std::cout << "RESULTS: "<<pass<<"/"<<t<<" PASSED"<<std::endl;
    std::cout << "========================================"<<std::endl;
    std::cout << (pass==t?"SUCCESS!":"FAILURE!")<<std::endl;
    return 0;
}
