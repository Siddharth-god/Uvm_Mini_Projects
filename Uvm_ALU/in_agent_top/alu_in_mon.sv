
//---------------------------------------------- In Monitor ----------------------------------------------
class alu_in_mon extends uvm_monitor; 
    `uvm_component_utils(alu_in_mon)
    `NEW_COMP

	virtual alu_if #(WIDTH) vif; 
	uvm_analysis_port #(alu_xtn) in_mon_port; 
	alu_xtn xtnh; 

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
		in_mon_port = new("in_mon_port",this);
		if(!uvm_config_db #(virtual alu_if #(WIDTH))::get(this,"","alu_if",vif))
			`uvm_fatal(get_type_name(),"Failed to get vif in IN MONITOR from TOP")

		xtnh = alu_xtn::type_id::create("xtnh");
    endfunction 

	task run_phase(uvm_phase phase);
		forever begin
			collect_in_data(); 
			$display("\nData in Sampled at time: #%0d\n",$time); 
			xtnh.print(); 
		end
	endtask 

	task collect_in_data(); 
		@(vif.alu_in_mon_cb) begin 
			xtnh.rst_n 	= vif.alu_in_mon_cb.rst_n;
			xtnh.a 		= vif.alu_in_mon_cb.a;
			xtnh.b 		= vif.alu_in_mon_cb.b;
			xtnh.op 	= vif.alu_in_mon_cb.op;

			in_mon_port.write(xtnh);
		end
	endtask

endclass  