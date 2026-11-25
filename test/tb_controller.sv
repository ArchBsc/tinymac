`timescale 1ns/1ps

module tb_controller;

// 1. Καλώδια του πάγκου δοκιμών (ίδια με τα ports του mac_controller)
    logic       clk;
    logic       rst_n;
    logic [1:0] opcode;
    logic       strobe;

    logic       acc_we;
    logic       mac_en;
    logic       load_bias;

    // 2. Σύνδεση (Instantiation) του κυκλώματός μας (DUT = Device Under Test)
    mac_controller dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .opcode    (opcode),
        .strobe    (strobe),
        .acc_we    (acc_we),
        .mac_en    (mac_en),
        .load_bias (load_bias)
    );

    // 3. Γεννήτρια ρολογιού: αλλάζει κάθε 5 ns -> περίοδος 10 ns
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // 4. Σενάρια ελέγχου (Issue #6)
    initial begin
    $dumpfile("tb_controller.vcd");
        $dumpvars(0, tb_controller);

    // --- TEST 1: Reset ενεργό (rst_n = 0) ---
        // Βάζουμε εσκεμμένα strobe=1 & MAC ενώ είμαστε σε reset -> όλα πρέπει να μείνουν 0
        rst_n  = 1'b0;
        opcode = 2'b10; // MAC
        strobe = 1'b1;
        #2;
        if (acc_we !== 0 || mac_en !== 0 || load_bias !== 0)
            $display("FAIL Test 1: Reset active");
        else
            $display("PASS Test 1: Reset active");  
            // Αφήνουμε το reset (rst_n = 1)
        @(negedge clk);
        strobe = 1'b0;
        opcode = 2'b00; // IDLE
        rst_n  = 1'b1;

        // --- TEST 2: IDLE (00) με strobe = 1 ---
        @(negedge clk);
        opcode = 2'b00; // IDLE
        strobe = 1'b1;
        #1;
        if (acc_we !== 0 || mac_en !== 0 || load_bias !== 0)
            $display("FAIL Test 2: IDLE");
        else
            $display("PASS Test 2: IDLE");
            @(posedge clk); // Πάει WAIT_RELEASE
        @(negedge clk);
        strobe = 1'b0;
        @(posedge clk); // Επιστρέφει READY
        
        // --- TEST 3: LOAD_BIAS (01) με strobe = 1 για πολλούς κύκλους ---
        @(negedge clk);
        opcode = 2'b01; // LOAD_BIAS
        strobe = 1'b1;
        #1;
        // 1ος κύκλος (READY): πρέπει acc_we=1, mac_en=0, load_bias=1
        if (acc_we !== 1 || mac_en !== 0 || load_bias !== 1)
            $display("FAIL Test 3a: LOAD_BIAS cycle 1");
        else
            $display("PASS Test 3a: LOAD_BIAS cycle 1");

        @(posedge clk); // Εκτελέστηκε -> τώρα η FSM πήγε WAIT_RELEASE
        #1;
        // 2ος κύκλος (WAIT_RELEASE, strobe ακόμα 1): πρέπει ΟΛΑ 0
        if (acc_we !== 0 || mac_en !== 0 || load_bias !== 0)
            $display("FAIL Test 3b: LOAD_BIAS WAIT_RELEASE (cycle 2)");
        else
            $display("PASS Test 3b: LOAD_BIAS WAIT_RELEASE (cycle 2)");

        @(posedge clk); // Κρατάμε strobe=1 και 3ο κύκλο -> πάλι ΟΛΑ 0
        #1;
        if (acc_we !== 0 || mac_en !== 0 || load_bias !== 0)
            $display("FAIL Test 3c: LOAD_BIAS WAIT_RELEASE (cycle 3)");
        else
            $display("PASS Test 3c: LOAD_BIAS WAIT_RELEASE (cycle 3)");

        // Κατεβάζουμε το strobe=0 για να γυρίσει στο READY
        @(negedge clk);
        strobe = 1'b0;
        @(posedge clk);

 // --- TEST 4: MAC (10) με strobe = 1 ---
        @(negedge clk);
        opcode = 2'b10; // MAC
        strobe = 1'b1;
        #1;
        // 1ος κύκλος (READY): πρέπει acc_we=1, mac_en=1, load_bias=0
        if (acc_we !== 1 || mac_en !== 1 || load_bias !== 0)
            $display("FAIL Test 4a: MAC cycle 1");
        else
            $display("PASS Test 4a: MAC cycle 1");

        @(posedge clk); // Πάει WAIT_RELEASE
        #1;
        if (acc_we !== 0 || mac_en !== 0 || load_bias !== 0)
            $display("FAIL Test 4b: MAC WAIT_RELEASE");
        else
            $display("PASS Test 4b: MAC WAIT_RELEASE");

        // Επιστροφή στο READY
        @(negedge clk);
        strobe = 1'b0;
        @(posedge clk);

  // --- TEST 5: RESERVED (11) με strobe = 1 ---
        @(negedge clk);
        opcode = 2'b11; // RESERVED
        strobe = 1'b1;
        #1;
        if (acc_we !== 0 || mac_en !== 0 || load_bias !== 0)
            $display("FAIL Test 5: RESERVED");
        else
            $display("PASS Test 5: RESERVED");

        @(posedge clk); // Τώρα είμαστε WAIT_RELEASE (με strobe=1)

// --- TEST 6: Ασύγχρονο Reset εν ώρα WAIT_RELEASE ---
        @(negedge clk);
        opcode = 2'b10; // MAC
        rst_n  = 1'b0;  // Πατάμε reset χωρίς να περιμένουμε posedge clk
        #1;
        if (acc_we !== 0 || mac_en !== 0 || load_bias !== 0)
            $display("FAIL Test 6a: Async reset outputs must be 0");
        else
            $display("PASS Test 6a: Async reset outputs are 0");

        // Αφήνουμε το reset ενώ strobe=1 & MAC:
        // Αν το ασύγχρονο reset μας γύρισε όντως στο READY, πρέπει να ενεργοποιηθεί το MAC!
        rst_n = 1'b1;
        #1;
        if (acc_we !== 1 || mac_en !== 1 || load_bias !== 0)
            $display("FAIL Test 6b: Returned to READY after async reset");
        else
            $display("PASS Test 6b: Returned to READY after async reset");

        @(posedge clk);
        #10;
        $display("=== Telos Simulation ===");
        $finish;
    end
    endmodule