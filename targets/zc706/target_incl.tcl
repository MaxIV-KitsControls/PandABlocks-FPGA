set FPGA_PART xc7z045ffg900-2
set BOARD_PART "xilinx.com:zc706:part0:1.2"
set HDL_TOP zc706_top

# Target specific Constriants to be read
# NB: we could just read the entire directory with 'add_files [glob $TARGET_DIR/const/*.xdc]
set CONSTRAINTS { \
            zc706-pins_impl.xdc
}
            
# Target specific 'hardware' blocks to be read.
# These could be added to the autogenerated 'constraints.tcl'
set TGT_SRC { \
            pcap \
            zedboard_demo
}

# List of IP that can be targeted to this platform.
# NB: these could built as and when required.
set TGT_IP {                        \
            pulse_queue             \
            fifo_1K32               \
            fifo_1K32_ft            \
            eth_phy                 \
            eth_mac                 \
            system_cmd_fifo         \
            fmc_acq430_ch_fifo      \
            fmc_acq430_sample_ram   \
            fmc_acq427_dac_fifo     \
            ila_0
}

