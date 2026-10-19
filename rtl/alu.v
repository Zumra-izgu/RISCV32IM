`include "defines.vh"

module alu (
    input wire [31:0] a, // 32-bit input_1
    input wire [31:0] b, // 32-bit input_2
    input wire [4:0]  alu_ctrl, 

    /*
    alu_ctrl: Operation type that is extracted in the alu_control.v,
    after reading the data in the instruction memory, 
    which is then passed to ALU.  
    */
    
    output reg [31:0] result,
    output reg        zero
);
 
    /*
    For the shift operations
    Note: As we operate on 32-bit values, 
    sh = 2^5 will not exceed the range. That's 
    why we extract only b[4:0].   
    */

    wire [4:0] sh = b[4:0]; 
    
    wire signed [63:0] a_signed = $signed(a);
    wire signed [63:0] b_signed = $signed(b);
    wire signed [63:0] mul_sout = a_signed * b_signed;


    /*
    As mixed multiplication isn't directly supported,
    so we pretend - $signed({1'b0, b}). 
    */

    //MUL Signed and Unsigned
    wire signed [63:0] mul_suout = a_signed * $signed({1'b0, b}); 

    //MUL Unsigned
    wire [63:0] unsigned_a = {32'b0, a};
    wire [63:0] unsigned_b = {32'b0, b};
    wire [63:0] mul_uout = unsigned_a * unsigned_b;


    //Purely combinational logic 

    always @(*) begin 
        case (alu_ctrl)
            `ALU_ADD:   result = a + b;
            `ALU_SUB:   result = a - b;
            `ALU_XOR:   result = a ^ b;
            `ALU_OR:    result = a | b;
            `ALU_AND:   result = a & b;
            `ALU_SLL:   result = a << sh;
            `ALU_SRL:   result = a >> sh;
            `ALU_SRA:   result = $signed(a) >>> sh;
            
            //Following two operation will return boolean values basically. 
            `ALU_SLT:   result = ($signed(a) < $signed(b) ? 32'd1 : 32'd0); 
            `ALU_SLTU:   result = (a < b) ? 32'd1 : 32'd0; 

            //M-extensions
            `ALU_MUL:   result = a * b; 

            `ALU_MULH:   result = mul_sout[63:32]; 

            `ALU_MULHSU:   result = mul_suout[63:32];

            `ALU_MULHU:   result = mul_uout[63:32];

            `ALU_DIV:  begin 
                if (b == 32'b0) //Zero division potential error handling
                    result = 32'hFFFFFFFF;
                else if (a == 32'h80000000 && b == 32'hFFFFFFFF)
                    result = 32'h80000000; //Conventially, it is set to this value. (RISCV specifications)
                else
                    result = $signed(a) / $signed(b);
        
            end

            `ALU_DIVU:  begin
                if (b == 32'b0)
                    result = 32'hFFFFFFFF;
                else
                    result = a / b;

            end       
       
            `ALU_REM: begin 
                if (b == 32'b0)
                    result = $signed(a);

                else if (a == 32'h80000000 && b == 32'hFFFFFFFF)
                    result = 32'd0; 
                else 
                    result = $signed(a) % $signed(b);
            end   
            
            
            `ALU_REMU: begin
                if (b == 32'b0)
                    result = a;
                else 
                    result = a % b; 
            end 

            
            default: result = 32'b0;
        endcase
        zero = (result == 32'b0);
        
    end

endmodule