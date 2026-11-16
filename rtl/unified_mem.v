// ============================================================================
// unified_mem.v -- single-ported shared memory (Von Neumann baseline)
// Owner : Phalak Sharma
//
// 512 x 16-bit memory holding BOTH code and data:
//   words 0x000-0x0FF : program (instruction region)
//   words 0x100-0x1FF : data    (data region)
// There is only ONE address port, so an instruction fetch and a data access
// can never happen in the same clock cycle. This structural hazard is what the
// Harvard organization removes.
// ============================================================================
`timescale 1ns / 1ps
module unified_mem #(
    parameter AW = 9
) (
    input  wire          clk,
    input  wire          we,
    input  wire [AW-1:0] addr,
    input  wire [15:0]   wdata,
    output wire [15:0]   rdata
);
    localparam DEPTH = (1 << AW);

    reg [15:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = (i < DEPTH/2) ? 16'hF000 : 16'h0000;   // HALT-fill code
    end

    always @(posedge clk) begin
        if (we)
            mem[addr] <= wdata;
    end

    assign rdata = mem[addr];
endmodule
