// ============================================================================
// vonneumann_top.v -- shared (Von Neumann) memory organization (baseline)
// Owner : Archit Gosain (integration)
//
// The SAME cpu_core is connected to ONE single-ported unified memory.
// A small two-state port arbiter decides who owns the port each cycle:
//
//   FETCH : port address = PC. The instruction is decoded straight from the
//           memory output. ALU / branch / LI instructions commit right away.
//           If the instruction is LW or SW it is latched into `ir`, its data
//           address is latched into the memory address register `mar`, the
//           core is stalled, and the arbiter moves to DATA.
//   DATA  : port address = mar. The core executes the latched instruction
//           from `ir` and commits; the arbiter returns to FETCH.
//
// The port address only ever comes from registers (pc or mar), so there is no
// combinational path from the memory output back to its own address.
//
// Every load/store therefore costs 2 cycles: CPI = 1 + (loads+stores)/instr.
//
// Unified memory map (word addresses):
//   0x000-0x0FF  code      0x100-0x1FF  data (data address 0x00-0xFF)
// ============================================================================
`timescale 1ns / 1ps
module vonneumann_top (
    input  wire        clk,
    input  wire        rst,
    output wire        halted,
    output reg         out_valid,
    output reg  [15:0] out_data,
    output reg         bus_error_seen,
    output wire [31:0] cycles,
    output wire [31:0] instret,
    output wire [31:0] loads,
    output wire [31:0] stores,
    output wire [31:0] ifetch,
    output wire [31:0] overlap_cycles
);
    localparam S_FETCH = 1'b0,
               S_DATA  = 1'b1;

    reg        state;
    reg [15:0] ir;                       // latched load/store instruction
    reg [7:0]  mar;                      // memory address register (data word)
    wire [7:0] dmem_addr;                // data word address from the decoder

    // ------------------------------------------------------------------ core
    wire [7:0]  pc;
    wire [15:0] mem_rdata;
    wire [15:0] core_instr = (state == S_DATA) ? ir : mem_rdata;
    wire        core_re, core_we, commit, is_load, is_store;
    wire [15:0] core_addr, core_wdata, core_rdata;
    wire        need_data = is_load | is_store;
    wire        stall     = (state == S_FETCH) & need_data;

    cpu_core #(.IAW(8)) u_core (
        .clk        (clk),
        .rst        (rst),
        .stall      (stall),
        .imem_addr  (pc),
        .instr      (core_instr),
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

    // ------------------------------------------------------- port arbiter
    always @(posedge clk) begin
        if (rst) begin
            state <= S_FETCH;
            ir    <= 16'd0;
            mar   <= 8'd0;
        end else if (state == S_FETCH) begin
            if (need_data) begin
                ir    <= mem_rdata;
                mar   <= dmem_addr;          // address computed from this instr
                state <= S_DATA;
            end
        end else begin
            state <= S_FETCH;
        end
    end

    // ------------------------------------------- data address decode / control
    wire       sel_dmem, sel_out, sel_cycle, fault;
    wire       dmem_re, dmem_we, out_we, bus_error;

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
        .dmem_rdata  (mem_rdata),
        .cycle_count (cycles[15:0]),
        .dmem_re     (dmem_re),
        .dmem_we     (dmem_we),
        .out_we      (out_we),
        .bus_error   (bus_error),
        .rdata       (core_rdata)
    );

    // ---------------------------------------------- single shared memory
    wire [8:0] mem_addr = (state == S_DATA) ? {1'b1, mar} : {1'b0, pc};

    unified_mem #(.AW(9)) u_mem (
        .clk   (clk),
        .we    ((state == S_DATA) & dmem_we),
        .addr  (mem_addr),
        .wdata (core_wdata),
        .rdata (mem_rdata)
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
        .fetch          (~halted & (state == S_FETCH)),
        .overlap        (1'b0),                 // one port: never overlaps
        .cycles         (cycles),
        .instret        (instret),
        .loads          (loads),
        .stores         (stores),
        .ifetch         (ifetch),
        .overlap_cycles (overlap_cycles)
    );
endmodule
