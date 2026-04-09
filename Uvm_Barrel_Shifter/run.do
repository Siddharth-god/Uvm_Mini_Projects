onbreak resume
coverage save -onexit uvm_bs.ucdb
run 0
log -r *
add wave -r sim:/uvm_bs/*
run -all
