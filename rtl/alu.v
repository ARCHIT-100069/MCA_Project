// ============================================================================
// alu.v -- 16-bit arithmetic logic unit
// Owner : Archit Gosain
// ============================================================================
`timescale 1ns / 1ps
`include "isa_defs.vh"

module alu (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire [2:0]  funct,
    output reg  [15:0] y
);
    always @(*) begin
        case (funct)
            `F_ADD : y = a + b;
            `F_SUB : y = a - b;
            `F_AND : y = a & b;
            `F_OR  : y = a | b;
            `F_XOR : y = a ^ b;
            `F_SLT : y = ($signed(a) < $signed(b)) ? 16'd1 : 16'd0;
            `F_SLL : y = a << b[3:0];
            `F_SRL : y = a >> b[3:0];
            default: y = 16'd0;
        endcase
    end
endmodule
