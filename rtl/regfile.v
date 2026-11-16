// ============================================================================
// regfile.v -- 8 x 16-bit register file, two read ports, one write port
// Owner : Archit Gosain
//
// R0 always reads as zero and ignores writes.
// ============================================================================
`timescale 1ns / 1ps
module regfile (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [2:0]  waddr,
    input  wire [15:0] wdata,
    input  wire [2:0]  raddr_a,
    input  wire [2:0]  raddr_b,
    output wire [15:0] rdata_a,
    output wire [15:0] rdata_b
);
    reg [15:0] r [1:7];
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 1; i < 8; i = i + 1)
                r[i] <= 16'd0;
        end else if (we && waddr != 3'd0) begin
            r[waddr] <= wdata;
        end
    end

    assign rdata_a = (raddr_a == 3'd0) ? 16'd0 : r[raddr_a];
    assign rdata_b = (raddr_b == 3'd0) ? 16'd0 : r[raddr_b];
endmodule
