module alu (
    input wire [7:0] A, // AC Input
    input wire [7:0] B, // R Input
    
    // Arithmetic Control Signals
    input wire add, sub, inc, clr,
    
    // Logic Control Signals
    input wire and_op, or_op, xor_op, not_op,
    
    // Outputs
    output reg [7:0] result,      // Feeds back to the bus -> AC
    output wire zero              // Feeds into the Z flag reg
);

    wire [7:0] arith_out;
    wire [7:0] logic_out;
    wire arith_active, logic_active;
    
    //Arithmetic Unit
    
    assign arith_out = add ? (A + B) :
                       sub ? (A - B) :
                       inc ? (A + 8'd1) :
                       clr ? 8'd0 : 
                       8'd0; // Default to 0 if no Arithmetic Input is Selected
                       
   //Logic Unit
   
   assign logic_out = and_op ? (A & B) :
                       or_op  ? (A | B) :
                       xor_op ? (A ^ B) :
                       not_op ? (~A) : 
                       8'd0; // Default to 0 if no Logic Input is Selected
                       
   //Selection Select
   
   assign arith_active  = add | sub | inc | clr;
   assign logic_active = and_op | or_op | xor_op | not_op;
   
   // Mux
   
    always @(*) begin
        if (arith_active)      result = arith_out;
        else if (logic_active) result = logic_out;
        else                   result = A; // Pass-through default
    end
    
    assign zero = (result == 8'd0);
    
endmodule