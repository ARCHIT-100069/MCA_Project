// ============================================================================
// cpu_core.v -- MH-16 single-cycle processor core
// Owner : Archit Gosain
//
// The core is memory-organization agnostic. It exposes:
//   * an instruction port  (imem_addr -> instr)
//   * a data port          (dmem_addr / dmem_wdata / dmem_re / dmem_we -> dmem_rdata)
//   * a `stall` input that blocks commit for the current cycle
//
// In the Harvard top level both ports go to separate memories and `stall` is
// tied low, so every instruction completes in one clock. In the Von Neumann
// top level both ports share one memory and an arbiter raises `stall` while
// the shared port is busy fetching an instruction that also needs data.
// ============================================================================
`timescale 1ns / 1ps
`include "isa_defs.vh"

module cpu_core #(
    parameter IAW = 8                       // instruction address width
) (
    input  wire           clk,
    input  wire           rst,
    input  wire           stall,            // 1 = do not commit this cycle

    // Instruction port
    output wire [IAW-1:0] imem_addr,
    input  wire [15:0]    instr,

    // Data port (raw requests; the top level qualifies them with commit)
    output wire           dmem_re,
    output wire           dmem_we,
    output wire [15:0]    dmem_addr,
    output wire [15:0]    dmem_wdata,
    input  wire [15:0]    dmem_rdata,

    // Status
    output wire           commit,           // instruction retires this cycle
    output wire           is_load,          // decoded instruction is LW
    output wire           is_store,         // decoded instruction is SW
    output reg            halted
);
    // ------------------------------------------------------------------ decode
    wire [3:0]  op    = instr[15:12];
    wire [2:0]  rd    = instr[11:9];
    wire [2:0]  rs    = instr[8:6];
    wire [2:0]  rt    = instr[5:3];
    wire [2:0]  funct = instr[2:0];
    wire [15:0] imm6  = {{10{instr[5]}}, instr[5:0]};
    wire [15:0] imm9  = {7'd0, instr[8:0]};

    wire op_alu  = (op == `OP_ALU);
    wire op_addi = (op == `OP_ADDI);
    wire op_lw   = (op == `OP_LW);
    wire op_sw   = (op == `OP_SW);
    wire op_beq  = (op == `OP_BEQ);
    wire op_bne  = (op == `OP_BNE);
    wire op_li   = (op == `OP_LI);
    wire op_j    = (op == `OP_J);
    wire op_halt = (op == `OP_HALT);

    assign is_load  = op_lw  & ~halted;
    assign is_store = op_sw  & ~halted;
    assign commit   = ~stall & ~halted & ~rst;

    // ---------------------------------------------------------- register file
    wire [15:0] ra, rb;
    wire        reg_we;
    wire [15:0] wb_data;

    regfile u_rf (
        .clk     (clk),
        .rst     (rst),
        .we      (reg_we),
        .waddr   (rd),
        .wdata   (wb_data),
        .raddr_a (rs),
        .raddr_b (op_alu ? rt : rd),   // SW stores rd, branches compare rd/rs
        .rdata_a (ra),
        .rdata_b (rb)
    );

    // -------------------------------------------------------------------- ALU
    wire [15:0] alu_b     = op_alu ? rb : imm6;
    wire [2:0]  alu_funct = op_alu ? funct : `F_ADD;
    wire [15:0] alu_y;

    alu u_alu (.a(ra), .b(alu_b), .funct(alu_funct), .y(alu_y));

    // ------------------------------------------------------------ data access
    assign dmem_addr  = alu_y;          // rs + imm6 for LW / SW
    assign dmem_wdata = rb;             // value of rd
    assign dmem_re    = is_load;
    assign dmem_we    = is_store;

    // -------------------------------------------------------------- writeback
    assign reg_we  = commit & (op_alu | op_addi | op_lw | op_li);
    assign wb_data = op_lw ? dmem_rdata :
                     op_li ? imm9       : alu_y;

    // -------------------------------------------------------------- next PC
    wire [IAW-1:0] pc;
    wire [IAW-1:0] pc_plus1  = pc + 1'b1;
    wire [IAW-1:0] br_target = pc_plus1 + imm6[IAW-1:0];
    wire           equal     = (ra == rb);
    wire           take_br   = (op_beq & equal) | (op_bne & ~equal);

    wire [IAW-1:0] next_pc = op_halt ? pc :
                             op_j    ? instr[IAW-1:0] :
                             take_br ? br_target : pc_plus1;

    program_counter #(.AW(IAW)) u_pc (
        .clk     (clk),
        .rst     (rst),
        .en      (commit),
        .next_pc (next_pc),
        .pc      (pc)
    );

    assign imem_addr = pc;

    // ------------------------------------------------------------------ halt
    always @(posedge clk) begin
        if (rst)
            halted <= 1'b0;
        else if (commit && op_halt)
            halted <= 1'b1;
    end
endmodule
