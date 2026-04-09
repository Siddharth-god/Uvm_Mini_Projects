
//---------------------------------------------- ENV ----------------------------------------------
class alu_env extends uvm_env; 
    `uvm_component_utils(alu_env)
    `NEW_COMP

    alu_in_agent alu_in_agenth; 
    alu_out_agent alu_out_agenth; 
	alu_sb alu_sbh; 

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 

        alu_in_agenth = alu_in_agent::type_id::create("alu_in_agenth",this); 
        alu_out_agenth = alu_out_agent::type_id::create("alu_out_agenth",this); 
        alu_sbh = alu_sb::type_id::create("alu_sbh",this); 
    endfunction 

	function void connect_phase(uvm_phase phase); 
		alu_out_agenth.alu_out_monh.out_mon_port.connect(alu_sbh.fifo_out.analysis_export);
		alu_in_agenth.alu_in_monh.in_mon_port.connect(alu_sbh.fifo_in.analysis_export);
	endfunction 
endclass  
