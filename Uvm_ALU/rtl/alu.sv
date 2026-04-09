
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