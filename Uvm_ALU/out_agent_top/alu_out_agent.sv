//-------------------------------------------- AGENT OUT ----------------------------------------------
class alu_out_agent extends uvm_agent; 
    `uvm_component_utils(alu_out_agent)
    `NEW_COMP

	alu_out_mon alu_out_monh;

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
        alu_out_monh = alu_out_mon::type_id::create("alu_monh",this);
    endfunction 
endclass    
