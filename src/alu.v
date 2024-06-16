`timescale 1ns/100ps

`include "opcodes.v"

module alu(
    input [15:0] A,
    input [15:0] B,
    input [3:0] ALUOp,
    output reg [15:0] C,
    output reg branch_cond
    );
always @(*) begin
    case(ALUOp)
        `ALUOP_NONE: begin
            C = A;
            branch_cond = 0;
        end
        `ALUOP_ADD: begin
            C = A + B;
            branch_cond = 0;
        end
        `ALUOP_SUB: begin
            C = A - B;
            branch_cond = 0;
        end
        `ALUOP_SHL: begin
            C = A << 1;
            branch_cond = 0;
        end
        `ALUOP_SHR: begin
            C = { A[15], A[15:1] };
            branch_cond = 0;
        end
        `ALUOP_AND: begin
            C = A & B;
            branch_cond = 0;
        end
        `ALUOP_ORR: begin
            C = A | B;
            branch_cond = 0;
        end
        `ALUOP_TCP: begin
            C = (~A) + 1;
            branch_cond = 0;
        end
        `ALUOP_NOT: begin
            C = ~A;
            branch_cond = 0;
        end
        `ALUOP_LHI: begin
            C = B << 8;
            branch_cond = 0;
        end
        `ALUOP_ORI: begin
            C = { A[15:8], (A[7:0] | B[7:0])};
            branch_cond = 0;
        end
        `ALUOP_BNE: begin
            C = 16'bz;
            branch_cond = A != B;
        end
        `ALUOP_BEQ: begin
            C = 16'bz;
            branch_cond = A == B;
        end
        `ALUOP_BGZ: begin
            C = 16'bz;
            branch_cond = ~A[15] && A != 0;
        end
        `ALUOP_BLZ: begin
            C = 16'bz;
            branch_cond = A[15];
        end
        default: begin
            C = 16'bz;
            branch_cond = 0;
        end
    endcase
end
endmodule
