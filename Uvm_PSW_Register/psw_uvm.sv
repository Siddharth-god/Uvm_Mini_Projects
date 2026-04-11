
package psw_pkg; 

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

endpackage 

import uvm_pkg::*; 
`include "uvm_macros.svh"
import psw_pkg::*;


module psw (
    input  wire        clk,
    input  wire        add_op,
    input  wire [7:0]  acc,
    input  wire [7:0]  operand,
    output reg  [7:0]  psw
);

reg [8:0] result;
reg [4:0] lower_sum;

always @(posedge clk) begin
    if (add_op) begin
        
        // Extended addition to capture carry
        result = {1'b0, acc} + {1'b0, operand};

		lower_sum = {1'b0,acc[3:0]} + {1'b0, operand[3:0]};

		// Carry flag
        psw[7] = result[8];

		// AC flag 
        psw[6] = lower_sum[4];

        // Overflow flag
		psw[2] = (acc[7] == operand[7]) && (acc[7] != result[7]);

        // Parity flag
        psw[0] = ~(^result[7:0]);

    end
end

property carry_flag; 
	@(posedge clk)
		result[8] |-> psw[7]; 
endproperty 

property overflow_flag;
	@(posedge clk)
		lower_sum[4] |-> psw[6];
endproperty 

property parity_flag;
	@(posedge clk)
		~^result[7:0] |-> psw[0];
endproperty 

CARRY : assert property (carry_flag)
			$display("PASS : --------------------------CARRY--------------------------");
		else 
			$display("FAIL : --------------------------CARRY--------------------------");
			

OVERFLOW : assert property (overflow_flag)
			$display("PASS : --------------------------OVERFLOW--------------------------");
		else 
			$display("FAIL : --------------------------OVERFLOW--------------------------");

PARITY : assert property (parity_flag)
			$display("PASS : --------------------------PARITY--------------------------");
		else 
			$display("FAIL : --------------------------PARITY--------------------------");
			
endmodule


//---------------------------------------------- ALU Interface ----------------------------------------------

interface psw_if(input bit clk); 
    
    bit        add_op;
    bit [7:0]  acc;
    bit [7:0]  operand;
    bit [7:0]  psw;

	clocking psw_drv_cb@(posedge clk); 
		output  add_op;
		output  acc;
		output  operand;
	endclocking 	

	clocking psw_in_mon_cb@(posedge clk); 
		default input #0; 
		input  add_op;
		input  acc;
		input  operand;
	endclocking 	

	clocking psw_out_mon_cb@(posedge clk); 
		default input #0; 
		input psw;
	endclocking 	

	modport psw_drv_md(clocking psw_drv_cb); 
	modport psw_in_mon_md(clocking psw_in_mon_cb); 
	modport psw_out_mon_md(clocking psw_out_mon_cb); 

endinterface 

//---------------------------------------------- psw_xtn ----------------------------------------------
class psw_xtn extends uvm_sequence_item; 
    `uvm_object_utils(psw_xtn)
	`NEW_OBJ

    rand    bit        add_op;
    rand    bit [7:0]  acc;
    rand    bit [7:0]  operand;
            bit [7:0]  psw;

	function void do_print(uvm_printer printer);
		printer.print_field("add_op",	add_op,	    1,  UVM_DEC);
		printer.print_field("acc",		acc,	    8,  UVM_DEC);
		printer.print_field("operand",  operand,    8,  UVM_DEC);
		printer.print_field("psw",	    psw,	    8,  UVM_DEC);
	endfunction 
	
endclass  


// Env config 
class env_config extends uvm_object; 
    `uvm_object_utils(env_config)
	`NEW_OBJ

    uvm_active_passive_enum in_agent_active; 
    uvm_active_passive_enum out_agent_active; 

    virtual psw_if vif; 
    int has_in_agent; 
    int has_out_agent; 
endclass 

//---------------------------------------------- In Seq ----------------------------------------------
class psw_seq_base extends uvm_sequence#(psw_xtn); 
    `uvm_object_utils(psw_seq_base)
    `NEW_OBJ
endclass

// Corner case (forced parity check) 
class psw_corner_seq extends psw_seq_base;
	`uvm_object_utils(psw_corner_seq)
    `NEW_OBJ

	task body(); 
		req = psw_xtn::type_id::create("req"); 
		$display("-------------------- Corner case Sequence Started --------------------");
		repeat(1) begin 
			start_item(req); 
			assert(req.randomize() with {
				add_op == 1; 
				acc == 8'b1111_1111; 
				operand == 8'b1111_1111;  // pushing to extreme boundry 
			});
			finish_item(req);	

			// overflow 
			start_item(req); 
			assert(req.randomize() with {
				add_op == 1; 
				acc == 127; 
				operand == 1;  // pushing to extreme boundry 
			});
			finish_item(req);	

			// sign overflow 
			$display("Signed Overflow");
			start_item(req); 
			assert(req.randomize() with {
				add_op == 1; 
				acc == 128; 
				operand == 128;  // pushing to extreme boundry 
			});
			finish_item(req);	
		end
	endtask 
endclass 


// seq random burst 
class alu_rand_burst_seq extends psw_seq_base;
	`uvm_object_utils(alu_rand_burst_seq)
    `NEW_OBJ

	task body(); 
		req = psw_xtn::type_id::create("req"); 
		$display("-------------------- Burst Sequence Started --------------------");
		repeat(20) begin 
			start_item(req); 
			assert(req.randomize() with {
				add_op == 1; 
				acc inside {[1:255]}; 
				operand inside {[1:255]}; 
			});
			finish_item(req);	
		end
	endtask 
endclass 


// Negative sequence 
class psw_negative_seq extends psw_seq_base;

	`uvm_object_utils(psw_negative_seq)
	`NEW_OBJ

	task body();
		req = psw_xtn::type_id::create("req");
		$display("-------------------- Negative Sequence --------------------");

		repeat(5) begin
			start_item(req);
			assert(req.randomize() with {
			add_op == 0; // Control signals define negative cases. (1 = ON & 0 = OFF) so control is off = negative
			acc inside {[0:255]};
			operand inside {[0:255]};
			});
			finish_item(req);
		end

	endtask
endclass

//---------------------------------------------- In Seqr ----------------------------------------------
class psw_in_seqr extends uvm_sequencer#(psw_xtn); 
    `uvm_component_utils(psw_in_seqr)
    `NEW_COMP
endclass  


//---------------------------------------------- In Driver ----------------------------------------------
class psw_in_drv extends uvm_driver #(psw_xtn); 
    `uvm_component_utils(psw_in_drv)
    `NEW_COMP

	virtual psw_if vif; 
    env_config env_cfg; 

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
		if(!uvm_config_db #(env_config)::get(this,"","env_config",env_cfg))
			`uvm_fatal(get_type_name(),"Failed to get env_cfg in IN DRV from TEST")
    endfunction 

    function void connect_phase(uvm_phase phase);
        vif = env_cfg.vif; 
    endfunction 

	task run_phase(uvm_phase phase);
		forever begin
			seq_item_port.get_next_item(req); 
			send_to_dut(req);
			seq_item_port.item_done();  
		end
	endtask 

	task send_to_dut(psw_xtn xtnh); 
		@(vif.psw_drv_cb) begin 
			vif.psw_drv_cb.add_op 	<= req.add_op; 
			vif.psw_drv_cb.acc 		<= req.acc; 
			vif.psw_drv_cb.operand 		<= req.operand; 
		end
	endtask

endclass  

//---------------------------------------------- In Monitor ----------------------------------------------
class psw_in_mon extends uvm_monitor; 
    `uvm_component_utils(psw_in_mon)
    `NEW_COMP

	virtual psw_if vif; 
    env_config env_cfg; 
	uvm_analysis_port #(psw_xtn) in_mon_port; 
	psw_xtn xtnh; 

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
		in_mon_port = new("in_mon_port",this);
		if(!uvm_config_db #(env_config)::get(this,"","env_config",env_cfg))
			`uvm_fatal(get_type_name(),"Failed to get env_cfg in IN MONITOR from TEST")

		xtnh = psw_xtn::type_id::create("xtnh");
    endfunction 

    function void connect_phase(uvm_phase phase);
        vif = env_cfg.vif; 
    endfunction 

	task run_phase(uvm_phase phase);
		forever begin
			$display("This is input monitor");
			collect_in_data(); 
			$display("\nData in Sampled at time: #%0d\n",$time); 
			xtnh.print(); 
		end
	endtask 

	task collect_in_data(); 
		@(vif.psw_in_mon_cb) begin 
			xtnh.add_op 	= vif.psw_in_mon_cb.add_op;
			xtnh.acc 		= vif.psw_in_mon_cb.acc;
			xtnh.operand 	= vif.psw_in_mon_cb.operand;

			in_mon_port.write(xtnh);
		end
	endtask

endclass  

//---------------------------------------------- Out Monitor ----------------------------------------------
class psw_out_mon extends uvm_monitor; 
    `uvm_component_utils(psw_out_mon)
    `NEW_COMP

	virtual psw_if vif; 
    env_config env_cfg; 
	uvm_analysis_port #(psw_xtn) out_mon_port;
	psw_xtn xtnh;  

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
		out_mon_port = new("out_mon_port",this);
		if(!uvm_config_db #(env_config)::get(this,"","env_config",env_cfg))
			`uvm_fatal(get_type_name(),"Failed to get env_cfg in OUT MONITOR from TEST")

		xtnh = psw_xtn::type_id::create("xtnh");
    endfunction 

    function void connect_phase(uvm_phase phase);
        vif = env_cfg.vif; 
    endfunction 

	task run_phase(uvm_phase phase);
		forever begin
			$display("This is output monitor");
			collect_out_data(); 
			$display("\nData out Sampled at time: #%0d\n",$time); 
			xtnh.print(); 
		end
	endtask 

	task collect_out_data(); 
		@(vif.psw_out_mon_cb) begin 
			xtnh.psw = vif.psw_out_mon_cb.psw;

			out_mon_port.write(xtnh);
		end
	endtask
endclass  

//---------------------------------------------- AGENT IN----------------------------------------------
class psw_in_agent extends uvm_agent; 
    `uvm_component_utils(psw_in_agent)
    `NEW_COMP

    psw_in_mon psw_in_monh; 
    psw_in_drv psw_in_drvh; 
    psw_in_seqr psw_in_seqrh; 
    env_config env_cfg;

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 

        if(!uvm_config_db #(env_config)::get(this,"","env_config",env_cfg))
			`uvm_fatal(get_type_name(),"Failed to get env_cfg in IN AGENT from TEST")

        psw_in_monh = psw_in_mon::type_id::create("psw_in_monh",this);
        if(env_cfg.in_agent_active == UVM_ACTIVE) begin 
            psw_in_drvh = psw_in_drv::type_id::create("psw_in_drvh",this);
            psw_in_seqrh = psw_in_seqr::type_id::create("psw_in_seqrh",this);
        end
    endfunction 

	function void connect_phase(uvm_phase phase); 
		psw_in_drvh.seq_item_port.connect(psw_in_seqrh.seq_item_export);
	endfunction 
endclass  

//---------------------------------------------- AGENT OUT ----------------------------------------------
class psw_out_agent extends uvm_agent; 
    `uvm_component_utils(psw_out_agent)
    `NEW_COMP

	psw_out_mon psw_out_monh;
    psw_in_drv psw_in_drvh; 
    psw_in_seqr psw_in_seqrh; 
    env_config env_cfg;

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
        if(!uvm_config_db #(env_config)::get(this,"","env_config",env_cfg))
			`uvm_fatal(get_type_name(),"Failed to get env_cfg in OUT AGENR from TEST")

        psw_out_monh = psw_out_mon::type_id::create("psw_out_monh",this);

        if(env_cfg.out_agent_active == UVM_ACTIVE) begin // This is passive 
            psw_in_drvh = psw_in_drv::type_id::create("psw_in_drvh",this);
            psw_in_seqrh = psw_in_seqr::type_id::create("psw_in_seqrh",this);
        end
    endfunction 
endclass    

//---------------------------------------------- SB ----------------------------------------------

class psw_sb extends uvm_scoreboard; 
	`uvm_component_utils(psw_sb)

	psw_xtn in_xtn; 
	psw_xtn out_xtn; 
	psw_xtn input_cov; 
	psw_xtn output_cov;

	bit [7:0] exp_psw;

	uvm_tlm_analysis_fifo #(psw_xtn) fifo_in; 
	uvm_tlm_analysis_fifo #(psw_xtn) fifo_out; 

	covergroup psw_cg;

				option.per_instance = 1;

				add_op_cp : coverpoint input_cov.add_op
				{
					bins off = {0};
					bins on  = {1};
				}

				acc_cp : coverpoint input_cov.acc
				{
					bins zero  = {0};
					bins mid   = {[1:126]};
					bins max   = {255};
					bins sign  = {128};
				}

				operand_cp : coverpoint input_cov.operand
				{
					bins zero  = {0};
					bins mid   = {[1:126]};
					bins max   = {255};
					bins sign  = {128};
				}

				carry_cp : coverpoint output_cov.psw[7]
				{
					bins carry0 = {0};
					bins carry1 = {1};
				}

				ac_cp : coverpoint output_cov.psw[6]
				{
					bins ac0 = {0};
					bins ac1 = {1};
				}

				overflow_cp : coverpoint output_cov.psw[2]
				{
					bins ov0 = {0};
					bins ov1 = {1};
				}

				parity_cp : coverpoint output_cov.psw[0]
				{
					bins even = {1};
					bins odd  = {0};
				}

				carry_overflow_cross : cross carry_cp, overflow_cp;

				parity_add_cross : cross parity_cp, add_op_cp;
		endgroup

	function new(string name, uvm_component parent);
		super.new(name,parent);
		psw_cg = new(); 
	endfunction

	function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
		fifo_out = new("fifo_out");
		fifo_in  = new("fifo_in");
	endfunction

	function void ref_model(psw_xtn xtnh); 
			
	bit [8:0] result;
	bit [4:0] lower_sum;

		if (in_xtn.add_op) begin
			
			// Extended addition to capture carry
			result = {1'b0, in_xtn.acc} + {1'b0, in_xtn.operand};

			lower_sum = {1'b0, in_xtn.acc[3:0]} + {1'b0, in_xtn.operand[3:0]};

			// Carry flag
			exp_psw[7] = result[8];

			// AC flag 
			exp_psw[6] = lower_sum[4];

			// Overflow flag
			exp_psw[2] = (in_xtn.acc[7] == in_xtn.operand[7]) && (in_xtn.acc[7] != result[7]);

			// Parity flag
			exp_psw[0] = ~(^result[7:0]);

		end
	endfunction

	task run_phase(uvm_phase phase); 

		forever begin 
			fork
				fifo_in.get(in_xtn);
				fifo_out.get(out_xtn);
			join

			ref_model(in_xtn);	
			input_cov = in_xtn; 
			output_cov = out_xtn; 
			psw_cg.sample();
				
			if(in_xtn.add_op) begin 

				if(exp_psw == out_xtn.psw)  begin 
					$display("Time = %0d",$time);
					`uvm_info(
						get_type_name(),
						$sformatf("SB : \n\n[Data Match Successful] : \nexp_psw[%b] == dut_psw[%b]\n",
									exp_psw,out_xtn.psw),
						UVM_LOW)


					// Carry Flag
					if(exp_psw[7] == 1)  begin 
						`uvm_info(
							get_type_name(),
							"SB : \n[Carry Generated]\n",
							UVM_LOW)
					end
					
					// Overflow Flag 
					if(exp_psw[6] == 1)  begin 
						`uvm_info(
							get_type_name(),
							"SB : \n[AC Flag]\n",
							UVM_LOW)
					end
					
					// Parity flag
					if(exp_psw[2] == 1)  begin 
						`uvm_info(
							get_type_name(),
							"SB : \n[Overflow Happened]\n",
							UVM_LOW)
					end

					// Parity flag
					if(exp_psw[0] == 1)  begin 
						`uvm_info(
							get_type_name(),
							"SB : \n[Parity Check]\n",
							UVM_LOW)
					end
				end
				else begin 
					$display("Time = %0d",$time);
					`uvm_error(
						get_type_name(),
						$sformatf("SB : \n\n[Data Mismatch] : \nexp_psw[%b] == dut_psw[%b]\n",
									exp_psw,out_xtn.psw))
				end
			end
			else 
				`uvm_warning(get_type_name(),"No operation is happening!")
		end
	endtask

endclass 

//---------------------------------------------- ENV ----------------------------------------------
class psw_env extends uvm_env; 
    `uvm_component_utils(psw_env)
    `NEW_COMP

    psw_in_agent psw_in_agenth; 
    psw_out_agent psw_out_agenth; 
	psw_sb psw_sbh; 

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 

        psw_in_agenth = psw_in_agent::type_id::create("psw_in_agenth",this); 
        psw_out_agenth = psw_out_agent::type_id::create("psw_out_agenth",this); 
        psw_sbh = psw_sb::type_id::create("psw_sbh",this); 
    endfunction 

	function void connect_phase(uvm_phase phase); 
		psw_out_agenth.psw_out_monh.out_mon_port.connect(psw_sbh.fifo_out.analysis_export);
		psw_in_agenth.psw_in_monh.in_mon_port.connect(psw_sbh.fifo_in.analysis_export);
	endfunction 
endclass  

//---------------------------------------------- TEST ----------------------------------------------
class psw_test_base extends uvm_test; 
    `uvm_component_utils(psw_test_base)
    `NEW_COMP

    psw_env psw_envh; 
    env_config env_cfg; 
    int has_in_agent = 1; 
    int has_out_agent = 1; 

    psw_corner_seq psw_corner_seqh;
	alu_rand_burst_seq alu_rand_burst_seqh;
	psw_negative_seq psw_negative_seqh;

    function void do_config();
        if(has_in_agent) begin 
            env_cfg.in_agent_active = UVM_ACTIVE;
        end

        if(has_out_agent) begin
            env_cfg.out_agent_active = UVM_PASSIVE;
        end

        env_cfg.has_in_agent = has_in_agent; 
        env_cfg.has_out_agent = has_out_agent; 
    endfunction 
	

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 

        env_cfg = env_config::type_id::create("env_cfg"); 

        if(!uvm_config_db #(virtual psw_if)::get(this,"","psw_if",env_cfg.vif))
            `uvm_fatal(get_type_name(),"Failed to get vif from TOP in TEST env_cfg")

        do_config(); 

        uvm_config_db #(env_config)::set(this,"*","env_config",env_cfg);

        psw_envh = psw_env::type_id::create("psw_envh",this);
    endfunction 

	function void end_of_elaboration_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction 

	task run_phase(uvm_phase phase);
		psw_corner_seqh = psw_corner_seq::type_id::create("psw_corner_seqh");
		alu_rand_burst_seqh = alu_rand_burst_seq::type_id::create("alu_rand_burst_seqh");
		psw_negative_seqh = psw_negative_seq::type_id::create("psw_negative_seqh");

        phase.raise_objection(this);
        psw_corner_seqh.start(psw_envh.psw_in_agenth.psw_in_seqrh);
		alu_rand_burst_seqh.start(psw_envh.psw_in_agenth.psw_in_seqrh);
		psw_negative_seqh.start(psw_envh.psw_in_agenth.psw_in_seqrh);
        phase.drop_objection(this);
	endtask 
endclass    

//----------------------------------------------- TOP ----------------------------------------------
module psw_uvm; 

	bit clk = 0; 

	always #5 clk = ~clk; 
	
	psw_if IF(clk); 

	psw DUT(
	    .clk(clk),
        .add_op(IF.add_op),
        .acc(IF.acc),
        .operand(IF.operand),
        .psw(IF.psw)
	);

    initial begin 
		uvm_config_db #(virtual psw_if)::set(null,"*","psw_if",IF);
        run_test("psw_test_base");
    end
endmodule 