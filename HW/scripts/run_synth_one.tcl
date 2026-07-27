# Usage:
# vivado -mode batch -source run_synth_one.tcl -tclargs <project.xpr> <synth_top> ?<out_report_dir>?

set project_xpr    [lindex $argv 0]
set synth_top      [lindex $argv 1]
set out_report_dir [lindex $argv 2]

if {$project_xpr eq "" || $synth_top eq ""} {
    puts "Usage: vivado -mode batch -source run_synth_one.tcl -tclargs <project.xpr> <synth_top> ?<out_report_dir>?"
    exit 1
}

if {$out_report_dir eq ""} {
    set script_dir      [file normalize [file dirname [info script]]]
    set hw_dir          [file normalize [file join $script_dir ".."]]
    set repo_root       [file normalize [file join $hw_dir ".."]]
    set out_report_dir  [file normalize [file join $repo_root "reports"]]
}

set report_dir [file normalize [file join $out_report_dir $synth_top]]
file mkdir $report_dir

puts "Opening project: $project_xpr"
open_project $project_xpr

set srcset [get_filesets sources_1]

puts "Setting synthesis top: $synth_top"
set_property top $synth_top $srcset

update_compile_order -fileset sources_1

if {[llength [get_runs synth_1 -quiet]]} {
    reset_run synth_1
}
if {[llength [get_runs impl_1 -quiet]]} {
    reset_run impl_1
}

puts "Launching synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

puts "Launching implementation..."
launch_runs impl_1 -to_step route_design -jobs 4
wait_on_run impl_1

puts "Opening synthesized design..."
open_run synth_1 -name synth_1

report_utilization               -file "$report_dir/post_synth_utilization.rpt"
report_timing_summary            -file "$report_dir/post_synth_timing_summary.rpt"
report_power                     -file "$report_dir/post_synth_power.rpt"
report_power                     -xpe  "$report_dir/post_synth_power.xpe"
report_clock_utilization         -file "$report_dir/post_synth_clock_utilization.rpt"

puts "Opening implemented design..."
open_run impl_1 -name impl_1

report_utilization               -file "$report_dir/post_impl_utilization.rpt"
report_utilization -hierarchical -file "$report_dir/post_impl_utilization_hier.rpt"
report_timing_summary            -file "$report_dir/post_impl_timing_summary.rpt"
report_timing -max_paths 10      -file "$report_dir/post_impl_timing.rpt"
report_power                     -file "$report_dir/post_impl_power.rpt"
report_power                     -xpe  "$report_dir/post_impl_power.xpe"
report_route_status              -file "$report_dir/post_impl_route_status.rpt"
report_drc                       -file "$report_dir/post_impl_drc.rpt"
report_clock_utilization         -file "$report_dir/post_impl_clock_utilization.rpt"

puts "Reports written to: $report_dir"

close_project
exit
