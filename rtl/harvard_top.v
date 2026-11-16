// ============================================================================
// harvard_top.v -- Harvard memory organization (proposed design)
// Owner : Archit Gosain (integration)
//
//            +-------------+  imem_addr   +---------------+
//            |             |------------->|  instr_mem    |  instruction path
//            |             |<-------------|  (ROM 256x16) |
//            |  cpu_core   |  instr       +---------------+
//            |             |
//            |             |  dmem_addr   +--------------+   +------------+
//            |             |------------->| addr_decoder |-->| rw_control |
//            |             |  wdata/re/we +--------------+   +-----+------+
//            |             |<----------------------------------------+
//            +-------------+  rdata             |              |
//                                         +-----v------+   +---v----+
//                                         |  data_mem  |   | I/O    |
//                                         | (RAM 256x16)|  | out/cyc|
//                                         +------------+   +--------+
//
// Instruction and data memories have independent ports, so an instruction
// fetch and a load/store happen in the SAME clock cycle: CPI = 1.
// ============================================================================
`timescale 1ns / 1ps
module harvard_top #(
    parameter IMEM_INIT = "",
    parameter DMEM_INIT = ""
) (
    input  wire        clk,
    input  wire        rst,
    output wire        halted,
    output reg         out_valid,     // one-cycle pulse per write to IO_OUT
    output reg  [15:0] out_data,
    output reg         bus_error_seen,
    output wire [31:0] cycles,
    output wire [31:0] instret,
    output wire [31:0] loads,
    output wire [31:0] stores,
    output wire [31:0] ifetch,
    output wire [31:0] overlap_cycles
);
    // ------------------------------------------------------------------ core
    wire [7:0]  imem_addr;
    wire [15:0] instr;
    wire        core_re, core_we, commit, is_load, is_store;
    wire [15:0] core_addr, core_wdata, core_rdata;

    cpu_core #(.IAW(8)) u_core (
        .clk        (clk),
        .rst        (rst),
        .stall      (1'b0),               // separate ports: never stall
        .imem_addr  (imem_addr),
        .instr      (instr),
        .dmem_re    (core_re),
        .dmem_we    (core_we),
        .dmem_addr  (core_addr),
        .dmem_wdata (core_wdata),
        .dmem_rdata (core_rdata),
        .commit     (commit),
        .is_load    (is_load),
        .is_store   (is_store),
        .halted     (halted)
    );

    // ------------------------------------------------- instruction path
    instr_mem #(.AW(8), .INIT_FILE(IMEM_INIT)) u_imem (
        .addr  (imem_addr),
        .instr (instr)
    );

    // ------------------------------------------------------- data path
    wire       sel_dmem, sel_out, sel_cycle, fault;
    wire [7:0] dmem_addr;
    wire       dmem_re, dmem_we, out_we, bus_error;
    wire [15:0] dmem_rdata;

    addr_decoder u_dec (
        .addr      (core_addr),
        .sel_dmem  (sel_dmem),
        .sel_out   (sel_out),
        .sel_cycle (sel_cycle),
        .fault     (fault),
        .dmem_addr (dmem_addr)
    );

    rw_control u_rw (
        .re          (core_re),
        .we          (core_we),
        .commit      (commit),
        .sel_dmem    (sel_dmem),
        .sel_out     (sel_out),
        .sel_cycle   (sel_cycle),
        .fault       (fault),
        .dmem_rdata  (dmem_rdata),
        .cycle_count (cycles[15:0]),
        .dmem_re     (dmem_re),
        .dmem_we     (dmem_we),
        .out_we      (out_we),
        .bus_error   (bus_error),
        .rdata       (core_rdata)
    );

    data_mem #(.AW(8), .INIT_FILE(DMEM_INIT)) u_dmem (
        .clk   (clk),
        .we    (dmem_we),
        .re    (dmem_re),
        .addr  (dmem_addr),
        .wdata (core_wdata),
        .rdata (dmem_rdata)
    );

    // ------------------------------------------------------- output port
    always @(posedge clk) begin
        if (rst) begin
            out_valid      <= 1'b0;
            out_data       <= 16'd0;
            bus_error_seen <= 1'b0;
        end else begin
            out_valid <= out_we;
            if (out_we)    out_data       <= core_wdata;
            if (bus_error) bus_error_seen <= 1'b1;
        end
    end

    // -------------------------------------------------- performance counters
    perf_counters u_perf (
        .clk            (clk),
        .rst            (rst),
        .running        (~halted),
        .commit         (commit),
        .load           (is_load),
        .store          (is_store),
        .fetch          (~halted),                         // fetch every cycle
        .overlap        (commit & (is_load | is_store)),   // fetch + data together
        .cycles         (cycles),
        .instret        (instret),
        .loads          (loads),
        .stores         (stores),
        .ifetch         (ifetch),
        .overlap_cycles (overlap_cycles)
    );
endmodule
