`timescale 1ns/100ps

`include "opcodes.v"
`include "constants.v"

module Cache(
    input clk,
    input reset_n,
    input Flush,
    input bus_granted,
    input i_readC,
    input [`WORD_SIZE-1:0] i_address_cpu,
    inout [`WORD_SIZE*4:0] i_data,
    inout [`WORD_SIZE-1:0] i_cache_data,
    output [`WORD_SIZE-1:0] i_address,
    output i_cache_hit,
    output i_readM,
    input d_readC,
    input d_writeC,
    input [`WORD_SIZE-1:0] d_address_cpu,
    inout [`WORD_SIZE*4:0] d_data,
    inout [`WORD_SIZE-1:0] d_cache_data,
    output [`WORD_SIZE-1:0] d_address,
    output d_cache_hit,
    output d_readM,
    output d_writeM
);
reg [`CACHE_TAG_BIT+`WORD_SIZE*`CACHE_BLOCK_SIZE:0] i_cache [0:`CACHE_INDEX_SIZE-1];
reg [`CACHE_TAG_BIT+`WORD_SIZE*`CACHE_BLOCK_SIZE:0] d_cache [0:`CACHE_INDEX_SIZE-1];
reg [`WORD_SIZE-1:0] i_outputData, d_outputData;
reg [`WORD_SIZE-1:0] i_memory_addr, d_memory_addr;

wire [`CACHE_TAG_BIT-1:0] i_input_tag, d_input_tag;
wire [`CACHE_INDEX_BIT-1:0] i_input_index, d_input_index;
wire [`CACHE_BLOCK_BIT-1:0] i_input_block, d_input_block;

wire [`CACHE_TAG_BIT-1:0] i_cache_tag, d_cache_tag;
wire i_cache_valid, d_cache_valid;
wire [`WORD_SIZE*`CACHE_BLOCK_SIZE-1:0] i_cache_block, d_cache_block;
wire i_cache_hit, d_cache_hit;

wire i_memory_ready, d_memory_ready;

assign { i_input_tag, i_input_index, i_input_block } = i_address_cpu;
assign { i_cache_tag, i_cache_valid, i_cache_block } = i_cache[i_input_index];
assign { d_input_tag, d_input_index, d_input_block } = d_address_cpu;
assign { d_cache_tag, d_cache_valid, d_cache_block } = d_cache[d_input_index];

assign i_cache_hit = i_readC && i_input_tag == i_cache_tag && i_cache_valid;
assign d_cache_hit = (d_readC || d_writeC) && d_input_tag == d_cache_tag && d_cache_valid;

assign i_memory_ready = i_readM && i_data[64] === 1;
assign d_memory_ready = d_readM && d_data[64] === 1;

assign i_readM = i_readC && !i_cache_hit;
assign d_readM =  bus_granted ? 0 : d_readC && !d_cache_hit;

assign d_writeM = bus_granted ? 0 : d_writeC;
assign d_data = d_writeM ? { 49'bz, d_cache_data } : 65'bz;

assign i_cache_data = i_readC ? i_outputData : `WORD_SIZE'bz;
assign d_cache_data = d_readC ? d_outputData : `WORD_SIZE'bz;

assign i_address = i_address_cpu;
assign d_address = bus_granted ? `WORD_SIZE'bz : d_address_cpu;

always @(*) begin
    if (i_cache_hit) begin
        case (i_input_block)
            2'b00: i_outputData <= i_cache_block[`WORD_SIZE-1:0];
            2'b01: i_outputData <= i_cache_block[`WORD_SIZE*2-1:`WORD_SIZE];
            2'b10: i_outputData <= i_cache_block[`WORD_SIZE*3-1:`WORD_SIZE*2];
            2'b11: i_outputData <= i_cache_block[`WORD_SIZE*4-1:`WORD_SIZE*3];
        endcase
    end
    if (d_cache_hit) begin
        case (d_input_block)
            2'b00: d_outputData <= d_cache_block[`WORD_SIZE-1:0];
            2'b01: d_outputData <= d_cache_block[`WORD_SIZE*2-1:`WORD_SIZE];
            2'b10: d_outputData <= d_cache_block[`WORD_SIZE*3-1:`WORD_SIZE*2];
            2'b11: d_outputData <= d_cache_block[`WORD_SIZE*4-1:`WORD_SIZE*3];
        endcase
    end
end

always @(posedge clk) begin
    if (!reset_n) begin
        for (integer i = 0; i < `CACHE_INDEX_SIZE; i=i+1) begin
            i_cache[i] <= 0;
            d_cache[i] <= 0;
        end
    end
    else begin
        if (i_readM) i_memory_addr <= i_address_cpu;
        if (d_readM) d_memory_addr <= d_address_cpu;
        if (i_memory_ready) i_cache[i_input_index] <= { i_memory_addr[`WORD_SIZE-1:4], 1'b1, i_data[`WORD_SIZE*`CACHE_BLOCK_SIZE-1:0] };
        if (d_memory_ready) d_cache[d_input_index] <= { d_memory_addr[`WORD_SIZE-1:4], 1'b1, d_data[`WORD_SIZE*`CACHE_BLOCK_SIZE-1:0] };

        if (d_writeC) begin
            if (d_cache_hit) begin
                case (d_input_block)
                    2'b00: d_cache[d_input_index][`WORD_SIZE-1:0] <= d_cache_data;
                    2'b01: d_cache[d_input_index][`WORD_SIZE*2-1:`WORD_SIZE] <= d_cache_data;
                    2'b10: d_cache[d_input_index][`WORD_SIZE*3-1:`WORD_SIZE*2] <= d_cache_data;
                    2'b11: d_cache[d_input_index][`WORD_SIZE*4-1:`WORD_SIZE*3] <= d_cache_data;
                endcase
            end
        end
    end
end

endmodule