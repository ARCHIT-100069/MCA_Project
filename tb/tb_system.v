// ============================================================================
// tb_system.v -- system testbench: Harvard vs Von Neumann, same program
// Owner : Mukund Mangla
//
// Loads one assembled program into BOTH organizations, runs them side by side
// and checks:
//   1. every value written to the output port matches <prog>.expect.hex
//   2. both machines halt, with no bus errors
//   3. the final data memories of both machines are identical
// It then prints the performance counters and appends one line to
// build/results.csv for the comparison plots.
//
//   vvp build/tb_system.vvp +PROG=sum_array [+VCD] [+NOCSV]
// ============================================================================
`timescale 1ns/1ps

module tb_system;
    localparam MAX_CYCLES = 100000;

    reg clk = 1'b0;
    reg rst = 1'b1;
    always #5 clk = ~clk;                 // 100 MHz

    // -------------------------------------------------------------- DUTs
    wire        h_halted, h_out_valid, h_err;
    wire [15:0] h_out;
    wire [31:0] h_cycles, h_instret, h_loads, h_stores, h_ifetch, h_overlap;

    harvard_top u_harvard (
        .clk(clk), .rst(rst), .halted(h_halted),
        .out_valid(h_out_valid), .out_data(h_out), .bus_error_seen(h_err),
        .cycles(h_cycles), .instret(h_instret), .loads(h_loads),
        .stores(h_stores), .ifetch(h_ifetch), .overlap_cycles(h_overlap)
    );

    wire        v_halted, v_out_valid, v_err;
    wire [15:0] v_out;
    wire [31:0] v_cycles, v_instret, v_loads, v_stores, v_ifetch, v_overlap;

    vonneumann_top u_vonneumann (
        .clk(clk), .rst(rst), .halted(v_halted),
        .out_valid(v_out_valid), .out_data(v_out), .bus_error_seen(v_err),
        .cycles(v_cycles), .instret(v_instret), .loads(v_loads),
        .stores(v_stores), .ifetch(v_ifetch), .overlap_cycles(v_overlap)
    );

    // ---------------------------------------------------------- program
    reg [8*64-1:0]  prog;
    reg [8*128-1:0] imem_file, dmem_file, exp_file;
    reg [15:0]      expected [0:255];
    integer         n_expected;
    integer         h_idx, v_idx, errors, i, cycle, csv;

    // ------------------------------------------------- output-port checking
    always @(posedge clk) begin
        if (!rst && h_out_valid) begin
            if (h_idx >= n_expected || h_out !== expected[1 + h_idx]) begin
                $display("  [FAIL] Harvard   out #%0d = %0d, expected %0d",
                         h_idx, h_out, expected[1 + h_idx]);
                errors = errors + 1;
            end else
                $display("  [ OK ] Harvard   out #%0d = %0d  (cycle %0d)", h_idx, h_out, h_cycles);
            h_idx = h_idx + 1;
        end
        if (!rst && v_out_valid) begin
            if (v_idx >= n_expected || v_out !== expected[1 + v_idx]) begin
                $display("  [FAIL] VonNeumann out #%0d = %0d, expected %0d",
                         v_idx, v_out, expected[1 + v_idx]);
                errors = errors + 1;
            end else
                $display("  [ OK ] VonNeumann out #%0d = %0d  (cycle %0d)", v_idx, v_out, v_cycles);
            v_idx = v_idx + 1;
        end
    end

    // ------------------------------------------------------------ main
    initial begin
        if (!$value$plusargs("PROG=%s", prog))
            prog = "sum_array";
        $sformat(imem_file, "build/programs/%0s.imem.hex",   prog);
        $sformat(dmem_file, "build/programs/%0s.dmem.hex",   prog);
        $sformat(exp_file,  "build/programs/%0s.expect.hex", prog);

        if ($test$plusargs("VCD")) begin
            $dumpfile("build/waves.vcd");
            $dumpvars(0, tb_system);
        end

        errors = 0; h_idx = 0; v_idx = 0;

        #1;   // let the memories run their own initial blocks first
        $readmemh(imem_file, u_harvard.u_imem.rom);
        $readmemh(dmem_file, u_harvard.u_dmem.ram);
        $readmemh(imem_file, u_vonneumann.u_mem.mem, 0,   255);
        $readmemh(dmem_file, u_vonneumann.u_mem.mem, 256, 511);
        $readmemh(exp_file,  expected);
        n_expected = expected[0];

        $display("============================================================");
        $display(" Program: %0s   (%0d expected outputs)", prog, n_expected);
        $display("============================================================");

        repeat (2) @(posedge clk);
        @(negedge clk) rst = 1'b0;

        cycle = 0;
        while (!(h_halted && v_halted) && cycle < MAX_CYCLES) begin
            @(posedge clk);
            cycle = cycle + 1;
        end
        repeat (3) @(posedge clk);   // drain the registered output port

        // ------------------------------------------------------- checks
        if (!h_halted || !v_halted) begin
            $display("  [FAIL] timeout: harvard halted=%0d vonneumann halted=%0d",
                     h_halted, v_halted);
            errors = errors + 1;
        end
        if (h_idx != n_expected || v_idx != n_expected) begin
            $display("  [FAIL] output count: harvard %0d, vonneumann %0d, expected %0d",
                     h_idx, v_idx, n_expected);
            errors = errors + 1;
        end
        if (h_err || v_err) begin
            $display("  [FAIL] bus error: harvard %0d, vonneumann %0d", h_err, v_err);
            errors = errors + 1;
        end
        for (i = 0; i < 256; i = i + 1)
            if (u_harvard.u_dmem.ram[i] !== u_vonneumann.u_mem.mem[256 + i]) begin
                $display("  [FAIL] data word 0x%02h differs: harvard %h, vonneumann %h",
                         i, u_harvard.u_dmem.ram[i], u_vonneumann.u_mem.mem[256 + i]);
                errors = errors + 1;
            end
        if (h_instret != v_instret) begin
            $display("  [FAIL] instruction counts differ");
            errors = errors + 1;
        end

        // ------------------------------------------------------- report
        $display("------------------------------------------------------------");
        $display("                     Harvard    Von Neumann");
        $display("  instructions    %10d   %10d", h_instret, v_instret);
        $display("  loads / stores  %5d/%-5d  %5d/%-5d", h_loads, h_stores, v_loads, v_stores);
        $display("  cycles          %10d   %10d", h_cycles, v_cycles);
        $display("  CPI             %10.3f   %10.3f",
                 $itor(h_cycles) / $itor(h_instret), $itor(v_cycles) / $itor(v_instret));
        $display("  fetch cycles    %10d   %10d", h_ifetch, v_ifetch);
        $display("  fetch+data same cycle %4d   %10d", h_overlap, v_overlap);
        $display("  speed-up (VN cycles / Harvard cycles) = %0.3f",
                 $itor(v_cycles) / $itor(h_cycles));
        $display("------------------------------------------------------------");
        if (errors == 0) $display(" RESULT: PASS  (%0s)", prog);
        else             $display(" RESULT: FAIL  (%0s, %0d errors)", prog, errors);
        $display("");

        if (!$test$plusargs("NOCSV")) begin
            csv = $fopen("build/results.csv", "a");
            $fdisplay(csv, "%0s,%0d,%0d,%0d,%0d,%0d,%0d,%0s", prog, h_instret, h_loads,
                      h_stores, h_cycles, v_cycles, h_overlap, (errors == 0) ? "PASS" : "FAIL");
            $fclose(csv);
        end
        $finish;
    end
endmodule
