
// ================= DRIVER =================
class drv extends uvm_driver #(xtn);

    virtual gray_if vif;
    env_config env_cfg;

    `uvm_component_utils(drv)

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(env_config)::get(this,"","env_config",env_cfg))
            `uvm_fatal(get_type_name(),"Failed to get env config from TEST in DRV")
    endfunction

    function void connect_phase(uvm_phase phase);
        vif = env_cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);
        @(vif.drv_cb)
        vif.drv_cb.rst <= 1;
        repeat(5) @(vif.drv_cb);
        vif.drv_cb.rst <= 0;
        forever begin
            seq_item_port.get_next_item(req);
            @(vif.drv_cb)
                vif.drv_cb.rst <= req.rst;
            $display("Driver is Driving : rst = %0d",req.rst);
            seq_item_port.item_done();
        end
    endtask

endclass
