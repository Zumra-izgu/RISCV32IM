/*
This instruction decode section is written in sequential logic. 

*/

`include "defines.vh"

module id_stage (
    input wire        clk,
    input wire        rst,
    input wire        flush,
    input wire [31:0] instr_in,
    input wire [31:0] pc_in,
    input wire [31:0] rf_rs1_data,
    input wire [31:0] rf_rs2_data,
    input wire        wb_reg_write,
    input wire [4:0]  wb_rd_addr,
    input wire [31:0] wb_wd, //write back write data


    output reg        reg_write,
    output reg        alu_src,
    output reg        mem_write,
    output reg        mem_read,
    output reg        mem_to_reg,
    output reg        branch,
    output reg        jump,
    output reg        is_auipc,
    output reg        is_jalr,
    output reg        system_halt,

    output reg [1:0]  alu_op,
    output reg [4:0]  rs1,
    output reg [4:0]  rs2,
    output reg [4:0]  rd,
    output reg [31:0] rs1_data,
    output reg [31:0] rs2_data,
    output reg [31:0] imm,
    output reg [31:0] pc_id
);

    wire [6:0] opcode = instr_in[6:0];
    wire [2:0] funct3 = instr_in[14:12];
    wire [4:0] rs1_addr = instr_in[19:15];
    wire [4:0] rs2_addr = instr_in[24:20];
    wire [4:0] rd_addr  = instr_in[11:7];



    /*
    (1) wb_reg_write             ? -> Is there a register value being written?
    (2) wb_rd_addr == rs1_addr   ? -> Is the register written and read the same?
    (3) wb_rd_addr != 5'b0       ? -> The register is not x0, right?

    If it returns 1, then bypass should be executed, which means that writing the register 
    value should be privileged over reading the register. 
    */

    wire [31:0] rs1_data_comb = (wb_reg_write && wb_rd_addr == rs1_addr && wb_rd_addr != 5'b0) ? wb_wd : rf_rs1_data;
    wire [31:0] rs2_data_comb = (wb_reg_write && wb_rd_addr == rs2_addr && wb_rd_addr != 5'b0) ? wb_wd : rf_rs2_data;




    //Control unit outputs (combinational)
    wire        reg_write_comb;
    wire        alu_src_comb;
    wire        mem_write_comb;
    wire        mem_read_comb;
    wire        mem_to_reg_comb;
    wire        branch_comb;
    wire        jump_comb;
    wire        is_auipc_comb;
    wire        is_jalr_comb;
    wire        system_halt_comb;
    wire [1:0]  alu_op_comb;


    control_unit cu (

        .opcode     (opcode),
        .funct3     (funct3),
        .imm        (instr_in[31:20]), 
        // In cu, only OP_SYSTEM uses imm and it is in I-TYPE.
        .reg_write  (reg_write_comb),
        .alu_src    (alu_src_comb),
        .mem_write  (mem_write_comb),
        .mem_read   (mem_read_comb),
        .mem_to_reg (mem_to_reg_comb),
        .branch     (branch_comb),
        .alu_op     (alu_op_comb),
        .jump       (jump_comb),
        .is_auipc   (is_auipc_comb),
        .is_jalr    (is_jalr_comb),
        .system_halt(system_halt_comb)
    );


    reg [31:0] imm_comb; 
   

    always @(*) begin

        imm_comb = 32'b0;
        
        case (opcode)

            /*
            In RISC-V, all registers are interpreted as signed. For this reason,
            "(instr_in[31] ? 12'hFFF : 12'h000)" sign extend is executed. It checks 
            the sign of the instruction and then, extend the immediate as negatively
            or positively.  
            */

            `OP_IMM, `OP_LOAD, `OP_JALR: begin

                imm_comb[31:20] = (instr_in[31] ? 12'hFFF : 12'h000);
                imm_comb[19:0]  = instr_in[31:12];

            end

            `OP_STORE: begin    
            
                imm_comb[31:20] = (instr_in[31] ? 12'hFFF : 12'h000);
                imm_comb[11:5]  = instr_in[31:25];
                imm_comb[4:0]   = instr_in[11:7];
                
            
            end
            
            `OP_BRANCH: begin
                imm_comb[31:20] = (instr_in[31] ? 12'hFFF : 12'h000);
                imm_comb[12]    = instr_in[31];
                imm_comb[11]    = instr_in[7];
                imm_comb[10:5]  = instr_in[30:25];
                imm_comb[4:1]   = instr_in[11:8];
                imm_comb[0]     = 1'b0;
            
            end

            `OP_JAL: begin

                imm_comb[31:20] = (instr_in[31] ? 12'hFFF : 12'h000);
                imm_comb[19:12] = instr_in[19:12];
                imm_comb[11]    = instr_in[20];
                imm_comb[10:1]  = instr_in[30:21];
                imm_comb[0]     = 1'b0;
            
            end

            `OP_LUI, `OP_AUIPC: begin

                imm_comb[31:12] = instr_in[31:12];
                imm_comb[11:0]  = 12'b0;
            end
            
            default: imm_comb = 32'b0;
        
        endcase
    end
    

    //ID/EX Pipeline Register (clocked, sequential)
    always @(posedge clk) begin
        if(rst || flush) begin
        //Insert NOP into EX
            reg_write   <= 1'b0; // <= means the operation will occur in the rising edge of the clock (non-blocking assignment)
            alu_src     <= 1'b0;
            mem_write   <= 1'b0;
            mem_read    <= 1'b0;
            mem_to_reg  <= 1'b0;
            branch      <= 1'b0;
            jump        <= 1'b0;
            is_auipc    <= 1'b0;
            is_jalr     <= 1'b0;
            system_halt <= 1'b0;
            alu_op      <= 2'b00;
            rs1         <= 5'b0;
            rs2         <= 5'b0;
            rd          <= 5'b0;
            rs1_data    <= 32'b0;
            rs2_data    <= 32'b0;
            imm         <= 32'b0;
            pc_id       <= 32'b0;

            end else begin

            reg_write   <= reg_write_comb;
            alu_src     <= alu_src_comb;
            mem_write   <= mem_write_comb;
            mem_read    <= mem_read_comb;
            mem_to_reg  <= mem_to_reg_comb;
            branch      <= branch_comb;
            jump        <= jump_comb;
            is_auipc    <= is_auipc_comb;
            is_jalr     <= is_jalr_comb;
            system_halt <= system_halt_comb;
            alu_op      <= alu_op_comb;
            rs1         <= rs1_addr;
            rs2         <= rs2_addr;
            rd          <= rd_addr;
            rs1_data    <= rs1_data_comb;
            rs2_data    <= rs2_data_comb;
            imm         <= imm_comb;
            pc_id       <= pc_in;
            
            end

        end 
    
    

endmodule