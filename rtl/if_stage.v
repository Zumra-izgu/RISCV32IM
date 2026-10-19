/*
Instruction fetch stage is written in sequential logic. 
*/

`include "defines.vh"

module if_stage (

    input wire        clk,
    input wire        rst,
    input wire        stall,
    input wire        flush,
    input wire [31:0] pc_target,
    input wire [31:0] pc_jalr_target,
    input wire [1:0]  pc_sel,

    // IF/ID register outputs 

    output reg [31:0] pc_out,
    output reg [31:0] instr_out
);

    wire [31:0] pc_reg;
    wire [31:0] pc_plus4 = pc_reg + 32'd4;
    wire [31:0] pc_next;


    //MUX structure for selecting the next PC target
    
    assign pc_next =    (pc_sel == 2'b00) ? pc_plus4 : //sequential (normal execution)
                        (pc_sel == 2'b01) ? pc_target: //branch  
                        (pc_sel == 2'b10) ? pc_target: //JAL
                        pc_jalr_target;                //JALR - In EX, its encoding is 2'b11

    
    
    
    pc pc_inst(
        .clk        (clk),
        .rst        (rst),
        .stall      (stall),
        .pc_next    (pc_next),
        .pc_out     (pc_reg)
    );


    /* 
    Instruction Memory [combinational ROM (Read Only Memory)]
    If the load is not overwhelming combinational works better than sequential. Otherwise, 
    it would generate long queues for processes can be executed immediately. 
    */

    wire [31:0] instr_fetch;
    instr_mem imem (
        .addr   (pc_reg),
        .instr  (instr_fetch)
    );

    //IF/ID Pipeline Register (clocked)

    always @(posedge clk) begin
        if(rst || flush) begin
            pc_out      <= 32'b0;
            instr_out   <= 32'h00000013; // NOP:addi x0, x0, 0

        end else if (!stall) begin
            pc_out      <= pc_reg;
            instr_out   <= instr_fetch;
        end 
        
        // stall = 1 nothing is assigned, which means old values are preserved. 
        
        end
    
   


endmodule