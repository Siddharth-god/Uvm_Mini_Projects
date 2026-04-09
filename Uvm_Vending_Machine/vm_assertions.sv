module vm_assertions(
    input  logic clk,
    input  logic rst,
    input  logic [1:0] in,
    input  logic  x,
    input  logic  y,
    input  logic [2:0] ps
);
    
    localparam idle = 3'b000;	
    localparam s1   = 3'b001;
    localparam s2   = 3'b010;
    localparam s3   = 3'b011;
    localparam s4   = 3'b100;
    
    //------------------Reset check------------------
    property reset_check;
        @(posedge clk) 
            rst |=> ps == idle; 
    endproperty : reset_check

    // State check---------------------------------------------------------------------------------------------------------------

    //------------------state idle------------------
    property state_idle_to_s1;
        @(posedge clk)
        disable iff(rst)
            (ps == idle && in == 2'b10)
                |=> ps == s1;
    endproperty : state_idle_to_s1

    property state_idle_to_idle;
        @(posedge clk)
        disable iff(rst)
            (ps == idle && (in == 2'b00 || in == 2'b01))
                |=> ps == idle;
    endproperty : state_idle_to_idle

    property state_idle_to_s2;
        @(posedge clk)
        disable iff(rst)
            (ps == idle && in == 2'b11)
                |=> ps == s2;
    endproperty : state_idle_to_s2

    //------------------state s1------------------
    property state_s1_to_s2;
        @(posedge clk)
        disable iff(rst)
            (ps == s1 && in == 2'b10)
                |=> ps == s2;
    endproperty : state_s1_to_s2

    property state_s1_to_s1;
        @(posedge clk)
        disable iff(rst)
            (ps == s1 && (in == 2'b00 || in == 2'b01) )
                |=> ps == s1;
    endproperty : state_s1_to_s1

    property state_s1_to_s3;
        @(posedge clk)
        disable iff(rst)
            (ps == s1 && in == 2'b11)
                |=> ps == s3;
    endproperty : state_s1_to_s3

    //------------------state s2------------------

    property state_s2_to_s3;
        @(posedge clk)
        disable iff(rst)
            (ps == s2 && in == 2'b10)
                |=> ps == s3;
    endproperty : state_s2_to_s3

    property state_s2_to_s4;
        @(posedge clk)
        disable iff(rst)
            (ps == s2 && in == 2'b11)
                |=> ps == s4;
    endproperty : state_s2_to_s4

    property state_s2_to_s2;
        @(posedge clk)
        disable iff(rst)
            (ps == s2 && (in == 2'b00 || in == 2'b01) )
                |=> ps == s2;
    endproperty : state_s2_to_s2

    //------------------state s3 & s4------------------
    property state_s3_to_idle;
        @(posedge clk)
            disable iff(rst)
            (ps == s3)
            |=> ps == idle ;
    endproperty : state_s3_to_idle

    property state_s4_to_idle;
        @(posedge clk)
            disable iff(rst)
                (ps == s4)
                    |=> ps == idle;
    endproperty : state_s4_to_idle

    //------------------Outputs-------------------

    property zero_op_check;
        @(posedge clk) 
            ((  (ps == idle) || 
                (ps == s1) ||  
                (ps == s2)) |-> (!x && !y)
            );
    endproperty : zero_op_check;


    property op_check_x;
        @(posedge clk) 
            (ps == s3) |-> x;
    endproperty : op_check_x;

    property op_check_x_y;
        @(posedge clk) 
            ( 
            (ps == s4) |-> (x && y)
            );
    endproperty : op_check_x_y;

    //------------------Sequence check-------------------

    // property seq_check_101;
    //     @(posedge clk)
    //         disable iff(rst)
    //             out |-> ($past(in,3) && !$past(in,2) && $past(in));
    // endproperty


    //-----------------Assert_Properties----------------------------------------------------------------------------------------

    // Reset check
    RESET : assert property (reset_check)
                $display("PASS : RESET at time=%0t",$time);
            else 
                $display("FAIL : RESET at time=%0t",$time);

    // State idle
    STATE_idle_TO_s1 : assert property (state_idle_to_s1)
                        $display("PASS : STATE_idle_TO_s1 at time=%0t",$time);
                    else 
                        $display("FAIL : STATE_idle_TO_s1 at time=%0t",$time);

    STATE_idle_to_idle : assert property (state_idle_to_idle)
                        $display("PASS : STATE_idle_to_idle at time=%0t",$time);
                    else 
                        $display("FAIL : STATE_idle_to_idle at time=%0t",$time);
    
    STATE_idle_TO_s2 : assert property (state_idle_to_s2)
                        $display("PASS : STATE_idle_TO_s2 at time=%0t",$time);
                    else 
                        $display("FAIL : STATE_idle_TO_s2 at time=%0t",$time);

    // State s1   
    STATE_s1_TO_s2 : assert property (state_s1_to_s2)
                        $display("PASS : STATE_s1_TO_s2 at time=%0t",$time);
                    else 
                        $display("FAIL : STATE_s1_TO_s2 at time=%0t",$time);

    STATE_S1_TO_S1 : assert property (state_s1_to_s1)
                        $display("PASS : STATE_S1_TO_S1 at time=%0t",$time);
                    else 
                        $display("FAIL : STATE_S1_TO_S1 at time=%0t",$time);
    
    STATE_s1_TO_s3 : assert property (state_s1_to_s3)
                        $display("PASS : STATE_s1_TO_s3 at time=%0t",$time);
                    else 
                        $display("FAIL : STATE_s1_TO_s3 at time=%0t",$time);
    
    // State s2
    STATE_s2_TO_s3 : assert property (state_s2_to_s3)
                        $display("PASS : STATE_s2_TO_s3 at time=%0t",$time);
                    else 
                        $display("FAIL : STATE_s2_TO_s3 at time=%0t",$time);
    
    STATE_s2_TO_s4 : assert property (state_s2_to_s4)
                        $display("PASS : STATE_s2_TO_s4 at time=%0t",$time);
                    else 
                        $display("FAIL : STATE_s2_TO_s4 at time=%0t",$time);
        
     STATE_s2_TO_s2 : assert property (state_s2_to_s2)
                        $display("PASS : STATE_s2_TO_s2 at time=%0t",$time);
                    else 
                        $display("FAIL : STATE_s2_TO_s2 at time=%0t",$time);

    // State s3
    STATE_s3_TO_idle : assert property (state_s3_to_idle)
                        $display("PASS : STATE_s3_TO_idle at time=%0t",$time);
                    else 
                        $display("FAIL : STATE_s3_TO_idle at time=%0t",$time);
    
    STATE_s4_TO_idle : assert property (state_s4_to_idle)
                        $display("PASS : STATE_s4_TO_idle at time=%0t",$time);
                    else 
                        $display("FAIL : STATE_s4_TO_idle at time=%0t",$time);

    // Output Check
    ZERO_OP_CHECK : assert property (zero_op_check)
                        $display("PASS : ZERO_OP_CHECK at time=%0t",$time);
                    else 
                        $display("FAIL : ZERO_OP_CHECK at time=%0t",$time);
    
    OP_CHECK_X : assert property (op_check_x)
                    $display("PASS : OP_CHECK at time=%0t",$time);
                else 
                    $display("FAIL : OP_CHECK at time=%0t",$time);

    OP_CHECK_XY : assert property (op_check_x_y)
                    $display("PASS : OP_CHECK_XY at time=%0t",$time);
                else 
                    $display("FAIL : OP_CHECK_XY at time=%0t",$time);
endmodule