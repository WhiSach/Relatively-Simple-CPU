module cpu (
    input wire clk,
    input wire rst,
    // Memory Interface
    input wire [7:0] mem_data_in,   // Data read from RAM
    output reg [15:0] mem_addr,     // Address sent to RAM
    output reg [7:0] mem_data_out,  // Data written to RAM
    output reg mem_rd,              // Memory read enable
    output reg mem_wr               // Memory write enable
);

//internal registers
reg [15:0] AR, PC
reg [7:0] DR, IR, TR, AC, R;
reg Z;