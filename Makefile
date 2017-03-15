# Top level make file for building PandA socket server and associated device
# drivers for interfacing to the FPGA resources.

TOP := $(CURDIR)

-include CONFIG
-include VERSION

export LM_LICENSE_FILE
export BUILD_DIR

DOCS_BUILD_DIR = $(BUILD_DIR)/html
SLOW_FPGA_BUILD_DIR = $(BUILD_DIR)/SlowFPGA
FPGA_BUILD_DIR = $(BUILD_DIR)/CarrierFPGA

default: $(DEFAULT_TARGETS)
.PHONY: default

export GIT_VERSION := $(shell git describe --abbrev=7 --dirty --always --tags)

# -------------------------------------------------------------------------
# Documentation
# -------------------------------------------------------------------------

$(DOCS_BUILD_DIR)/index.html: $(wildcard docs/*.rst docs/*/*.rst docs/conf.py)
	$(SPHINX_BUILD) -b html docs $(DOCS_BUILD_DIR)

docs: $(DOCS_BUILD_DIR)/index.html

.PHONY: docs


# -------------------------------------------------------------------------
# FPGA builds
# -------------------------------------------------------------------------
APP_FILE = $(TOP)/apps/$(APP_NAME)

# Extract FMC and SFP design names from config file
FMC_DESIGN = $(shell sed -n '/^FMC_/{s///;s/ .*//;p}' $(APP_FILE))
SFP_DESIGN = $(shell sed -n '/^SFP_/{s///;s/ .*//;p}' $(APP_FILE))

INCR_DESIGN = false

carrier-fpga: $(FPGA_BUILD_DIR)
	rm -rf $(BUILD_DIR)/config_d
	rm -rf $(TOP)/CarrierFPGA/src/hdl/autogen
	cd python && ./config_generator.py -a $(APP_FILE)
	cd python && ./vhdl_generator.py
	$(MAKE) -C $< -f $(TOP)/CarrierFPGA/Makefile VIVADO=$(VIVADO) \
	    TOP=$(TOP) OUTDIR=$(FPGA_BUILD_DIR) \
		FMC_DESIGN=$(FMC_DESIGN) SFP_DESIGN=$(SFP_DESIGN) \
			INCR_DESIGN=$(INCR_DESIGN)

devicetree: $(FPGA_BUILD_DIR)
	$(MAKE) -C $< -f $(TOP)/CarrierFPGA/Makefile VIVADO=$(VIVADO) \
	    TOP=$(TOP) OUTDIR=$(FPGA_BUILD_DIR) TAR_REPO=$(TAR_REPO) \
		DEVTREE_VER=$(DEVTREE_VER) devicetree

slow-fpga: $(SLOW_FPGA_BUILD_DIR) tools/virtexHex2Bin
	source $(ISE)  &&  $(MAKE) -C $< -f $(TOP)/SlowFPGA/Makefile \
            TOP=$(TOP) SRC_DIR=$(TOP)/SlowFPGA BOARD=$(BOARD) mcs

tools/virtexHex2Bin : tools/virtexHex2Bin.c
	gcc -o $@ $<

sw_clean :
	$(MAKE) -f $(TOP)/CarrierFPGA/Makefile TOP=$(TOP) sw_clean

.PHONY: carrier-fpga slow-fpga devicetree sw_clean

# -------------------------------------------------------------------------
# Build installation package
# -------------------------------------------------------------------------

ZPKG_VERSION = $(BOARD)-FMC_$(FMC_DESIGN)_SFP_$(SFP_DESIGN)-$(FIRMWARE)

zpkg: etc/panda-fpga.list $(FIRMWARE_BUILD)
#	$(error Still need to specify FIRMWARE_BUILD dependencies)
	rm -f $(BUILD_DIR)/*.zpg
	$(MAKE_ZPKG) -t $(BUILD_DIR) -b $(BUILD_DIR) -d $(BUILD_DIR) \
            $< $(ZPKG_VERSION)

.PHONY: zpkg

# -------------------------------------------------------------------------
# This needs to go more or less last to avoid conflict with other targets.
# -------------------------------------------------------------------------

$(BUILD_DIR)/%:
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)
	find -name '*.pyc' -delete

.PHONY: clean

# 
# DEPLOY += $(PANDA_KO)
# DEPLOY += $(SERVER)
# 
# deploy: $(DEPLOY)
# 	scp $^ root@172.23.252.202:/opt
# 
# .PHONY: deploy

