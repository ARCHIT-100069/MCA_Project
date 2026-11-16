// ============================================================================
// isa_defs.vh -- MH-16 instruction set definitions
// Project 9 : Instruction and Data Memory Hierarchy
// Owner     : Archit Gosain (ISA + core)
//
// 16-bit instructions, 16-bit data, 8 general registers (R0 is always zero).
//
//   R-type : [15:12]=0000 [11:9]=rd [8:6]=rs [5:3]=rt [2:0]=funct
//   I-type : [15:12]=op   [11:9]=rd [8:6]=rs [5:0]=imm6 (signed)
//   LI     : [15:12]=0110 [11:9]=rd [8:0]=imm9 (unsigned)
//   J      : [15:12]=0111 [11:0]=target (absolute word address)
//   HALT   : [15:12]=1111
// ============================================================================
`ifndef MH16_ISA_DEFS_VH
`define MH16_ISA_DEFS_VH

// Opcodes
`define OP_ALU   4'h0   // rd = rs <funct> rt
`define OP_ADDI  4'h1   // rd = rs + imm6
`define OP_LW    4'h2   // rd = MEM[rs + imm6]
`define OP_SW    4'h3   // MEM[rs + imm6] = rd
`define OP_BEQ   4'h4   // if (rd == rs) pc = pc + 1 + imm6
`define OP_BNE   4'h5   // if (rd != rs) pc = pc + 1 + imm6
`define OP_LI    4'h6   // rd = zero_extend(imm9)
`define OP_J     4'h7   // pc = target
`define OP_HALT  4'hF   // stop the processor

// ALU function codes (R-type funct field)
`define F_ADD    3'd0
`define F_SUB    3'd1
`define F_AND    3'd2
`define F_OR     3'd3
`define F_XOR    3'd4
`define F_SLT    3'd5   // signed set-less-than
`define F_SLL    3'd6   // shift left by rt[3:0]
`define F_SRL    3'd7   // logical shift right by rt[3:0]

// Data address map (decoded by addr_decoder.v)
`define DMEM_BASE   16'h0000   // 0x0000 - 0x00FF : data memory (256 words)
`define IO_OUT      16'h0100   // write-only output port
`define IO_CYCLE    16'h0101   // read-only cycle counter

`endif
