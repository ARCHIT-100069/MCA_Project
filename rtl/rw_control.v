// ============================================================================
// rw_control.v -- read/write control for the data side
// Owner : Phalak Sharma
//
// Combines the core's raw request (re / we), the commit signal and the address
// decoder's select lines into the per-device enables, and multiplexes the
// read data returned to the core.
//
//  * A write only reaches a device when the instruction actually commits, so a
//    stalled store can never write twice.
//  * Writes to read-only or unmapped addresses are dropped and flagged.
// ============================================================================
`timescale 1ns / 1ps
module rw_control (
    input  wire        re,            // core wants to read
    input  wire        we,            // core wants to write
    input  wire        commit,        // instruction retires this cycle
    input  wire        sel_dmem,
    input  wire        sel_out,
    input  wire        sel_cycle,
    input  wire        fault,
    input  wire [15:0] dmem_rdata,
    input  wire [15:0] cycle_count,

    output wire        dmem_re,
    output wire        dmem_we,
    output wire        out_we,
    output wire        bus_error,
    output wire [15:0] rdata
);
    assign dmem_re   = re & sel_dmem;
    assign dmem_we   = we & sel_dmem & commit;
    assign out_we    = we & sel_out  & commit;
    assign bus_error = commit & ((re | we) & fault | (we & sel_cycle) | (re & sel_out));

    assign rdata = (re & sel_dmem ) ? dmem_rdata  :
                   (re & sel_cycle) ? cycle_count : 16'h0000;
endmodule
