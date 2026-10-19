module data_mem (
    input wire        clk,
    input wire        we,
    input wire [31:0] addr,
    input wire [31:0] wd,
    output wire [31:0] rd
);
    reg [31:0] mem [0:31];
    integer i;
    initial for (i = 0; i < 32; i = i + 1) mem[i] = 32'b0;
    always @(posedge clk) if (we) mem[addr >> 2] <= wd;
    assign rd = mem[addr >> 2];
endmodule