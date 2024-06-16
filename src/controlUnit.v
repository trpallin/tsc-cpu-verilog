`timescale 1ns/100ps

`include "opcodes.v"
`include "constants.v"

module ControlUnit (
	input clk,
	input reset_n,
	input [3:0] OPCode,
	input [5:0] FunctionCode,
	input Flush,
	input stall,
	input i_stall,
	input d_stall,

	input dma_begin,
	input dma_end,
	input bus_request,
	input d_readM,
	input d_writeM,

	output i_readC,

	output [3:0] ALUOp_BRNC,
	output branch,
	output JMP_OR_JAL,
	output JPR_OR_JRL,
	output reg readRS,
	output reg readRT,

	output [3:0] ALUOp,
	output ALUSrcA,
	output ALUSrcB,
	output [1:0] RegDst,

	output d_writeC,
	output d_readC,

	output RegWrite,
	output MemtoReg,

	output [2:0] RegWriteForStall,

	output wwd,
	output add_num_inst,
	output is_halted,
	output MemInvalid,
	output WBInvalid,

	output dma_cmd,
	output reg bus_granted
	);
// EX signal
reg [3:0] EX_ALUOp;
reg [3:0] EX_ALUOp_BRNC;
reg EX_ALUSrcA;
reg EX_ALUSrcB;
reg [1:0] EX_RegDst;
reg EX_MemWrite;
reg EX_MemRead;
reg EX_RegWrite;
reg EX_MemtoReg;
reg EX_is_halted;
reg EX_invalid;
reg EX_wwd;
reg EX_branch;
reg EX_JMP_OR_JAL;
reg EX_JPR_OR_JRL;

// MEM signal
reg MEM_MemWrite;
reg MEM_MemRead;
reg MEM_RegWrite;
reg MEM_MemtoReg;
reg MEM_is_halted;
reg MEM_invalid;
reg MEM_wwd;
reg MEM_branch;
reg MEM_JMP_OR_JAL;
reg MEM_JPR_OR_JRL;

// WB signal
reg WB_RegWrite;
reg WB_MemtoReg;
reg WB_is_halted;
reg WB_invalid;
reg WB_wwd;

reg [3:0] C_ALUOp;
reg [3:0] C_ALUOp_BRNC;
reg C_ALUSrc_A;
reg C_ALUSrc_B;
reg [1:0] C_RegDst;
reg C_MemWrite;
reg C_MemRead;
reg C_RegWrite;
reg C_MemtoReg;
reg C_is_halted;
reg C_WWD;
reg REG_FLUSHED;
reg C_JMP_OR_JAL;
reg C_JPR_OR_JRL;
reg C_branch;
reg dma_ongoing;

assign i_readC = 1;
assign { ALUOp, ALUSrcA, ALUSrcB, RegDst } = { EX_ALUOp, EX_ALUSrcA, EX_ALUSrcB, EX_RegDst };
assign d_writeC = MEM_MemWrite && !MEM_invalid;
assign d_readC = MEM_MemRead && !MEM_invalid;
assign RegWrite = WB_RegWrite && !WB_invalid;
assign MemtoReg = WB_MemtoReg;
assign RegWriteForStall = { WB_RegWrite === 1 && !WB_invalid, MEM_RegWrite === 1 && !MEM_invalid, EX_RegWrite === 1 && !EX_invalid};
assign wwd = WB_wwd && WB_invalid === 0;
assign add_num_inst = WB_invalid === 0;
assign is_halted = WB_is_halted && WB_invalid === 0;
assign MemInvalid = MEM_invalid;
assign WBInvalid = WB_invalid;
assign branch = MEM_branch;
assign ALUOp_BRNC = EX_ALUOp_BRNC;
assign JMP_OR_JAL = MEM_JMP_OR_JAL;
assign JPR_OR_JRL = MEM_JPR_OR_JRL;
assign dma_cmd = dma_ongoing && !d_readM && !d_writeC;

always @(posedge dma_begin) dma_ongoing <= 1;
always @(posedge dma_end) dma_ongoing <= 0;

always @(*) begin
	C_WWD = (OPCode === `OPCODE_TYPE_R) && (FunctionCode === `FUNC_WWD);
	case(OPCode)
		`OPCODE_ADI: begin
			C_ALUOp_BRNC = 4'bz;
			C_branch = 0;
			C_JMP_OR_JAL = 0;
			C_JPR_OR_JRL = 0;
			readRS = 1;
			readRT = 0;

			C_ALUOp = `ALUOP_ADD;
			C_ALUSrc_A = 0;
			C_ALUSrc_B = 1;
			C_RegDst = 0;

			C_MemWrite = 0;
			C_MemRead = 0;
			
			C_RegWrite = (stall || REG_FLUSHED) ? 0 : 1;
			C_MemtoReg = 0;
			C_is_halted = 0;
		end
		`OPCODE_ORI: begin
			C_ALUOp_BRNC = 4'bz;
			C_branch = 0;
			C_JMP_OR_JAL = 0;
			C_JPR_OR_JRL = 0;
			readRS = 1;
			readRT = 0;

			C_ALUOp = `ALUOP_ORR;
			C_ALUSrc_A = 0;
			C_ALUSrc_B = 1;
			C_RegDst = 0;

			C_MemWrite = 0;
			C_MemRead = 0;

			C_RegWrite = (stall || REG_FLUSHED) ? 0 : 1;
			C_MemtoReg = 0;
			C_is_halted = 0;
		end
		`OPCODE_LHI: begin
			C_ALUOp_BRNC = 4'bz;
			C_branch = 0;
			C_JMP_OR_JAL = 0;
			C_JPR_OR_JRL = 0;
			readRS = 0;
			readRT = 0;

			C_ALUOp = `ALUOP_LHI;
			C_ALUSrc_A = 0;
			C_ALUSrc_B = 1;
			C_RegDst = 0;

			C_MemWrite = 0;
			C_MemRead = 0;

			C_RegWrite = (stall || REG_FLUSHED) ? 0 : 1;
			C_MemtoReg = 0;
			C_is_halted = 0;
		end
		`OPCODE_LWD: begin
			C_ALUOp_BRNC = 4'bz;
			C_branch = 0;
			C_JMP_OR_JAL = 0;
			C_JPR_OR_JRL = 0;
			readRS = 1;
			readRT = 0;

			C_ALUOp = `ALUOP_ADD;
			C_ALUSrc_A = 0;
			C_ALUSrc_B = 1;
			C_RegDst = 0;

			C_MemWrite = 0;
			C_MemRead = 1;

			C_RegWrite = (stall || REG_FLUSHED) ? 0 : 1;
			C_MemtoReg = 1;
			C_is_halted = 0;
		end
		`OPCODE_SWD: begin
			C_ALUOp_BRNC = 4'bz;
			C_branch = 0;
			C_JMP_OR_JAL = 0;
			C_JPR_OR_JRL = 0;
			readRS = 1;
			readRT = 0;

			C_ALUOp = `ALUOP_ADD;
			C_ALUSrc_A = 0;
			C_ALUSrc_B = 1;
			C_RegDst = 0;

			C_MemWrite = (stall || REG_FLUSHED) ? 0 : 1;
			C_MemRead = 0;

			C_RegWrite = 0;
			C_MemtoReg = 0;
			C_is_halted = 0;
		end

		`OPCODE_BNE: begin
			C_ALUOp_BRNC = `ALUOP_BNE;
			C_branch = 1;
			C_JMP_OR_JAL = 0;
			C_JPR_OR_JRL = 0;
			readRS = 1;
			readRT = 1;

			C_ALUOp = `ALUOP_BNE;
			C_ALUSrc_A = 0;
			C_ALUSrc_B = 0;
			C_RegDst = 0;

			C_MemWrite = 0;
			C_MemRead = 0;

			C_RegWrite = 0;
			C_MemtoReg = 0;
			C_is_halted = 0;
		end
		`OPCODE_BEQ: begin
			C_ALUOp_BRNC = `ALUOP_BEQ;
			C_branch = 1;
			C_JMP_OR_JAL = 0;
			C_JPR_OR_JRL = 0;
			readRS = 1;
			readRT = 1;

			C_ALUOp = `ALUOP_BEQ;
			C_ALUSrc_A = 0;
			C_ALUSrc_B = 0;
			C_RegDst = 0;

			C_MemWrite = 0;
			C_MemRead = 0;

			C_RegWrite = 0;
			C_MemtoReg = 0;
			C_is_halted = 0;
		end
		`OPCODE_BGZ: begin
			C_ALUOp_BRNC = `ALUOP_BGZ;
			C_branch = 1;
			C_JMP_OR_JAL = 0;
			C_JPR_OR_JRL = 0;
			readRS = 1;
			readRT = 0;

			C_ALUOp = `ALUOP_BGZ;
			C_ALUSrc_A = 0;
			C_ALUSrc_B = 0;
			C_RegDst = 0;

			C_MemWrite = 0;
			C_MemRead = 0;

			C_RegWrite = 0;
			C_MemtoReg = 0;
			C_is_halted = 0;
		end
		`OPCODE_BLZ: begin
			C_ALUOp_BRNC = `ALUOP_BLZ;
			C_branch = 1;
			C_JMP_OR_JAL = 0;
			C_JPR_OR_JRL = 0;
			readRS = 1;
			readRT = 0;

			C_ALUOp = `ALUOP_BLZ;
			C_ALUSrc_A = 0;
			C_ALUSrc_B = 0;
			C_RegDst = 0;

			C_MemWrite = 0;
			C_MemRead = 0;

			C_RegWrite = 0;
			C_MemtoReg = 0;
			C_is_halted = 0;
		end

		`OPCODE_JMP: begin
			C_ALUOp_BRNC = 4'bz;
			C_branch = 0;
			C_JMP_OR_JAL = 1;
			C_JPR_OR_JRL = 0;
			readRS = 0;
			readRT = 0;

			C_ALUOp = `ALUOP_NONE;
			C_ALUSrc_A = 0;
			C_ALUSrc_B = 0;
			C_RegDst = 0;

			C_MemWrite = 0;
			C_MemRead = 0;

			C_RegWrite = 0;
			C_MemtoReg = 0;
			C_is_halted = 0;
		end
		`OPCODE_JAL: begin
			C_ALUOp_BRNC = 4'bz;
			C_branch = 0;
			C_JMP_OR_JAL = 1;
			C_JPR_OR_JRL = 0;
			readRS = 0;
			readRT = 0;
			
			C_ALUOp = `ALUOP_NONE;
			C_ALUSrc_A = 1;
			C_ALUSrc_B = 1;
			C_RegDst = 2;

			C_MemWrite = 0;
			C_MemRead = 0;

			C_RegWrite = 1;
			C_MemtoReg = 0;
			C_is_halted = 0;
		end

		`OPCODE_TYPE_R: begin
			case(FunctionCode)
				`FUNC_ADD: begin
					C_ALUOp_BRNC = 4'bz;
					C_branch = 0;
					C_JMP_OR_JAL = 0;
					C_JPR_OR_JRL = 0;
					readRS = 1;
					readRT = 1;

					C_ALUOp = `ALUOP_ADD;
					C_ALUSrc_A = 0;
					C_ALUSrc_B = 0;
					C_RegDst = 1;

					C_MemWrite = 0;
					C_MemRead = 0;

					C_RegWrite = (stall || REG_FLUSHED) ? 0 : 1;
					C_MemtoReg = 0;
					C_is_halted = 0;
				end
				`FUNC_SUB: begin
					C_ALUOp_BRNC = 4'bz;
					C_branch = 0;
					C_JMP_OR_JAL = 0;
					C_JPR_OR_JRL = 0;
					readRS = 1;
					readRT = 1;

					C_ALUOp = `ALUOP_SUB;
					C_ALUSrc_A = 0;
					C_ALUSrc_B = 0;
					C_RegDst = 1;

					C_MemWrite = 0;
					C_MemRead = 0;

					C_RegWrite = (stall || REG_FLUSHED) ? 0 : 1;
					C_MemtoReg = 0;
					C_is_halted = 0;
				end
				`FUNC_AND: begin
					C_ALUOp_BRNC = 4'bz;
					C_branch = 0;
					C_JMP_OR_JAL = 0;
					C_JPR_OR_JRL = 0;
					readRS = 1;
					readRT = 1;

					C_ALUOp = `ALUOP_AND;
					C_ALUSrc_A = 0;
					C_ALUSrc_B = 0;
					C_RegDst = 1;

					C_MemWrite = 0;
					C_MemRead = 0;

					C_RegWrite = (stall || REG_FLUSHED) ? 0 : 1;
					C_MemtoReg = 0;
					C_is_halted = 0;
				end
				`FUNC_ORR: begin
					C_ALUOp_BRNC = 4'bz;
					C_branch = 0;
					C_JMP_OR_JAL = 0;
					C_JPR_OR_JRL = 0;
					readRS = 1;
					readRT = 1;

					C_ALUOp = `ALUOP_ORR;
					C_ALUSrc_A = 0;
					C_ALUSrc_B = 0;
					C_RegDst = 1;

					C_MemWrite = 0;
					C_MemRead = 0;

					C_RegWrite = (stall || REG_FLUSHED) ? 0 : 1;
					C_MemtoReg = 0;
					C_is_halted = 0;
				end
				`FUNC_NOT: begin
					C_ALUOp_BRNC = 4'bz;
					C_branch = 0;
					C_JMP_OR_JAL = 0;
					C_JPR_OR_JRL = 0;
					readRS = 1;
					readRT = 0;

					C_ALUOp = `ALUOP_NOT;
					C_ALUSrc_A = 0;
					C_ALUSrc_B = 0;
					C_RegDst = 1;

					C_MemWrite = 0;
					C_MemRead = 0;

					C_RegWrite = (stall || REG_FLUSHED) ? 0 : 1;
					C_MemtoReg = 0;
					C_is_halted = 0;
				end
				`FUNC_TCP: begin
					C_ALUOp_BRNC = 4'bz;
					C_branch = 0;
					C_JMP_OR_JAL = 0;
					C_JPR_OR_JRL = 0;
					readRS = 1;
					readRT = 0;

					C_ALUOp = `ALUOP_TCP;
					C_ALUSrc_A = 0;
					C_ALUSrc_B = 0;
					C_RegDst = 1;

					C_MemWrite = 0;
					C_MemRead = 0;

					C_RegWrite = (stall || REG_FLUSHED) ? 0 : 1;
					C_MemtoReg = 0;
					C_is_halted = 0;
				end
				`FUNC_SHL: begin
					C_ALUOp_BRNC = 4'bz;
					C_branch = 0;
					C_JMP_OR_JAL = 0;
					C_JPR_OR_JRL = 0;
					readRS = 1;
					readRT = 0;

					C_ALUOp = `ALUOP_SHL;
					C_ALUSrc_A = 0;
					C_ALUSrc_B = 0;
					C_RegDst = 1;

					C_MemWrite = 0;
					C_MemRead = 0;

					C_RegWrite = (stall || REG_FLUSHED) ? 0 : 1;
					C_MemtoReg = 0;
					C_is_halted = 0;
				end
				`FUNC_SHR: begin
					C_ALUOp_BRNC = 4'bz;
					C_branch = 0;
					C_JMP_OR_JAL = 0;
					C_JPR_OR_JRL = 0;
					readRS = 1;
					readRT = 0;

					C_ALUOp = `ALUOP_SHR;
					C_ALUSrc_A = 0;
					C_ALUSrc_B = 0;
					C_RegDst = 1;

					C_MemWrite = 0;
					C_MemRead = 0;

					C_RegWrite = (stall || REG_FLUSHED) ? 0 : 1;
					C_MemtoReg = 0;
					C_is_halted = 0;
				end
				`FUNC_WWD: begin
					C_ALUOp_BRNC = 4'bz;
					C_branch = 0;
					C_JMP_OR_JAL = 0;
					C_JPR_OR_JRL = 0;
					readRS = 1;
					readRT = 0;

					C_ALUOp = `ALUOP_NONE;
					C_ALUSrc_A = 0;
					C_ALUSrc_B = 0;
					C_RegDst = 0;

					C_MemWrite = 0;
					C_MemRead = 0;

					C_RegWrite = 0;
					C_MemtoReg = 0;
					C_is_halted = 0;
				end
				`FUNC_JPR: begin
					C_ALUOp_BRNC = 4'bz;
					C_branch = 0;
					C_JMP_OR_JAL = 0;
					C_JPR_OR_JRL = 1;
					readRS = 1;
					readRT = 0;

					C_ALUOp = `ALUOP_NONE;
					C_ALUSrc_A = 0;
					C_ALUSrc_B = 0;
					C_RegDst = 0;

					C_MemWrite = 0;
					C_MemRead = 0;

					C_RegWrite = 0;
					C_MemtoReg = 0;
					C_is_halted = 0;
				end
				`FUNC_JRL: begin
					C_ALUOp_BRNC = 4'bz;
					C_branch = 0;
					C_JMP_OR_JAL = 0;
					C_JPR_OR_JRL = 1;
					readRS = 1;
					readRT = 0;

					C_ALUOp = `ALUOP_NONE;
					C_ALUSrc_A = 1;
					C_ALUSrc_B = 0;
					C_RegDst = 2;

					C_MemWrite = 0;
					C_MemRead = 0;

					C_RegWrite = 1;
					C_MemtoReg = 0;
					C_is_halted = 0;
				end
				`FUNC_HLT: begin
					C_ALUOp_BRNC = 4'bz;
					C_branch = 0;
					C_JMP_OR_JAL = 0;
					C_JPR_OR_JRL = 0;
					readRS = 0;
					readRT = 0;

					C_ALUOp = `ALUOP_NONE;
					C_ALUSrc_A = 0;
					C_ALUSrc_B = 0;
					C_RegDst = 0;

					C_MemWrite = 0;
					C_MemRead = 0;

					C_RegWrite = 0;
					C_MemtoReg = 0;
					C_is_halted = 1;
				end
			endcase
		end
	endcase
end

always @(posedge clk) begin
	if (!reset_n) begin
		REG_FLUSHED <= 1;
		// EX signal
		EX_ALUOp <= 0;
		EX_ALUOp_BRNC <= 0;
		EX_ALUSrcA <= 0;
		EX_ALUSrcB <= 0;
		EX_RegDst <= 0;
		EX_MemWrite <= 0;
		EX_MemRead <= 0;
		EX_RegWrite <= 0;
		EX_MemtoReg <= 0;
		EX_is_halted <= 0;
		EX_invalid <= 1;
		EX_wwd <= 0;
		EX_branch <= 0;
		EX_JMP_OR_JAL <= 0;
		EX_JPR_OR_JRL <= 0;
		// MEM signal
		MEM_MemWrite <= 0;
		MEM_MemRead <= 0;
		MEM_RegWrite <= 0;
		MEM_MemtoReg <= 0;
		MEM_is_halted <= 0;
		MEM_invalid <= 1;
		MEM_wwd <= 0;
		MEM_branch <= 0;
		MEM_JMP_OR_JAL <= 0;
		MEM_JPR_OR_JRL <= 0;
		//WB signal
		WB_RegWrite <= 0;
		WB_MemtoReg <= 0;
		WB_is_halted <= 0;
		WB_invalid <= 1;
		WB_wwd <= 0;
		// dma
		bus_granted <= 0;
		dma_ongoing <= 0;
	end
	else begin
		REG_FLUSHED <= stall || d_stall ? REG_FLUSHED : (i_stall ? 1 : Flush);
		// EX signal
		EX_ALUOp <= d_stall ? EX_ALUOp : C_ALUOp;
		EX_ALUOp_BRNC <= d_stall ? EX_ALUOp_BRNC : C_ALUOp_BRNC;
		EX_ALUSrcA <= d_stall ? EX_ALUSrcA : C_ALUSrc_A;
		EX_ALUSrcB <= d_stall ? EX_ALUSrcB : C_ALUSrc_B;
		EX_RegDst <= d_stall ? EX_RegDst : C_RegDst;
		EX_MemWrite <= d_stall ? EX_MemWrite : C_MemWrite;
		EX_MemRead <= d_stall ? EX_MemRead : C_MemRead;
		EX_RegWrite <= d_stall ? EX_RegWrite : C_RegWrite;
		EX_MemtoReg <= d_stall ? EX_MemtoReg : C_MemtoReg;
		EX_is_halted <= d_stall ? EX_is_halted : C_is_halted;
		EX_invalid <= d_stall ? EX_invalid : REG_FLUSHED || stall || Flush;
		EX_wwd <= d_stall ? EX_wwd : C_WWD;
		EX_branch <= d_stall ? EX_branch : C_branch;
		EX_JMP_OR_JAL <= d_stall ? EX_JMP_OR_JAL : C_JMP_OR_JAL;
		EX_JPR_OR_JRL <= d_stall ? EX_JPR_OR_JRL : C_JPR_OR_JRL;
		// MEM signal
		MEM_MemWrite <= d_stall ? MEM_MemWrite : EX_MemWrite;
		MEM_MemRead <= d_stall ? MEM_MemRead : EX_MemRead;
		MEM_RegWrite <= d_stall ? MEM_RegWrite : EX_RegWrite;
		MEM_MemtoReg <= d_stall ? MEM_MemtoReg : EX_MemtoReg;
		MEM_is_halted <= d_stall ? MEM_is_halted : EX_is_halted;
		MEM_invalid <= d_stall ? MEM_invalid : EX_invalid || Flush;
		MEM_wwd <= d_stall ? MEM_wwd : EX_wwd;
		MEM_branch <= d_stall ? MEM_branch : EX_branch;
		MEM_JMP_OR_JAL <= d_stall ? MEM_JMP_OR_JAL : EX_JMP_OR_JAL;
		MEM_JPR_OR_JRL <= d_stall ? MEM_JPR_OR_JRL : EX_JPR_OR_JRL;
		//WB signal
		WB_RegWrite <= MEM_RegWrite;
		WB_MemtoReg <= MEM_MemtoReg;
		WB_is_halted <= MEM_is_halted;
		WB_invalid <= MEM_invalid || d_stall;
		WB_wwd <= MEM_wwd;
		// dma
		if (!d_readM && !d_writeM) bus_granted <= bus_request ? 1 : 0;
	end
end

endmodule