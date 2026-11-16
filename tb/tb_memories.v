// ============================================================================
// tb_memories.v -- directed unit test for instr_mem, data_mem, unified_mem
// Owner : Mukund Mangla
// ============================================================================
`timescale 1ns/1ps

module tb_memories;
    reg clk = 0;
    always #5 clk = ~clk;

    integer errors = 0, tests = 0, i;

    task expect16;
        input [15:0] got, want;
        input [8*24-1:0] what;
        begin
            tests = tests + 1;
            if (got !== want) begin
                errors = errors + 1;
                $display("[FAIL] %0s: got %h want %h", what, got, want);
            end
        end
    endtask

    // ------------------------------------------------ instruction memory
    reg  [7:0]  i_addr;
    wire [15:0] i_data;
    instr_mem #(.AW(8)) u_imem (.addr(i_addr), .instr(i_data));

    // ------------------------------------------------------ data memory
    reg         d_we, d_re;
    reg  [7:0]  d_addr;
    reg  [15:0] d_wdata;
    wire [15:0] d_rdata;
    data_mem #(.AW(8)) u_dmem (.clk(clk), .we(d_we), .re(d_re),
                               .addr(d_addr), .wdata(d_wdata), .rdata(d_rdata));

    // ---------------------------------------------------- unified memory
    reg         u_we;
    reg  [8:0]  u_addr;
    reg  [15:0] u_wdata;
    wire [15:0] u_rdata;
    unified_mem #(.AW(9)) u_umem (.clk(clk), .we(u_we), .addr(u_addr),
                                  .wdata(u_wdata), .rdata(u_rdata));

    initial begin
        d_we = 0; d_re = 0; d_addr = 0; d_wdata = 0;
        u_we = 0; u_addr = 0; u_wdata = 0; i_addr = 0;
        #1;

        // instr_mem: unloaded words read as HALT; loaded words read back
        i_addr = 8'd200; #1; expect16(i_data, 16'hF000, "imem default HALT");
        u_imem.rom[5] = 16'h6E05;
        i_addr = 8'd5;   #1; expect16(i_data, 16'h6E05, "imem async read");

        // data_mem: write on clock edge, async read, quiet bus when re=0
        @(negedge clk); d_addr = 8'h10; d_wdata = 16'h1234; d_we = 1;
        @(negedge clk); d_we = 0; d_re = 1;
        #1; expect16(d_rdata, 16'h1234, "dmem write/read");
        d_re = 0; #1; expect16(d_rdata, 16'h0000, "dmem quiet when re=0");
        d_re = 1; d_addr = 8'h11; #1; expect16(d_rdata, 16'h0000, "dmem other word");
        // write is not visible before the clock edge
        d_addr = 8'h20; d_wdata = 16'hAAAA; d_we = 1; #1;
        expect16(d_rdata, 16'h0000, "dmem write is synchronous");
        @(posedge clk); #1; expect16(d_rdata, 16'hAAAA, "dmem after edge");
        d_we = 0;
        // walk all 256 words
        for (i = 0; i < 256; i = i + 1) begin
            @(negedge clk); d_addr = i; d_wdata = i * 7 + 3; d_we = 1;
        end
        @(negedge clk); d_we = 0;
        for (i = 0; i < 256; i = i + 1) begin
            d_addr = i; #1; expect16(d_rdata, i * 7 + 3, "dmem walk");
        end

        // unified_mem: code half HALT-filled, data half zero, one port
        u_addr = 9'h005; #1; expect16(u_rdata, 16'hF000, "umem code default");
        u_addr = 9'h105; #1; expect16(u_rdata, 16'h0000, "umem data default");
        @(negedge clk); u_addr = 9'h1FF; u_wdata = 16'h5A5A; u_we = 1;
        @(negedge clk); u_we = 0; #1; expect16(u_rdata, 16'h5A5A, "umem write/read");
        u_addr = 9'h0FF; #1; expect16(u_rdata, 16'hF000, "umem regions separate");

        if (errors == 0) $display("tb_memories: PASS (%0d checks)", tests);
        else             $display("tb_memories: FAIL (%0d of %0d checks)", errors, tests);
        $finish;
    end
endmodule
