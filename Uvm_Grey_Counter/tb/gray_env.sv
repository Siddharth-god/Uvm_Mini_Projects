
// ================= ENV =================
class env extends uvm_env;

    `uvm_component_utils(env)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    in_agent in_agth;
    out_agent out_agth;
    sb sbh;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        in_agth  = in_agent::type_id::create("in_agth",this);
        out_agth = out_agent::type_id::create("out_agth",this);
        sbh      = sb::type_id::create("sbh",this);
    endfunction

    function void connect_phase(uvm_phase phase);
        in_agth.in_monh.in_mon_port.connect(sbh.fifo_in.analysis_export);
        out_agth.out_monh.out_mon_port.connect(sbh.fifo_out.analysis_export);
    endfunction

endclass