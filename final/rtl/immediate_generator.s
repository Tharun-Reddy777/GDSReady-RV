module immediate_generator (
    input  wire [31:0] instruction,
    output reg  [31:0] immediate
);

    wire [6:0] opcode;

    assign opcode = instruction[6:0];

    always @(*) begin
        immediate = 32'd0;

        case (opcode)

            // I-type: ALU immediate instructions and LW
            7'b0010011: begin
                immediate = {{20{instruction[31]}},
                             instruction[31:20]};
            end

            7'b0000011: begin
                immediate = {{20{instruction[31]}},
                             instruction[31:20]};
            end

            // S-type: SW
            7'b0100011: begin
                immediate = {{20{instruction[31]}},
                             instruction[31:25],
                             instruction[11:7]};
            end

            // B-type: BEQ / BNE
            7'b1100011: begin
                immediate = {{19{instruction[31]}},
                             instruction[31],
                             instruction[7],
                             instruction[30:25],
                             instruction[11:8],
                             1'b0};
            end

            // J-type: JAL
            7'b1101111: begin
                immediate = {{11{instruction[31]}},
                             instruction[31],
                             instruction[19:12],
                             instruction[20],
                             instruction[30:21],
                             1'b0};
            end

            default: begin
                immediate = 32'd0;
            end

        endcase
    end

endmodule
