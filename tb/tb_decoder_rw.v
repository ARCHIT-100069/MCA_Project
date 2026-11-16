// ============================================================================
// tb_decoder_rw.v -- directed unit test for addr_decoder + rw_control
// Owner : Mukund Mangla
// ============================================================================
`timescale 1ns/1ps

module tb_decoder_rw;
    reg  [15:0] addr;
    reg         re, we, commit;
    wire        sel_dmem, sel_out, sel_cycle, fault;
    wire [7:0]  dmem_addr;
    wire        dmem_re, dmem_we, out_we, bus_error;
    wire [15:0] rdata;

    addr_decoder u_dec (
        .addr(addr), .sel_dmem(sel_dmem), .sel_out(sel_out),
        .sel_cycle(sel_cycle), .fault(fault), .dmem_addr(dmem_addr)
    );

    rw_control u_rw (
        .re(re), .we(we), .commit(commit),
        .sel_dmem(sel_dmem), .sel_out(sel_out), .sel_cycle(sel_cycle), .fault(fault),
        .dmem_rdata(16'hBEEF), .cycle_count(16'd1234),
        .dmem_re(dmem_re), .dmem_we(dmem_we), .out_we(out_we),
        .bus_error(bus_error), .rdata(rdata)
    );

    integer errors = 0, tests = 0;

    task check;
        input [15:0] a;
        input        r, w, c;
        input [3:0]  exp_sel;     // {dmem, out, cycle, fault}
        input [3:0]  exp_ctl;     // {dmem_re, dmem_we, out_we, bus_error}
        input [15:0] exp_rdata;
        begin
            addr = a; re = r; we = w; commit = c;
            #1;
            tests = tests + 1;
            if ({sel_dmem, sel_out, sel_cycle, fault} !== exp_sel ||
                {dmem_re, dmem_we, out_we, bus_error} !== exp_ctl ||
                rdata !== exp_rdata ||
                (sel_dmem && dmem_addr !== a[7:0])) begin
                errors = errors + 1;
                $display("[FAIL] addr=%h re=%b we=%b commit=%b sel=%b ctl=%b rdata=%h",
                         a, r, w, c, {sel_dmem, sel_out, sel_cycle, fault},
                         {dmem_re, dmem_we, out_we, bus_error}, rdata);
            end
        end
    endtask

    initial begin
        //      addr     re we c   sel     ctl     rdata
        check(16'h0000, 1, 0, 1, 4'b1000, 4'b1000, 16'hBEEF);  // read first word
        check(16'h00FF, 1, 0, 1, 4'b1000, 4'b1000, 16'hBEEF);  // read last word
        check(16'h0042, 0, 1, 1, 4'b1000, 4'b0100, 16'h0000);  // write commits
        check(16'h0042, 0, 1, 0, 4'b1000, 4'b0000, 16'h0000);  // stalled write blocked
        check(16'h0100, 0, 1, 1, 4'b0100, 4'b0010, 16'h0000);  // output port write
        check(16'h0100, 0, 1, 0, 4'b0100, 4'b0000, 16'h0000);  // stalled: no write
        check(16'h0101, 1, 0, 1, 4'b0010, 4'b0000, 16'd1234);  // cycle counter read
        check(16'h0101, 0, 1, 1, 4'b0010, 4'b0001, 16'h0000);  // write to RO -> error
        check(16'h0100, 1, 0, 1, 4'b0100, 4'b0001, 16'h0000);  // read WO -> error
        check(16'h0102, 1, 0, 1, 4'b0001, 4'b0001, 16'h0000);  // unmapped read
        check(16'hFFFF, 0, 1, 1, 4'b0001, 4'b0001, 16'h0000);  // unmapped write
        check(16'h0200, 0, 0, 1, 4'b0001, 4'b0000, 16'h0000);  // no access: no error
        check(16'h0010, 0, 0, 1, 4'b1000, 4'b0000, 16'h0000);  // idle: quiet bus

        if (errors == 0) $display("tb_decoder_rw: PASS (%0d directed tests)", tests);
        else             $display("tb_decoder_rw: FAIL (%0d of %0d tests)", errors, tests);
        $finish;
    end
endmodule
