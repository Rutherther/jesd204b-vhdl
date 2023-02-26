export ROOT := $(shell pwd)
SIMDIR := $(ROOT)/sim
export SRCDIR := $(ROOT)/src
TBDIR := $(ROOT)/testbench
WORKDIR := $(ROOT)/work
VHDLEX := vhd

#####################################################
#                                                   #
#                 Top level entity                  #
#                                                   #
#####################################################
export TOP_ENTITY := frame_alignment
export TOP_ENTITY_VHDL := $(SRCDIR)/$(TOP_ENTITY).$(VHDLEX)
TESTBENCH ?= $(TOP_ENTITY)_tb # default

WAVEFORM_VIEWER := gtkwave

COMPILER := ghdl
COMPILER_FLAGS := --std=08 --workdir=$(WORKDIR)

STOP_TIME ?= 1000ns
WAVEFORM_FILE ?= $(SIMDIR)/out.ghw

RUN_FLAGS := --stop-time=$(STOP_TIME) --wave=$(WAVEFORM_FILE) --stats

TBSOURCES := $(wildcard $(TBDIR)/*.$(VHDLEX)) $(wildcard $(TBDIR)/**/*.$(VHDLEX))
export SOURCES := $(wildcard $(SRCDIR)/*.$(VHDLEX)) $(wildcard $(SRCDIR)/**/*.$(VHDLEX))
ALL_SOURCES := $(SOURCES) $(TBSOURCES)

EXECUTABLE := $(SIMDIR)/$(TESTBENCH)

.PHONY: all clean

import: $(WORKDIR) $(ALL_SOURCES)
	$(COMPILER) -i $(COMPILER_FLAGS) $(ALL_SOURCES)

compile: $(SIMDIR) $(WORKDIR) $(ALL_SOURCES)
	@$(COMPILER) -i $(COMPILER_FLAGS) $(ALL_SOURCES)
	@$(COMPILER) -m -o $(EXECUTABLE) $(COMPILER_FLAGS) $(TESTBENCH)

all: compile run view

$(TBDIR)/$(TESTBENCH): compile

$(WORKDIR):
	@mkdir $(WORKDIR)

$(SIMDIR):
	@mkdir $(SIMDIR)

run: $(TBDIR)/$(TESTBENCH) $(SIMDIR)
	@$(EXECUTABLE) $(RUN_FLAGS)

view:
	gsettings set com.geda.gtkwave reload 1
	gsettings set com.geda.gtkwave reload 0
	pgrep $(WAVEFORM_VIEWER) || $(WAVEFORM_VIEWER) $(WAVEFORM_FILE) &

clean:
	@$(RM) -rf $(SIMDIR)
	@$(RM) -rf $(WORKDIR)

