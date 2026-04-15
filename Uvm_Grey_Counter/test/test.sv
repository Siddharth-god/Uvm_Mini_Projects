
// ================= TEST =================
class test extends uvm_test;

    env envh;
    env_config env_cfg;

    `uvm_component_utils(test)

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        env_cfg = env_config::type_id::create("env_cfg");

        if(!uvm_config_db#(virtual gray_if)::get(this,"","vif",env_cfg.vif))
            `uvm_fatal(get_type_name(),"Failed to get vif from TOP in TEST")

        env_cfg.in_agent_active  = UVM_ACTIVE;
        env_cfg.out_agent_active = UVM_PASSIVE;

        uvm_config_db#(env_config)::set(this,"*","env_config",env_cfg);

        envh = env::type_id::create("envh",this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

endclass

// ================= TEST 1 =================
class test_pos extends test;


    `uvm_component_utils(test_pos)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    seq_pos seq_posh;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        seq_posh = seq_pos::type_id::create("seq_posh");

        phase.raise_objection(this);

        seq_posh.start(envh.in_agth.seqrh);

        phase.drop_objection(this);
    endtask

endclass


// ================= TEST 2 =================
class test_neg extends test;

    seq_neg seq_negh;

    `uvm_component_utils(test_neg)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        seq_negh = seq_neg::type_id::create("seq_negh");

        phase.raise_objection(this);
        seq_negh.start(envh.in_agth.seqrh);
        phase.drop_objection(this);
    endtask

endclass


// ================= TEST 3 =================
class test_corner extends test;

    seq_corner seq_cornerh;

    `uvm_component_utils(test_corner)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        seq_cornerh = seq_corner::type_id::create("seq_cornerh");

        phase.raise_objection(this);
        seq_cornerh.start(envh.in_agth.seqrh);
        phase.drop_objection(this);
    endtask

endclass

