
//---------------------------------------------- AGENT IN----------------------------------------------
class alu_in_agent extends uvm_agent; 
    `uvm_component_utils(alu_in_agent)
    `NEW_COMP

    alu_in_mon alu_in_monh; 
    alu_in_drv alu_in_drvh; 
    alu_in_seqr alu_in_seqrh; 

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 

        alu_in_monh = alu_in_mon::type_id::create("alu_monh",this);
        alu_in_drvh = alu_in_drv::type_id::create("alu_drvh",this);
        alu_in_seqrh = alu_in_seqr::type_id::create("alu_seqrh",this);
        
    endfunction 

	function void connect_phase(uvm_phase phase); 
		alu_in_drvh.seq_item_port.connect(alu_in_seqrh.seq_item_export);
	endfunction 
endclass  
