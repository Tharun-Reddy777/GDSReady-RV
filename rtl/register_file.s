module register_file (
    input  wire        clk,
    input  wire        reset,

    input  wire        reg_write,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] write_data,

    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    reg [31:0] regs [0:31];

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
        end
        else if (reg_write && (rd != 5'd0)) begin
            regs[rd] <= write_data;
        end
    end

    // ------------------------------------------------------------
    // Register-file write-through / WB-to-ID bypass
    //
    // If the register being read is simultaneously being written
    // in the WB stage, return the new value instead of the old
    // value stored in the register array.
    // ------------------------------------------------------------

    assign read_data1 =
        (rs1 == 5'd0) ? 32'd0 :
        (reg_write && (rd != 5'd0) && (rd == rs1))
            ? write_data :
            regs[rs1];

    assign read_data2 =
        (rs2 == 5'd0) ? 32'd0 :
        (reg_write && (rd != 5'd0) && (rd == rs2))
            ? write_data :
            regs[rs2];

endmodule
