#!/usr/bin/env bash
# run_yosys.sh -- synthesize both organizations for a Xilinx 7-series target
# Owner: Kumar Sanu
#
# Needs Yosys. Run ./scripts/run_all.sh first so the program hex files exist.
# Reports (LUTs, flip-flops, distributed RAM) are written next to
# this script.
set -euo pipefail
cd "$(dirname "$0")/../.."
OUT=docs/synthesis
RTL="rtl/alu.v rtl/regfile.v rtl/program_counter.v rtl/cpu_core.v rtl/instr_mem.v \
     rtl/data_mem.v rtl/unified_mem.v rtl/addr_decoder.v rtl/rw_control.v \
     rtl/perf_counters.v rtl/harvard_top.v rtl/vonneumann_top.v"
PROG=build/programs/bubble_sort
# instr_mem.v loads this file when the SYNTHESIS macro is defined.
cp "$PROG.imem.hex" build/synth_imem.hex

for top in harvard_top vonneumann_top; do
    yosys -q -l "$OUT/${top}_xc7.log" -p "
        read_verilog -DSYNTHESIS -I rtl $RTL;
        synth_xilinx -top $top -flatten;
        tee -o $OUT/${top}_xc7_stat.txt stat" > /dev/null
    echo "== $top"
    grep -E "LUT|FD|RAM|CARRY|MUXF|cells" "$OUT/${top}_xc7_stat.txt" | sed 's/^ */  /'
done
