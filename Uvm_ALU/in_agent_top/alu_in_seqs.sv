
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


