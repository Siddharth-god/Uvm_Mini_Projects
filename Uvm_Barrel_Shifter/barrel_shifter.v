module barrel_shifter(
    input [7:0] in,
    input [2:0] sel,
    output reg [7:0] out
);
    always@(in,sel)
        case(sel)   
            3'b000 : out = in;
            3'b001 : out = {in[0],in[7:1]};           
            3'b010 : out = {in[1:0],in[7:2]};           
            3'b011 : out = {in[2:0],in[7:3]};            
            3'b100 : out = {in[3:0],in[7:4]};           
            3'b101 : out = {in[4:0],in[7:5]};          
            3'b110 : out = {in[5:0],in[7:6]}; 
            3'b111 : out = {in[6:0],in[7]};      
            default : out = in;     
        endcase 
endmodule 
/*
`timescale 1ns/1ps

module barrel_shifter;

    reg  [7:0] in;
    reg  [2:0] sel;
    wire [7:0] out;

    // DUT
    barrel_shift dut (
        .in(in),
        .sel(sel),
        .out(out)
    );

    // reference model (golden)
    function [7:0] rotate_right;
        input [7:0] data;
        input [2:0] shift;
        begin
            rotate_right = (data >> shift) | (data << (8 - shift));
        end
    endfunction

    integer i;

    initial begin
        $display("Starting test...");

        // random tests
        for (i = 0; i < 20; i = i + 1) begin
            in  = $random;
            sel = $random % 8;

            #1; // wait for combinational logic

            if (out !== rotate_right(in, sel)) begin
                $display("FAIL | in=%b sel=%0d out=%b expected=%b",
                          in, sel, out, rotate_right(in, sel));
            end
            else begin
                $display("PASS | in=%b sel=%0d out=%b",
                          in, sel, out);
            end
        end

        $display("Test completed.");
        $finish;
    end

endmodule
    */