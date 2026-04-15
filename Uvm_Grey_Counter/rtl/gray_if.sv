// ================= INTERFACE =================
interface gray_if(input bit clk);

    bit rst;
    bit [3:0] gray_count;

    clocking drv_cb @(posedge clk);
        output rst;
    endclocking

    clocking in_mon_cb @(posedge clk);
        input rst; // rst initial value is 0 (which is sampled by monitor at the same time driver drives)
    endclocking

    clocking out_mon_cb @(posedge clk);
        default input #0; // this will always capture previous cycle output (but on previous cc no value is generated default values are monitored and we get output gray_count as x)
        input gray_count;
        input rst; 
    endclocking

    modport drv_mod (clocking drv_cb);
    modport in_mon_mod (clocking in_mon_cb);
    modport out_mon_mod (clocking out_mon_cb);
endinterface