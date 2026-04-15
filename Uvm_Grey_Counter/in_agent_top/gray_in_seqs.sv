
// ================= SEQUENCES =================
class seq_base extends uvm_sequence #(xtn);
    `uvm_object_utils(seq_base)
    function new(string name="seq_base");
        super.new(name);
    endfunction
endclass

class seq_pos extends seq_base;
    `uvm_object_utils(seq_pos)
    function new(string name="seq_pos");
        super.new(name);
    endfunction

    task body();
        req = xtn::type_id::create("req");
		$display("-------------------- Positive case Sequence Started --------------------");
        repeat(50) begin
            start_item(req);
            assert(req.randomize() with { rst==0; }); // reset 0 ---> Executes normal behaviour 
            finish_item(req);
        end
    endtask
endclass

class seq_neg extends seq_base;
    `uvm_object_utils(seq_neg)
    function new(string name="seq_neg");
        super.new(name);
    endfunction

    task body();
        req = xtn::type_id::create("req");
		$display("-------------------- Negative case Sequence Started --------------------");
        repeat(20) begin
            start_item(req);
            assert(req.randomize() with { rst inside {0,1}; }); // Randomely resets counter, checks whether design behaves correctly even if the reset occrs randomely. the neg sequence introduece invalid states of design so when we give random reset we are checking if design goes into invalid state and the reset 0 won't give valid output also so neg
            finish_item(req);
        end
    endtask
endclass

class seq_corner extends seq_base;
    `uvm_object_utils(seq_corner)
    function new(string name="seq_cormer");
        super.new(name);
    endfunction

    task body();
        req = xtn::type_id::create("req");
		$display("-------------------- Corner case Sequence Started --------------------");
        repeat(50) begin
            start_item(req);
            assert(req.randomize() with { rst==0; }); // Burst sequence with instant reset to check how design behaves when we give reset after continuous valid operations. to check if design resets properly after multiple valid ops 
            finish_item(req);
        end

        start_item(req);
        assert(req.randomize() with { rst==1; });
        finish_item(req);
    endtask
endclass
