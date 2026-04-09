interface barrel_shifter_if(input bit clk);
    logic [7:0] in;
    logic [2:0] sel; 
    logic [7:0] out; 

    clocking bs_drv_cb@(posedge clk);
        output in;
        output sel; 
    endclocking 

    clocking bs_mon_cb@(posedge clk);
        input in;
        input sel; 
        input out; 
    endclocking 

    modport BS_DRV_MP(clocking bs_drv_cb);
    modport BS_MON_MP(clocking bs_mon_cb);

endinterface 