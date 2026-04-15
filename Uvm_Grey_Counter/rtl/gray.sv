// ================= RTL =================
module gray_counter(
    input clk,rst,
    output reg [3:0] gray_count
);
reg [3:0] bin_count;

always @(posedge clk)
begin
    if(rst)
        begin
            gray_count = 4'b0000;
            bin_count  = 4'b0000;
            $display("reset in DUT = %0d ################## at time = %0d",rst,$time);
        end
    else
        begin
            bin_count = bin_count + 1;
            gray_count = {bin_count[3],
                        bin_count[3]^bin_count[2],
                        bin_count[2]^bin_count[1],
                        bin_count[1]^bin_count[0]}; 
            $display("bin count in DUT = %0d ################## at time = %0d",bin_count,$time);
            $display("gray count in DUT = %0d ################## at time = %0d",gray_count,$time);
        end
end
endmodule 

// property p_reset; 
//         @(posedge clk) 
//             rst |=> (gray_count == 0);
//     endproperty 

//     // SVA samples in the preponed region 
//     property p_bin_incr; 
//         @(posedge clk) 
//             disable iff(rst)
//                 !rst |=> $past(bin_count) + 1;
//     endproperty 

//         property p_gray_count;
//         @(posedge clk)
//         disable iff(rst)
//             !rst |=> gray_count == {bin_count[3],
//                            bin_count[3]^bin_count[2],
//                            bin_count[2]^bin_count[1],
//                            bin_count[1]^bin_count[0]};
//     endproperty
 

//     RESET : assert property(p_reset)
//                 $display("PASS :-------- RESET -------- | Time = %0t",$time);
//             else 
//                 $display("FAIL :-------- RESET -------- | Time = %0t",$time);

//     BIN_INCR : assert property(p_bin_incr)
//                 $display("PASS :-------- BIN_INCR -------- bin_count=%0d | Time = %0t",bin_count,$time);
//             else 
//                 $display("FAIL :-------- BIN_INCR -------- bin_count=%0d | Time = %0t",bin_count,$time);

//     GRAY_CNT : assert property(p_gray_count)
//                 $display("PASS :-------- GREY_CNT -------- | Time = %0t",$time);
//             else 
//                 $display("FAIL :-------- GREY_CNT -------- | Time = %0t",$time);
// endmodule
