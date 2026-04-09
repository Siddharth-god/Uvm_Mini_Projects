
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