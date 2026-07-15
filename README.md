# RedefineIp-stub

Minimal stand-in "super-repo" -- receives repository_dispatch events from
mmu-stub, bumps the dependencies/mmu-stub submodule pointer, and
regenerates its own stub RTL. Used to test the full dependency-release ->
notify -> bump -> regenerate chain in isolation from real toolchain
concerns.
