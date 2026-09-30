module branch_unit (
    input  wire        branch,
    input  wire        branch_ne,
    input  wire        jump,
    input  wire        alu_zero,

    input  wire [31:0] pc,
    input  wire [31:0] immediate,

    output reg         take_branch,
    output reg  [31:0] target_pc
);

    always @(*) begin
        take_branch = 1'b0;
        target_pc   = pc + immediate;

        if (jump) begin
            take_branch = 1'b1;
        end
        else if (branch) begin
            if (branch_ne)
                take_branch = !alu_zero;   // BNE
            else
                take_branch = alu_zero;    // BEQ
        end
    end

endmodule
