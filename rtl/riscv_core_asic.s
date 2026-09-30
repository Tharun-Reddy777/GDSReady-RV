module riscv_core_asic (
    input  wire        clk,
    input  wire        reset,

    // Instruction memory interface
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,

    // Data memory interface
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    input  wire [31:0] dmem_rdata,
    output wire        dmem_read,
    output wire        dmem_write,

    // Debug / verification outputs
    output wire [31:0] debug_pc,
    output wire [31:0] debug_wb_data,
    output wire [4:0]  debug_wb_rd,
    output wire        debug_wb_valid
);

    // ============================================================
    // IF STAGE
    // ============================================================

    wire [31:0] pc;
    wire [31:0] next_pc;
    wire [31:0] instruction;

    wire        pc_stall;
    wire        if_id_stall;
    wire        id_ex_flush;

    program_counter u_pc (
        .clk     (clk),
        .reset   (reset),
        .stall   (pc_stall),
        .next_pc (next_pc),
        .pc      (pc)
    );

    // ASIC-facing instruction memory interface
    assign imem_addr = pc;
    assign instruction = imem_rdata;

    wire [31:0] pc_plus4;

    assign pc_plus4 = pc + 32'd4;


    // ============================================================
    // IF/ID PIPELINE REGISTER
    // ============================================================

    wire [31:0] if_id_pc;
    wire [31:0] if_id_instruction;

    wire branch_taken;
    wire [31:0] branch_target;

    if_id_reg u_if_id (
        .clk             (clk),
        .reset           (reset),
        .stall           (if_id_stall),
        .flush           (branch_taken),

        .pc_in           (pc),
        .instruction_in  (instruction),

        .pc_out          (if_id_pc),
        .instruction_out (if_id_instruction)
    );


    // ============================================================
    // ID STAGE
    // ============================================================

    wire [6:0] id_opcode;
    wire [4:0] id_rd;
    wire [2:0] id_funct3;
    wire [4:0] id_rs1;
    wire [4:0] id_rs2;
    wire [6:0] id_funct7;

    instruction_decoder u_decoder (
        .instruction (if_id_instruction),

        .opcode      (id_opcode),
        .rd          (id_rd),
        .funct3      (id_funct3),
        .rs1         (id_rs1),
        .rs2         (id_rs2),
        .funct7      (id_funct7)
    );


    wire [31:0] id_immediate;

    immediate_generator u_imm (
        .instruction (if_id_instruction),
        .immediate    (id_immediate)
    );


    wire        id_reg_write;
    wire        id_mem_read;
    wire        id_mem_write;
    wire        id_mem_to_reg;
    wire        id_alu_src;
    wire        id_branch;
    wire        id_branch_ne;
    wire        id_jump;
    wire [3:0]  id_alu_ctrl;

    control_unit u_control (
        .opcode     (id_opcode),
        .funct3     (id_funct3),
        .funct7     (id_funct7),

        .reg_write  (id_reg_write),
        .mem_read   (id_mem_read),
        .mem_write  (id_mem_write),
        .mem_to_reg (id_mem_to_reg),
        .alu_src    (id_alu_src),
        .branch     (id_branch),
        .branch_ne   (id_branch_ne),
        .jump       (id_jump),
        .alu_ctrl   (id_alu_ctrl)
    );


    // ============================================================
    // WRITEBACK CONNECTIONS
    // ============================================================

    wire [31:0] wb_write_data;


    // ============================================================
    // REGISTER FILE
    // ============================================================

    wire [31:0] regfile_rs1_data;
    wire [31:0] regfile_rs2_data;

    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;

    wire [4:0] mem_wb_rd;
    wire       mem_wb_reg_write;

    register_file u_regfile (
        .clk        (clk),
        .reset      (reset),

        .reg_write  (mem_wb_reg_write),
        .rs1        (id_rs1),
        .rs2        (id_rs2),
        .rd         (mem_wb_rd),
        .write_data (wb_write_data),

        .read_data1 (regfile_rs1_data),
        .read_data2 (regfile_rs2_data)
    );


    // ============================================================
    // EXPLICIT WB-TO-ID BYPASS
    // ============================================================

    wire wb_to_id_rs1;
    wire wb_to_id_rs2;

    assign wb_to_id_rs1 =
        mem_wb_reg_write &&
        (mem_wb_rd != 5'd0) &&
        (mem_wb_rd == id_rs1);

    assign wb_to_id_rs2 =
        mem_wb_reg_write &&
        (mem_wb_rd != 5'd0) &&
        (mem_wb_rd == id_rs2);

    assign id_rs1_data =
        wb_to_id_rs1 ? wb_write_data : regfile_rs1_data;

    assign id_rs2_data =
        wb_to_id_rs2 ? wb_write_data : regfile_rs2_data;


    // ============================================================
    // HAZARD DETECTION
    // ============================================================

    wire [4:0] id_ex_rd;
    wire       id_ex_mem_read;

    hazard_detection u_hazard (
        .if_id_rs1     (id_rs1),
        .if_id_rs2     (id_rs2),

        .id_ex_rd      (id_ex_rd),
        .id_ex_mem_read(id_ex_mem_read),

        .pc_stall      (pc_stall),
        .if_id_stall   (if_id_stall),
        .id_ex_flush   (id_ex_flush)
    );


    // ============================================================
    // ID/EX PIPELINE REGISTER
    // ============================================================

    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_rs1_data;
    wire [31:0] id_ex_rs2_data;
    wire [31:0] id_ex_immediate;

    wire [4:0]  id_ex_rs1;
    wire [4:0]  id_ex_rs2;

    wire [2:0]  id_ex_funct3;
    wire [6:0]  id_ex_funct7;

    wire        id_ex_reg_write;
    wire        id_ex_mem_write;
    wire        id_ex_mem_to_reg;
    wire        id_ex_alu_src;
    wire        id_ex_branch;
    wire        id_ex_branch_ne;
    wire        id_ex_jump;
    wire [3:0]  id_ex_alu_ctrl;

    id_ex_reg u_id_ex (
        .clk           (clk),
        .reset         (reset),
        .flush         (id_ex_flush | branch_taken),

        .pc_in         (if_id_pc),
        .rs1_data_in   (id_rs1_data),
        .rs2_data_in   (id_rs2_data),
        .immediate_in  (id_immediate),

        .rs1_in        (id_rs1),
        .rs2_in        (id_rs2),
        .rd_in         (id_rd),

        .funct3_in     (id_funct3),
        .funct7_in     (id_funct7),

        .reg_write_in  (id_reg_write),
        .mem_read_in   (id_mem_read),
        .mem_write_in  (id_mem_write),
        .mem_to_reg_in (id_mem_to_reg),
        .alu_src_in    (id_alu_src),
        .branch_in     (id_branch),
        .branch_ne_in  (id_branch_ne),
        .jump_in       (id_jump),

        .alu_ctrl_in   (id_alu_ctrl),

        .pc_out        (id_ex_pc),
        .rs1_data_out  (id_ex_rs1_data),
        .rs2_data_out  (id_ex_rs2_data),
        .immediate_out (id_ex_immediate),

        .rs1_out       (id_ex_rs1),
        .rs2_out       (id_ex_rs2),
        .rd_out        (id_ex_rd),

        .funct3_out    (id_ex_funct3),
        .funct7_out    (id_ex_funct7),

        .reg_write_out (id_ex_reg_write),
        .mem_read_out  (id_ex_mem_read),
        .mem_write_out (id_ex_mem_write),
        .mem_to_reg_out(id_ex_mem_to_reg),
        .alu_src_out   (id_ex_alu_src),
        .branch_out    (id_ex_branch),
        .branch_ne_out (id_ex_branch_ne),
        .jump_out      (id_ex_jump),

        .alu_ctrl_out  (id_ex_alu_ctrl)
    );


    // ============================================================
    // EX STAGE
    // ============================================================

    wire [1:0] forward_a;
    wire [1:0] forward_b;

    wire [31:0] ex_mem_alu_result;
    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_mem_data;

    wire [31:0] ex_operand_a;
    wire [31:0] ex_forwarded_b;
    wire [31:0] ex_operand_b;

    assign ex_operand_a =
        (forward_a == 2'b10) ? ex_mem_alu_result :
        (forward_a == 2'b01) ? wb_write_data :
                                id_ex_rs1_data;

    assign ex_forwarded_b =
        (forward_b == 2'b10) ? ex_mem_alu_result :
        (forward_b == 2'b01) ? wb_write_data :
                                id_ex_rs2_data;

    assign ex_operand_b =
        id_ex_alu_src ? id_ex_immediate : ex_forwarded_b;


    forwarding_unit u_forwarding (
        .id_ex_rs1       (id_ex_rs1),
        .id_ex_rs2       (id_ex_rs2),

        .ex_mem_rd       (ex_mem_rd),
        .ex_mem_reg_write(ex_mem_reg_write),

        .mem_wb_rd       (mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),

        .forward_a       (forward_a),
        .forward_b       (forward_b)
    );


    wire [31:0] alu_result;
    wire        alu_zero;

    alu u_alu (
        .a        (ex_operand_a),
        .b        (ex_operand_b),
        .alu_ctrl (id_ex_alu_ctrl),

        .result   (alu_result),
        .zero     (alu_zero)
    );


    // ============================================================
    // BRANCH / JUMP
    // ============================================================

    branch_unit u_branch (
        .branch      (id_ex_branch),
        .branch_ne   (id_ex_branch_ne),
        .jump        (id_ex_jump),
        .alu_zero    (alu_zero),

        .pc          (id_ex_pc),
        .immediate   (id_ex_immediate),

        .take_branch (branch_taken),
        .target_pc   (branch_target)
    );

    assign next_pc = branch_taken ? branch_target : pc_plus4;


    // ============================================================
    // EX/MEM PIPELINE REGISTER
    // ============================================================

    wire [31:0] ex_mem_rs2_data;
    wire [31:0] ex_mem_pc_plus4;

    wire        ex_mem_mem_read;
    wire        ex_mem_mem_write;
    wire        ex_mem_mem_to_reg;

    wire [4:0]  ex_mem_rd;

    wire        ex_mem_reg_write;
    wire        ex_mem_jump;

    ex_mem_reg u_ex_mem (
        .clk           (clk),
        .reset         (reset),

        .alu_result_in (alu_result),
        .rs2_data_in   (ex_forwarded_b),
        .pc_plus4_in   (id_ex_pc + 32'd4),

        .rd_in         (id_ex_rd),

        .reg_write_in  (id_ex_reg_write),
        .mem_read_in   (id_ex_mem_read),
        .mem_write_in  (id_ex_mem_write),
        .mem_to_reg_in (id_ex_mem_to_reg),
        .jump_in       (id_ex_jump),

        .alu_result_out(ex_mem_alu_result),
        .rs2_data_out  (ex_mem_rs2_data),
        .pc_plus4_out  (ex_mem_pc_plus4),

        .rd_out        (ex_mem_rd),

        .reg_write_out (ex_mem_reg_write),
        .mem_read_out  (ex_mem_mem_read),
        .mem_write_out (ex_mem_mem_write),
        .mem_to_reg_out(ex_mem_mem_to_reg),
        .jump_out      (ex_mem_jump)
    );


    // ============================================================
    // DATA MEMORY INTERFACE
    // ============================================================

    assign dmem_addr  = ex_mem_alu_result;
    assign dmem_wdata = ex_mem_rs2_data;
    assign dmem_read  = ex_mem_mem_read;
    assign dmem_write = ex_mem_mem_write;


    // ============================================================
    // MEM/WB PIPELINE REGISTER
    // ============================================================

    wire [31:0] mem_wb_pc_plus4;

    wire        mem_wb_mem_to_reg;
    wire        mem_wb_jump;

    mem_wb_reg u_mem_wb (
        .clk           (clk),
        .reset         (reset),

        .mem_data_in   (dmem_rdata),
        .alu_result_in (ex_mem_alu_result),
        .pc_plus4_in   (ex_mem_pc_plus4),

        .rd_in         (ex_mem_rd),

        .reg_write_in  (ex_mem_reg_write),
        .mem_to_reg_in (ex_mem_mem_to_reg),
        .jump_in       (ex_mem_jump),

        .mem_data_out  (mem_wb_mem_data),
        .alu_result_out(mem_wb_alu_result),
        .pc_plus4_out  (mem_wb_pc_plus4),

        .rd_out        (mem_wb_rd),

        .reg_write_out (mem_wb_reg_write),
        .mem_to_reg_out(mem_wb_mem_to_reg),
        .jump_out      (mem_wb_jump)
    );


    // ============================================================
    // WRITEBACK
    // ============================================================

    assign wb_write_data =
        mem_wb_jump ? mem_wb_pc_plus4 :
        mem_wb_mem_to_reg ? mem_wb_mem_data :
                            mem_wb_alu_result;


    // ============================================================
    // DEBUG / VERIFICATION
    // ============================================================

    assign debug_pc       = pc;
    assign debug_wb_data  = wb_write_data;
    assign debug_wb_rd    = mem_wb_rd;
    assign debug_wb_valid = mem_wb_reg_write;

endmodule
