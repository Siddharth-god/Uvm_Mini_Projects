package gray_pkg; 
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "../tb/gray_env_config.sv"
    
    `include "../in_agent_top/gray_in_xtn.sv"
    `include "../in_agent_top/gray_in_drv.sv"
    `include "../in_agent_top/gray_in_mon.sv"
    `include "../in_agent_top/gray_in_seqr.sv"
    `include "../in_agent_top/gray_in_seqs.sv"
    `include "../in_agent_top/gray_in_agt.sv"

    `include "../out_agent_top/gray_out_mon.sv"
    `include "../out_agent_top/gray_out_agt.sv"

    `include "../tb/gray_sb.sv"
    `include "../tb/gray_env.sv"

    `include "../test/test.sv"
endpackage 