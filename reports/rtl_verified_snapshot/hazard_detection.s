module hazard_detection (
    input  wire [4:0] if_id_rs1,
    input  wire [4:0] if_id_rs2,

    input  wire [4:0] id_ex_rd,
    input  wire        id_ex_mem_read,

    output reg         pc_stall,
    output reg         if_id_stall,
    output reg         id_ex_flush
);

    always @(*) begin

        pc_stall    = 1'b0;
        if_id_stall = 1'b0;
        id_ex_flush = 1'b0;

        // Load-use hazard
        if (id_ex_mem_read &&
            (id_ex_rd != 5'd0) &&
            ((id_ex_rd == if_id_rs1) ||
             (id_ex_rd == if_id_rs2))) begin

            pc_stall    = 1'b1;
            if_id_stall = 1'b1;
            id_ex_flush = 1'b1;
        end

    end

endmodule
