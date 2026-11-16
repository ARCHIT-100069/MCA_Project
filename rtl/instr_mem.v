// ============================================================================
// instr_mem.v -- instruction memory (read-only, Harvard instruction path)
// Owner : Phalak Sharma
//
// 256 x 16-bit ROM with an asynchronous read port. Unused words hold HALT
// (0xF000) so a program that runs off its end stops safely.
// The program image is loaded from a hex file produced by scripts/asm.py.
// ============================================================================
`timescale 1ns / 1ps
module instr_mem #(
    parameter AW        = 8,
    parameter INIT_FILE = ""
) (
    input  wire [AW-1:0] addr,
    output wire [15:0]   instr
);
    localparam DEPTH = (1 << AW);

    reg [15:0] rom [0:DEPTH-1];
    integer i;

    initial begin
`ifdef SYNTHESIS
        // Synthesis: full 256-word image copied here by docs/synthesis/run_yosys.sh
        // (kept separate from the loop below, which Yosys would let override it).
        $readmemh("build/synth_imem.hex", rom);
`else
        for (i = 0; i < DEPTH; i = i + 1)
            rom[i] = 16'hF000;          // HALT
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, rom);
`endif
    end

    assign instr = rom[addr];
endmodule
