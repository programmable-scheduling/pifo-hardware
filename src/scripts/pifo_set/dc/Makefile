#=======================================================================
# 6.375 Makefile for dc-synth
#-----------------------------------------------------------------------
#
# This makefile will use Cadence RTL Compiler to synthesize
# your RTL into a gate-level verilog netlist.
#

default : all

#basedir = $(PROJ_DIR)

#--------------------------------------------------------------------
# Sources
#--------------------------------------------------------------------

include Makefile.common

# get source verilog filenames and toplevel module name
include Makefile.include

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

build_suffix   := $(shell date +%Y-%m-%d_%H-%M)
build_dir      := build-$(build_suffix)
curr_build_dir := current
curr_build_dir_tstamp := current/timestamp.txt

synth_tcl      := synth.tcl
libs_tcl       := libs.tcl
synth_sdc      := synth.sdc
scripts        := $(synth_tcl) $(libs_tcl) $(synth_sdc)
makegen_tcl    := make_generated_vars.tcl

synth_vars = \
	set DESIGN_RTL_DIR  { $(RTL_FILES_ROOT) }; \
	set DESIGN_RTL      { $(RTL_FILES) }; \
	set DESIGN_TOPLEVEL $(TOPLEVEL); \
	set SYNTH_LIB       { $(SYNTH_LIB) }; \

define new-build-dir-cmds
	mkdir $(build_dir)
	rm -f $(curr_build_dir)
	ln -s $(build_dir) $(curr_build_dir)
	cp $(scripts) $(curr_build_dir)
	echo '$(synth_vars)' > $(curr_build_dir)/$(makegen_tcl)
endef

new-build-dir :
	$(new-build-dir-cmds)

%.v : 
	true

synth : $(vsrcs) $(scripts) 
	$(new-build-dir-cmds)
	cd $(curr_build_dir); \
	dc_shell-xg-t $(OPTS) < $(synth_tcl) | tee dc.log; \


junk += 

.PHONY : synth new-build-dir

#--------------------------------------------------------------------
# Default make target
#--------------------------------------------------------------------

all : synth

#--------------------------------------------------------------------
# Clean up
#--------------------------------------------------------------------

clean :
	rm -rf build-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]-[0-9][0-9] \
	       current $(junk) *~ \#*
