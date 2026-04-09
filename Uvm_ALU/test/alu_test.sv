
//---------------------------------------------- TEST ----------------------------------------------
class alu_test_base extends uvm_test; 
    `uvm_component_utils(alu_test_base)
    `NEW_COMP

    alu_env alu_envh; 


    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 

        alu_envh = alu_env::type_id::create("alu_envh",this);
    endfunction 

	function void end_of_elaboration_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction 

endclass    

//------------------------------------------------ Burst ------------------------------------------------
class alu_rand_burst_test extends alu_test_base; 
    `uvm_component_utils(alu_rand_burst_test)
    `NEW_COMP

    alu_rst_seq alu_rst_seqh; 
	alu_rand_burst_seq alu_rand_burst_seqh;

	task run_phase(uvm_phase phase);
			alu_rst_seqh = alu_rst_seq::type_id::create("alu_rst_seqh");
			alu_rand_burst_seqh = alu_rand_burst_seq::type_id::create("alu_rand_burst_seqh");

			phase.raise_objection(this);
			alu_rst_seqh.start(alu_envh.alu_in_agenth.alu_in_seqrh);
			alu_rand_burst_seqh.start(alu_envh.alu_in_agenth.alu_in_seqrh); 
			phase.drop_objection(this);
	endtask 
endclass    


//------------------------------------------------ Invalid Opcode ------------------------------------------------
class alu_invalid_opcode_test extends alu_test_base; 
    `uvm_component_utils(alu_invalid_opcode_test)
    `NEW_COMP

    alu_rst_seq alu_rst_seqh; 
	alu_invalid_opcode_seq alu_invalid_opcode_seqh;

	task run_phase(uvm_phase phase);
			alu_rst_seqh = alu_rst_seq::type_id::create("alu_rst_seqh");
			alu_invalid_opcode_seqh = alu_invalid_opcode_seq::type_id::create("alu_invalid_opcode_seqh");

			phase.raise_objection(this);
			alu_rst_seqh.start(alu_envh.alu_in_agenth.alu_in_seqrh);
			alu_invalid_opcode_seqh.start(alu_envh.alu_in_agenth.alu_in_seqrh);
			phase.drop_objection(this);
	endtask 
endclass    


//------------------------------------------------ Wraparound ------------------------------------------------
class alu_wrap_test extends alu_test_base; 
    `uvm_component_utils(alu_wrap_test)
    `NEW_COMP

    alu_rst_seq alu_rst_seqh; 
	alu_wrap_seq alu_wrap_seqh;

	task run_phase(uvm_phase phase);
			alu_rst_seqh = alu_rst_seq::type_id::create("alu_rst_seqh");
			alu_wrap_seqh = alu_wrap_seq::type_id::create("alu_wrap_seqh");

			phase.raise_objection(this);
			alu_rst_seqh.start(alu_envh.alu_in_agenth.alu_in_seqrh);
			alu_wrap_seqh.start(alu_envh.alu_in_agenth.alu_in_seqrh);
			phase.drop_objection(this);
	endtask 
endclass    


//------------------------------------------------ Overlap ------------------------------------------------
class alu_overlap_test extends alu_test_base; 
    `uvm_component_utils(alu_overlap_test)
    `NEW_COMP

    alu_rst_seq alu_rst_seqh; 
	alu_overlap_seq alu_overlap_seqh;

	task run_phase(uvm_phase phase);
			alu_rst_seqh = alu_rst_seq::type_id::create("alu_rst_seqh");
			alu_overlap_seqh = alu_overlap_seq::type_id::create("alu_overlap_seqh");

			phase.raise_objection(this);
			alu_rst_seqh.start(alu_envh.alu_in_agenth.alu_in_seqrh);
			alu_overlap_seqh.start(alu_envh.alu_in_agenth.alu_in_seqrh);
			phase.drop_objection(this);
	endtask 
endclass    