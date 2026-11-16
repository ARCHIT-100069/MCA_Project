#!/usr/bin/env bash
# run_all.sh -- assemble every program, run unit tests and the system test
# Owner: Mukund Mangla
#
#   ./scripts/run_all.sh            # everything
#   ./scripts/run_all.sh --vcd      # also dump build/waves.vcd for sum_array
#
# Needs Icarus Verilog (iverilog, vvp) and python3.
set -euo pipefail
cd "$(dirname "$0")/.."

PROGRAMS="fibonacci sum_array vector_add bubble_sort memcpy io_decode"
RTL="rtl/alu.v rtl/regfile.v rtl/program_counter.v rtl/cpu_core.v \
     rtl/instr_mem.v rtl/data_mem.v rtl/unified_mem.v rtl/addr_decoder.v \
     rtl/rw_control.v rtl/perf_counters.v rtl/harvard_top.v rtl/vonneumann_top.v"
IV="iverilog -g2012 -Wall -I rtl"

mkdir -p build/programs
rm -f build/results.csv
echo "program,instructions,loads,stores,harvard_cycles,vonneumann_cycles,overlap_cycles,status" > build/results.csv

echo "== Assembling programs"
for p in $PROGRAMS; do python3 scripts/asm.py "programs/$p.asm" build/programs; done

echo "== Unit tests"
$IV -s tb_memories   -o build/tb_memories.vvp   rtl/instr_mem.v rtl/data_mem.v rtl/unified_mem.v tb/tb_memories.v
vvp -n build/tb_memories.vvp
$IV -s tb_decoder_rw -o build/tb_decoder_rw.vvp rtl/addr_decoder.v rtl/rw_control.v tb/tb_decoder_rw.v
vvp -n build/tb_decoder_rw.vvp

echo "== System test (Harvard vs Von Neumann)"
$IV -s tb_system -o build/tb_system.vvp $RTL tb/tb_system.v
for p in $PROGRAMS; do vvp -n build/tb_system.vvp +PROG="$p"; done

if [[ "${1:-}" == "--vcd" ]]; then
    vvp -n build/tb_system.vvp +PROG=sum_array +VCD +NOCSV > /dev/null
    echo "Waveform written to build/waves.vcd (open with GTKWave)"
fi

echo "== Summary"
if command -v column > /dev/null; then column -s, -t build/results.csv; else tr ',' '\t' < build/results.csv; fi
if grep -q FAIL build/results.csv; then echo "SOME TESTS FAILED"; exit 1; fi
echo "ALL TESTS PASSED"
