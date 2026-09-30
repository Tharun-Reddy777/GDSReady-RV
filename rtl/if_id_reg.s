module if_id_reg (
    input  wire        clk,
    input  wire        reset,
    input  wire        stall,
    input  wire        flush,

    input  wire [31:0] pc_in,
    input  wire [31:0] instruction_in,

    output reg  [31:0] pc_out,
    output reg  [31:0] instruction_out
);

    always @(posedge clk) begin
        if (reset) begin
            pc_out          <= 32'd0;
            instruction_out <= 32'd0;
        end
        else if (flush) begin
            pc_out          <= 32'd0;
            instruction_out <= 32'd0;
        end
        else if (!stall) begin
            pc_out          <= pc_in;
            instruction_out <= instruction_in;
        end
    end

endmodule
