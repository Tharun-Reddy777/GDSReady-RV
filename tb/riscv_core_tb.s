`timescale 1ns/1ps

module riscv_core_tb;

    reg clk;
    reg reset;

    integer errors;

    riscv_core dut (
        .clk   (clk),
        .reset (reset)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        errors = 0;

        $dumpfile("riscv_core.vcd");
        $dumpvars(0, riscv_core_tb);

        reset = 1'b1;

        #20;

        reset = 1'b0;

        #250;

        $display("");
        $display("==============================================");
        $display("RV32I JAL VERIFICATION");
        $display("==============================================");

        $display("x1 = %h", dut.u_regfile.regs[1]);
        $display("x2 = %h", dut.u_regfile.regs[2]);
        $display("x3 = %h", dut.u_regfile.regs[3]);

        // JAL x1,+8 must save PC+4 = 4
        if (dut.u_regfile.regs[1] !== 32'h00000004) begin
            $display("ERROR: x1 expected 00000004");
            errors = errors + 1;
        end

        // Target instruction sets x2 = 7.
        // The wrong-path x2 = 99 must be flushed.
        if (dut.u_regfile.regs[2] !== 32'h00000007) begin
            $display("ERROR: x2 expected 00000007");
            errors = errors + 1;
        end

        // x3 = x1 + 1 = 5
        if (dut.u_regfile.regs[3] !== 32'h00000005) begin
            $display("ERROR: x3 expected 00000005");
            errors = errors + 1;
        end

        $display("");

        if (errors == 0)
            $display("PASS: JAL TEST");
        else
            $display("FAIL: %0d ERROR(S)", errors);

        $display("==============================================");

        $finish;
    end

endmodule
