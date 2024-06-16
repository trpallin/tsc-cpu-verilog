`define WORD_SIZE 16
/*************************************************
* DMA module (DMA.v)
* input: clock (CLK), bus request (BR) signal, 
*        data from the device (edata), and DMA command (cmd)
* output: bus grant (BG) signal 
*         READ signal
*         memory address (addr) to be written by the device, 
*         offset device offset (0 - 2)
*         data that will be written to the memory
*         interrupt to notify DMA is end
* You should NOT change the name of the I/O ports and the module name
* You can (or may have to) change the type and length of I/O ports 
* (e.g., wire -> reg) if you want 
* Do not add more ports! 
*************************************************/

module DMA (
    input CLK, BG,
    input [4 * `WORD_SIZE - 1 : 0] edata,
    input cmd,
    output reg BR, 
    output WRITE,
    output [`WORD_SIZE - 1 : 0] addr, 
    output [4 * `WORD_SIZE - 1 : 0] data,
    output reg [1:0] offset,
    output reg interrupt);

    reg [1:0] offset_counter;
    reg [2:0] d_counter;

    wire one_memwrite_finished;
    
    assign one_memwrite_finished = d_counter == `MEMORY_LATENCY-1;
    assign all_memwrite_finished = offset_counter == 2 && one_memwrite_finished; 
    assign addr = BG ? 16'h1f4 + (offset_counter * 4) : `WORD_SIZE'bz;
    assign data = BG ? edata : 64'bz;
    assign WRITE = BG && one_memwrite_finished ? 1 : 0;

    initial begin
        BR <= 0;
        offset <= 2'bz;
        offset_counter <= 0;
        d_counter <= 0;
        interrupt <= 0;
    end

    always @(posedge CLK) begin
        if (one_memwrite_finished) BR <= 0;
        else if (cmd) BR <= 1;

        if (all_memwrite_finished) interrupt <= 1;
        else interrupt <= 0;

        if (BG) begin
            offset <= offset_counter;
            if (one_memwrite_finished) begin
                d_counter <= 0;
                offset_counter <= offset_counter == 2 ? 0 : offset_counter+1;
            end
            else d_counter <= d_counter+1;
        end
        else begin
            d_counter <= 0;
            offset <= 2'bz;
        end
    end
endmodule


