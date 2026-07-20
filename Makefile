
project = redefine

TARGET ?= RedefineIP

# Toolchains and tools
MILL = ./../playground/mill

-include ./../playground/Makefile.include
-include cd.config

RTL_TARGET ?= rtl

# Targets
synrtl:## Generates Verilog code from Chisel sources (output to ./generated_sv_dir)
	$(MILL) $(project).runMain $(project).synthRtlLazyMain $(TARGET)

rtl:## Generates Verilog code from Chisel sources (output to ./generated_sv_dir)
	$(MILL) $(project).runMain $(project).rtlLazyMain $(TARGET)

.PHONY: rtl-dispatch
rtl-dispatch: ## Used by CD: runs whichever target cd.config's RTL_TARGET names (default: rtl; synrtl is the synthesis-oriented variant)
	$(MAKE) $(RTL_TARGET) TARGET=$(TARGET)


.PHONY: verilate 
verilate: check-env ## Generate Verilator simulation executable for  TARGET = RV32 (default) or RV64 or RV32RoCC or RV64RoCC 
	$(MILL) $(project).runMain $(project).TestLazyMain $(TARGET)

.PHONY: check-env
check-env:
ifndef RISCV
	$(error RISCV environment variable is not defined)
endif	
