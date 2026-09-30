module instruction_memory (
    input  wire [31:0] address,
    output wire [31:0] instruction
);

    reg [31:0] memory [0:255];

    integer i;

    initial begin
        // Fill unused instruction memory with RV32I NOPs.
        // NOP = ADDI x0, x0, 0
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'h00000013;

        // Load the complete program.
        $readmemh("tb/programs/program.hex", memory);
    end

    assign instruction = memory[address[9:2]];

endmodule
