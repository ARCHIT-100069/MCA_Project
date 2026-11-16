# Instruction and Data Memory Hierarchy

**Modern Computer Architecture, Project 9 (Memory Organization), Phase I**

Team: **Archit Gosain** (lead), **Phalak Sharma** (co-lead), **Mukund Mangla**, **Jatin**, **Kumar Sanu**

We built a Harvard-style memory organization in Verilog, with separate instruction and data memories, a program counter, a data address decoder and read/write control. We connected it to a small 16-bit processor of our own (MH-16). We then attached the **same** processor to a single shared memory (Von Neumann baseline) and ran the same six programs on both machines side by side.

| | Harvard (proposed) | Shared memory (baseline) |
|---|---|---|
| Memories | `instr_mem` ROM 256x16 + `data_mem` RAM 256x16 | one `unified_mem` 512x16, single port |
| Fetch + load/store in one cycle | yes | no, the port arbiter stalls for one cycle |
| Measured CPI | **1.000** on every program | **1 + f_mem** (1.020 to 1.562) |
| Speed-up of Harvard | 1.02x to **1.56x** | |

- **Report (IEEE format):** [docs/report/phase1_report.pdf](docs/report/phase1_report.pdf)
- **Prototype video (Phase I demo):** [https://drive.google.com/file/d/1nOItqqYGjEf7bIux0CEANo1jN_VVqIMC/view?usp=sharing](https://drive.google.com/file/d/1nOItqqYGjEf7bIux0CEANo1jN_VVqIMC/view?usp=sharing)
- **Block diagrams:** [Harvard](docs/diagrams/harvard_block_diagram.png), [shared memory](docs/diagrams/vonneumann_block_diagram.png)
- **Waveform:** [docs/evidence/waveform_sum_array.png](docs/evidence/waveform_sum_array.png)
- **Results:** [docs/evidence/results_table.md](docs/evidence/results_table.md), [CPI chart](docs/evidence/cpi_vs_memfraction.png), [cycles chart](docs/evidence/cycles_comparison.png)
- **Synthesis (Yosys, Xilinx 7-series):** [docs/synthesis/](docs/synthesis/)

## Repository layout

```
rtl/                    synthesizable Verilog
  isa_defs.vh           MH-16 opcodes, ALU codes, data address map
  cpu_core.v            single-cycle core (PC, decode, regfile, ALU, next-PC)
  program_counter.v     PC register with commit enable
  alu.v, regfile.v      datapath blocks
  instr_mem.v           instruction memory (ROM)          -- Harvard instruction path
  data_mem.v            data memory (RAM)                 -- Harvard data path
  addr_decoder.v        data address decoder (RAM / OUT port / cycle counter / fault)
  rw_control.v          read/write enables, read-data mux, bus-error detection
  unified_mem.v         single-port shared memory         -- baseline
  perf_counters.v       cycles, instructions, loads, stores, overlap counters
  harvard_top.v         proposed design (top level)
  vonneumann_top.v      baseline with FETCH/DATA port arbiter, IR and MAR
tb/
  tb_system.v           runs one program on BOTH machines and checks results
  tb_memories.v         unit test: instr_mem, data_mem, unified_mem
  tb_decoder_rw.v       unit test: addr_decoder + rw_control
programs/*.asm          6 benchmark programs (with expected outputs)
scripts/
  asm.py                two-pass MH-16 assembler -> hex images
  run_all.sh            assemble + all simulations + summary
  plot_waveform.py      VCD -> timing diagram PNG
  plot_results.py       results.csv -> charts + markdown table
docs/
  report/               IEEE report (HTML source + PDF)
  diagrams/             block diagrams (PNG/SVG) + generator
  evidence/             simulation log, waveform, charts, results table
  synthesis/            Yosys script and resource reports
  demo/                 demo video link and script
```

## How to run

You need [Icarus Verilog](https://steveicarus.github.io/iverilog/usage/installation.html) and Python 3. On macOS:

```sh
brew install icarus-verilog
./scripts/run_all.sh          # add --vcd to dump build/waves.vcd for GTKWave
```

The run ends with:

```
program      instructions  loads  stores  harvard_cycles  vonneumann_cycles  overlap_cycles  status
fibonacci    102           0      2       102             104                2               PASS
sum_array    87            16     2       87              105                18              PASS
vector_add   151           32     17      151             200                49              PASS
bubble_sort  301           64     40      301             405                104             PASS
memcpy       297           64     33      297             394                97              PASS
io_decode    16            4      5       16              25                 9               PASS
ALL TESTS PASSED
```

Figures (needs `pip install matplotlib`):

```sh
python3 scripts/plot_waveform.py build/waves.vcd docs/evidence/waveform_sum_array.png
python3 scripts/plot_results.py build/results.csv docs/evidence
python3 docs/diagrams/draw_diagrams.py docs/diagrams
```

Synthesis (needs Yosys): `./docs/synthesis/run_yosys.sh`. Report PDF (needs Google Chrome): `./docs/report/build_pdf.sh`.

## MH-16 instruction set (summary)

| Instruction | Meaning |
|---|---|
| `add/sub/and/or/xor/slt/sll/srl rd, rs, rt` | `rd = rs op rt` |
| `addi rd, rs, imm6` | `rd = rs + imm` (imm -32..31) |
| `lw rd, imm(rs)` / `sw rd, imm(rs)` | load / store data word `rs + imm` |
| `beq/bne rd, rs, label` | conditional branch |
| `li rd, imm9` | `rd = imm` (0..511) |
| `j label`, `halt` | jump, stop |
| `nop`, `mov rd, rs`, `out rd` | pseudo-instructions (`out` = `sw rd, 0(r7)` with r7 = 0x100) |

Data address map: `0x000-0x0FF` data memory, `0x100` output port (write), `0x101` cycle counter (read). Anything else raises a bus error.

## Team contributions

| Member | Role | Files |
|---|---|---|
| Archit Gosain | Lead: ISA, processor core, both top-level integrations, repository | `rtl/isa_defs.vh`, `rtl/cpu_core.v`, `rtl/alu.v`, `rtl/regfile.v`, `rtl/program_counter.v`, `rtl/perf_counters.v`, `rtl/harvard_top.v`, `rtl/vonneumann_top.v`, `README.md`, `docs/architecture.md` |
| Phalak Sharma | Co-lead: memory subsystem, IEEE report | `rtl/instr_mem.v`, `rtl/data_mem.v`, `rtl/unified_mem.v`, `rtl/addr_decoder.v`, `rtl/rw_control.v`, `docs/report/` |
| Mukund Mangla | Verification | `tb/`, `scripts/run_all.sh`, `scripts/plot_waveform.py`, `docs/evidence/simulation_log.txt`, `docs/evidence/waveform_sum_array.png` |
| Jatin | Assembler and benchmark programs | `scripts/asm.py`, `programs/` |
| Kumar Sanu | Diagrams, synthesis, results charts, demo video | `docs/diagrams/`, `docs/synthesis/`, `scripts/plot_results.py`, `docs/evidence/*.png` charts, `docs/demo/` |

## Phase II plan

Add the shared lower-level memory: a unified main memory with latency behind small split L1 instruction and data caches. Then measure hit rate, average memory access time and CPI, and get Vivado timing on an Artix-7.
