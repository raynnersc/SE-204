#
.PHONY: clean all simu_batch compile simu_gui info syn

export PATH:=/comelec/softs/bin:$(PATH)

VLOG = vlog
VSIM = vsim
SYN  = precision

TOPDIR = $(shell pwd)
TB_TOP = testbench_top
WORK_DIR = work

#VPATH := ${TOPDIR} ${TOPDIR}/..

# Whisbone interface sources
WSHBSRCDIR  = $(TOPDIR)/../wshb_if
WSHBSRC     = $(wildcard $(WSHBSRCDIR)/*.sv)
DEP         = $(patsubst $(WSHBSRCDIR)/%.sv,$(WORK_DIR)/.%.compiled,${WSHBSRC})

# Whishbone testbench sources
WSHBTBSRCDIR  = $(TOPDIR)/../wshb_if/testbench
WSHBTBSRC     = $(wildcard $(WSHBTBSRCDIR)/*.sv)
DEP          += $(patsubst $(WSHBTBSRCDIR)/%.sv,$(WORK_DIR)/.%.compiled,${WSHBTBSRC})

# Module sources
SRCDIR    = $(TOPDIR)/wb_bram
SRC       = $(SRCDIR)/wb_bram.sv
DEP      += $(patsubst $(SRCDIR)/%.sv,$(WORK_DIR)/.%.compiled,${SRC})

# Module testbench sources
TBDIR     = $(TOPDIR)/wb_bram_tb_src
TBSRC     = $(wildcard $(TBDIR)/*.sv)
DEP      += $(patsubst $(TBDIR)/%.sv,$(WORK_DIR)/.%.compiled,${TBSRC})

# Auxiliary files for synthesis
SYNDIR = $(TOPDIR)/wb_bram_syn_src
SYNSRC = $(wildcard $(SYNDIR)/*.sv)

# Repertoires et fichiers pour la synthèse
AREA_FILE   = wb_bram_area.log
TIMING_FILE   = wb_bram_timing.log


info:
	@echo "Les commandes possibles sont:"
	@echo "make compile    : compilation des codes (module à tester et testbenchs)"
	@echo "make simu_batch : simulation en mode terminal, avec simple affichage des résultats des tests"
	@echo "make simu_gui   : simulation en mode graphique pour faire un debug de votre code."
	@echo "make all        : équivalent à simu_gui"
	@echo "make syn        : test de synthèse de votre module wb_bram"
	@echo "make info       : ce message"
	@echo "make clean      : nettoyage des fichiers inutiles"

all: simu_batch

simu_batch: compile
	cd $(WORK_DIR) ; $(VSIM)  -suppress 7033 -batch -t 1ps -lib work $(TB_TOP) -do "run -all ; quit"

simu_gui: compile
	cd $(WORK_DIR); $(VSIM) -suppress 7033 -t 1ps -lib work $(TB_TOP)

compile: $(DEP)

$(WORK_DIR)/.%.compiled: $(WSHBTBSRCDIR)/%.sv | $(WORK_DIR)/work
	cd $(WORK_DIR) ; $(VLOG)  +acc $<
	touch $@

$(WORK_DIR)/.%.compiled: $(WSHBSRCDIR)/%.sv | $(WORK_DIR)/work
	cd $(WORK_DIR) ; $(VLOG)  +acc $<
	touch $@

$(WORK_DIR)/.%.compiled: $(TBDIR)/%.sv | $(WORK_DIR)/work
	cd $(WORK_DIR) ; $(VLOG)  +acc $<
	touch $@

$(WORK_DIR)/.%.compiled: $(SRCDIR)/%.sv | $(WORK_DIR)/work
	cd $(WORK_DIR) ; $(VLOG)  +acc $<
	touch $@

$(WORK_DIR)/.%.compiled: $(BRDGSRCDIR)/%.sv | $(WORK_DIR)/work
	cd $(WORK_DIR) ; $(VLOG)  +acc $<
	touch $@

syn: $(WORK_DIR)/$(AREA_FILE)

$(WORK_DIR)/$(AREA_FILE): $(WSHBSRC) $(SRC) $(WORK_DIR)
	cd $(WORK_DIR) && TOP_MODULE=wrapper HDL_FILES="$(SYNSRC) $(SRC) $(WSHBSRC)" make -f ../Makefile_syn pr

$(WORK_DIR):
	mkdir $(WORK_DIR)

$(WORK_DIR)/work: $(WORK_DIR)
	cd $(WORK_DIR) ; vlib work

clean:
	rm -rf $(WORK_DIR)

# Les interfaces on besoin du générateur de paquets
$(WORK_DIR)/.wshb_m.compiled:$(WORK_DIR)/.packet.compiled
$(WORK_DIR)/.wshb_s.compiled:$(WORK_DIR)/.packet.compiled

