
//---------------------------------------------- Out Monitor ----------------------------------------------
class alu_out_mon extends uvm_monitor; 
    `uvm_component_utils(alu_out_mon)
    `NEW_COMP

	virtual alu_if #(WIDTH) vif; 
	uvm_analysis_port #(alu_xtn) out_mon_port;
	alu_xtn xtnh;  

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
		out_mon_port = new("out_mon_port",this);
		if(!uvm_config_db #(virtual alu_if #(WIDTH))::get(this,"","alu_if",vif))
			`uvm_fatal(get_type_name(),"Failed to get vif in OUT MONITOR from TOP")

		xtnh = alu_xtn::type_id::create("xtnh");
    endfunction 

	task run_phase(uvm_phase phase);
		forever begin
			collect_out_data(); 
			$display("\nData out Sampled at time: #%0d\n",$time); 
			xtnh.print(); 
		end
	endtask 

	task collect_out_data(); 
		@(vif.alu_out_mon_cb) begin 
			xtnh.result = vif.alu_out_mon_cb.result;
			xtnh.zero 	= vif.alu_out_mon_cb.zero;

			out_mon_port.write(xtnh);
		end
	endtask
endclass  
