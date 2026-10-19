module instr_mem (
    input wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] mem [0:31];
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) mem[i] = 32'h00000013;
        mem[0] = 32'h03400493; // addi s1, zero, 52
        mem[1] = 32'hffc48513; // addi a0, s1, -4
        mem[2] = 32'h01042583; // lw  s3, 16(a0)
        mem[3] = 32'h01342023; // sw  s3, 1(a0)      -> addr = 49 (0x31)
        mem[4] = 32'h01340433; // xor s2, a0, s3
        mem[5] = 32'h01316633; // or  s2, s2, s3
        mem[6] = 32'h028004b3; // mul  s1, s1, a0
        mem[7] = 32'h028004b3; // div  s1, s1, a0
    end
    assign instr = mem[addr >> 2];
endmodule