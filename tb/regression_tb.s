`timescale 1ns/1ps

module regression_tb;

    reg clk;
    reg reset;

    integer errors;
    integer test_number;
    integer i;

    riscv_core dut (
        .clk   (clk),
        .reset (reset)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Run one test by loading its program into instruction memory
    // ------------------------------------------------------------
    task run_test;
        input [8*32-1:0] test_name;
        input [8*64-1:0] program_file;
        begin
            test_number = test_number + 1;

            $display("");
            $display("==============================================");
            $display("TEST %0d: %0s", test_number, test_name);
            $display("==============================================");

            // Reset CPU/registers.
            reset = 1'b1;
            #20;

            // Clear register file explicitly for deterministic tests.
            dut.u_regfile.regs[0] = 32'd0;
            dut.u_regfile.regs[1] = 32'd0;
            dut.u_regfile.regs[2] = 32'd0;
            dut.u_regfile.regs[3] = 32'd0;
            dut.u_regfile.regs[4] = 32'd0;
            dut.u_regfile.regs[5] = 32'd0;
            dut.u_regfile.regs[6] = 32'd0;

            // Load the selected program.
            $readmemh(program_file, dut.u_imem.memory);

            reset = 1'b0;

            // Let the five-stage pipeline execute.
            #250;

            $display("x1 = %h", dut.u_regfile.regs[1]);
            $display("x2 = %h", dut.u_regfile.regs[2]);
            $display("x3 = %h", dut.u_regfile.regs[3]);
            $display("x4 = %h", dut.u_regfile.regs[4]);
            $display("x5 = %h", dut.u_regfile.regs[5]);
            $display("x6 = %h", dut.u_regfile.regs[6]);
        end
    endtask

    initial begin
        errors = 0;
        test_number = 0;

        $dumpfile("riscv_regression.vcd");
        $dumpvars(0, regression_tb);

        // --------------------------------------------------------
        // TEST 1: ALU + forwarding
        // --------------------------------------------------------

        reset = 1'b1;
        #20;

        // Clear instruction memory to NOPs before loading this test.
        for (i = 0; i < 256; i = i + 1)
            dut.u_imem.memory[i] = 32'h00000013;

        $readmemh("tb/regression/alu.hex", dut.u_imem.memory);

        reset = 1'b0;

        #150;

        $display("");
        $display("==============================================");
        $display("TEST 1: ALU + FORWARDING");
        $display("==============================================");

        $display("x1 = %h", dut.u_regfile.regs[1]);
        $display("x2 = %h", dut.u_regfile.regs[2]);
        $display("x3 = %h", dut.u_regfile.regs[3]);
        $display("x4 = %h", dut.u_regfile.regs[4]);
        $display("x5 = %h", dut.u_regfile.regs[5]);

        if (dut.u_regfile.regs[1] !== 32'h00000005) errors = errors + 1;
        if (dut.u_regfile.regs[2] !== 32'h0000000A) errors = errors + 1;
        if (dut.u_regfile.regs[3] !== 32'h0000000F) errors = errors + 1;
        if (dut.u_regfile.regs[4] !== 32'hFFFFFFFB) errors = errors + 1;
        if (dut.u_regfile.regs[5] !== 32'h0000000A) errors = errors + 1;

        if (errors == 0)
            $display("PASS: ALU + FORWARDING");
        else
            $display("FAIL: ALU + FORWARDING");

        // --------------------------------------------------------
        // TEST 2: LW/SW + load-use hazard
        // --------------------------------------------------------

        reset = 1'b1;
        #20;

        // Clear instruction memory to NOPs before loading this test.
        for (i = 0; i < 256; i = i + 1)
            dut.u_imem.memory[i] = 32'h00000013;

        $readmemh("tb/regression/load_store.hex", dut.u_imem.memory);

        dut.u_regfile.regs[0] = 32'd0;
        dut.u_regfile.regs[1] = 32'd0;
        dut.u_regfile.regs[2] = 32'd0;
        dut.u_regfile.regs[3] = 32'd0;
        dut.u_regfile.regs[4] = 32'd0;

        reset = 1'b0;

        #200;

        $display("");
        $display("==============================================");
        $display("TEST 2: LOAD/STORE + LOAD-USE");
        $display("==============================================");

        $display("x1 = %h", dut.u_regfile.regs[1]);
        $display("x2 = %h", dut.u_regfile.regs[2]);
        $display("x3 = %h", dut.u_regfile.regs[3]);
        $display("x4 = %h", dut.u_regfile.regs[4]);
        $display("memory[2] = %h", dut.u_dmem.memory[2]);

        if (dut.u_regfile.regs[1] !== 32'h00000008) errors = errors + 1;
        if (dut.u_regfile.regs[2] !== 32'h00000001) errors = errors + 1;
        if (dut.u_dmem.memory[2] !== 32'h00000001) errors = errors + 1;
        if (dut.u_regfile.regs[3] !== 32'h00000001) errors = errors + 1;
        if (dut.u_regfile.regs[4] !== 32'h00000009) errors = errors + 1;

        if (dut.u_regfile.regs[1] === 32'h00000008 &&
            dut.u_regfile.regs[2] === 32'h00000001 &&
            dut.u_dmem.memory[2] === 32'h00000001 &&
            dut.u_regfile.regs[3] === 32'h00000001 &&
            dut.u_regfile.regs[4] === 32'h00000009)
            $display("PASS: LOAD/STORE + LOAD-USE");
        else
            $display("FAIL: LOAD/STORE + LOAD-USE");

        // --------------------------------------------------------
        // TEST 3: BEQ/BNE
        // --------------------------------------------------------

        reset = 1'b1;
        #20;

        // Clear instruction memory to NOPs before loading this test.
        for (i = 0; i < 256; i = i + 1)
            dut.u_imem.memory[i] = 32'h00000013;

        $readmemh("tb/regression/branch.hex", dut.u_imem.memory);

        dut.u_regfile.regs[0] = 32'd0;
        dut.u_regfile.regs[1] = 32'd0;
        dut.u_regfile.regs[2] = 32'd0;
        dut.u_regfile.regs[3] = 32'd0;
        dut.u_regfile.regs[4] = 32'd0;
        dut.u_regfile.regs[5] = 32'd0;
        dut.u_regfile.regs[6] = 32'd0;

        reset = 1'b0;

        #300;

        $display("");
        $display("==============================================");
        $display("TEST 3: BEQ/BNE");
        $display("==============================================");

        $display("x1 = %h", dut.u_regfile.regs[1]);
        $display("x2 = %h", dut.u_regfile.regs[2]);
        $display("x3 = %h", dut.u_regfile.regs[3]);
        $display("x5 = %h", dut.u_regfile.regs[5]);
        $display("x6 = %h", dut.u_regfile.regs[6]);

        if (dut.u_regfile.regs[1] !== 32'h00000001) errors = errors + 1;
        if (dut.u_regfile.regs[2] !== 32'h00000001) errors = errors + 1;
        if (dut.u_regfile.regs[3] !== 32'h00000007) errors = errors + 1;
        if (dut.u_regfile.regs[5] !== 32'h00000002) errors = errors + 1;
        if (dut.u_regfile.regs[6] !== 32'h00000009) errors = errors + 1;

        if (dut.u_regfile.regs[1] === 32'h00000001 &&
            dut.u_regfile.regs[2] === 32'h00000001 &&
            dut.u_regfile.regs[3] === 32'h00000007 &&
            dut.u_regfile.regs[5] === 32'h00000002 &&
            dut.u_regfile.regs[6] === 32'h00000009)
            $display("PASS: BEQ/BNE");
        else
            $display("FAIL: BEQ/BNE");

        // --------------------------------------------------------
        // TEST 4: JAL
        // --------------------------------------------------------

        reset = 1'b1;
        #20;

        // Clear instruction memory to NOPs before loading this test.
        for (i = 0; i < 256; i = i + 1)
            dut.u_imem.memory[i] = 32'h00000013;

        $readmemh("tb/regression/jal.hex", dut.u_imem.memory);

        dut.u_regfile.regs[0] = 32'd0;
        dut.u_regfile.regs[1] = 32'd0;
        dut.u_regfile.regs[2] = 32'd0;
        dut.u_regfile.regs[3] = 32'd0;

        reset = 1'b0;

        #250;

        $display("");
        $display("==============================================");
        $display("TEST 4: JAL");
        $display("==============================================");

        $display("x1 = %h", dut.u_regfile.regs[1]);
        $display("x2 = %h", dut.u_regfile.regs[2]);
        $display("x3 = %h", dut.u_regfile.regs[3]);

        if (dut.u_regfile.regs[1] !== 32'h00000004) errors = errors + 1;
        if (dut.u_regfile.regs[2] !== 32'h00000007) errors = errors + 1;
        if (dut.u_regfile.regs[3] !== 32'h00000005) errors = errors + 1;

        if (dut.u_regfile.regs[1] === 32'h00000004 &&
            dut.u_regfile.regs[2] === 32'h00000007 &&
            dut.u_regfile.regs[3] === 32'h00000005)
            $display("PASS: JAL");
        else
            $display("FAIL: JAL");

        // --------------------------------------------------------
        // FINAL RESULT
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("FINAL RTL REGRESSION RESULT");
        $display("==============================================");

        if (errors == 0) begin
            $display("ALL RTL REGRESSION TESTS PASSED");
            $display("RESULT: PASS");
        end
        else begin
            $display("TOTAL ERRORS = %0d", errors);
            $display("RESULT: FAIL");
        end

        $display("==============================================");

        $finish;
    end

endmodule
