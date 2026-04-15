
// ================= ENV CONFIG =================
class env_config extends uvm_object;

    virtual gray_if vif;
    uvm_active_passive_enum in_agent_active;
    uvm_active_passive_enum out_agent_active;

    `uvm_object_utils(env_config)

    function new(string name="env_config");
        super.new(name);
    endfunction

endclass