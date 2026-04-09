
//---------------------------------------------- In Driver ----------------------------------------------
class alu_in_drv extends uvm_driver #(alu_xtn); 
    `uvm_component_utils(alu_in_drv)
    `NEW_COMP

	virtual alu_if #(WIDTH) vif; 

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
		if(!uvm_config_db #(virtual alu_if #(WIDTH))::get(this,"","alu_if",vif))
			`uvm_fatal(get_type_name(),"Failed to get vif in IN DRV from TOP")
    endfunction 

	task run_phase(uvm_phase phase);
		forever begin
			seq_item_port.get_next_item(req); 
			send_to_dut(req);
			seq_item_port.item_done();  
		end
	endtask 

	task send_to_dut(alu_xtn xtnh); 
		$display("xxxxxxxxxxxxxxxxx--------------- Inside Send to DUT ---------------xxxxxxxxxxxxxxxxx");
		@(vif.alu_drv_cb) begin 
			vif.alu_drv_cb.rst_n 	<= req.rst_n; 
			vif.alu_drv_cb.a 		<= req.a; 
			vif.alu_drv_cb.b 		<= req.b; 
			vif.alu_drv_cb.op 		<= req.op;
		end
	endtask

endclass  