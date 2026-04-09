
//---------------------------------------------- SB ----------------------------------------------

class alu_sb extends uvm_scoreboard; 
	`uvm_component_utils(alu_sb)
    `NEW_COMP

	alu_xtn in_xtn; 
	alu_xtn out_xtn; 

	int exp_result; 
	int exp_zero; 

	uvm_tlm_analysis_fifo #(alu_xtn) fifo_in; 
	uvm_tlm_analysis_fifo #(alu_xtn) fifo_out; 

	function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
		fifo_out = new("fifo_out");
		fifo_in  = new("fifo_in");
	endfunction

	function void ref_model(alu_xtn xtnh); 
		
		if(!in_xtn.rst_n)
			exp_result <= '0;
		else begin
			case(in_xtn.op)
				3'b000: exp_result <= in_xtn.a + in_xtn.b;      // ADD
				3'b001: exp_result <= in_xtn.a - in_xtn.b;      // SUB
				3'b010: exp_result <= in_xtn.a & in_xtn.b;      // AND
				3'b011: exp_result <= in_xtn.a | in_xtn.b;      // OR
				3'b100: exp_result <= in_xtn.a ^ in_xtn.b;      // XOR
				3'b101: exp_result <= (in_xtn.a < in_xtn.b);    // SLT
				default: exp_result <= '0;
			endcase
		end
		exp_zero = (exp_result == 0);
	endfunction

	task run_phase(uvm_phase phase); 

		fork
			forever begin 
				fifo_in.get(in_xtn);
				ref_model(in_xtn);
			end

			forever begin
				fifo_out.get(out_xtn);
				
				if(exp_result == out_xtn.result && exp_zero == out_xtn.zero)  begin 
					$display("Time = %0d",$time);
					`uvm_info(
						get_type_name(),
						$sformatf("SB : \n\n[Data Match Successful] : \nexp_result[%0d] == dut_result[%0d]\nexp_zero[%0d] == dut_zero[%0d]\n",
									exp_result, out_xtn.result, exp_zero, out_xtn.zero),
						UVM_LOW)
				end
				else begin 
					$display("Time = %0d",$time);
					`uvm_error(
						get_type_name(),
						$sformatf("SB : \n\n[Data Mismatch] : \nexp_result[%0d] != dut_result[%0d]\nexp_zero[%0d] != dut_zero[%0d]\n",
									exp_result, out_xtn.result, exp_zero, out_xtn.zero))
				end

			end
		join
	endtask

endclass 