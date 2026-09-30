module mem_wb_reg (
    input  wire        clk,
    input  wire        reset,

    input  wire [31:0] mem_data_in,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] pc_plus4_in,

    input  wire [4:0]  rd_in,

    input  wire        reg_write_in,
    input  wire        mem_to_reg_in,
    input  wire        jump_in,

    output reg  [31:0] mem_data_out,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] pc_plus4_out,

    output reg  [4:0]  rd_out,

    output reg         reg_write_out,
    output reg         mem_to_reg_out,
    output reg         jump_out
);

    always @(posedge clk) begin
        if (reset) begin
            mem_data_out   <= 32'd0;
            alu_result_out <= 32'd0;
            pc_plus4_out   <= 32'd0;

            rd_out         <= 5'd0;

            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            jump_out       <= 1'b0;
        end
        else begin
            mem_data_out   <= mem_data_in;
            alu_result_out <= alu_result_in;
            pc_plus4_out   <= pc_plus4_in;

            rd_out         <= rd_in;

            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            jump_out       <= jump_in;
        end
    end

endmodule
