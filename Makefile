# Stub Makefile -- same as mmu-stub, no real toolchain dependency.
-include cd.config
RTL_TARGET ?= rtl
TARGET ?= stub

.PHONY: rtl lazyrtl rtl-dispatch

rtl:
	@mkdir -p generated_sv_dir
	@echo "// stub top-level generated RTL, includes bumped submodule at:" > generated_sv_dir/stub.sv
	@echo "// $$(cat dependencies/mmu-stub/generated_sv_dir/stub.sv 2>/dev/null || echo '(submodule not yet initialized)')" >> generated_sv_dir/stub.sv
	@echo "stub rtl target -- wrote generated_sv_dir/stub.sv"

lazyrtl: rtl

rtl-dispatch:
	@$(MAKE) $(RTL_TARGET) TARGET=$(TARGET)
