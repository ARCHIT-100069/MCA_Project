// ============================================================================
// perf_counters.v -- performance counters used for the architecture comparison
// Owner : Archit Gosain
//
// Counts, until the core halts:
//   cycles         : clock cycles spent running
//   instret        : instructions retired
//   loads / stores : committed data reads / writes
//   ifetch         : cycles in which the instruction port was used
//   overlap        : cycles in which an instruction fetch AND a data access
//                    happened together (only possible with Harvard ports)
// CPI = cycles / instret.
// ============================================================================
`timescale 1ns / 1ps
module perf_counters (
    input  wire        clk,
    input  wire        rst,
    input  wire        running,      // core not halted
    input  wire        commit,
    input  wire        load,
    input  wire        store,
    input  wire        fetch,
    input  wire        overlap,
    output reg  [31:0] cycles,
    output reg  [31:0] instret,
    output reg  [31:0] loads,
    output reg  [31:0] stores,
    output reg  [31:0] ifetch,
    output reg  [31:0] overlap_cycles
);
    always @(posedge clk) begin
        if (rst) begin
            cycles         <= 32'd0;
            instret        <= 32'd0;
            loads          <= 32'd0;
            stores         <= 32'd0;
            ifetch         <= 32'd0;
            overlap_cycles <= 32'd0;
        end else if (running) begin
            cycles <= cycles + 32'd1;
            if (commit)          instret        <= instret + 32'd1;
            if (commit & load)   loads          <= loads   + 32'd1;
            if (commit & store)  stores         <= stores  + 32'd1;
            if (fetch)           ifetch         <= ifetch  + 32'd1;
            if (overlap)         overlap_cycles <= overlap_cycles + 32'd1;
        end
    end
endmodule
