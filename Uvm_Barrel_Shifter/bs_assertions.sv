module bs_assertions(  // Anothe way is to use select as clock --> That needs check for every single select -> This will cover everything at once. 
    in,
    sel,
    out
);
    input [7:0] in;
    input [2:0] sel;
    input [7:0] out; 

    always @(*) begin
        #0; // why #0 ---------> Wait until all current updates (NBA + combinational propagation) are done” So flow becomes: input changes → DUT computes → THEN assertion checks ✔️ else we get failures. Because assertioins runs immediately.

        assert (out == ((in >> sel) | (in << (8 - sel))))
            $display("PASS : RIGHT SHIFT --- time=%0t",$time);
        else 
            $error("FAIL : RIGHT SHIFT --- time=%0t",$time);
    end
    
    always @(*) begin 
        #0;
        if(sel == 0) begin 
            assert(out == in) 
                $display("PASS : NO SHIFT --- time=%0t",$time);
            else 
                $error("FAIL : NO SHIFT --- time=%0t",$time);
        end
    end

    always @(*) begin 
        #0;
        if(sel == 8) begin 
            assert(out == in) 
                $display("PASS : OUT == IN --- time=%0t",$time);
            else 
                $error("FAIL : OUT == IN --- time=%0t",$time);
        end
    end

    always @(*) begin 
        #0;
        assert($countones(out) == $countones(in)) 
            $display("PASS : SAME NO OF ONES --- time=%0t",$time);
        else 
            $error("FAIL : SAME NO OF ONES --- time=%0t",$time);
    end

endmodule 