/*
This is a header file. Within this file, macros and 
other objects are defined. Information in this document
is used in the other code files. 
*/

`ifndef DEFINES_VH
`define DEFINES_VH

/*
Following encodings such as "7'b0110111" are fixed 
references set by the RISC-V ISA specification. 
*/

//Generic operation encodings (OPCODE)
`define OP_LUI    7'b0110111 
`define OP_AUIPC  7'b0010111
`define OP_JAL    7'b1101111
`define OP_JALR   7'b1100111
`define OP_BRANCH 7'b1100011
`define OP_LOAD   7'b0000011
`define OP_STORE  7'b0100011
`define OP_IMM    7'b0010011
`define OP_REG    7'b0110011 
`define OP_SYSTEM 7'b1110011   // ECALL, EBREAK
`define OP_FENCE  7'b0001111   // FENCE

//Note: M-extensions will also use the opcode of OP_REG.

//FUNCT3 ENCODINGS


//R-TYPE instructions encoding (funct3)
`define F3_ADD  3'b000
`define F3_SUB  3'b000
`define F3_XOR  3'b100
`define F3_OR   3'b110
`define F3_AND  3'b111
`define F3_SLL  3'b001
`define F3_SRL  3'b101
`define F3_SRA  3'b101
`define F3_SLT  3'b010
`define F3_SLTU 3'b011


//I-TYPE instructions encoding (funct3)
`define F3_ADDI   3'b000
`define F3_XORI   3'b100
`define F3_ORI    3'b110
`define F3_ANDI   3'b111
`define F3_SLLI   3'b001
`define F3_SRLI   3'b101
`define F3_SRAI   3'b101
`define F3_SLTI   3'b010 
`define F3_SLTUI  3'b011

//Load instructions (funct3)
`define F3_LB   3'b000
`define F3_LH   3'b001
`define F3_LW   3'b010
`define F3_LBU  3'b100
`define F3_LHU  3'b101


//S-TYPE instructions encoding (funct3)
`define F3_SB   3'b000
`define F3_SH   3'b001
`define F3_SW   3'b010


//B-TYPE instructions encoding (funct3)
`define F3_BEQ  3'b000 // branch equal 
`define F3_BNE  3'b001 // is branch equal?
`define F3_BLT  3'b100 // branch smaller 
`define F3_BGE  3'b101 // branch bigger equal
`define F3_BLTU 3'b110 
`define F3_BGEU 3'b111


//OP_SYSTEM (funct3)
`define F3_SYSTEM   3'b000; //Flag for the privileged instructions


/*
Many R-TYPE and I-TYPE instructions share the same 
funct3 encoding. To differentiate them, additional 
funct7 encodings should be identified as well. 
*/


`define F7_ZERO     7'b0000000 //ADD, XOR, OR, AND, SLL, SRL, SLT, SLTU 
`define F7_SUB      7'b0100000
`define F7_SRA      7'b0100000
`define F7_MULDIV  7'b0000001


//M-EXTENSIONS ENCODING (funct3)
`define F3_MUL      3'b000 
`define F3_MULH     3'b001 
`define F3_MULHSU   3'b010
`define F3_MULHU    3'b011
`define F3_DIV      3'b100 
`define F3_DIVU     3'b101 
`define F3_REM     3'b110          
`define F3_REMU     3'b111


//Immediate Types 
`define IMM_I   3'b000 
`define IMM_S   3'b001
`define IMM_B   3'b010 
`define IMM_U   3'b011 
`define IMM_J   3'b100


//ALU CONTROL CODES ENCODING 

`define ALU_ADD     5'b00000 
`define ALU_SUB     5'b00001 
`define ALU_XOR     5'b00010 
`define ALU_OR      5'b00011 
`define ALU_AND     5'b00100 
`define ALU_SLL     5'b00101 
`define ALU_SRL     5'b00110 
`define ALU_SRA     5'b00111 
`define ALU_SLT     5'b01000 
`define ALU_SLTU    5'b01001 

`define ALU_MUL     5'b01010       
`define ALU_MULH    5'b01011  
`define ALU_MULHSU  5'b01100 
`define ALU_MULHU   5'b01101 
`define ALU_DIV     5'b01110  
`define ALU_DIVU    5'b01111  
`define ALU_REM    5'b10000          
`define ALU_REMU    5'b10001 




`endif