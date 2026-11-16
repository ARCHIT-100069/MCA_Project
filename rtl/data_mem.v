// ============================================================================
// data_mem.v -- data memory (read/write, Harvard data path)
// Owner : Phalak Sharma
//
// 256 x 16-bit RAM. Writes happen on the rising clock edge when `we` is high.
// Reads are asynchronous and return zero when `re` is low, so the read bus is
// quiet when the memory is not selected.
// ============================================================================
`timescale 1ns / 1ps
module data_mem #(
    parameter AW        = 8,
    parameter INIT_FILE = ""
) (
    input  wire          clk,
    input  wire          we,
    input  wire          re,
    input  wire [AW-1:0] addr,
    input  wire [15:0]   wdata,
    output wire [15:0]   rdata
);
    localparam DEPTH = (1 << AW);

    reg [15:0] ram [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            ram[i] = 16'h0000;
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, ram);
    end

    always @(posedge clk) begin
        if (we)
            ram[addr] <= wdata;
    end

    assign rdata = re ? ram[addr] : 16'h0000;
endmodule
