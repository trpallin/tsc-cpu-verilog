`timescale 1ns/100ps

`include "opcodes.v"
`include "constants.v"

module BTB(
    input clk,
    input reset_n,
    input [`WORD_SIZE-1:0] PC,
    input Flush,
    input stall,
    input branch,
    input branch_cond,
    input JMP_OR_JAL,
    input JPR_OR_JRL,
    input [`WORD_SIZE-1:0] rsValue,
    input btbWrite,
    input [`WORD_SIZE-1:0] btbWriteAddress,
    input [`WORD_SIZE-1:0] branchPC,
    output reg [`WORD_SIZE-1:0] nextPC,
    output reg btbHit
);
reg [`BTB_TAG_SIZE+`WORD_SIZE-1:0] btb [0:`BTB_SIZE-1];

wire [`BTB_TAG_SIZE-1:0] tag, btbTag;
wire [`BTB_INDEX_SIZE-1:0] btbIndex;
wire [`WORD_SIZE-1:0] btbTargetAddress;

assign { tag, btbIndex } = PC;
assign { btbTag, btbTargetAddress } = btb[btbIndex];

always @(*) begin
    if (Flush) begin
        if (JPR_OR_JRL) nextPC = rsValue;
        else if (JMP_OR_JAL) nextPC = btbWriteAddress;
        else if (branch === 1 && branch_cond === 1) nextPC = btbWriteAddress;
        else nextPC = branchPC + 1;
    end
    else begin
        nextPC = btbTag === tag ? btbTargetAddress : PC + 1;
    end
end

always @(posedge clk) begin
    if (!reset_n) begin
        btbHit <= 0;
        for (integer i = 0; i < `BTB_SIZE; i = i + 1) begin
            btb[i] <= { `BTB_TAG_SIZE'bz, `WORD_SIZE'b0 };
        end
    end
    else begin
        btbHit <= stall ? btbHit : btbTag === tag;
        if (btbWrite) begin
            btb[branchPC[`BTB_INDEX_SIZE-1:0]] <= { branchPC[`WORD_SIZE-1:`WORD_SIZE-`BTB_TAG_SIZE], btbWriteAddress };
        end
    end
end
endmodule