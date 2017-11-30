# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
set_clock_groups -asynchronous  \
-group clk_fpga_0 \
-group FMC_CLK0_M2C_P \
-group FMC_CLK1_M2C_P \
-group [get_clocks -filter {NAME =~ *TXOUTCLK}] \
-group EXTCLK_P \
-group [get_clocks clk2mux] -group [get_clocks clk2mux] \
-group [get_clocks clk1mux] -group [get_clocks clk1mux] \
-group [get_clocks GTXCLK0_P] \
-group [get_clocks -of_objects [get_pins eventr_plle2_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins eventr_plle2_adv_inst/CLKOUT0]] \

# Pack IOB registers
set_property iob true [get_cells -hierarchical -regexp -filter {NAME =~ .*iob_reg.*}]
