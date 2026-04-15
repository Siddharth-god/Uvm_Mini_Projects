
// ================= IN AGENT =================
class in_agent extends uvm_agent;

    drv drvh;
    in_mon in_monh;
    seqr seqrh;
    env_config env_cfg;

    `uvm_component_utils(in_agent)

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction


    function void build_phase(uvm_phase phase);
        if(!uvm_config_db#(env_config)::get(this,"","env_config",env_cfg))
            `uvm_fatal("AGT","cfg fail")

        in_monh = in_mon::type_id::create("in_monh",this);

        if(env_cfg.in_agent_active==UVM_ACTIVE) begin
            drvh = drv::type_id::create("drvh",this);
            seqrh = seqr::type_id::create("seqrh",this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        if(env_cfg.in_agent_active==UVM_ACTIVE)
            drvh.seq_item_port.connect(seqrh.seq_item_export);
    endfunction

endclass