# Demo video: preparation guide and script

Presenter and recorder: **Kumar Sanu**. Length: **at most 5 minutes**.

The video must: state the project idea, name all five members, and show the prototype working.

---

## Part 1: Get ready (about 20 minutes, do this once)

### 1. Download the project

Go to https://github.com/ARCHIT-100069/MCA_Project, click the green **Code** button, then **Download ZIP**, and unzip it. If you use git:

```bash
git clone https://github.com/ARCHIT-100069/MCA_Project.git
```

### 2. Install the simulator, for the live test run

**Mac:**
```bash
brew install icarus-verilog
```

**Windows:**
1. Install Icarus Verilog from https://bleyer.org/icarus/ (the latest `iverilog-...-x64_setup.exe`). During setup, tick **"Add executable folder(s) to the user PATH"**.
2. Install Git for Windows (https://git-scm.com/download/win). It includes **Git Bash**, which runs the test script.
3. Install Python 3 (https://www.python.org/downloads/) and tick **"Add python.exe to PATH"**.

### 3. Test it once before recording

Open Terminal (Mac) or **Git Bash** (Windows) inside the project folder and run:

```bash
./scripts/run_all.sh
```

It should end with `ALL TESTS PASSED`. On Windows, if `python3` is not found, run this first:

```bash
alias python3=python
```

**If it will not run on your laptop, don't worry.** During the video, open `docs/evidence/simulation_log.txt` and scroll to the bottom instead. It is the saved output of the same run.

### 4. Open these files, in this order, before you hit record

You can view them on the GitHub website or in VS Code. Make the text large (Ctrl/Cmd and +).

1. The GitHub repo page (README)
2. `docs/diagrams/harvard_block_diagram.png`
3. `rtl/cpu_core.v`
4. `rtl/instr_mem.v`, `rtl/data_mem.v`, `rtl/addr_decoder.v`, `rtl/rw_control.v`
5. `docs/diagrams/vonneumann_block_diagram.png`
6. `programs/bubble_sort.asm`
7. Terminal / Git Bash in the project folder
8. `docs/evidence/waveform_sum_array.png`
9. `docs/evidence/cpi_vs_memfraction.png`
10. `docs/evidence/results_table.md`

### 5. Set up the screen recorder

- **Mac:** press **Cmd + Shift + 5**, choose **Record Entire Screen**, and set **Options → Microphone** to the built-in mic.
- **Windows:** use **Snipping Tool → Record** (Windows 11), or **OBS Studio** (free, https://obsproject.com): add a "Display Capture" source and turn on the mic.
- Close notifications (WhatsApp, email) and quit other apps.
- Do one 10-second test recording and check that your voice is clear.

---

## Part 2: The script (read this while recording)

About 650 words, which takes about 4.5 minutes at a normal pace. **Bold** lines tell you what to show.

### 0:00 to 0:35 Introduction
**[Show: GitHub repo page]**

> Hello. This is our project for Modern Computer Architecture: Project 9, **Instruction and Data Memory Hierarchy**.
> Our team members are **Archit Gosain**, **Phalak Sharma**, **Mukund Mangla**, **Jatin**, and me, **Kumar Sanu**.
>
> The idea: a processor needs two things from memory, its instructions and its data. If both share one memory port, every load or store blocks the next instruction fetch. This is the Von Neumann bottleneck. We built a **Harvard** memory organization in Verilog, with separate instruction and data memories, and compared it with a shared-memory machine that uses the **same processor**.

### 0:35 to 1:25 The processor and Harvard design (Archit's part)
**[Show: harvard_block_diagram.png]**

> This is our Harvard design. Archit, our team lead, designed the processor, which we call MH-16. It is a 16-bit, single-cycle processor with a program counter, decoder, eight registers and an ALU.
>
> On the left is the core. The green path is the instruction path, going to the instruction memory. The orange path is the data path, going to the data memory and I/O.

**[Show: rtl/cpu_core.v, scroll to the module ports]**

> The key point is that the core has an instruction port, a data port and a **stall** input. That lets us plug the exact same core into both memory systems, so any difference we measure comes only from the memory organization. In the Harvard design the stall is always zero, so every instruction finishes in one clock cycle.

### 1:25 to 2:15 The memory subsystem (Phalak's part)
**[Show: instr_mem.v, then addr_decoder.v, then rw_control.v]**

> Phalak, our co-lead, built the memory subsystem. The instruction memory is a 256-word ROM. The data memory is a 256-word RAM, and each has its own port.
>
> The address decoder maps data addresses: zero to FF is the data RAM, 100 hex is an output port, and 101 is a cycle counter. Anything else raises a bus error.
>
> The read/write control only lets a write through when the instruction actually commits, so a stalled store can never write twice.

**[Show: vonneumann_block_diagram.png]**

> For comparison, this is the baseline: one unified memory with a single port. An arbiter has two states, FETCH and DATA, so every load or store takes two cycles instead of one.

### 2:15 to 2:50 Assembler and programs (Jatin's part)
**[Show: programs/bubble_sort.asm]**

> Jatin wrote an assembler in Python and six test programs. They range from Fibonacci, which almost never touches memory, to memcpy and bubble sort, which do a lot of loads and stores. Each program lists its expected outputs, so the testbench can check results automatically.

### 2:50 to 3:45 Live simulation (Mukund's part)
**[Show: Terminal. Type `./scripts/run_all.sh` and press Enter]**

> Mukund built our verification. This script assembles every program and runs all the tests. The system testbench runs the **same program on both machines at the same time**. It checks every output, checks that both machines halt, and checks that their final memories are identical.

**[Wait for `ALL TESTS PASSED` and point at the summary table]**

> All tests pass. Look at the cycle counts: bubble sort takes 301 cycles on the Harvard machine and 405 on the shared-memory machine.

**[Show: waveform_sum_array.png]**

> In this waveform, the blue Harvard signals show the load happening in the same cycle as the instruction fetch. On the orange shared-memory side, the stall goes high and the program counter stays at 4 for two cycles while the memory serves the data.

### 3:45 to 4:35 Results and synthesis (my part)
**[Show: cpi_vs_memfraction.png]**

> I worked on the diagrams, the synthesis and the results. This chart shows cycles per instruction against the fraction of instructions that are loads or stores. The Harvard machine stays at exactly 1. The shared machine follows the line CPI equals 1 plus that fraction, up to 1.56. So the Harvard design is up to **1.56 times faster**, and our measurements match the theory exactly.

**[Show: README "Synthesis" link or the docs/synthesis folder]**

> I also synthesized both designs with Yosys for a Xilinx FPGA. Synthesis found a real problem: a combinational loop in our first shared-memory design. We fixed it by adding a memory address register.

### 4:35 to 5:00 Closing
**[Show: README, scroll to "Phase II plan"]**

> In Phase II we will add a shared lower-level main memory behind small instruction and data caches, and measure hit rates and timing on an FPGA.
> Thank you for watching. This was Archit, Phalak, Mukund, Jatin and Kumar.

---

## Part 3: After recording

1. Watch it once. Check that it is **under 5:00**, all **five names** are clearly said, and the voice is audible.
2. To trim the start or end: on Mac, open the file in QuickTime and use **Edit → Trim**. On Windows, use the Photos / Clipchamp editor.
3. Upload to **YouTube**: Create → Upload video, then set Visibility to **Unlisted**. Title: *MCA Project 9 – Instruction and Data Memory Hierarchy (Phase I Demo)*.
   Or upload to **Google Drive** and set **Share → Anyone with the link → Viewer**.
4. Open the link in a private/incognito window to confirm it plays without signing in.
5. Send the link to Archit, who adds it to the repo and submits the form.

## Checklist

- [ ] Under 5 minutes
- [ ] Project idea stated at the start
- [ ] All five names said: Archit Gosain, Phalak Sharma, Mukund Mangla, Jatin, Kumar Sanu
- [ ] Prototype shown working (`ALL TESTS PASSED` or the simulation log)
- [ ] Link works for anyone
