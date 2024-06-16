`timescale 1ns/100ps

`include "opcodes.v"
`include "constants.v"

module Datapath(
	input clk,
	input reset_n,
	input i_cache_hit,
	inout [`WORD_SIZE-1:0] i_cache_data,
	input d_cache_hit,
	inout [`WORD_SIZE-1:0] d_cache_data,
	input branch,
	input JMP_OR_JAL,
	input JPR_OR_JRL,
	input readRS,
	input readRT,

	input [3:0] ALUOp,
	input [3:0] ALUOp_BRNC,
	input ALUSrcA,
	input ALUSrcB,
	input [1:0] RegDst,

	input RegWrite,
	input d_readC,
	input d_writeC,
	input MemtoReg,
	input [2:0] RegWriteForStall,
	input wwd,
	input MemInvalid,
	input WBInvalid,
	input bus_granted,

	output [3:0] OPCode,
	output [5:0] FunctionCode,
	output [`WORD_SIZE-1:0] i_address,
	output [`WORD_SIZE-1:0] d_address,
	output Flush,
	output stall,
	output i_stall,
	output d_stall,

	output reg [`WORD_SIZE-1:0] output_port
	);
reg [`WORD_SIZE-1:0] PC;

// ID signal
reg [`WORD_SIZE-1:0] ID_PC;
reg [`WORD_SIZE-1:0] ID_inst;
wire ID_btbHit;

// EX signal
reg [`WORD_SIZE-1:0] EX_PC;
reg [`WORD_SIZE-1:0] EX_inst;
reg [`WORD_SIZE-1:0] EX_RF_A;
reg [`WORD_SIZE-1:0] EX_RF_B;
reg EX_btbHit;

// MEM signal
reg [`WORD_SIZE-1:0] MEM_PC;
reg [`WORD_SIZE-1:0] MEM_inst;
reg [`WORD_SIZE-1:0] MEM_RF_A;
reg [`WORD_SIZE-1:0] MEM_RF_B;
reg [`WORD_SIZE-1:0] MEM_ALUOut;
reg [1:0] MEM_RFWriteAddress;
reg MEM_btbHit;
reg MEM_branch_cond;

// WB signal
reg [`WORD_SIZE-1:0] WB_RF_A;
reg [`WORD_SIZE-1:0] WB_MemReadData;
reg [`WORD_SIZE-1:0] WB_ALUOut;
reg [1:0] WB_RFWriteAddress;
reg [`WORD_SIZE-1:0] WB_inst;

reg [2:0] d_counter;

wire [1:0] RegReadAddressA, RegReadAddressB, RegWriteAddress;
wire [`WORD_SIZE-1:0] RegReadDataA, RegReadDataB, RegWriteData;
wire [1:0] rs, rt, rd;
wire [`WORD_SIZE-1:0] ALUInputA, ALUInputB, ALUOutput;
wire EX_branch_cond;
wire [`WORD_SIZE-1:0] nextPC;
wire [2:0] RegAddressToCheckStall_EX, RegAddressToCheckStall_MEM, RegAddressToCheckStall_WB;
wire [1:0] RegWriteAddressEX;
wire [`WORD_SIZE-1:0] btbWriteAddress;
wire memwrite_finished;
wire mem_read_signal, mem_write_signal;

assign { OPCode, rs, rt, rd, FunctionCode } = ID_inst;
assign btbWriteAddress = (branch === 1) ? ( MEM_PC + { {8{MEM_inst[7]}}, MEM_inst[7:0] } ) : JMP_OR_JAL ? { MEM_PC[15:12], MEM_inst[11:0] } : 16'bz;
assign ALUInputA = ALUSrcA ? EX_PC : EX_RF_A;
assign ALUInputB = ALUSrcB ? { {8{EX_inst[7]}}, EX_inst[7:0] } : EX_RF_B;
assign d_address = MEM_ALUOut;
assign d_cache_data = d_writeC ? MEM_RF_B : 16'bz;
assign RegWriteData = MemtoReg ? WB_MemReadData : WB_ALUOut;
assign i_address = PC;
assign Flush = MemInvalid === 0 && ((MEM_btbHit && branch === 1 && MEM_branch_cond === 0) || (!MEM_btbHit && branch === 1 && MEM_branch_cond === 1) || JPR_OR_JRL || (JMP_OR_JAL && !MEM_btbHit));
assign RegReadAddressA = rs;
assign RegReadAddressB = rt;
assign RegWriteAddress = WB_RFWriteAddress;
assign RegAddressToCheckStall_EX = RegWriteForStall[0] ? RegWriteAddressEX : 2'bz;
assign RegAddressToCheckStall_MEM = RegWriteForStall[1] ? MEM_RFWriteAddress : 2'bz;
assign RegAddressToCheckStall_WB = RegWriteForStall[2] ? WB_RFWriteAddress : 2'bz;
assign stall = !Flush && ((readRS && rs !== 2'bz && ((rs === RegAddressToCheckStall_EX) || (rs === RegAddressToCheckStall_MEM) || (rs === RegAddressToCheckStall_WB))) || (readRT && rt !== 2'bz && (rt === RegAddressToCheckStall_EX || rt === RegAddressToCheckStall_MEM || rt === RegAddressToCheckStall_WB)));
assign RegWriteAddressEX = RegDst[1] ? 2'b10 : (RegDst[0] ? EX_inst[7:6] : EX_inst[9:8]);
assign i_stall = !i_cache_hit;
assign d_stall = (!d_cache_hit && d_readC) || (d_writeC && !memwrite_finished) || (bus_granted && mem_read_signal && !d_cache_hit) || (bus_granted && mem_write_signal);
assign memwrite_finished = d_counter == `MEMORY_LATENCY-1;
assign mem_read_signal = !MemInvalid && MEM_inst[15:12] == `OPCODE_LWD;
assign mem_write_signal = !MemInvalid && MEM_inst[15:12] == `OPCODE_SWD;

BTB btb (
	.clk(clk),
	.reset_n(reset_n),
	.PC(PC),
	.Flush(Flush),
	.stall(stall),
	.branch(branch),
	.branch_cond(MEM_branch_cond),
	.JMP_OR_JAL(JMP_OR_JAL),
	.JPR_OR_JRL(JPR_OR_JRL),
	.rsValue(MEM_RF_A),
	.btbWrite((branch === 1 && MEM_branch_cond === 1) || JMP_OR_JAL),
	.btbWriteAddress(btbWriteAddress),
	.branchPC(MEM_PC-1),
	.nextPC(nextPC),
	.btbHit(ID_btbHit)
);

alu alu_BRNC (
	.A(EX_RF_A),
	.B(EX_RF_B),
	.ALUOp(ALUOp_BRNC),
	.C(),
	.branch_cond(EX_branch_cond)
);

alu alu_EX (
	.A(ALUInputA),
	.B(ALUInputB),
	.ALUOp(ALUOp),
	.C(ALUOutput),
	.branch_cond()
);

RF RF (
  .ReadAddressA(RegReadAddressA),
  .ReadAddressB(RegReadAddressB),
  .WriteAddress(RegWriteAddress),
  .WriteData(RegWriteData),
  .write(RegWrite),
  .clk(clk),
  .reset_n(reset_n),
  .ReadDataA(RegReadDataA),
  .ReadDataB(RegReadDataB)
  );

always @(posedge clk) begin
	if (!reset_n) begin
		PC <= 0;
		// ID signal
		ID_PC <= 0;
		ID_inst <= 0;
		// EX signal
		EX_PC <= 0;
		EX_inst <= 0;
		EX_RF_A <= 0;
		EX_RF_B <= 0;
		EX_btbHit <= 0;
		// MEM signal
		MEM_PC <= 0;
		MEM_inst <= 0;
		MEM_RF_A <= 0;
		MEM_RF_B <= 0;
		MEM_ALUOut <= 0;
		MEM_RFWriteAddress <= 0;
		MEM_btbHit <= 0;
		// WB signal
		WB_RF_A <= 0;
		WB_MemReadData <= 0;
		WB_ALUOut <= 0;
		WB_RFWriteAddress <= 0;
		WB_inst <= 0;

		MEM_branch_cond <= 0;
		d_counter <= 0;
		output_port <= 0;
	end
	else begin
		PC <= Flush ? nextPC : stall || i_stall || d_stall ? PC : nextPC;
		// ID signal
		ID_PC <= stall || i_stall || d_stall ? ID_PC : PC + 1;
		ID_inst <= stall || i_stall || d_stall ? ID_inst : i_cache_data;
		// EX signal
		EX_PC <= d_stall ? EX_PC : ID_PC;
		EX_RF_A <= d_stall ? EX_RF_A : RegReadDataA;
		EX_RF_B <= d_stall ? EX_RF_B : RegReadDataB;
		EX_inst <= d_stall ? EX_inst : ID_inst;
		EX_btbHit <= d_stall ? EX_btbHit : ID_btbHit;
		// MEM signal
		MEM_PC <= d_stall ? MEM_PC : EX_PC;
		MEM_inst <= d_stall ? MEM_inst : EX_inst;
		MEM_RF_A <= d_stall ? MEM_RF_A : EX_RF_A;
		MEM_RF_B <= d_stall ? MEM_RF_B : EX_RF_B;
		MEM_ALUOut <= d_stall ? MEM_ALUOut : ALUOutput;
		MEM_RFWriteAddress <= d_stall ? MEM_RFWriteAddress : RegWriteAddressEX;
		MEM_btbHit <= d_stall ? MEM_btbHit : EX_btbHit;
		MEM_branch_cond <= EX_branch_cond;
		// WB signal
		WB_RF_A <= MEM_RF_A;
		WB_MemReadData <= d_cache_data;
		WB_ALUOut <= MEM_ALUOut;
		WB_RFWriteAddress <= MEM_RFWriteAddress;
		WB_inst <= MEM_inst;

		if (wwd) output_port <= WB_RF_A;
		else output_port <= output_port;

		if (d_writeC) begin
			if (memwrite_finished) d_counter <= 0;
			else if (bus_granted) d_counter <= d_counter;
			else d_counter <= d_counter+1;
		end
	end
end
endmodule