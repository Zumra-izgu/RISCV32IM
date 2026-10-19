`include "defines.vh"

module riscv_pipeline (
    input wire clk,
    input wire rst
);

    // ----- IF/ID -----
    reg [31:0] pc_id_reg, instr_id_reg;
    wire [31:0] pc_id = pc_id_reg;
    wire [31:0] instr_id = instr_id_reg;

    // ----- ID/EX pipeline registers -----
    reg         reg_write_ex, alu_src_ex, mem_write_ex, mem_read_ex, mem_to_reg_ex;
    reg         branch_ex, jump_ex, is_auipc_ex, is_jalr_ex;
    reg  [1:0]  alu_op_ex;
    reg  [4:0]  rs1_ex, rs2_ex, rd_ex;
    reg  [31:0] rs1_data_ex, rs2_data_ex, imm_ex, pc_ex;
    reg  [2:0]  funct3_ex;
    reg  [6:0]  funct7_ex;

    // ----- EX outputs -----
    wire [31:0] alu_result_ex, alu_operand_b_ex;
    wire        zero_ex, branch_taken_ex;
    wire [31:0] pc_target_ex, pc_jalr_target_ex;
    wire [1:0]  pc_sel_ex;
    wire        mem_write_ex_out, mem_to_reg_ex_out, reg_write_ex_out;
    wire [4:0]  rd_ex_out;

    // ----- EX/MEM pipeline registers -----
    reg [31:0] alu_result_mem;
    reg        mem_to_reg_mem, reg_write_mem, mem_write_mem;
    reg [4:0]  rd_mem;

    // ----- MEM/WB pipeline registers -----
    reg         mem_to_reg_wb, reg_write_wb;
    reg  [4:0]  rd_wb;
    reg  [31:0] alu_result_wb, mem_read_data_wb;

    // ----- Hazard and Forwarding -----
    wire        stall, bubble;
    wire [1:0]  forward_a, forward_b;
    wire        flush_if_id;

    // ----- Register File -----
    wire [31:0] rf_rs1_data, rf_rs2_data, wd_wb_signal;

    // ----- IF signals -----
    wire [31:0] pc_if, instr_if;

    // ----- ID signals -----
    wire        reg_write_id, alu_src_id, mem_write_id, mem_read_id, mem_to_reg_id;
    wire        branch_id, jump_id, is_auipc_id, is_jalr_id;
    wire [1:0]  alu_op_id;
    wire [4:0]  rs1_id, rs2_id, rd_id;
    wire [31:0] rs1_data_id, rs2_data_id, imm_id, pc_id_out;

    // ----- Instances -----
    register_file rf_core (
        .clk(clk),
        .we(reg_write_wb),
        .rs1_addr(rs1_id),
        .rs2_addr(rs2_id),
        .rd_addr(rd_wb),
        .wd(wd_wb_signal),
        .rs1_data(rf_rs1_data),
        .rs2_data(rf_rs2_data)
    );

    if_stage if_stage_inst (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush_if_id),
        .pc_target(pc_target_ex),
        .pc_jalr_target(pc_jalr_target_ex),
        .pc_sel(pc_sel_ex),
        .pc_out(pc_if),
        .instr_out(instr_if)
    );

    // IF/ID register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_id_reg <= 32'b0;
            instr_id_reg <= 32'h00000013;
        end else if (flush_if_id) begin
            pc_id_reg <= 32'b0;
            instr_id_reg <= 32'h00000013;
        end else if (!stall) begin
            pc_id_reg <= pc_if;
            instr_id_reg <= instr_if;
        end
    end

    // ID stage
    id_stage id_stage_inst (
        .clk(clk),
        .rst(rst),
        .flush(flush_if_id),
        .instr_in(instr_id),
        .pc_in(pc_id),
        .rf_rs1_data(rf_rs1_data),
        .rf_rs2_data(rf_rs2_data),
        .wb_reg_write(reg_write_wb),
        .wb_rd_addr(rd_wb),
        .wb_wd(wd_wb_signal),
        .reg_write(reg_write_id),
        .alu_src(alu_src_id),
        .mem_write(mem_write_id),
        .mem_read(mem_read_id),
        .mem_to_reg(mem_to_reg_id),
        .branch(branch_id),
        .jump(jump_id),
        .is_auipc(is_auipc_id),
        .is_jalr(is_jalr_id),
        .alu_op(alu_op_id),
        .rs1(rs1_id),
        .rs2(rs2_id),
        .rd(rd_id),
        .rs1_data(rs1_data_id),
        .rs2_data(rs2_data_id),
        .imm(imm_id),
        .pc_id(pc_id_out)
    );

    // Hazard unit
    hazard_unit hu (
        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .rd_ex(rd_ex),
        .mem_read_ex(mem_read_ex),
        .stall(stall),
        .bubble(bubble)
    );

    // ID/EX register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_write_ex  <= 0; alu_src_ex    <= 0; mem_write_ex  <= 0;
            mem_read_ex   <= 0; mem_to_reg_ex <= 0;
            branch_ex     <= 0; jump_ex       <= 0; is_auipc_ex   <= 0; is_jalr_ex <= 0;
            alu_op_ex     <= 2'b00;
            rs1_ex        <= 0; rs2_ex        <= 0; rd_ex         <= 0;
            rs1_data_ex   <= 0; rs2_data_ex   <= 0; imm_ex        <= 0; pc_ex <= 0;
            funct3_ex     <= 0; funct7_ex     <= 0;
        end else if (bubble) begin
            // Insert NOP – zero all control signals
            reg_write_ex  <= 0; alu_src_ex    <= 0; mem_write_ex  <= 0;
            mem_read_ex   <= 0; mem_to_reg_ex <= 0;
            branch_ex     <= 0; jump_ex       <= 0; is_auipc_ex   <= 0; is_jalr_ex <= 0;
            alu_op_ex     <= 2'b00;
            rs1_ex        <= 0; rs2_ex        <= 0; rd_ex         <= 0;
            rs1_data_ex   <= 0; rs2_data_ex   <= 0; imm_ex        <= 0; pc_ex <= 0;
            funct3_ex     <= 0; funct7_ex     <= 0;
        end else if (!stall) begin
            reg_write_ex  <= reg_write_id;
            alu_src_ex    <= alu_src_id;
            mem_write_ex  <= mem_write_id;
            mem_read_ex   <= mem_read_id;
            mem_to_reg_ex <= mem_to_reg_id;
            branch_ex     <= branch_id;
            jump_ex       <= jump_id;
            is_auipc_ex   <= is_auipc_id;
            is_jalr_ex    <= is_jalr_id;
            alu_op_ex     <= alu_op_id;
            rs1_ex        <= rs1_id;
            rs2_ex        <= rs2_id;
            rd_ex         <= rd_id;
            rs1_data_ex   <= rs1_data_id;
            rs2_data_ex   <= rs2_data_id;
            imm_ex        <= imm_id;
            pc_ex         <= pc_id_out;
            funct3_ex     <= instr_id[14:12];
            funct7_ex     <= instr_id[31:25];
        end
    end

    // Forwarding unit
    forwarding_unit fu (
        .rs1_ex(rs1_ex),
        .rs2_ex(rs2_ex),
        .rd_mem(rd_mem),
        .rd_wb(rd_wb),
        .reg_write_mem(reg_write_mem),
        .reg_write_wb(reg_write_wb),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // Data memory
    wire [31:0] mem_read_data_from_dmem;
    data_mem dmem (
        .clk(clk),
        .we(mem_write_mem),
        .addr(alu_result_mem),
        .wd(alu_operand_b_ex),   // store data comes from EX stage
        .rd(mem_read_data_from_dmem)
    );

    // EX stage – added mem_data ports and mem_to_reg from MEM/WB
    ex_stage ex_stage_inst (
        .clk(clk),
        .rst(rst),
        .mem_write_in(mem_write_ex),
        .mem_to_reg_in(mem_to_reg_ex),
        .reg_write_in(reg_write_ex),
        .alu_src(alu_src_ex),
        .branch(branch_ex),
        .jump(jump_ex),
        .is_auipc(is_auipc_ex),
        .is_jalr(is_jalr_ex),
        .alu_op(alu_op_ex),
        .rs1(rs1_ex),
        .rs2(rs2_ex),
        .rd(rd_ex),
        .rs1_data(rs1_data_ex),
        .rs2_data(rs2_data_ex),
        .imm(imm_ex),
        .pc_id(pc_ex),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .alu_mem_out(alu_result_mem),
        .alu_wb_out(alu_result_wb),
        .mem_data_mem(mem_read_data_from_dmem),   // new
        .mem_data_wb(mem_read_data_wb),           // new
        .mem_to_reg_mem(mem_to_reg_mem),          // new
        .mem_to_reg_wb(mem_to_reg_wb),            // new
        .funct3_ex(funct3_ex),
        .funct7_ex(funct7_ex),
        .alu_result(alu_result_ex),
        .zero(zero_ex),
        .pc_target(pc_target_ex),
        .branch_taken(branch_taken_ex),
        .alu_operand_b(alu_operand_b_ex),
        .pc_sel(pc_sel_ex),
        .pc_jalr_target(pc_jalr_target_ex),
        .mem_write_out(mem_write_ex_out),
        .mem_to_reg_out(mem_to_reg_ex_out),
        .reg_write_out(reg_write_ex_out),
        .rd_out(rd_ex_out)
    );

    // EX/MEM register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result_mem <= 0;
            mem_to_reg_mem <= 0;
            reg_write_mem  <= 0;
            mem_write_mem  <= 0;
            rd_mem         <= 0;
        end else begin
            alu_result_mem <= alu_result_ex;
            mem_to_reg_mem <= mem_to_reg_ex_out;
            reg_write_mem  <= reg_write_ex_out;
            mem_write_mem  <= mem_write_ex_out;
            rd_mem         <= rd_ex_out;
        end
    end

    // MEM/WB register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result_wb    <= 0;
            mem_read_data_wb <= 0;
            reg_write_wb     <= 0;
            mem_to_reg_wb    <= 0;
            rd_wb            <= 0;
        end else begin
            alu_result_wb    <= alu_result_mem;
            mem_read_data_wb <= mem_read_data_from_dmem;
            reg_write_wb     <= reg_write_mem;
            mem_to_reg_wb    <= mem_to_reg_mem;
            rd_wb            <= rd_mem;
        end
    end

    // Write-back mux
    assign wd_wb_signal = mem_to_reg_wb ? mem_read_data_wb : alu_result_wb;

    // Flush IF/ID only for branches/jumps
    assign flush_if_id = branch_taken_ex || jump_ex;

endmodule