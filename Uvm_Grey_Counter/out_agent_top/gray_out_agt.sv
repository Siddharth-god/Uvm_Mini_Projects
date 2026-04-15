
// ================= OUT AGENT =================
class out_agent extends uvm_agent;

    out_mon out_monh;
    env_config env_cfg;

    `uvm_component_utils(out_agent)

      function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db#(env_config)::get(this,"","env_config",env_cfg))
            `uvm_fatal(get_type_name(),"Failed to get env_cfg from TEST")

        out_monh = out_mon::type_id::create("out_monh",this);
    endfunction

endclass
