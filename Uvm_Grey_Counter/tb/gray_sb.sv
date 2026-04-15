
// ================= SCOREBOARD =================
class sb extends uvm_scoreboard;

    `uvm_component_utils(sb)


    uvm_tlm_analysis_fifo #(xtn) fifo_in;
    uvm_tlm_analysis_fifo #(xtn) fifo_out;

    xtn in_xtn, out_xtn;

    // coverage
    xtn in_cov, out_cov; 
    // Debug 
    int exp_q[$];
    int dut_q[$];
    int exp_rst[$];
    int dut_rst[$];

    bit [3:0] gray_count;

    covergroup gray_cg; 
        rst : coverpoint in_cov.rst{
            bins r0 = {0};
        }

        gray_cnt : coverpoint out_cov.gray_count{
            bins all_val[] = {[0:15]};
        }

        X : cross gray_cnt, rst;
    endgroup 


    function new(string name, uvm_component parent);
        super.new(name,parent);
        fifo_in  = new("fifo_in",this);
        fifo_out = new("fifo_out",this);
        gray_cg = new();
    endfunction

    task run_phase(uvm_phase phase);
        bit [3:0] ref_bin;

        forever begin
            fork 
                fifo_in.get(in_xtn);
                fifo_out.get(out_xtn);
            join

            in_cov = in_xtn; 
            out_cov = out_xtn; 
            gray_cg.sample(); 

            $display("SB :: Got input transactions : rst = %0d",in_xtn.rst);
            $display("SB :: Got output transactions : gray_count = %0d",out_xtn.gray_count);

            if(in_xtn.rst) begin
                ref_bin = 0;
                gray_count = 0;
            end
            else begin
                ref_bin = ref_bin + 1;
                gray_count = {ref_bin[3],
                              ref_bin[3]^ref_bin[2],
                              ref_bin[2]^ref_bin[1],
                              ref_bin[1]^ref_bin[0]};
            end
            exp_q.push_back(gray_count); 
            exp_rst.push_back(in_xtn.rst); 

            dut_q.push_back(out_xtn.gray_count);
            dut_rst.push_back(out_xtn.rst);

            $display("Stored values :\nexp_rst=%p\ndut_rst=%p\n",exp_rst,dut_rst);
            $display("Stored values :\nexp_vals=%p\ndut_vals=%p\n",exp_q,dut_q);


 
                if(out_xtn.gray_count == gray_count) 
                    `uvm_info("SB",
                            $sformatf("[Data Match Successful] :\nexp_grey_count = %0d\ndut_grey_count = %0d\n\n",
                                        gray_count,out_xtn.gray_count),
                            UVM_LOW)
                else
                    `uvm_error("SB",$sformatf("[Data Mismatch] :\nexp_grey_count = %0d\ndut_grey_count = %0d\n\n",
                                        gray_count,out_xtn.gray_count))
            end
    endtask

endclass
