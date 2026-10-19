module mem_stage (
    input wire        clk,
    input wire        rst,
    input wire        mem_write,
    input wire        mem_to_reg,
    input wire        reg_write,
    input wire [4:0]  rd,
    input wire [31:0] alu_result_in,
    input wire [31:0] wd,


    output wire [31:0] mem_read_data, // This signal is used in the forwarding unit. 
    output wire [31:0] alu_result_out,
    output wire        mem_to_reg_out,
    output wire        reg_write_out,
    output wire [4:0]  rd_out
);

    data_mem dmem (
        .clk(clk),
        .we(mem_write),
        .addr(alu_result_in),
        .wd(wd),
        .rd(mem_read_data)
    );

    assign alu_result_out = alu_result_in;
    assign mem_to_reg_out = mem_to_reg;
    assign reg_write_out  = reg_write;
    assign rd_out         = rd;

endmodule