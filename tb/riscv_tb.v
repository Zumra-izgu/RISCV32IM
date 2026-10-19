`timescale 1ns/1ps

module riscv_tb;

    reg clk, rst;
    always #5 clk = ~clk;

    riscv_pipeline dut (.clk(clk), .rst(rst));

    integer cycle = 0;
    always @(posedge clk) begin
        cycle = cycle + 1;
        if (cycle < 25) begin
            $display("[%0d] PC=0x%h, instr=0x%h", cycle, dut.pc_if, dut.instr_if);
        end
        if (dut.stall) begin
            $display(">>> [%0d] STALL TRIGGERED! (mem_read_ex=%b, rd_ex=0x%h, rs2_id=0x%h)",
                     cycle, dut.mem_read_ex, dut.rd_ex, dut.rs2_id);
        end
        if (dut.mem_write_ex) begin
            $display("========================================");
            $display(">>> [%0d] STORE IN EX STAGE", cycle);
            $display("    instr_id   = 0x%h", dut.instr_id);
            $display("    rs1_ex     = %0d", dut.rs1_ex);
            $display("    rd_wb      = %0d", dut.rd_wb);
            $display("    reg_write_wb = %0d", dut.reg_write_wb);
            $display("    forward_a  = %0d", dut.forward_a);
            $display("    alu_a      = 0x%h", dut.ex_stage_inst.alu_a);
            $display("    imm_ex     = 0x%h", dut.imm_ex);
            $display("========================================");
        end
        if (dut.mem_write_mem) begin
            $display(">>> [%0d] STORE WRITTEN: addr = 0x%h (decimal %0d), wd = 0x%h",
                     cycle, dut.alu_result_mem, dut.alu_result_mem, dut.alu_operand_b_ex);
        end
    end

    initial begin
        $dumpfile("riscv.vcd");
        $dumpvars(0, riscv_tb);
        clk = 0; rst = 1;
        #10 rst = 0;
        repeat (120) @(posedge clk);
        $display("Simulation finished.");
        $finish;
    end

endmodule