// ============================================================================
// program_counter.v -- instruction address register
// Owner : Archit Gosain
//
// Holds the word address of the instruction being executed. The PC only
// advances when `en` is high, which lets the Von Neumann arbiter freeze the
// processor for one cycle while the shared memory port serves a data access.
// ============================================================================
`timescale 1ns / 1ps
module program_counter #(
    parameter AW = 8                 // 2^AW instruction words
) (
    input  wire          clk,
    input  wire          rst,        // synchronous, active high
    input  wire          en,         // update enable (commit)
    input  wire [AW-1:0] next_pc,
    output reg  [AW-1:0] pc
);
    always @(posedge clk) begin
        if (rst)
            pc <= {AW{1'b0}};
        else if (en)
            pc <= next_pc;
    end
endmodule
