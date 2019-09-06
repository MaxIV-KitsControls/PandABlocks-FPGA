#
# Generate PS part of the firmware based as Zynq Block design
#

# Source directory
set TARGET_DIR [lindex $argv 0]
set_param board.repoPaths $TARGET_DIR/configs

# Build directory
set BUILD_DIR [lindex $argv 1]

# Output file
set OUTPUT_FILE [lindex $argv 2]

# Vivado run mode - gui or batch mode
set MODE [lindex $argv 3]

# Create project
create_project -part xc7z020clg484-1 -force panda_ps $BUILD_DIR

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects panda_ps]
set_property "board_part" "em.avnet.com:zed:part0:1.3" $obj
set_property "default_lib" "xil_defaultlib" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

# Create block design
# (THIS is exported from Vivado design tool)
source $TARGET_DIR/bd/panda_ps.tcl

# Exit script here if gui mode - i.e. if running 'make edit_ps_bd'
if {[string match "gui" [string tolower $MODE]]} { return }

# Generate the wrapper
set design_name [get_bd_designs]
make_wrapper -files [get_files $design_name.bd] -top -import

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "top" "panda_ps_wrapper" $obj

# Generate Output Files
generate_target all [get_files $OUTPUT_FILE]
#open_bd_design $OUTPUT_FILE

# Export to SDK
#file mkdir $BUILD_DIR/panda_ps.sdk
#write_hwdef -force -file $BUILD_DIR/panda_ps_wrapper.hdf

# Close block design and project
#close_bd_design panda_ps
close_project
exit