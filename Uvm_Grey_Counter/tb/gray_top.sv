
// ================= TOP =================
module gray_top;

    import uvm_pkg::*;
    import gray_pkg::*;

    bit clk;
    always #5 clk = ~clk;

    gray_if IF(clk);

    gray_counter DUT(
        .clk(clk),
        .rst(IF.rst),
        .gray_count(IF.gray_count)
    );

    bind DUT gray_assertions A(
        .clk(clk),
        .rst(rst),
        .gray_count(gray_count),
        .bin_count(DUT.bin_count)
    );

    initial begin
        uvm_config_db#(virtual gray_if)::set(null,"*","vif",IF);
        run_test("test_neg");
    end

endmodule
