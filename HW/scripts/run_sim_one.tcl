# Usage:
# vivado -mode batch -source run_sim_one.tcl -tclargs <project.xpr> <sim_top> ?<out_csv_dir>?

set project_xpr [lindex $argv 0]
set sim_top     [lindex $argv 1]
set out_csv_dir [lindex $argv 2]

if {$project_xpr eq "" || $sim_top eq ""} {
    puts "Usage: vivado -mode batch -source run_sim_one.tcl -tclargs <project.xpr> <sim_top> ?<out_csv_dir>?"
    exit 1
}

if {$out_csv_dir eq ""} {
    set script_dir  [file normalize [file dirname [info script]]]
    set hw_dir      [file normalize [file join $script_dir ".."]]
    set repo_root   [file normalize [file join $hw_dir ".."]]
    set out_csv_dir [file normalize [file join $repo_root "results"]]
}

file mkdir $out_csv_dir

puts "Opening project: $project_xpr"
open_project $project_xpr

set simset [get_filesets sim_1]

puts "Setting simulation top: $sim_top"
set_property top $sim_top $simset
set_property xsim.simulate.runtime all $simset
set_property -name {xsim.simulate.xsim.more_options} \
             -value "-testplusarg OUT_CSV_DIR=$out_csv_dir" \
             -objects $simset

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Simulation CSV directory: $out_csv_dir"
puts "Launching simulation..."
launch_simulation
puts "Simulation completed for top: $sim_top"

close_sim
close_project
exit
