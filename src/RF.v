`timescale 1ns/100ps

`include "opcodes.v"
`include "constants.v"

module RF(
    input [1:0] ReadAddressA,
    input [1:0] ReadAddressB,
    input [1:0] WriteAddress,
    input [15:0] WriteData,
    input write,
    input clk,
    input reset_n,
    output reg [15:0] ReadDataA,
    output reg [15:0] ReadDataB
);
reg [15:0] mem[3:0];

always @(posedge clk) begin
	if (!reset_n) begin
		mem[0] <= 0;
		mem[1] <= 0;
		mem[2] <= 0;
		mem[3] <= 0;
	end
	else if (write) begin
		mem[WriteAddress] <= WriteData;
	end
end

always @(*) begin
	ReadDataA = mem[ReadAddressA];
	ReadDataB = mem[ReadAddressB];
end

endmodule
