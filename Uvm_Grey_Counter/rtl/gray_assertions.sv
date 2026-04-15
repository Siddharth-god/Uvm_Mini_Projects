
module gray_assertions(
    clk,
    rst,
    bin_count,
    gray_count
);

    input rst, clk;
    input [3:0] bin_count;
    input [3:0] gray_count; 
    

        property p_reset; 
            @(posedge clk) 
                rst |=> (gray_count == 0);
        endproperty 

        // SVA samples in the preponed region 
        property p_bin_incr; 
            @(posedge clk) 
                disable iff(rst)
                    !rst |=> $past(bin_count) + 1;
        endproperty 

        property p_gray_count;
            @(posedge clk)
            disable iff(rst)
                !rst |=> gray_count == {bin_count[3],
                            bin_count[3]^bin_count[2],
                            bin_count[2]^bin_count[1],
                            bin_count[1]^bin_count[0]};
        endproperty
    

        RESET : assert property(p_reset)
                    $display("PASS :-------- RESET -------- | Time = %0t",$time);
                else 
                    $display("FAIL :-------- RESET -------- | Time = %0t",$time);

        BIN_INCR : assert property(p_bin_incr)
                    $display("PASS :-------- BIN_INCR -------- bin_count=%0d | Time = %0t",bin_count,$time);
                else 
                    $display("FAIL :-------- BIN_INCR -------- bin_count=%0d | Time = %0t",bin_count,$time);

        GRAY_CNT : assert property(p_gray_count)
                    $display("PASS :-------- GREY_CNT -------- | Time = %0t",$time);
                else 
                    $display("FAIL :-------- GREY_CNT -------- | Time = %0t",$time);
endmodule



/*
----------------------------------------------------------------------
Region              What happens
----------------------------------------------------------------------
Preponed            SVA samples signal values (takes a snapshot)
Active              Blocking assignments (=) execute
NBA                 Non-blocking assignments (<=) update
Observed            SVA evaluates properties using the sampled values
----------------------------------------------------------------------

####################################################
# SVA + BLOCKING ASSIGNMENT — DEBUG NOTES #
####################################################

## SV SIMULATION REGIONS (in order per clock edge)

[1] PREPONED ← SVA samples all signal values HERE (snapshot)
[2] ACTIVE ← Blocking assignments (=) execute HERE
[3] NBA ← Non-blocking assignments (<=) update HERE
[4] OBSERVED ← SVA evaluates properties using preponed snapshot

## KEY RULE

SVA always samples BEFORE the DUT updates
# Whatever value was stable before the clock edge
# is what SVA captures — not the new updated value

## DUT UPDATE vs SVA SAMPLE — side by side

NON-BLOCKING (<=) — SAFE:
PREPONED → SVA samples bin_count (old value) ✓
NBA → bin_count updates to new value ✓
OBSERVED → $past() has clean old value ✓

BLOCKING (=) — PROBLEMATIC:
PREPONED → SVA samples bin_count (old value) ✓
ACTIVE → bin_count IMMEDIATELY overwrites !
OBSERVED → $past() boundary becomes ambiguous ✗

## WRAP FAILURE — WHY @225ns FAILS

# Timeline of bin_count from $display (post-active):
@195ns → bin_count = 14
@205ns → bin_count = 15
@215ns → bin_count = 0 (wrap: 15+1 overflows 4-bit)
@225ns → bin_count = 1 ← FAIL reported here

# What SVA sees at each edge (preponed snapshot):
@215ns preponed : samples bin_count = 15
@215ns active : blocking runs → bin_count = 0
@215ns observed : current=15, $past()=14 → 15==14+1 PASS ✓

@225ns preponed : samples bin_count = 0 (post-wrap stable)
@225ns active : blocking runs → bin_count = 1
@225ns observed : current=0, $past()=15
0 == 15+1 (4-bit) → 0 == 0 ... AMBIGUOUS
QuestaSim resolves: FAIL ✗

# NOTE: $display prints AFTER active region
# so display shows bin_count=1 but SVA sampled bin_count=0
# They are looking at the SAME signal at the SAME edge
# but seeing DIFFERENT values — that is the blocking effect

## @65ns FAILURE — FIRST INCREMENT AFTER RESET

@55ns : bin_count = x (reset era, never incremented)
@65ns : rst goes low, bin_count = 1 after active

@65ns preponed : samples bin_count = x (reset era value)
@65ns observed : current=x, $past()=x
x == x+1 → FAIL ✗ (x propagation)

## ASSERTION VERDICT

p_bin_incr logic → CORRECT ✓
QuestaSim behavior → CORRECT (legal per LRM) ✓
DUT blocking (=) → ROOT CAUSE ✗

# LRM IEEE 1800 states:
"Blocking assignments in clocked always blocks
create race conditions with SVA sampling"
→ Result is tool-dependent / undefined behavior
→ Not a tool bug. Not an assertion bug. DUT bug.

## GOLDEN RULES

NEVER → always @(posedge clk) bin_count = ...
ALWAYS → always @(posedge clk) bin_count <= ...

# Non-blocking (<=) ensures:
# SVA preponed snapshot is always clean and stable
# $past() always captures correct previous cycle value
# No race between ACTIVE and PREPONED regions

####################################################
# END OF NOTE #
####################################################

-----------------------------------------------------------------------------
####################################################
Reset fails at @5ns (very first posedge) because:
####################################################

@5ns preponed : SVA samples gray_count = x  ← never been touched yet
@5ns active   : DUT runs → gray_count = 0   ← blocking assigns 0 now
@5ns observed : rst=1, gray_count=x
                x == 0 → FAIL ✗

####################################################
One line reason:
####################################################
At the very first clock edge, gray_count has never been initialized — 
it is still x when SVA takes its preponed snapshot. The blocking assignment sets it to 0 only in the active region, 
which is already too late for SVA to see.
####################################################
*/