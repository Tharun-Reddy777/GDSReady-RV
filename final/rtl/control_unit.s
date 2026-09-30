module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,

    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        alu_src,
    output reg        branch,
    output reg        branch_ne,
    output reg        jump,
    output reg [3:0]  alu_ctrl
);

    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_AND = 4'b0010;
    localparam ALU_OR  = 4'b0011;
    localparam ALU_XOR = 4'b0100;
    localparam ALU_SLT = 4'b0101;
    localparam ALU_SLL = 4'b0110;
    localparam ALU_SRL = 4'b0111;
    localparam ALU_SRA = 4'b1000;

    always @(*) begin

        // Safe defaults
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;
        alu_src   = 1'b0;
        branch    = 1'b0;
        branch_ne = 1'b0;
        jump      = 1'b0;
        alu_ctrl  = ALU_ADD;

        case (opcode)

            // =====================================================
            // R-type
            // ADD, SUB, AND, OR, XOR, SLT, SLL, SRL, SRA
            // =====================================================
            7'b0110011: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;

                case (funct3)

                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            alu_ctrl = ALU_SUB;
                        else
                            alu_ctrl = ALU_ADD;
                    end

                    3'b111: alu_ctrl = ALU_AND;
                    3'b110: alu_ctrl = ALU_OR;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b001: alu_ctrl = ALU_SLL;
                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_ctrl = ALU_SRA;
                        else
                            alu_ctrl = ALU_SRL;
                    end

                    default: alu_ctrl = ALU_ADD;

                endcase
            end

            // =====================================================
            // I-type ALU
            // ADDI, ANDI, ORI, XORI, SLTI, SLLI, SRLI, SRAI
            // =====================================================
            7'b0010011: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;

                case (funct3)

                    3'b000: alu_ctrl = ALU_ADD; // ADDI
                    3'b111: alu_ctrl = ALU_AND; // ANDI
                    3'b110: alu_ctrl = ALU_OR;  // ORI
                    3'b100: alu_ctrl = ALU_XOR; // XORI
                    3'b010: alu_ctrl = ALU_SLT; // SLTI
                    3'b001: alu_ctrl = ALU_SLL; // SLLI

                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_ctrl = ALU_SRA;
                        else
                            alu_ctrl = ALU_SRL;
                    end

                    default: alu_ctrl = ALU_ADD;

                endcase
            end

            // =====================================================
            // LW
            // =====================================================
            7'b0000011: begin
                reg_write = 1'b1;
                mem_read  = 1'b1;
                mem_to_reg = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = ALU_ADD;
            end

            // =====================================================
            // SW
            // =====================================================
            7'b0100011: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = ALU_ADD;
            end

            // =====================================================
            // Conditional branches
            // funct3 = 000 -> BEQ
            // funct3 = 001 -> BNE
            // =====================================================
            7'b1100011: begin
                branch   = 1'b1;
                alu_src  = 1'b0;
                alu_ctrl = ALU_SUB;

                case (funct3)
                    3'b000: branch_ne = 1'b0; // BEQ
                    3'b001: branch_ne = 1'b1; // BNE
                    default: branch_ne = 1'b0;
                endcase
            end

            // =====================================================
            // JAL
            // =====================================================
            7'b1101111: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = ALU_ADD;
            end

            default: begin
                reg_write = 1'b0;
            end

        endcase
    end

endmodule
