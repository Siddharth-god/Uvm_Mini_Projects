
//----------------------------------------------- TOP ----------------------------------------------
module alu_top; 

	import alu_pkg::*;
	import uvm_pkg::*;
	
	bit clk = 0; 

	always #5 clk = ~clk; 

	// parameter WIDTH = 32; 
	
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
        run_test();
    end
endmodule 