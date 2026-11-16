# Prototype demo video: script (at most 5 minutes)

Owner: Kumar Sanu (recording and editing). Every member speaks their own part.

Record the screen with QuickTime (File > New Screen Recording) or OBS. Keep the terminal font large. Upload to YouTube (Unlisted) or Google Drive ("Anyone with the link can view"), then paste the link into [video.md](video.md) and the README.

| Time | Speaker | On screen | What to say |
|---|---|---|---|
| 0:00-0:40 | **Archit Gosain** | README top | "Hi, we are team ___: Archit Gosain, Phalak Sharma, Mukund Mangla, Jatin and Kumar Sanu. Our project is Project 9, Instruction and Data Memory Hierarchy. The idea: a processor needs instructions and data from memory. If both share one memory port, a load or store blocks the next instruction fetch. We built a Harvard organization with separate instruction and data memories, and compared it with a shared-memory machine built around the same processor." |
| 0:40-1:30 | **Archit Gosain** | `docs/diagrams/harvard_block_diagram.png`, then `rtl/cpu_core.v` | "This is our 16-bit processor, MH-16. It has a program counter, decoder, eight registers and an ALU. The core has an instruction port, a data port and a stall input, so the same core plugs into both memory systems. In the Harvard top the stall is always zero." |
| 1:30-2:20 | **Phalak Sharma** | `rtl/instr_mem.v`, `rtl/addr_decoder.v`, `rtl/rw_control.v`, then `vonneumann_block_diagram.png` | "I built the memory subsystem. The instruction memory is a ROM and the data memory a RAM, each with its own port. The address decoder maps data addresses: 0 to FF is RAM, 100 is the output port, 101 is a cycle counter. Read/write control only lets a write through when the instruction commits. The baseline has one unified memory, and an arbiter with FETCH and DATA states, so every load or store needs two cycles." |
| 2:20-3:00 | **Jatin** | `programs/bubble_sort.asm`, run `python3 scripts/asm.py programs/bubble_sort.asm build/programs` | "I wrote an assembler in Python and six test programs, from Fibonacci, which almost never touches memory, to memcpy and bubble sort, which do. Each program lists its expected outputs so the testbench can check them automatically." |
| 3:00-3:50 | **Mukund Mangla** | run `./scripts/run_all.sh` live, then the waveform PNG | "Our testbench runs the same program on both machines together and checks the outputs, that both halt, and that the final memories are identical. Everything passes. In the waveform, on the Harvard side the load and the fetch happen in the same cycle. On the shared side the PC stays at 4 for two cycles while the memory serves the data." |
| 3:50-4:40 | **Kumar Sanu** | `docs/evidence/cpi_vs_memfraction.png`, `cycles_comparison.png`, `docs/synthesis/` | "Results: the Harvard machine always has CPI 1. The shared machine's CPI is exactly 1 plus the fraction of loads and stores, up to 1.56. So Harvard is up to 1.56 times faster. I also synthesized both designs with Yosys for a Xilinx 7-series FPGA and drew the block diagrams." |
| 4:40-5:00 | **Phalak Sharma** | README "Phase II plan" | "In Phase II we will add a shared lower-level main memory behind small instruction and data caches, and measure hit rates and timing on an FPGA. Thank you." |

Checklist before uploading:

- [ ] Under 5:00
- [ ] All five names said clearly in the first 40 seconds
- [ ] Project idea stated
- [ ] Live simulation run shown (ALL TESTS PASSED visible)
- [ ] Link set to viewable by anyone
