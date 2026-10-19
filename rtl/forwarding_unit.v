/*
In code file, before writing back the operation's
result back to memeory, the value may be wanted to 
use immediately after. This would cause a hazard, as 
the value would not be updated, resulting using 
the old value. For this reason, forwarding unit detects
these type of scenarios and forward the value directly to 
the execute stage to prevent the hazard. 
*/

module forwarding_unit (
    input wire [4:0] rs1_ex, //register
    input wire [4:0] rs2_ex, //register

    input wire [4:0] rd_mem,
    input wire [4:0] rd_wb, //register
    input wire       reg_write_mem, // COntrol signal 
    input wire       reg_write_wb, // Control signal

    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);

    always @(*) begin
        /*
        Following to variables (forward_a, forward_b):

        MUX signals to determine where to get the signal. 
        There are two extraordinary options for that:

        (1) Immediately after ALU finished the operation. (Between EX - MEM)
        (2) Immediately after write back stage, however before writing it to the register file. (Between MEM - WB)
        
        default = Taking value from the register file 

        Encoding for three cases:
        (1)2'b00 -> NOT forwarding case (default)
        (2)2'b01 -> EX/MEM forwarding (RAW - Read After Write) 
        (3)2'b10 -> MEM/WB forwarding 
        */

        forward_a = 2'b00; //Default value   
        forward_b = 2'b00; //Default value  

        // EX/MEM forwarding (highest priority)
        if (reg_write_mem && rd_mem != 5'b0) begin //checking whether it is x0 register as it is always 0 and are not written back. 
            if (rd_mem == rs1_ex) forward_a = 2'b01;
            if (rd_mem == rs2_ex) forward_b = 2'b01;
        end

        // MEM/WB forwarding (lower priority – only if not already forwarded from MEM)
        if (reg_write_wb && rd_wb != 5'b0) begin
            if (rd_wb == rs1_ex && forward_a == 2'b00) forward_a = 2'b10; // Checking whether forward_a has been done or not. It is for implying forwarding priority.  
            if (rd_wb == rs2_ex && forward_b == 2'b00) forward_b = 2'b10;
        end
    end

endmodule