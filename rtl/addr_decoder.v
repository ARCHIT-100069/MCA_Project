// ============================================================================
// addr_decoder.v -- data address decoder
// Owner : Phalak Sharma
//
// Maps a 16-bit data address onto the devices of the data side:
//   0x0000 - 0x00FF : data memory           -> sel_dmem, dmem_addr = addr[7:0]
//   0x0100          : output port (write)   -> sel_out
//   0x0101          : cycle counter (read)  -> sel_cycle
//   anything else   : unmapped              -> fault
// ============================================================================
`timescale 1ns / 1ps
`include "isa_defs.vh"

module addr_decoder (
    input  wire [15:0] addr,
    output wire        sel_dmem,
    output wire        sel_out,
    output wire        sel_cycle,
    output wire        fault,
    output wire [7:0]  dmem_addr
);
    assign sel_dmem  = (addr[15:8] == 8'h00);
    assign sel_out   = (addr == `IO_OUT);
    assign sel_cycle = (addr == `IO_CYCLE);
    assign fault     = ~(sel_dmem | sel_out | sel_cycle);
    assign dmem_addr = addr[7:0];
endmodule
