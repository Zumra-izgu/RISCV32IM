module wb_stage (
    input wire        clk,
    input wire        rst,
    input wire        mem_to_reg,
    input wire        reg_write,
    input wire [4:0]  rd,
    input wire [31:0] alu_result,
    input wire [31:0] mem_read_data,
    
    output wire        reg_write_out,
    output wire [4:0]  rd_out,
    output wire [31:0] wd_out
);

    assign reg_write_out = reg_write;
    assign rd_out        = rd;
    assign wd_out        = mem_to_reg ? mem_read_data : alu_result;

endmodule