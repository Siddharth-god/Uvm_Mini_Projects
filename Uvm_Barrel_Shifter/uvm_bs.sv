
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

// config --------------------------------------------------------------------------
class bs_config extends uvm_object;
    `uvm_object_utils(bs_config)
    `NEW_OBJ

    virtual barrel_shifter_if vif;
endclass 

// Xtn -----------------------------------------------------------------------------
class bs_xtn extends uvm_sequence_item;
    `uvm_object_utils(bs_xtn)
    `NEW_OBJ

    rand bit [7:0] in;
    rand bit [2:0] sel; 
    bit [7:0] out;

    virtual function void do_print(uvm_printer printer);
        printer.print_field("in",in,8,UVM_DEC);
        printer.print_field("sel",sel,3,UVM_DEC);
        printer.print_field("out",in,8,UVM_DEC);
    endfunction

endclass

// Seq -----------------------------------------------------------------------------
class bs_seq extends uvm_sequence #(bs_xtn);
    `uvm_object_utils(bs_seq)
    `NEW_OBJ    
endclass 

// MIN DATA - COVERING 
class bs_seq_min extends uvm_sequence #(bs_xtn);
    `uvm_object_utils(bs_seq_min)
    `NEW_OBJ

    task body();
        repeat(80) begin 
            req = bs_xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                in inside {[0:86]};
            });
            finish_item(req);
        end
    endtask
    
endclass 

// MID DATA - COVERING 
class bs_seq_mid extends uvm_sequence #(bs_xtn);
    `uvm_object_utils(bs_seq_mid)
    `NEW_OBJ

    task body();
        repeat(80) begin 
            req = bs_xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                in inside {[87:171]};
            });
            finish_item(req);
        end
    endtask
    
endclass 

// MAX DATA - COVERING 
class bs_seq_max extends uvm_sequence #(bs_xtn);
    `uvm_object_utils(bs_seq_max)
    `NEW_OBJ

    task body();
        repeat(80) begin 
            req = bs_xtn::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                in inside {[172:255]};
            });
            finish_item(req);
        end
    endtask
    
endclass 

// Seqr ----------------------------------------------------------------------------
class bs_seqr extends uvm_sequencer #(bs_xtn);
    `uvm_component_utils(bs_seqr)
    `NEW_COMP
endclass 


// Drv ----------------------------------------------------------------------------
class bs_drv extends uvm_driver #(bs_xtn);
    `uvm_component_utils(bs_drv)
    `NEW_COMP

    virtual barrel_shifter_if vif;
    bs_config bs_cfgh;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(bs_config)::get(this,"","bs_config",bs_cfgh))
            `uvm_fatal(get_full_name(),"Cannot get() bs_cfg from TEST in DRV")
    endfunction

    function void connect_phase(uvm_phase phase);
        vif = bs_cfgh.vif; 
    endfunction

    task run_phase(uvm_phase phase);
        @(vif.bs_drv_cb)
            vif.bs_drv_cb.in <= 0;
            vif.bs_drv_cb.sel <= 0;
        forever begin 
            seq_item_port.get_next_item(req);
            // send to dut 
            $display("\nDriving: in=%0d sel=%0d", req.in, req.sel);

            @(vif.bs_drv_cb) begin 
                vif.bs_drv_cb.in  <= req.in;
                vif.bs_drv_cb.sel <= req.sel;
            end
            seq_item_port.item_done();
        end
    endtask
endclass 


// Mon ----------------------------------------------------------------------------
class bs_mon extends uvm_monitor;
    `uvm_component_utils(bs_mon)
    `NEW_COMP


    virtual barrel_shifter_if vif;
    bs_config bs_cfgh;
    uvm_analysis_port #(bs_xtn) bs_mon_port;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        bs_mon_port = new("bs_mon_port",this);

        if(!uvm_config_db #(bs_config)::get(this,"","bs_config",bs_cfgh))
            `uvm_fatal(get_full_name(),"Cannot get() bs_cfg from TEST in MON")
    endfunction

    function void connect_phase(uvm_phase phase);
        vif = bs_cfgh.vif; 
    endfunction 

    task run_phase(uvm_phase phase);
        bs_xtn mon_xtn;
        forever begin 
            // repeat(2)
            @(vif.bs_mon_cb) begin 
                mon_xtn = bs_xtn::type_id::create("mon_xtn");
                mon_xtn.in = vif.bs_mon_cb.in;
                mon_xtn.sel = vif.bs_mon_cb.sel;
                mon_xtn.out = vif.bs_mon_cb.out;

                `uvm_info(get_type_name(),"Sampling Transactions",UVM_LOW)
                mon_xtn.print();

                bs_mon_port.write(mon_xtn);
            end
        end
    endtask
endclass 


// Agent ----------------------------------------------------------------------------
class bs_agent extends uvm_agent;
    `uvm_component_utils(bs_agent)
    `NEW_COMP

    bs_drv bs_drvh;
    bs_mon bs_monh;
    bs_seqr bs_seqrh;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        bs_drvh = bs_drv::type_id::create("bs_drvh",this);
        bs_monh = bs_mon::type_id::create("bs_monh",this);
        bs_seqrh = bs_seqr::type_id::create("bs_seqrh",this);
    endfunction

    function void connect_phase(uvm_phase phase);
        bs_drvh.seq_item_port.connect(bs_seqrh.seq_item_export);
    endfunction 
endclass 

// Sb -----------------------------------------------------------------------------
class bs_sb extends uvm_scoreboard;
    `uvm_component_utils(bs_sb)
    //`NEW_COMP

    uvm_analysis_imp #(bs_xtn, bs_sb) bs_mon2sb_imp;
    bit [7:0] exp_out;

    // Coverage ---------

    bs_xtn barrel_cov;

    covergroup cg_barrel_shifter; 
        IN : coverpoint barrel_cov.in{
            bins in_min = {[0:31]};
            bins in_min2 = {[32:63]};
            bins in_min3 = {[64:96]};
            bins in_mid1 = {[97:128]};
            bins in_mid2 = {[129:161]};
            bins in_max1 = {[162:194]};
            bins in_max2 = {[195:226]};
            bins in_max3 = {[227:255]};
        }

        SEL : coverpoint barrel_cov.sel{
            bins sel_000 = {3'b000};                                       
            bins sel_001 = {3'b001};                           
            bins sel_010 = {3'b010};                           
            bins sel_011 = {3'b011};                           
            bins sel_100 = {3'b100};                           
            bins sel_101 = {3'b101};                           
            bins sel_110 = {3'b110};                           
            bins sel_111 = {3'b111};                           
        }

        OUT : coverpoint barrel_cov.out{
            bins in_min = {[0:31]};
            bins in_min2 = {[32:63]};
            bins in_min3 = {[64:96]};
            bins in_mid1 = {[97:128]};
            bins in_mid2 = {[129:161]};
            bins in_max1 = {[162:194]};
            bins in_max2 = {[195:226]};
            bins in_max3 = {[227:255]};
        }

        IN_SEL : cross IN,SEL;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name,parent);
        cg_barrel_shifter = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        bs_mon2sb_imp = new("bs_mon2sb_imp",this);
    endfunction

    function void write(bs_xtn mon_xtn);
/*
        `uvm_info(get_type_name(), 
                    $sformatf("\n\nDEBUG: Received input=%b | sel=%b\n",mon_xtn.in, mon_xtn.sel),   
                    UVM_LOW)
*/
        case(mon_xtn.sel)   
            3'b000 : exp_out = mon_xtn.in;
            3'b001 : exp_out = {mon_xtn.in[0],  mon_xtn.in[7:1]};           
            3'b010 : exp_out = {mon_xtn.in[1:0],mon_xtn.in[7:2]};           
            3'b011 : exp_out = {mon_xtn.in[2:0],mon_xtn.in[7:3]};            
            3'b100 : exp_out = {mon_xtn.in[3:0],mon_xtn.in[7:4]};           
            3'b101 : exp_out = {mon_xtn.in[4:0],mon_xtn.in[7:5]};          
            3'b110 : exp_out = {mon_xtn.in[5:0],mon_xtn.in[7:6]}; 
            3'b111 : exp_out = {mon_xtn.in[6:0],mon_xtn.in[7]};      
            default : exp_out = mon_xtn.in;     
        endcase 

        if(exp_out == mon_xtn.out)
            `uvm_info("\n\nScore Board : [Data Match Successful",
                        $sformatf("\ninput => %b(%0d) | sel => %0d\nexp_out => %b\ndut_out => %b\n",mon_xtn.in,mon_xtn.in, mon_xtn.sel, exp_out, mon_xtn.out),
                        UVM_LOW)
        else 
            `uvm_info("\nScore Board : [Data Mismatch",
                        $sformatf("\ninput => %b(%0d) | sel => %0d\nexp_out => %b\ndut_out => %b\n",mon_xtn.in,mon_xtn.in, mon_xtn.sel, exp_out, mon_xtn.out),
                        UVM_LOW)

        barrel_cov = mon_xtn;
        cg_barrel_shifter.sample();
    endfunction
endclass 

// Env ----------------------------------------------------------------------------
class bs_env extends uvm_env;
    `uvm_component_utils(bs_env)

    `NEW_COMP

    bs_agent bs_agenth; 
    bs_sb bs_sbh;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        bs_agenth = bs_agent::type_id::create("bs_agenth",this);
        bs_sbh = bs_sb::type_id::create("bs_sbh",this);
    endfunction

    function void connect_phase(uvm_phase phase);
        bs_agenth.bs_monh.bs_mon_port.connect(bs_sbh.bs_mon2sb_imp);
    endfunction

endclass 


// Test ----------------------------------------------------------------------------
class bs_test extends uvm_test;
    `uvm_component_utils(bs_test)

    `NEW_COMP

    bs_env bs_envh;

    bs_seq_min bs_seq_minh;
    bs_seq_mid bs_seq_midh;
    bs_seq_max bs_seq_maxh;

    bs_config bs_cfgh; 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        bs_cfgh = bs_config::type_id::create("bs_cfgh");

        if(!uvm_config_db #(virtual barrel_shifter_if)::get(this,"","barrel_shifter_if",bs_cfgh.vif))
            `uvm_fatal(get_full_name(),"Cannot get() vif from TOP in -- TEST")


        uvm_config_db #(bs_config)::set(this,"*","bs_config",bs_cfgh);

        bs_envh = bs_env::type_id::create("bs_envh",this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase); // Test defines the duration and work as a break so no forever here

        bs_seq_minh = bs_seq_min::type_id::create("bs_seq_minh");
        bs_seq_midh = bs_seq_mid::type_id::create("bs_seq_midh");
        bs_seq_maxh = bs_seq_max::type_id::create("bs_seq_maxh");

        phase.raise_objection(this);
        fork
            bs_seq_minh.start(bs_envh.bs_agenth.bs_seqrh);
            bs_seq_midh.start(bs_envh.bs_agenth.bs_seqrh);
            bs_seq_maxh.start(bs_envh.bs_agenth.bs_seqrh);
        join
        phase.drop_objection(this);
    endtask
endclass 

// Top ----------------------------------------------------------------------------
module uvm_bs;

    bit clk = 0;

    always #5 clk = ~clk;

    barrel_shifter_if bs_if(clk);

    barrel_shifter DUT(
        .in(bs_if.in),
        .sel(bs_if.sel),
        .out(bs_if.out)
    );

    bind barrel_shifter bs_assertions BS_ASSERTIONS(
        .in(in),
        .sel(sel),
        .out(out)
    );

    initial begin
        uvm_config_db #(virtual barrel_shifter_if)::set(null,"*","barrel_shifter_if",bs_if);
        run_test("bs_test");
    end
endmodule 