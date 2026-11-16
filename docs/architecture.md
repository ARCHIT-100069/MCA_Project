# Architecture notes

Owner: Archit Gosain

## Why the core is memory-agnostic

`cpu_core.v` has an instruction port, a data port and a `stall` input. When `stall` is high, nothing commits: the PC holds and the register file does not write. Both top levels use the identical core, so any difference in cycles comes only from the memory organization.

## Harvard top (`harvard_top.v`)

- `instr_mem` is addressed by the PC and returns the instruction in the same cycle (asynchronous read).
- The core's data address goes through `addr_decoder`, and `rw_control` produces `dmem_we/re` and `out_we`.
- `stall` is tied to 0. Each instruction takes 1 cycle, so CPI = 1.
- `overlap_cycles` counts cycles where a fetch and a data access happen together. It always equals loads + stores.

## Shared-memory top (`vonneumann_top.v`)

A one-bit FSM decides who owns the single memory port.

| State | Port address | What happens |
|---|---|---|
| FETCH | `{0, pc}` | Instruction is read and decoded. Non-memory instructions commit. If it is LW/SW: `ir <= instruction`, `mar <= data address`, stall, go to DATA |
| DATA | `{1, mar}` | Core executes `ir`, data is read or written, commit, go to FETCH |

The MAR (memory address register) was added after Yosys reported a combinational loop: memory output → instruction → ALU → data address → memory address. Because the port address now comes only from registers (`pc` or `mar`), that loop is gone.

## Timing per instruction

| Instruction | Harvard cycles | Shared cycles |
|---|---|---|
| ALU / addi / li / branch / jump / halt | 1 | 1 |
| lw / sw (including `out`) | 1 | 2 |

So `CPI_shared = 1 + (loads + stores) / instructions`, which the measurements match exactly.

## Data address map (`addr_decoder.v`)

| Address | Device | Access |
|---|---|---|
| 0x0000-0x00FF | data memory (256 words) | read / write |
| 0x0100 | output port | write only |
| 0x0101 | cycle counter (low 16 bits) | read only |
| other | none | bus error |

`rw_control.v` gates every write with `commit`, so a store that is stalled for a cycle writes exactly once.
