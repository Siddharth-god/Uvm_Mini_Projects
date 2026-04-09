
package alu_pkg; 
	parameter WIDTH = 32; 

    import uvm_pkg::*; 
    `include "uvm_macros.svh"

//------------------------------------DEFAULT MACROS--------------------------------------
`define NEW_COMP	\
	function new(string name = "", uvm_component parent);	\
		super.new(name,parent);	\
	endfunction

`define NEW_OBJ	\
	function new(string name = "");	\
		super.new(name);	\
	endfunction
//-----------------------------------------------------------------------------------------

    // In agent top 
    `include "../in_agent_top/alu_xtn.sv"
    `include "../in_agent_top/alu_in_drv.sv"
    `include "../in_agent_top/alu_in_mon.sv"
    `include "../in_agent_top/alu_in_seqr.sv"
    `include "../in_agent_top/alu_in_seqs.sv"
    `include "../in_agent_top/alu_in_agent.sv"

    // Out agent top 
    `include "../out_agent_top/alu_out_mon.sv"
    `include "../out_agent_top/alu_out_agent.sv"

    // tb 
    `include "../tb/alu_env_config.sv"
    `include "../tb/alu_sb.sv"
    `include "../tb/alu_env.sv"

    // test
    `include "../test/alu_test.sv"

endpackage 