module cpu (
    input wire clk,
    input wire rst,
    // Memory Interface
    input wire [7:0] mem_data_in,   // Data read from RAM
    output reg [15:0] mem_addr,     // Address sent to RAM
    output reg [7:0] mem_data_out,  // Data written to RAM
    output reg mem_rd,              // Memory read enable
    output reg mem_wr               // Memory write enable
    
        // ALU Control Wires
    wire alu_add  = (current_state == ADD1);
    wire alu_sub  = (current_state == SUB1);
    wire alu_inc  = (current_state == INAC1);
    wire alu_clr  = (current_state == CLAC1);
    wire alu_and  = (current_state == AND1);
    wire alu_or   = (current_state == OR1);
    wire alu_xor  = (current_state == XOR1);
    wire alu_not  = (current_state == NOT1);

    // ALU Outputs
    wire [7:0] alu_out;
    wire alu_zero;

    // Instantiate the ALU
    alu u_alu (
        .A(AC), 
        .B(R),
        .add(alu_add), .sub(alu_sub), .inc(alu_inc), .clr(alu_clr),
        .and_op(alu_and), .or_op(alu_or), .xor_op(alu_xor), .not_op(alu_not),
        .result(alu_out), 
        .zero(alu_zero)
);

    //internal registers
    reg [15:0] AR, PC;
    reg [7:0] DR, IR, TR, AC, R;
    reg Z;

// Finite State Machine (FSM) states (6 bits for 39 states)

    localparam [5:0] 
        FETCH1 = 6'd0,  FETCH2 = 6'd1,  FETCH3 = 6'd2,
        LDAC1  = 6'd3,  LDAC2  = 6'd4,  LDAC3  = 6'd5,  LDAC4  = 6'd6,  LDAC5  = 6'd7,
        STAC1  = 6'd8,  STAC2  = 6'd9,  STAC3  = 6'd10, STAC4  = 6'd11, STAC5  = 6'd12,
        JUMP1  = 6'd13, JUMP2  = 6'd14, JUMP3  = 6'd15,
        JMPZY1 = 6'd16, JMPZY2 = 6'd17, JMPZY3 = 6'd18, // JMPZ Taken
        JPNYZ1 = 6'd19, JPNYZ2 = 6'd20, JPNYZ3 = 6'd21, // JPNZ Taken
        ADD1   = 6'd22, SUB1   = 6'd23, INAC1  = 6'd24, CLAC1  = 6'd25,
        AND1   = 6'd26, OR1    = 6'd27, XOR1   = 6'd28, NOT1   = 6'd29,
        MVAC1  = 6'd30, MOVR1  = 6'd31, NOP1   = 6'd32;

    reg [5:0] current_state, next_state;

// Opcode Parameters

localparam OP_NOP  = 8'b00000000, OP_LDAC = 8'b00000001, OP_STAC = 8'b00000010,
           OP_MVAC = 8'b00000011, OP_MOVR = 8'b00000100, OP_JUMP = 8'b00000101,
           OP_JMPZ = 8'b00000110, OP_JPNZ = 8'b00000111, OP_ADD = 8'b00001000,
           OP_SUB = 8'b00001001, OP_INAC = 8'b00001010, OP_CLAC = 8'b00001011,
           OP_AND = 8'b00001100, OP_OR = 8'b00001101, OP_XOR = 8'b00001110,
           OP_NOT = 8'b00001111;

always @(*) begin
    next_state = FETCH1; // Default state
    case(current_state)
        //FETCH CYCLE
        FETCH1: next_state = FETCH2;
        FETCH2: next_state = FETCH3;
        FETCH3: begin
            //decide next state based on IR
            case(IR)
                OP_LDAC: next_state = LDAC1;
                OP_STAC: next_state = STAC1;
                OP_MVAC: next_state = MVAC1;
                OP_MOVR: next_state = MOVR1;
                OP_JUMP: next_state = JUMP1;
                OP_JMPZ: next_state = JMPZY1; // Check Z flag later
                OP_JPNZ: next_state = JPNYZ1; // Check Z flag later
                OP_ADD:  next_state = ADD1;
                OP_SUB:  next_state = SUB1;
                OP_INAC: next_state = INAC1;
                OP_CLAC: next_state = CLAC1;
                OP_AND:  next_state = AND1;
                OP_OR:   next_state = OR1;
                OP_XOR:  next_state = XOR1;
                OP_NOT:  next_state = NOT1;
                default: next_state = NOP1; // For unrecognized opcodes
            endcase
        end

            // --- LDAC Cycle ---
            LDAC1: next_state = LDAC2; LDAC2: next_state = LDAC3; LDAC3: next_state = LDAC4; 
            LDAC4: next_state = LDAC5; LDAC5: next_state = FETCH1;

            // --- STAC Cycle ---
            STAC1: next_state = STAC2; STAC2: next_state = STAC3; STAC3: next_state = STAC4; 
            STAC4: next_state = STAC5; STAC5: next_state = FETCH1;

            // --- JUMP Cycle ---
            JUMP1: next_state = JUMP2; JUMP2: next_state = JUMP3; JUMP3: next_state = FETCH1;

            // --- JMPZ Cycle (Taken) ---
            JMPZY1: next_state = JMPZY2; JMPZY2: next_state = JMPZY3; JMPZY3: next_state = FETCH1;

            // --- JPNZ Cycle (Taken) ---
            JPNYZ1: next_state = JPNYZ2; JPNYZ2: next_state = JPNYZ3; JPNYZ3: next_state = FETCH1;

            // --- 1-Byte Instructions (1 state only) ---
            ADD1, SUB1, INAC1, CLAC1, AND1, OR1, XOR1, NOT1, 
            MVAC1, MOVR1, NOP1: next_state = FETCH1;
        endcase
    end

always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= FETCH1;
            PC <= 16'd0; AR <= 16'd0; DR <= 8'd0; IR <= 8'd0; TR <= 8'd0; AC <= 8'd0; R <= 8'd0; Z <= 1'b0;
            mem_addr <= 16'd0; mem_data_out <= 8'd0; mem_rd <= 1'b0; mem_wr <= 1'b0;
        end else begin
            current_state <= next_state;
            mem_rd <= 1'b0; // Default inactive
            mem_wr <= 1'b0; // Default inactive
            
            
    