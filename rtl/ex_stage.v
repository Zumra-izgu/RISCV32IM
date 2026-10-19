/*
Execute stage is designed with clock, which is sequential.
ALU operations are realized in the stage.
*/

`include "defines.vh"

module ex_stage (
    input wire        clk,
    input wire        rst,
    input wire        flush,

    //Input from ID/EX Registers
    input wire        mem_write_in,
    input wire        mem_read_in,
    input wire        mem_to_reg_in,
    input wire        reg_write_in,
    input wire        system_halt_in,
    input wire        alu_src,

    input wire        branch,
    input wire        jump,
    input wire        is_auipc,
    input wire        is_jalr,

    input wire [1:0]  alu_op,
    input wire [4:0]  rs1,
    input wire [4:0]  rs2,
    input wire [4:0]  rd,
    input wire [31:0] rs1_data,
    input wire [31:0] rs2_data,
    input wire [31:0] imm,
    input wire [2:0]  funct3_ex,
    input wire [6:0]  funct7_ex,
    input wire [31:0] pc_id,

    // 2 bits - 4 possible combinations - forwarding -> 3 occasions
    input wire [1:0]  forward_a,
    input wire [1:0]  forward_b,

    input wire [31:0] alu_mem_out,
    input wire [31:0] alu_wb_out,
    input wire [31:0] mem_data_mem,
    input wire [31:0] mem_data_wb,
    input wire        mem_to_reg_mem,
    input wire        mem_to_reg_wb,
    
    output wire [31:0] pc_target,
    output wire        branch_taken,
    output wire [1:0]  pc_sel,
    output wire [31:0] pc_jalr_target,

    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_store_data,
    output reg [4:0]  mem_rd,
    output reg        mem_write_out,
    output reg        mem_read_out,
    output reg        mem_to_reg_out,
    output reg        mem_reg_write_out,
    output reg        mem_system_halt_out,
    output reg [6:0]  funct_7,
    output reg [2:0]  funct_3

);



    wire [31:0] alu_a, alu_b_raw, alu_b_final;
    wire [4:0]  alu_ctrl;
    wire [31:0] alu_result;
    wire        zero;



    assign alu_a = is_auipc ? pc_id                     :
                   (forward_a == 2'b01) ? alu_mem_out   :
                   (forward_a == 2'b10) ? alu_wb_out    : 
                   rs1_data;





    assign alu_b_raw = (forward_b == 2'b01) ? alu_mem_out :
                       (forward_b == 2'b10) ? alu_wb_out : rs2_data;

    // If the forwarded value comes from a load, use the memory read data

    wire [31:0] alu_b_forwarded;

    assign alu_b_forwarded =
        (forward_b == 2'b01 && mem_to_reg_mem) ? mem_data_mem : //EX/MEM forwarding
        (forward_b == 2'b10 && mem_to_reg_wb)  ? mem_data_wb  : //MEM/WB forwarding. Note: Encoding can be found in forwarding_unit.v
        alu_b_raw;

    assign alu_b_final  = alu_src ? imm : //If b is a set immediate, no need for forwarding.
                          alu_b_forwarded;

      

   

    alu_control ac (
                    .alu_op(alu_op),
                    .funct3(funct3_ex), 
                    .funct7(funct7_ex), 
                    .alu_ctrl(alu_ctrl)
                    );



    alu alu_inst (
                    .a(alu_a), 
                    .b(alu_b_final), 
                    .alu_ctrl(alu_ctrl), 
                    .result(alu_result), 
                    .zero(zero)
                );

        
    assign  pc_jalr_target = alu_result;
    assign  pc_target = pc_id + imm;


    wire beq  = (alu_a == alu_b_forwarded);
    wire bne  = (alu_a != alu_b_forwarded);
    wire blt  = ($signed(alu_a) < $signed(alu_b_forwarded));
    wire bge  = ($signed(alu_a) >= $signed(alu_b_forwarded));
    wire bltu = (alu_a < alu_b_forwarded);
    wire bgeu = (alu_a >= alu_b_forwarded);

    reg cond;
    
    always @(*) begin
        case (funct3_ex)
            `F3_BEQ : cond = beq;
            `F3_BNE : cond = bne;
            `F3_BLT : cond = blt;
            `F3_BGE : cond = bge;
            `F3_BLTU: cond = bltu;
            `F3_BGEU: cond = bgeu;
            default : cond = 1'b0;
        endcase
    end

    assign branch_taken = branch & cond;

    //Determines from what source the data will be taken. 
    assign pc_sel = is_jalr      ? 2'b11    :
                    branch_taken ? 2'b01    :
                    jump         ? 2'b10    :                
                    2'b00; //default

                   
    always @(posedge clk) begin

        if (rst || flush) begin
            // Reset for the previous values  
            mem_alu_result      <= 32'b0;
            mem_store_data      <= 32'b0;
            mem_rd              <= 5'b0;
            mem_write_out       <= 1'b0;
            mem_read_out        <= 1'b0;
            mem_to_reg_out      <= 1'b0;
            mem_reg_write_out   <= 1'b0;
            mem_system_halt_out <= 1'b0;
            funct_7             <= 7'b0;
            funct_3             <= 3'b0;
        end else begin
            mem_alu_result      <= alu_result;
            mem_store_data      <= alu_b_forwarded;
            mem_rd              <= rd;
            mem_write_out       <= mem_write_in ;
            mem_read_out        <= mem_read_in ;
            mem_to_reg_out      <= mem_to_reg_in;
            mem_reg_write_out   <= reg_write_in;
            mem_system_halt_out <= system_halt_in;
            funct_7             <= funct7_ex;
            funct_3             <= funct3_ex;
        end

    end

endmodule