/*
In this file, control signals are generated which 
will accompany the instruction along the whole 
pipeline. And they are going to be used in the
associated stage. This action is attributed to the 
instruction decode (ID) stage. 
*/

`include "defines.vh"

module control_unit (

    input wire [6:0]    opcode,
    input wire [2:0]    funct3,
    input wire [11:0]   imm,



    output reg       reg_write, //write result back to register file (WB stage)
    output reg       alu_src, //Determines whether the operand is an immediate or not.
    output reg       mem_write,
    output reg       mem_read,
    output reg       mem_to_reg,
    output reg       branch,
    output reg [1:0] alu_op,
    output reg       jump,
    output reg       is_auipc,
    output reg       is_jalr,
    output reg       system_halt
);

    always @(*) begin

        // Following two lines are to prevent possible latch errors.
        reg_write = 1'b0;
        alu_src = 1'b0;
        mem_write = 1'b0;
        mem_read = 1'b0;
        mem_to_reg = 1'b0;
        branch = 1'b0;
        jump = 1'b0;
        is_auipc = 1'b0; 
        is_jalr = 1'b0;
        system_halt = 1'b0; 
        alu_op = 2'b00;

        case (opcode)

            `OP_LUI, `OP_AUIPC: begin
                reg_write = 1'b1; 
                alu_src = 1'b1;
                alu_op = 2'b00;
                if (opcode == `OP_AUIPC) 
                    is_auipc = 1'b1;
            end

            `OP_JAL: begin
                reg_write = 1'b1; 
                alu_src = 1'b1; 
                jump = 1'b1;
                alu_op = 2'b00;
            end

            `OP_JALR: begin
                reg_write = 1'b1; 
                alu_src = 1'b1; 
                jump = 1'b1;
                is_jalr = 1'b1;
                alu_op = 2'b00;
            end

            `OP_IMM: begin
                reg_write = 1'b1; 
                alu_src = 1'b1; 
                alu_op = 2'b11; //check alu_control.v file
            end


            `OP_REG: begin
                reg_write = 1'b1; 
                alu_src = 1'b0; 
                alu_op = 2'b10;
            end

            `OP_LOAD: begin
                reg_write = 1'b1; 
                alu_src = 1'b1; 
                mem_read = 1'b1; 
                mem_to_reg = 1'b1; 
                alu_op = 2'b00;
            end

            `OP_STORE: begin
                alu_src = 1'b1; 
                mem_write = 1'b1; 
                alu_op = 2'b00;
            end

            `OP_BRANCH: begin
                branch = 1'b1; 
                alu_src = 1'b0; //The operand b is rs2
                alu_op = 2'b01; 

                /*
                RISCV developers' preference:
                ((a - b) == 0 ?) == 1 => a is eqaul to b. 
                */

            end

            `OP_FENCE: begin
            // Empty on purpose.
            end

            `OP_SYSTEM: begin 
            if (funct3 == 3'b000) begin
                if (imm == 12'h000 || imm == 12'h001) begin // 12-bit because immediate in I-type is 12-bits 
                    system_halt = 1'b1;
                end
                


            end 
            end 
        default: ;
        endcase
        
    end

endmodule