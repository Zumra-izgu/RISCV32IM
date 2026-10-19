/*
In this code file, load hazard is addressed.
*/


module hazard_unit (
    input wire [4:0] rs1_id,
    input wire [4:0] rs2_id,
    input wire [4:0] rd_ex,
    input wire       mem_read_ex, // It is a signal, which indicated whether the instruction is a load instruction or not. 

    output reg       stall,
    output reg       bubble      // flushes ID/EX instead of IF/ID
);


    always @(*) begin
        stall  = 1'b0;
        bubble = 1'b0;

        /*
        Load-use hazard: the instruction in ID uses a register that
        is being loaded by the instruction currently in EX, which means
        that even though forwarding is implemented, it won't be fast enough
        to prevent ALU using old values of the variables. For this reason, 
        a stall is injected and consequently, forwarding is executed. 
        */

        if (mem_read_ex && rd_ex != 5'b0 && (rd_ex == rs1_id || rd_ex == rs2_id)) begin

            stall  = 1'b1;   // keep PC and IF/ID unchanged
            bubble = 1'b1;   // make ID/EX a NOP for one cycle

        end
    end
endmodule