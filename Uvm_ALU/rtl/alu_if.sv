
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