//This should be sequential

module register_file (
    input wire        clk,
    input wire        we,
    input wire [4:0]  rs1_addr,
    input wire [4:0]  rs2_addr,
    input wire [4:0]  rd_addr,
    input wire [31:0] wd,
    output reg [31:0] rs1_data,
    output reg [31:0] rs2_data
);
    //Initialization
    reg [31:0] rf [0:31];
    integer i;
    initial for (i = 0; i < 32; i = i + 1) rf[i] = 32'b0;

    always @(posedge clk) begin
        if (we && rd_addr != 5'b0) rf[rd_addr] <= wd;
    end

    // Combinational read with bypass for same-cycle write
    always @(*) begin
        rs1_data = (rs1_addr == 5'b0) ? 32'b0 : rf[rs1_addr];
        rs2_data = (rs2_addr == 5'b0) ? 32'b0 : rf[rs2_addr];
        if (we && rd_addr != 5'b0) begin
            if (rd_addr == rs1_addr) rs1_data = wd;
            if (rd_addr == rs2_addr) rs2_data = wd;
        end
    end


    always @(posedge clk) begin
        //How do we insert the regiters here after initialization. 
    end 
endmodule