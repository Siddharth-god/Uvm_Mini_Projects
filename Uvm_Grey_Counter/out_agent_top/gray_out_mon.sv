

// ================= OUTPUT MONITOR =================
class out_mon extends uvm_monitor;

    virtual gray_if vif;
    env_config env_cfg;
    uvm_analysis_port #(xtn) out_mon_port;
    xtn xtnh; 

    `uvm_component_utils(out_mon)

    function new(string name, uvm_component parent);
        super.new(name,parent);
        out_mon_port = new("out_mon_port",this);
    endfunction

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db#(env_config)::get(this,"","env_config",env_cfg))
            `uvm_fatal("MON","cfg fail")

        xtnh= xtn::type_id::create("xtnh");
    endfunction

    function void connect_phase(uvm_phase phase);
        vif = env_cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);
        @(vif.out_mon_cb);
        forever begin
            @(vif.out_mon_cb);
            xtnh.rst = vif.out_mon_cb.rst;
            xtnh.gray_count = vif.out_mon_cb.gray_count;
            $display("Output monitor is sampling : gray_count = %0d",xtnh.gray_count);
            out_mon_port.write(xtnh);
        end
    endtask

endclass
