
// ================= INPUT MONITOR =================
class in_mon extends uvm_monitor;

    virtual gray_if vif;
    env_config env_cfg;
    uvm_analysis_port #(xtn) in_mon_port;
    xtn xtnh;

    `uvm_component_utils(in_mon)

    function new(string name, uvm_component parent);
        super.new(name,parent);
        in_mon_port = new("in_mon_port",this);
    endfunction

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db#(env_config)::get(this,"","env_config",env_cfg))
            `uvm_fatal("MON","cfg fail")

        xtnh = xtn::type_id::create("xtnh");
    endfunction

    function void connect_phase(uvm_phase phase);
        vif = env_cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);
        @(vif.in_mon_cb); // By adding 1 cycle extra here we can eliminate the default signal sampling and first unwanted comparison can be removed so no mismatch for first compare
        forever begin
            @(vif.in_mon_cb);
            xtnh.rst = vif.in_mon_cb.rst;
            $display("Input monitor is sampling : rst = %0d",xtnh.rst);
            in_mon_port.write(xtnh);
        end
    endtask

endclass