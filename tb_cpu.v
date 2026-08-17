// ============================================================
//  Testbench: tb_cpu.v
//  DUT     : cpu (Relatively Simple CPU)
//  Tests   : All 16 opcodes via small programs loaded into a
//            256-byte model RAM.  Results are checked with
//            $display pass/fail messages.
//  Sim     : iverilog tb_cpu.v cpu.v alu.v -o sim && ./sim
// ============================================================

`timescale 1ns/1ps

module tb_cpu;

    // --------------------------------------------------------
    //  DUT signals
    // --------------------------------------------------------
    reg         clk;
    reg         rst;
    reg  [7:0]  mem_data_in;
    wire [15:0] mem_addr;
    wire [7:0]  mem_data_out;
    wire        mem_rd;
    wire        mem_wr;

    // --------------------------------------------------------
    //  Model RAM  (256 bytes, byte-addressable)
    // --------------------------------------------------------
    reg [7:0] ram [0:255];

    // --------------------------------------------------------
    //  Instantiate DUT
    // --------------------------------------------------------
    cpu dut (
        .clk         (clk),
        .rst         (rst),
        .mem_data_in (mem_data_in),
        .mem_addr    (mem_addr),
        .mem_data_out(mem_data_out),
        .mem_rd      (mem_rd),
        .mem_wr      (mem_wr)
    );

    // --------------------------------------------------------
    //  Clock  (10 ns period)
    // --------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // --------------------------------------------------------
    //  RAM read/write model
    // --------------------------------------------------------
    always @(*) begin
        if (mem_rd)
            mem_data_in = ram[mem_addr[7:0]];
        else
            mem_data_in = 8'hxx;
    end

    always @(posedge clk) begin
        if (mem_wr)
            ram[mem_addr[7:0]] <= mem_data_out;
    end

    // --------------------------------------------------------
    //  Helper: reset CPU and clear RAM
    // --------------------------------------------------------
    task do_reset;
        integer i;
        begin
            rst = 1;
            for (i = 0; i < 256; i = i+1)
                ram[i] = 8'h00;   // fill with NOP
            @(posedge clk);
            @(posedge clk);
            rst = 0;
        end
    endtask

    // --------------------------------------------------------
    //  Helper: run N clock cycles
    // --------------------------------------------------------
    task run_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i+1)
                @(posedge clk);
        end
    endtask

    // --------------------------------------------------------
    //  Helper: check AC register (accessed via hierarchical ref)
    // --------------------------------------------------------
    `define AC  dut.AC
    `define R   dut.R
    `define PC  dut.PC
    `define Z   dut.Z

    integer pass_cnt;
    integer fail_cnt;

    task check_ac;
        input [7:0] expected;
        input [63:0] test_name;   // up to 8 ASCII chars packed
        begin
            if (`AC === expected) begin
                $display("  PASS  [%s]  AC = 0x%02X", test_name, `AC);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  FAIL  [%s]  AC = 0x%02X  expected 0x%02X",
                          test_name, `AC, expected);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    task check_ram;
        input [7:0]  addr;
        input [7:0]  expected;
        input [63:0] test_name;
        begin
            if (ram[addr] === expected) begin
                $display("  PASS  [%s]  RAM[0x%02X] = 0x%02X", test_name, addr, ram[addr]);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  FAIL  [%s]  RAM[0x%02X] = 0x%02X  expected 0x%02X",
                          test_name, addr, ram[addr], expected);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    task check_z;
        input       expected;
        input [63:0] test_name;
        begin
            if (`Z === expected) begin
                $display("  PASS  [%s]  Z = %b", test_name, `Z);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  FAIL  [%s]  Z = %b  expected %b",
                          test_name, `Z, expected);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // --------------------------------------------------------
    //  Opcode constants (mirrors cpu.v localparams)
    // --------------------------------------------------------
    localparam OP_NOP  = 8'h00, OP_LDAC = 8'h01, OP_STAC = 8'h02,
               OP_MVAC = 8'h03, OP_MOVR = 8'h04, OP_JUMP = 8'h05,
               OP_JMPZ = 8'h06, OP_JPNZ = 8'h07, OP_ADD  = 8'h08,
               OP_SUB  = 8'h09, OP_INAC = 8'h0A, OP_CLAC = 8'h0B,
               OP_AND  = 8'h0C, OP_OR   = 8'h0D, OP_XOR  = 8'h0E,
               OP_NOT  = 8'h0F;

    // --------------------------------------------------------
    //  Waveform dump
    // --------------------------------------------------------
    initial begin
        $dumpfile("tb_cpu.vcd");
        $dumpvars(0, tb_cpu);
    end

    // ============================================================
    //  MAIN TEST SEQUENCE
    // ============================================================
    initial begin
        pass_cnt = 0;
        fail_cnt = 0;

        $display("==============================================");
        $display("  Relatively Simple CPU - Testbench");
        $display("==============================================");

        // ====================================================
        //  TEST 1: NOP
        //    Program:  NOP ; NOP ; NOP
        //    Expected: PC advances, AC unchanged (= 0x00)
        // ====================================================
        $display("\n--- TEST 1: NOP ---");
        do_reset;
        // RAM already full of 0x00 (NOP) after do_reset
        run_cycles(12);     // 3 NOPs x ~4 states each
        check_ac(8'h00, "NOP     ");

        // ====================================================
        //  TEST 2: LDAC -- load immediate value from memory
        //    Program:
        //      [0x00] LDAC  0x00A5   -> AC = ram[0x00A5] = 0x42
        //      [0x03] NOP
        //    Data:
        //      [0xA5] = 0x42
        // ====================================================
        $display("\n--- TEST 2: LDAC ---");
        do_reset;
        ram[8'h00] = OP_LDAC;
        ram[8'h01] = 8'h00;    // address high byte
        ram[8'h02] = 8'hA5;    // address low byte
        ram[8'hA5] = 8'h42;    // data to load
        run_cycles(25);
        check_ac(8'h42, "LDAC    ");

        // ====================================================
        //  TEST 3: STAC -- store AC to memory
        //    Program:
        //      [0x00] LDAC  0x00B0   -> AC = 0x55
        //      [0x03] STAC  0x00C0   -> ram[0xC0] = AC
        //    Data:
        //      [0xB0] = 0x55
        // ====================================================
        $display("\n--- TEST 3: STAC ---");
        do_reset;
        ram[8'h00] = OP_LDAC;
        ram[8'h01] = 8'h00;
        ram[8'h02] = 8'hB0;
        ram[8'hB0] = 8'h55;

        ram[8'h03] = OP_STAC;
        ram[8'h04] = 8'h00;
        ram[8'h05] = 8'hC0;
        run_cycles(50);
        check_ram(8'hC0, 8'h55, "STAC    ");

        // ====================================================
        //  TEST 4: ADD  (AC + R)
        //    Setup:  R = 0x0F, AC = 0x01
        //    Expected: AC = 0x10
        // ====================================================
        $display("\n--- TEST 4: ADD ---");
        do_reset;
        // Load 0x0F into AC then move to R
        ram[8'h00] = OP_LDAC;  ram[8'h01] = 8'h00;  ram[8'h02] = 8'hD0;
        ram[8'hD0] = 8'h0F;
        ram[8'h03] = OP_MVAC;  // R = AC (= 0x0F)
        // Load 0x01 into AC
        ram[8'h04] = OP_LDAC;  ram[8'h05] = 8'h00;  ram[8'h06] = 8'hD1;
        ram[8'hD1] = 8'h01;
        ram[8'h07] = OP_ADD;   // AC = AC + R = 0x01 + 0x0F = 0x10
        run_cycles(80);
        check_ac(8'h10, "ADD     ");

        // ====================================================
        //  TEST 5: SUB  (AC - R)
        //    Setup:  R = 0x20, AC = 0x05  ->  AC = 0x05 - 0x20 (wraps)
        //    OR: R = 0x05, AC = 0x20  ->  AC = 0x1B
        // ====================================================
        $display("\n--- TEST 5: SUB ---");
        do_reset;
        // Load 0x05 into AC -> MVAC -> R = 0x05
        ram[8'h00] = OP_LDAC;  ram[8'h01] = 8'h00;  ram[8'h02] = 8'hD0;
        ram[8'hD0] = 8'h05;
        ram[8'h03] = OP_MVAC;           // R = 0x05
        // Load 0x20 into AC
        ram[8'h04] = OP_LDAC;  ram[8'h05] = 8'h00;  ram[8'h06] = 8'hD1;
        ram[8'hD1] = 8'h20;
        ram[8'h07] = OP_SUB;            // AC = AC - R = 0x20 - 0x05 = 0x1B
        run_cycles(80);
        check_ac(8'h1B, "SUB     ");

        // ====================================================
        //  TEST 6: INAC (increment AC by 1)
        //    Setup:  AC = 0xFF  -> expect AC = 0x00, Z = 1
        // ====================================================
        $display("\n--- TEST 6: INAC (wrap + zero flag) ---");
        do_reset;
        ram[8'h00] = OP_LDAC;  ram[8'h01] = 8'h00;  ram[8'h02] = 8'hD0;
        ram[8'hD0] = 8'hFF;
        ram[8'h03] = OP_INAC;
        run_cycles(40);
        check_ac(8'h00, "INAC    ");
        check_z (1'b1,  "INAC-Z  ");

        // ====================================================
        //  TEST 7: CLAC (clear AC -> 0x00, Z = 1)
        // ====================================================
        $display("\n--- TEST 7: CLAC ---");
        do_reset;
        ram[8'h00] = OP_LDAC;  ram[8'h01] = 8'h00;  ram[8'h02] = 8'hD0;
        ram[8'hD0] = 8'hAB;
        ram[8'h03] = OP_CLAC;
        run_cycles(40);
        check_ac(8'h00, "CLAC    ");
        check_z (1'b1,  "CLAC-Z  ");

        // ====================================================
        //  TEST 8: AND
        //    R = 0xF0, AC = 0x0F -> AC = 0x00, Z = 1
        // ====================================================
        $display("\n--- TEST 8: AND ---");
        do_reset;
        ram[8'h00] = OP_LDAC;  ram[8'h01] = 8'h00;  ram[8'h02] = 8'hD0;
        ram[8'hD0] = 8'hF0;
        ram[8'h03] = OP_MVAC;           // R = 0xF0
        ram[8'h04] = OP_LDAC;  ram[8'h05] = 8'h00;  ram[8'h06] = 8'hD1;
        ram[8'hD1] = 8'h0F;             // AC = 0x0F
        ram[8'h07] = OP_AND;            // AC = 0x0F & 0xF0 = 0x00
        run_cycles(80);
        check_ac(8'h00, "AND     ");
        check_z (1'b1,  "AND-Z   ");

        // ====================================================
        //  TEST 9: OR
        //    R = 0xA0, AC = 0x0B -> AC = 0xAB
        // ====================================================
        $display("\n--- TEST 9: OR ---");
        do_reset;
        ram[8'h00] = OP_LDAC;  ram[8'h01] = 8'h00;  ram[8'h02] = 8'hD0;
        ram[8'hD0] = 8'hA0;
        ram[8'h03] = OP_MVAC;           // R = 0xA0
        ram[8'h04] = OP_LDAC;  ram[8'h05] = 8'h00;  ram[8'h06] = 8'hD1;
        ram[8'hD1] = 8'h0B;             // AC = 0x0B
        ram[8'h07] = OP_OR;             // AC = 0x0B | 0xA0 = 0xAB
        run_cycles(80);
        check_ac(8'hAB, "OR      ");

        // ====================================================
        //  TEST 10: XOR
        //    R = 0xFF, AC = 0xFF -> AC = 0x00, Z = 1
        // ====================================================
        $display("\n--- TEST 10: XOR ---");
        do_reset;
        ram[8'h00] = OP_LDAC;  ram[8'h01] = 8'h00;  ram[8'h02] = 8'hD0;
        ram[8'hD0] = 8'hFF;
        ram[8'h03] = OP_MVAC;           // R = 0xFF
        ram[8'h04] = OP_LDAC;  ram[8'h05] = 8'h00;  ram[8'h06] = 8'hD1;
        ram[8'hD1] = 8'hFF;             // AC = 0xFF
        ram[8'h07] = OP_XOR;            // AC = 0xFF ^ 0xFF = 0x00
        run_cycles(80);
        check_ac(8'h00, "XOR     ");
        check_z (1'b1,  "XOR-Z   ");

        // ====================================================
        //  TEST 11: NOT
        //    AC = 0xAA -> AC = 0x55
        // ====================================================
        $display("\n--- TEST 11: NOT ---");
        do_reset;
        ram[8'h00] = OP_LDAC;  ram[8'h01] = 8'h00;  ram[8'h02] = 8'hD0;
        ram[8'hD0] = 8'hAA;
        ram[8'h03] = OP_NOT;
        run_cycles(40);
        check_ac(8'h55, "NOT     ");

        // ====================================================
        //  TEST 12: MVAC / MOVR  (AC->R and R->AC round-trip)
        //    Load 0x7E into AC, MVAC -> R=0x7E, CLAC, MOVR -> AC=0x7E
        // ====================================================
        $display("\n--- TEST 12: MVAC / MOVR ---");
        do_reset;
        ram[8'h00] = OP_LDAC;  ram[8'h01] = 8'h00;  ram[8'h02] = 8'hD0;
        ram[8'hD0] = 8'h7E;
        ram[8'h03] = OP_MVAC;           // R = 0x7E
        ram[8'h04] = OP_CLAC;           // AC = 0x00
        ram[8'h05] = OP_MOVR;           // AC = R = 0x7E
        run_cycles(60);
        check_ac(8'h7E, "MOVR    ");

        // ====================================================
        //  TEST 13: JUMP (unconditional)
        //    Program at 0x00: JUMP -> 0x0010
        //    At 0x0010: LDAC -> 0x00D0, data = 0x99
        //    If jump works, AC = 0x99
        // ====================================================
        $display("\n--- TEST 13: JUMP ---");
        do_reset;
        ram[8'h00] = OP_JUMP;
        ram[8'h01] = 8'h00;   // target high
        ram[8'h02] = 8'h10;   // target low  -> jump to 0x0010
        // 0x03..0x0F are NOP (0x00 from do_reset)
        ram[8'h10] = OP_LDAC;
        ram[8'h11] = 8'h00;
        ram[8'h12] = 8'hD0;
        ram[8'hD0] = 8'h99;
        run_cycles(60);
        check_ac(8'h99, "JUMP    ");

        // ====================================================
        //  TEST 14: JMPZ (jump if Z == 1)
        //    Set Z=1 via CLAC, then JMPZ -> 0x0020 -> LDAC -> 0xBB
        // ====================================================
        $display("\n--- TEST 14: JMPZ (taken) ---");
        do_reset;
        ram[8'h00] = OP_CLAC;           // AC=0, Z=1
        ram[8'h01] = OP_JMPZ;
        ram[8'h02] = 8'h00;
        ram[8'h03] = 8'h20;             // target 0x0020
        ram[8'h20] = OP_LDAC;
        ram[8'h21] = 8'h00;
        ram[8'h22] = 8'hD0;
        ram[8'hD0] = 8'hBB;
        run_cycles(70);
        check_ac(8'hBB, "JMPZ-T  ");

        // ====================================================
        //  TEST 15: JPNZ (jump if Z == 0)
        //    Load non-zero -> INAC so Z=0, then JPNZ -> 0x0030 -> 0xCC
        // ====================================================
        $display("\n--- TEST 15: JPNZ (taken) ---");
        do_reset;
        ram[8'h00] = OP_LDAC;  ram[8'h01] = 8'h00;  ram[8'h02] = 8'hD1;
        ram[8'hD1] = 8'h01;    // AC = 0x01 (non-zero)
        ram[8'h03] = OP_INAC;  // AC = 0x02, Z = 0
        ram[8'h04] = OP_JPNZ;
        ram[8'h05] = 8'h00;
        ram[8'h06] = 8'h30;    // target 0x0030
        ram[8'h30] = OP_LDAC;
        ram[8'h31] = 8'h00;
        ram[8'h32] = 8'hD2;
        ram[8'hD2] = 8'hCC;
        run_cycles(80);
        check_ac(8'hCC, "JPNZ-T  ");

        // ====================================================
        //  TEST 16: Count-to-5 integration program
        //    Uses LDAC, STAC, INAC, MVAC, SUB, JMPZ, MOVR, JPNZ
        // ====================================================
        $display("\n--- TEST 16: Count-to-5 integration ---");
        do_reset;
        // 0x00: LDAC 0x00F0  (load counter = 0)
        ram[8'h00] = OP_LDAC; ram[8'h01] = 8'h00; ram[8'h02] = 8'hF0;
        ram[8'hF0] = 8'h00;
        // 0x03: STAC 0x00F0  (store counter)
        ram[8'h03] = OP_STAC; ram[8'h04] = 8'h00; ram[8'h05] = 8'hF0;
        // 0x06: INAC          (counter++)
        ram[8'h06] = OP_INAC;
        // 0x07: MVAC          (R = counter)
        ram[8'h07] = OP_MVAC;
        // 0x08: LDAC 0x00F1  (load limit = 5)
        ram[8'h08] = OP_LDAC; ram[8'h09] = 8'h00; ram[8'h0A] = 8'hF1;
        ram[8'hF1] = 8'h05;
        // 0x0B: SUB           (AC = limit - counter; Z=1 when equal)
        ram[8'h0B] = OP_SUB;
        // 0x0C: JMPZ 0x00F2  (if AC==0 i.e. counter==limit, done)
        ram[8'h0C] = OP_JMPZ; ram[8'h0D] = 8'h00; ram[8'h0E] = 8'hF2;
        // 0x0F: MOVR          (restore AC = counter from R)
        ram[8'h0F] = OP_MOVR;
        // 0x10: JPNZ 0x0006  (loop back to INAC)
        ram[8'h10] = OP_JPNZ; ram[8'h11] = 8'h00; ram[8'h12] = 8'h06;
        // 0xF2: MOVR          (done: restore AC = counter = 5)
        ram[8'hF2] = OP_MOVR;
        // 0xF3..end: NOP (halt by spinning on NOPs)
        run_cycles(800);
        check_ac(8'h05, "COUNT-5 ");

        // ====================================================
        //  SUMMARY
        // ====================================================
        $display("\n==============================================");
        $display("  Results: %0d PASSED,  %0d FAILED", pass_cnt, fail_cnt);
        $display("==============================================\n");

        $finish;
    end

endmodule
