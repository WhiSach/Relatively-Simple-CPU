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
reg [15:0] AR, PC;
reg [7:0] DR, IR, TR, AC, R;
reg Z;

// Finite State Machine (FSM) states

localparam FETCH1 = 4'd0, FETCH2 = 4'd1, FETCH3 = 4'd2, DECODE = 4'd3,
               LDAC1  = 4'd4, LDAC2  = 4'd5, LDAC3  = 4'd6, LDAC4  = 4'd7, LDAC5  = 4'd8,
                STAC1  = 4'd9, STAC2  = 4'd10, STAC3  = 4'd11, STAC4  = 4'd12, STAC5  = 4'd13,
                JUMP1 = 4'd14, JUMP2 = 4'd15, JUMP3 = 4'd16, JMPZY1 = 4'd17, JMPZY2 = 4'd18, JMPZY3 = 4'd19,
                JMPZN1 = 4'd20, JMPZN2 = 4'd21, JPNYZ1 = 4'd22, JPNYZ2 = 4'd23, JPNYZ3 = 4'd24,
                JPNZN1 = 4'd25, JPNZN2 = 4'd26, ADD1 = 4'd27, SUB1 = 4'd28, AND1 = 4'd29, OR1 = 4'd30, NOT1 = 4'd31, 
                NOP1 = 4'd32, XOR1 = 4'd33, MVAC1 = 4'd34, MVAC2 = 4'd35;

reg [3:0] current_state;

localparam OP_NOP  = 8'b00000000, OP_LDAC = 8'b00000001, OP_STAC = 8'b00000010,
           OP_MVAC = 8'b00000011, OP_MOVR = 8'b00000100, OP_JUMP = 8'b00000101,
           OP_JMPZ = 8'b00000110, OP_JPNZ = 8'b00000111, OP_ADD = 8'b00001000,
           OP_SUB = 8'b00001001, OP_INAC = 8'b00001010, OP_CLAC = 8'b00001011,
           OP_AND = 8'b00001100, OP_OR = 8'b00001101, OP_XOR = 8'b00001110,
           OP_NOT = 8'b00001111;