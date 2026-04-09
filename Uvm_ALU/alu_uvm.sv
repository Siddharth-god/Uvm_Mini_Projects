

package alu_pkg; 
	parameter WIDTH = 32; 

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
import alu_pkg::*;


module alu #(
    parameter WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic [WIDTH-1:0]      a,
    input  logic [WIDTH-1:0]      b,
    input  logic [2:0]            op,

    output logic [WIDTH-1:0]      result,
    output logic                  zero
);

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        result <= '0;
    else begin
        case(op)

            3'b000: result <= a + b;      // ADD
            3'b001: result <= a - b;      // SUB
            3'b010: result <= a & b;      // AND
            3'b011: result <= a | b;      // OR
            3'b100: result <= a ^ b;      // XOR
            3'b101: result <= (a < b);    // SLT

            default: result <= '0;

        endcase
    end
end

assign zero = (result == 0);

endmodule

//---------------------------------------------- ALU Interface ----------------------------------------------

interface alu_if #(WIDTH)(input bit clk); 
    bit                  rst_n;
    bit [WIDTH-1:0]      a;
    bit [WIDTH-1:0]      b;
    bit [2:0]            op;
    bit [WIDTH-1:0]      result;
    bit                  zero;

	clocking alu_drv_cb@(posedge clk); 
		output  rst_n;
		output  a;
		output  b;
		output  op;
	endclocking 	

	clocking alu_in_mon_cb@(posedge clk); 
		input  rst_n;
		input  a;
		input  b;
		input  op;
	endclocking 	

	clocking alu_out_mon_cb@(posedge clk); 
		input  result;
		input  zero;
	endclocking 	

	modport alu_in_drv_md(clocking alu_drv_cb); 
	modport alu_in_mon_md(clocking alu_in_mon_cb); 
	modport alu_out_mon_md(clocking alu_out_mon_cb); 
endinterface 

//---------------------------------------------- alu_xtn ----------------------------------------------
class alu_xtn extends uvm_sequence_item; 
    `uvm_object_utils(alu_xtn)
	`NEW_OBJ

	rand bit             rst_n;
    rand bit [WIDTH-1:0] a;
    rand bit [WIDTH-1:0] b;
    rand bit [2:0]            op;
    bit [WIDTH-1:0]      result;
    bit                  zero;

	function void do_print(uvm_printer printer);
		printer.print_field("rst_n",	rst_n,	1,		UVM_DEC);
		printer.print_field("a",		a,	  	WIDTH,	UVM_DEC);
		printer.print_field("b",		b,		WIDTH,	UVM_DEC);
		printer.print_field("result",	result,	WIDTH,	UVM_DEC);
		printer.print_field("zero",		zero,	1,		UVM_DEC);
		printer.print_field("op",		op,		3,		UVM_DEC);
	endfunction 
	
endclass  

//---------------------------------------------- In Seq ----------------------------------------------
class alu_in_seq_base extends uvm_sequence#(alu_xtn); 
    `uvm_object_utils(alu_in_seq_base)
    `NEW_OBJ
endclass

// seq reset 
class alu_rst_seq extends alu_in_seq_base;
	`uvm_object_utils(alu_rst_seq)
    `NEW_OBJ

	task body(); 
		req = alu_xtn::type_id::create("req"); 
		$display("-------------------- Reset Sequence Started --------------------");
		repeat(3) begin 
			start_item(req); 
			assert(req.randomize() with {
				rst_n == 0; a == 0; b ==0; 
			})
			finish_item(req);	
		end
	endtask 
endclass 


// seq random burst 
class alu_rand_burst_seq extends alu_in_seq_base;
	`uvm_object_utils(alu_rand_burst_seq)
    `NEW_OBJ

	task body(); 
		req = alu_xtn::type_id::create("req"); 
		$display("-------------------- Burst Sequence Started --------------------");
		repeat(10) begin 
			start_item(req); 
			assert(req.randomize() with {
				rst_n == 1; 
				a inside {[1:255]}; 
				b inside {[1:255]}; 
				op inside {[0:5]};
			})
			finish_item(req);	
		end
	endtask 
endclass 


// corner case (op out of case) 
class alu_invalid_opcode_seq extends alu_in_seq_base;
	`uvm_object_utils(alu_invalid_opcode_seq)
    `NEW_OBJ

	task body(); 
		req = alu_xtn::type_id::create("req"); 
		$display("-------------------- Corner case Sequence Started --------------------");
		repeat(10) begin 
			start_item(req); 
			assert(req.randomize() with {
				rst_n == 1; 
				a inside {[1:255]}; 
				b inside {[1:255]}; 
				op inside {[6:7]}; // As 6,7 does not have any operation (default will take over)
			})
			finish_item(req);	
		end
	endtask 
endclass 

// wraparound : Wraparound happens when the result of an arithmetic operation exceeds the range that the bit-width can represent. Since the register only stores WIDTH bits, any extra bits are discarded.
/*
// Overflow : 
If an operation produces a value larger than that, the upper carry bit is lost and the value wraps back to the beginning of the range.

Example:

a = 1111 (15)
b = 0001 (1)

ADD
---------
10000

But the register can only store 4 bits:

0000

So the result wraps from 15 back to 0.

// Underflow :

a = 0
b = 1
SUB

Binary subtraction:

0000 - 0001

This underflows and becomes

1111

which is the maximum value.

So wraparound verifies that the ALU behaves correctly when overflow or underflow occurs.
*/ 
class alu_wrap_seq extends alu_in_seq_base;
    `uvm_object_utils(alu_wrap_seq)
    `NEW_OBJ

    task body();
        req = alu_xtn::type_id::create("req");

        $display("-------------------- Wraparound Sequence --------------------");

        repeat(10) begin
            start_item(req);

            assert(req.randomize() with {
                rst_n == 1;
                a == '1;      // max value => 32'b1111...111 wraps back to 0 (so zero flag = 1)
                b == 1;
                op inside {0,1}; // ADD or SUB
            });

            finish_item(req);
        end
    endtask
endclass

// overlap : Overlap refers to cases where the operands cancel each other out or overlap in value, causing the result to collapse to a special value (often zero).
/*
// Subtraction of equal numbers
a = 25
b = 25

25 - 25 = 0
// XOR of identical numbers
a = X
b = X

X ^ X = 0
*/
class alu_overlap_seq extends alu_in_seq_base;
    `uvm_object_utils(alu_overlap_seq)
    `NEW_OBJ

    task body();
        req = alu_xtn::type_id::create("req");

        $display("-------------------- Overlap Sequence --------------------");

        repeat(10) begin
            start_item(req);

            assert(req.randomize() with {
                rst_n == 1;
                a inside {[1:255]};
                b == a;
                op inside {1,4}; // SUB or XOR
            });

            finish_item(req);
        end
    endtask
endclass




//---------------------------------------------- In Seqr ----------------------------------------------
class alu_in_seqr extends uvm_sequencer#(alu_xtn); 
    `uvm_component_utils(alu_in_seqr)
    `NEW_COMP
endclass  


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

//---------------------------------------------- AGENT OUT ----------------------------------------------
class alu_out_agent extends uvm_agent; 
    `uvm_component_utils(alu_out_agent)
    `NEW_COMP

	alu_out_mon alu_out_monh;

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 
        alu_out_monh = alu_out_mon::type_id::create("alu_monh",this);
    endfunction 
endclass    

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

//---------------------------------------------- TEST ----------------------------------------------
class alu_test_base extends uvm_test; 
    `uvm_component_utils(alu_test_base)
    `NEW_COMP

    alu_env alu_envh; 
	alu_rst_seq alu_rst_seqh; 
	alu_rand_burst_seq alu_rand_burst_seqh;
	alu_invalid_opcode_seq alu_invalid_opcode_seqh;
	alu_wrap_seq alu_wrap_seqh;
	alu_overlap_seq alu_overlap_seqh;

    function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 

        alu_envh = alu_env::type_id::create("alu_envh",this);
    endfunction 

	function void end_of_elaboration_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction 

	task run_phase(uvm_phase phase);
			alu_rst_seqh = alu_rst_seq::type_id::create("alu_rst_seqh");
			alu_rand_burst_seqh = alu_rand_burst_seq::type_id::create("alu_rand_burst_seqh");
			alu_invalid_opcode_seqh = alu_invalid_opcode_seq::type_id::create("alu_invalid_opcode_seqh");
			alu_wrap_seqh = alu_wrap_seq::type_id::create("alu_wrap_seqh");
			alu_overlap_seqh = alu_overlap_seq::type_id::create("alu_overlap_seqh");


			phase.raise_objection(this);
			alu_rst_seqh.start(alu_envh.alu_in_agenth.alu_in_seqrh);
			//alu_rand_burst_seqh.start(alu_envh.alu_in_agenth.alu_in_seqrh); 
			//alu_invalid_opcode_seqh.start(alu_envh.alu_in_agenth.alu_in_seqrh);
			alu_wrap_seqh.start(alu_envh.alu_in_agenth.alu_in_seqrh);
			alu_overlap_seqh.start(alu_envh.alu_in_agenth.alu_in_seqrh);
			phase.drop_objection(this);
	endtask 
endclass    

//----------------------------------------------- TOP ----------------------------------------------
module alu_uvm; 

	bit clk = 0; 

	always #5 clk = ~clk; 

	parameter WIDTH = 32; 
	
	alu_if #(.WIDTH(WIDTH)) IF(clk); 

	alu #(.WIDTH(WIDTH)) 
		DUT(
		.clk(clk),
		.rst_n(IF.rst_n),
		.a(IF.a),
		.b(IF.b),
		.op(IF.op),
		.result(IF.result),
		.zero(IF.zero)
	);

    initial begin 
		uvm_config_db #(virtual alu_if #(WIDTH))::set(null,"*","alu_if",IF);
        run_test("alu_test_base");
    end
endmodule 