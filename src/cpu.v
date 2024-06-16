`timescale 1ns/100ps
`define WORD_SIZE 16    // data and address word size

`include "opcodes.v"

module cpu(
        input Clk, 
        input Reset_N,

	// Instruction memory interface
        output i_readM, 
        output i_writeM, 
        output [`WORD_SIZE-1:0] i_address, 
        inout [`WORD_SIZE*4:0] i_data, 

	// Data memory interface
        output d_readM, 
        output d_writeM, 
        output [`WORD_SIZE-1:0] d_address, 
        inout [`WORD_SIZE*4:0] d_data, 

        // DMA
        input dma_begin,
        input dma_end,
        output dma_cmd,
        input bus_request,
        output bus_granted,

        // test signal
        output reg [`WORD_SIZE-1:0] num_inst, 
        output [`WORD_SIZE-1:0] output_port, 

        output is_halted
);

wire [3:0] OPCode;
wire [5:0] FunctionCode;
wire Flush;
wire stall;
wire i_stall;
wire d_stall;

// Control Signal
wire branch;
wire [3:0] ALUOp;
wire [3:0] ALUOp_BRNC;
wire ALUSrcA;
wire ALUSrcB;
wire [1:0] RegDst;
wire d_writeC;
wire d_readC;
wire RegWrite;
wire MemtoReg;
wire [2:0] RegWriteForStall;
wire wwd;
wire add_num_inst;
wire MemInvalid, WBInvalid;
wire JMP_OR_JAL, JPR_OR_JRL;
wire readRS, readRT;
wire i_readC, d_readC, d_wrtieC;

// cache data
wire [`WORD_SIZE-1:0] i_cache_data, d_cache_data;
wire i_cache_hit, d_cache_hit;

wire [`WORD_SIZE-1:0] i_address_cpu, d_address_cpu;

wire d_cache_dataReady;

ControlUnit controlUnit (
        .clk(Clk),
        .reset_n(Reset_N),
        .OPCode(OPCode),
        .FunctionCode(FunctionCode),
        .Flush(Flush),
        .stall(stall),
        .i_stall(i_stall),
        .d_stall(d_stall),
        .dma_begin(dma_begin),
        .dma_end(dma_end),
        .bus_request(bus_request),
        .d_readM(d_readM),
        .d_writeM(d_writeM),
        .i_readC(i_readC),
        .branch(branch),
        .JMP_OR_JAL(JMP_OR_JAL),
        .JPR_OR_JRL(JPR_OR_JRL),
        .readRS(readRS),
        .readRT(readRT),
        .ALUOp(ALUOp),
        .ALUOp_BRNC(ALUOp_BRNC),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .RegDst(RegDst),
        .d_writeC(d_writeC),
        .d_readC(d_readC),
        .RegWrite(RegWrite),
        .MemtoReg(MemtoReg),
        .RegWriteForStall(RegWriteForStall),
        .wwd(wwd),
        .add_num_inst(add_num_inst),
        .is_halted(is_halted),
        .MemInvalid(MemInvalid),
        .WBInvalid(WBInvalid),
        .dma_cmd(dma_cmd),
        .bus_granted(bus_granted)
);

Cache cache (
        .clk(!Clk),
        .reset_n(Reset_N),
        .Flush(Flush),
        .bus_granted(bus_granted),
        .i_readC(i_readC),
        .i_address_cpu(i_address_cpu),
        .i_data(i_data),
        .i_cache_data(i_cache_data),
        .i_address(i_address),
        .i_cache_hit(i_cache_hit),
        .i_readM(i_readM),
        .d_readC(d_readC),
        .d_writeC(d_writeC),
        .d_address_cpu(d_address_cpu),
        .d_data(d_data),
        .d_cache_data(d_cache_data),
        .d_address(d_address),
        .d_cache_hit(d_cache_hit),
        .d_readM(d_readM),
        .d_writeM(d_writeM)
);

Datapath datapath (
        .clk(Clk),
        .reset_n(Reset_N),
        .i_cache_hit(i_cache_hit),
        .i_cache_data(i_cache_data),
        .d_cache_hit(d_cache_hit),
        .d_cache_data(d_cache_data),
        .ALUOp_BRNC(ALUOp_BRNC),
        .branch(branch),
        .JMP_OR_JAL(JMP_OR_JAL),
        .JPR_OR_JRL(JPR_OR_JRL),
        .readRS(readRS),
        .readRT(readRT),
        .ALUOp(ALUOp),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .RegDst(RegDst),
        .RegWrite(RegWrite),
        .d_readC(d_readC),
        .d_writeC(d_writeC),
        .MemtoReg(MemtoReg),
        .RegWriteForStall(RegWriteForStall),
        .wwd(wwd),
        .MemInvalid(MemInvalid),
        .WBInvalid(WBInvalid),
        .bus_granted(bus_granted),
        .OPCode(OPCode),
        .FunctionCode(FunctionCode),
        .i_address(i_address_cpu),
        .d_address(d_address_cpu),
        .Flush(Flush),
        .stall(stall),
        .i_stall(i_stall),
        .d_stall(d_stall),
        .output_port(output_port)
);

always @(posedge Clk) begin
        if (!Reset_N) begin
                num_inst <= 0;
        end
        else begin
                num_inst <= num_inst + add_num_inst;
        end
end

endmodule
