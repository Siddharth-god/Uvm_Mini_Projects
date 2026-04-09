

import uvm_pkg::*;
`include "uvm_macros.svh"

//------------------------------------DEFAULT MACROS--------------------------------------
`define NEW_COMP	\
	function new(string name = "", uvm_component parent);	\
		super.new(name,parent);	\
	endfunction

//******** NEW Object
`define NEW_OBJ	\
	function new(string name = "");	\
		super.new(name);	\
	endfunction
//----------------------------------------------------------------------------------------

module vening_machine #(parameter 
    idle = 3'b000,	
    s1   = 3'b001,
    s2   = 3'b010,
    s3   = 3'b011,
    s4   = 3'b100
)(
    input clk, rst,
    input [1:0] in,
    output x, y
);

reg [2:0] ps, ns;

// State register
always @(posedge clk) begin
    if (rst)
        ps <= idle;
    else
        ps <= ns;
end

// Next state logic
always @(*) begin
    case(ps)
        idle: begin
            if (in == 2'b10) ns = s1;
            else if (in == 2'b11) ns = s2;
            else ns = ps;
        end

        s1: begin
            if (in == 2'b10) ns = s2;
            else if (in == 2'b11) ns = s3;
            else ns = ps;
        end

        s2: begin
            if (in == 2'b10) ns = s3;
            else if (in == 2'b11) ns = s4;
            else ns = ps;
        end

        s3: ns = idle;
        s4: ns = idle;

        default: ns = idle;
    endcase
end

// Output logic (Moore)
assign x = (ps == s3) || (ps == s4);
assign y = (ps == s4);
    
endmodule

// Mealy Output logic 
// assign x = (ps == s3 && in) so it should have input as well bcoz "mealy" depends on both input and current state. 

// Interface -------------------------------------------------------------------


interface vm_if(input bit clk);
    logic rst;
	logic [1:0]in;
	logic x,y;

    clocking vm_drv_cb@(posedge clk);
        output rst;
        output in;
    endclocking

    clocking vm_mon_cb@(posedge clk);
        default input #0;
        input rst; // I can directly get these signals from monitor so i can use them in sb.
        input in;
        input x;
        input y;
    endclocking

    modport VM_DRV_MP(clocking vm_drv_cb);
    modport VM_MON_MP(clocking vm_mon_cb);

endinterface 


// Config -------------------------------------------------------------------

class g_cfg extends uvm_object;
    `uvm_object_utils(g_cfg)
    `NEW_OBJ

    virtual vm_if vif;
endclass 

// Trans -------------------------------------------------------------------
class vm_xtn extends uvm_sequence_item; 
    `uvm_object_utils(vm_xtn)
    `NEW_OBJ

    rand bit rst;
	rand bit [1:0]in;
	bit x;
    bit y;

    virtual function void do_print(uvm_printer printer);
        printer.print_field("in",in,2,UVM_DEC);
        printer.print_field("rst",rst,1,UVM_DEC);
        printer.print_field("x",x,1,UVM_DEC);
        printer.print_field("y",y,1,UVM_DEC);
    endfunction 
endclass 

// Seq -------------------------------------------------------------------
class vm_seq extends uvm_sequence #(vm_xtn); 
    `uvm_object_utils(vm_seq)
    `NEW_OBJ

endclass 

// RESET
class vm_seq_rst extends vm_seq;
    `uvm_object_utils(vm_seq_rst)
    `NEW_OBJ

    task body();
        repeat(2) begin 
            req = vm_xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {rst == 1;});
            finish_item(req);
        end
    endtask
endclass 

// INPUT COINS
class vm_seq_coin extends vm_seq;
    `uvm_object_utils(vm_seq_coin)
    `NEW_OBJ

    task body();
        repeat(50) begin 
            req = vm_xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize());
            finish_item(req);
        end
    endtask
endclass 

// MIXED COINS 
class vm_seq_12r extends vm_seq;
    `uvm_object_utils(vm_seq_12r)
    `NEW_OBJ

    task body();
        repeat(10) begin 
            req = vm_xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                rst == 0;
                in dist {2'b10 := 40, 2'b11 := 60};
        });
            finish_item(req);
        end
    endtask
endclass

// s3 TARGETTING
class vm_seq_1r extends vm_seq;
    `uvm_object_utils(vm_seq_1r)
    `NEW_OBJ

    task body();
        repeat(10) begin 
            req = vm_xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {in == 2'b10 && rst == 0;});
            finish_item(req);
        end
    endtask
endclass 

// S4 TARGETTING 
class vm_seq_2r extends vm_seq;
    `uvm_object_utils(vm_seq_2r)
    `NEW_OBJ

    task body();
        repeat(10) begin 
            req = vm_xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {in == 2'b11 && rst == 0;});
            finish_item(req);
        end
    endtask
endclass 

// TARGETTING s1 => s3 
class vm_seq_s1_s3 extends vm_seq;
    `uvm_object_utils(vm_seq_s1_s3)
    `NEW_OBJ

    task body();
        repeat(10) begin 
            req = vm_xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                rst == 0;
                in dist {2'b10 := 70, 2'b11 := 30};
            });
            finish_item(req);
        end
    endtask
endclass

// Seqr -------------------------------------------------------------------
class vm_seqr extends uvm_sequencer #(vm_xtn); 
    `uvm_component_utils(vm_seqr)
    `NEW_COMP
endclass 


// Driver -------------------------------------------------------------------
class vm_drv extends uvm_driver #(vm_xtn); 
    `uvm_component_utils(vm_drv)
    `NEW_COMP

    virtual vm_if vif;
    g_cfg g_cfgh;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(g_cfg)::get(this,"","g_cfg",g_cfgh))
            `uvm_fatal(get_full_name(),"Cannot get() g_cfg from TEST in DRV")
    endfunction 

    function void connect_phase(uvm_phase phase);
        vif = g_cfgh.vif;
    endfunction

    task run_phase(uvm_phase phase);
        forever begin 
            seq_item_port.get_next_item(req);
            
            // If print used here, Driver prints when transaction is fetched - NOT when it actually hits DUT
            @(vif.vm_drv_cb) begin 
                vif.vm_drv_cb.rst <= req.rst;
                vif.vm_drv_cb.in <= req.in;
            end
            seq_item_port.item_done();
        end
    endtask 
endclass 


// Mon -------------------------------------------------------------------
class vm_mon extends uvm_monitor; 
    `uvm_component_utils(vm_mon)
    `NEW_COMP

    uvm_analysis_port #(vm_xtn) mon_port;
    virtual vm_if vif;
    g_cfg g_cfgh;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_port = new("mon_port",this);

        if(!uvm_config_db #(g_cfg)::get(this,"","g_cfg",g_cfgh))
            `uvm_fatal(get_full_name(),"Cannot get() g_cfg from TEST in MON")
    endfunction 

    function void connect_phase(uvm_phase phase);
        vif = g_cfgh.vif;
    endfunction

    task run_phase(uvm_phase phase);
        vm_xtn xtnh;

        forever begin 
            repeat(2) 
                @(vif.vm_mon_cb) begin 
                    xtnh = vm_xtn::type_id::create("xtnh");
                    xtnh.rst = vif.vm_mon_cb.rst;
                    xtnh.in = vif.vm_mon_cb.in;
                    xtnh.x = vif.vm_mon_cb.x;
                    xtnh.y = vif.vm_mon_cb.y;
                
                `uvm_info(get_type_name(),"Sampling transaction", UVM_LOW)
                xtnh.print();

                mon_port.write(xtnh); // write to sb
            end
        end
    endtask
    
endclass 

// Agent -------------------------------------------------------------------
class vm_agent extends uvm_agent; 
    `uvm_component_utils(vm_agent)
    `NEW_COMP

    vm_seqr vm_seqrh;
    vm_drv vm_drvh;
    vm_mon vm_monh;


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        vm_seqrh = vm_seqr::type_id::create("vm_seqrh",this);
        vm_drvh = vm_drv::type_id::create("vm_drvh",this);
        vm_monh = vm_mon::type_id::create("vm_monh",this);
    endfunction 

    function void connect_phase(uvm_phase phase);
        vm_drvh.seq_item_port.connect(vm_seqrh.seq_item_export);
    endfunction 

endclass 

// ScoreBoard -------------------------------------------------------------------
class vm_sb extends uvm_scoreboard;
    `uvm_component_utils(vm_sb)

    uvm_analysis_imp #(vm_xtn, vm_sb) mon2sb_imp;

    int total;
    bit out_x, out_y;

    int match_count;
    int mismatch_count;

    // ADD: State parameters (same values as DUT)
    localparam idle = 3'b000, s1 = 3'b001, s2 = 3'b010, s3 = 3'b011, s4 = 3'b100;
    reg [2:0] exp_state;

    vm_xtn cov_inputs_xtn;
    vm_xtn cov_outputs_xtn;

    covergroup cg_fsm_inp;
        INP : coverpoint cov_inputs_xtn.in{
            bins inputs[] = {[0:3]};
        }

        RST : coverpoint cov_inputs_xtn.rst{
            bins low = {0};
            bins high = {1};
        }
    endgroup 

    covergroup cg_fsm_op;
        X : coverpoint cov_outputs_xtn.x{
            bins low = {0};
            bins high = {1};
        }

        Y : coverpoint cov_outputs_xtn.y{
            bins low = {0};
            bins high = {1};
        }
        X_Y : cross X,Y{
            ignore_bins ignore_xzero_yone =
            binsof(X) intersect {0} && 
            binsof(Y) intersect {1};   //---> Ignore x=0 and y=1 cross (it can never happen in this vm machine)
        }
    endgroup 

    covergroup cg_fsm_states_tran;
        STATES : coverpoint exp_state{
            bins IDLE = {idle};
            bins s1   = {s1};
            bins s2   = {s2};
            bins s3   = {s3};
            bins S4   = {s4};
        }

        TRANSITION : coverpoint exp_state{
            bins idle_to_s1 = (idle => s1);
            bins idle_to_s2 = (idle => s2);

            bins s1_to_s2   = (s1 => s2);  
            bins s1_to_s3   = (s1 => s3);                       

            bins s2_to_s3   = (s2 => s3);   
            bins s2_to_s4   = (s2 => s4);               

            bins s3_to_idle = (s3 => idle);   

            bins s4_to_idle = (s4 => idle);                       
        }
    endgroup


    function new(string name, uvm_component parent);
        super.new(name,parent);
        mon2sb_imp = new("mon2sb_imp",this);

        cg_fsm_inp = new();
        cg_fsm_op  = new();
        cg_fsm_states_tran = new();

        exp_state = idle;  // Initialize
    endfunction 

    // MODIFIED: Track FSM state properly
    function void exp_out(vm_xtn local_xtn);        
        if(local_xtn.rst) begin
            exp_state = idle;
            return;
        end
        else begin
        // FSM state transition (NEW: matches DUT exactly)
        case(exp_state)
            idle: begin
                if (local_xtn.in == 2'b10) exp_state = s1;
                else if (local_xtn.in == 2'b11) exp_state = s2;
                else exp_state = idle;
            end

            s1: begin
                if (local_xtn.in == 2'b10) exp_state = s2;
                else if (local_xtn.in == 2'b11) exp_state = s3;
                else exp_state = s1;
            end

            s2: begin
                if (local_xtn.in == 2'b10) exp_state = s3;
                else if (local_xtn.in == 2'b11) exp_state = s4;
                else exp_state = s2;
            end

            s3: exp_state = idle;
            s4: exp_state = idle;

            default: exp_state = idle;
        endcase
    end
    endfunction

    // MODIFIED: Use FSM states for expected outputs
    function void write(vm_xtn mon_xtn);
        //vm_xtn local_xtn;

        `uvm_info(get_type_name(), $sformatf("DEBUG: Received x=%0d y=%0d in=%0d rst=%0d", 
              mon_xtn.x, mon_xtn.y, mon_xtn.in, mon_xtn.rst), UVM_LOW)

//---------------------------------NEVER FORGET THIS ISSUE-------------------------------------------
    // THE F I M GENIUS TO FIGURE THIS OUT -- GO TO HELL BITCHES-----------------------------------

        // if(!$cast(local_xtn,mon_xtn.clone()))
        //     `uvm_fatal(get_type_name(),"Casting failed in write implementation")

        /*
        // clone() calls create() → new EMPTY vm_xtn
        // NO automatic field copy happens without do_copy()
        local_xtn = mon_xtn.clone();  // local_xtn.x/y remain 0!       
        */
//----------------------------------------------------------------------------------------------------         
        exp_out(mon_xtn);

        // FIXED: Expected outputs based on FSM states (Moore machine)
        // Same logic as DUT: x = (ps == s3) || (ps == s4), y = (ps == s4)
        out_x = (exp_state == s3) || (exp_state == s4);
        out_y = (exp_state == s4);

        // Compare Expected out & DUT out (your original code unchanged)
        if((out_x == mon_xtn.x) && (out_y == mon_xtn.y)) begin 
            `uvm_info(get_type_name(),$sformatf("\n\nScoreboard Success [Data Match Successfully] ==> \n[ x = out_x ] : [%0d = %0d] \n[ y = out_y ] : [%0d = %0d]\n",
                        mon_xtn.x, out_x, mon_xtn.y, out_y),
                        UVM_LOW)
            match_count++;
        end
        else begin 
            `uvm_error(get_type_name(), $sformatf(
                                    "\n\nScoreboard Error [Data Mismatch]: \nReceived Transaction: x=%d| y=%0d\nExpected Transaction: out_x=%d  | out_y=%0d\n Expected State: %0d\n",
                                    mon_xtn.x, mon_xtn.y, out_x, out_y, exp_state))
            mismatch_count++;
        end

        cov_inputs_xtn = mon_xtn;
        cov_outputs_xtn = mon_xtn;

        cg_fsm_inp.sample();
        cg_fsm_op.sample();
        cg_fsm_states_tran.sample();

    endfunction

    function void report_phase(uvm_phase phase);
        $display("//===============================================//");
        $display("====| Test Results: %0d matches, %0d mismatches.|====", match_count, mismatch_count);
        $display("//===============================================//");

        if(mismatch_count > 0) begin
            `uvm_fatal("TEST FAILED", "Mismatches detected in scoreboard.")
        end
    endfunction
endclass 

// Env -------------------------------------------------------------------
class vm_env extends uvm_env; 
    `uvm_component_utils(vm_env)
    `NEW_COMP

    vm_agent vm_agenth;
    vm_sb vm_sbh;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        vm_agenth = vm_agent::type_id::create("vm_agenth",this);
        vm_sbh = vm_sb::type_id::create("vm_sbh",this);
    endfunction 

    function void connect_phase(uvm_phase phase);
        vm_agenth.vm_monh.mon_port.connect(vm_sbh.mon2sb_imp);
    endfunction 

endclass 

// Test -------------------------------------------------------------------
class vm_test extends uvm_test; 
    `uvm_component_utils(vm_test)
    `NEW_COMP

    vm_env vm_envh;
    vm_seq vm_seq_rst_h;
    vm_seq vm_seq_coin_h;
    vm_seq_2r vm_seq_2r_h;
    vm_seq_1r vm_seq_1r_h;
    vm_seq_12r vm_seq_12r_h;
    vm_seq_s1_s3 vm_seq_s1_s3_h;

    g_cfg g_cfgh; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        g_cfgh = g_cfg::type_id::create("g_cfgh");

        if(!uvm_config_db #(virtual vm_if)::get(this,"","vm_if",g_cfgh.vif))
            `uvm_fatal(get_full_name(),"Cannot get() vif from TOP in TEST")

        // set config to all low levels
        uvm_config_db #(g_cfg)::set(this,"*","g_cfg",g_cfgh);

        vm_envh = vm_env::type_id::create("vm_envh",this);
    endfunction  

    task run_phase(uvm_phase phase);

        vm_seq_rst_h = vm_seq_rst::type_id::create("vm_seq_rst_h");
        vm_seq_coin_h = vm_seq_coin::type_id::create("vm_seq_coin_h");
        vm_seq_2r_h = vm_seq_2r::type_id::create("vm_seq_2r_h");
        vm_seq_1r_h = vm_seq_1r::type_id::create("vm_seq_1r_h");
        vm_seq_12r_h = vm_seq_12r::type_id::create("vm_seq_12r_h");
        vm_seq_s1_s3_h = vm_seq_s1_s3::type_id::create("vm_seq_s1_s3_h");

        phase.raise_objection(this);
        fork
            vm_seq_rst_h.start(vm_envh.vm_agenth.vm_seqrh);   
            vm_seq_coin_h.start(vm_envh.vm_agenth.vm_seqrh);
            vm_seq_12r_h.start(vm_envh.vm_agenth.vm_seqrh);
            vm_seq_1r_h.start(vm_envh.vm_agenth.vm_seqrh);
            vm_seq_2r_h.start(vm_envh.vm_agenth.vm_seqrh);
            vm_seq_s1_s3_h.start(vm_envh.vm_agenth.vm_seqrh);
        join
        phase.drop_objection(this);
    endtask

endclass 

// Top -------------------------------------------------------------------
module uvm_vm;

    bit clk = 0;

    always #5 clk = ~clk;

    vm_if VMIF(clk);

    vening_machine DUT(
        .clk(VMIF.clk),
        .rst(VMIF.rst),
        .in(VMIF.in),
        .x(VMIF.x),
        .y(VMIF.y)
    );

    bind DUT vm_assertions VM_ASSERTIONS(
        .clk(clk),
        .rst(rst),
        .in(in),
        .x(x),
        .y(y),
        .ps(DUT.ps)
    );

    initial begin 
        uvm_config_db #(virtual vm_if)::set(null,"*","vm_if",VMIF);
        run_test("vm_test");
    end
endmodule 

//---------------------------------------------------------------END---------------------------------------------------------------
