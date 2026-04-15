
// ================= TRANSACTION =================
class xtn extends uvm_sequence_item;

    `uvm_object_utils(xtn)

    rand bit rst;
    bit [3:0] gray_count;

    function new(string name="xtn");
        super.new(name);
    endfunction

    function void do_print(uvm_printer printer);
        printer.print_field("rst", rst, 1, UVM_DEC);
        printer.print_field("gray_count", gray_count, 4, UVM_DEC);
    endfunction

endclass