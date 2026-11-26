`timescale 1ns/1ps
`default_nettype none

module tb_datapath;

    // Σήματα σύνδεσης με το DUT (Device Under Test)
    logic               clk;
    logic               rst_n;
    logic signed [3:0]  x;
    logic signed [3:0]  w;
    logic signed [7:0]  bias;
    logic               acc_we;
    logic               mac_en;
    logic               load_bias;
    logic signed [15:0] acc;

    int errors = 0;

    // Στιγμιοποίηση του mac_datapath
    mac_datapath dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .x         (x),
        .w         (w),
        .bias      (bias),
        .acc_we    (acc_we),
        .mac_en    (mac_en),
        .load_bias (load_bias),
        .acc       (acc)
    );

    // Παραγωγή ρολογιού περιόδου 10 ns (100 MHz)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Βοηθητική διαδικασία ελέγχου της εξόδου acc
    task check_acc(input logic signed [15:0] expected, input string test_name);
        begin
            if (acc !== expected) begin
                $display("[FAIL] %s | Αναμενόμενο: %0d, Πραγματικό: %0d (t=%0t)",
                         test_name, expected, acc, $time);
                errors++;
            end else begin
                $display("[PASS] %s | acc = %0d", test_name, acc);
            end
        end
    endtask

    initial begin
        // Καταγραφή κυματομορφών για τον Surfer / GTKWave
        $dumpfile("tb_datapath.vcd");
        $dumpvars(0, tb_datapath);

        // Αρχικοποίηση εισόδων
        rst_n     = 1'b0;
        x         = 4'sd0;
        w         = 4'sd0;
        bias      = 8'sd0;
        acc_we    = 1'b0;
        mac_en    = 1'b0;
        load_bias = 1'b0;

        // 1. Έλεγχος ασύγχρονου reset
        #3;
        check_acc(16'sd0, "1. Async Reset");
        @(negedge clk);
        rst_n = 1'b1;

        // 2. LOAD_BIAS με θετική τιμή (+25)
        @(negedge clk);
        bias = 8'sd25; acc_we = 1'b1; mac_en = 1'b0; load_bias = 1'b1;
        @(posedge clk); #1;
        check_acc(16'sd25, "2. LOAD_BIAS (+25)");

        // 3. LOAD_BIAS με αρνητική τιμή (-10) -> έλεγχος sign extension
        @(negedge clk);
        bias = -8'sd10; acc_we = 1'b1; mac_en = 1'b0; load_bias = 1'b1;
        @(posedge clk); #1;
        check_acc(-16'sd10, "3. LOAD_BIAS (-10, sign extension)");

        // 4. MAC (+3 * +4 = +12) -> -10 + 12 = +2
        @(negedge clk);
        x = 4'sd3; w = 4'sd4; acc_we = 1'b1; mac_en = 1'b1; load_bias = 1'b0;
        @(posedge clk); #1;
        check_acc(16'sd2, "4. MAC (+3 * +4)");

        // 5. MAC (+5 * -3 = -15) -> 2 - 15 = -13
        @(negedge clk);
        x = 4'sd5; w = -4'sd3; acc_we = 1'b1; mac_en = 1'b1; load_bias = 1'b0;
        @(posedge clk); #1;
        check_acc(-16'sd13, "5. MAC (+5 * -3)");

        // 6. MAC (-8 * -8 = +64) -> -13 + 64 = +51
        @(negedge clk);
        x = 4'sh8; w = 4'sh8; acc_we = 1'b1; mac_en = 1'b1; load_bias = 1'b0;
        @(posedge clk); #1;
        check_acc(16'sd51, "6. MAC (-8 * -8)");

        // 7. Διατήρηση τιμής όταν acc_we = 0
        @(negedge clk);
        x = 4'sd7; w = 4'sd7; acc_we = 1'b0; mac_en = 1'b1; load_bias = 1'b0;
        @(posedge clk); #1;
        check_acc(16'sd51, "7. Hold (acc_we = 0)");

        // 8. Μη έγκυροι συνδυασμοί ελέγχου (0,0) και (1,1) με acc_we = 1
        @(negedge clk);
        acc_we = 1'b1; mac_en = 1'b0; load_bias = 1'b0;
        @(posedge clk); #1;
        check_acc(16'sd51, "8a. Invalid ctrl (0,0)");

        @(negedge clk);
        acc_we = 1'b1; mac_en = 1'b1; load_bias = 1'b1;
        @(posedge clk); #1;
        check_acc(16'sd51, "8b. Invalid ctrl (1,1)");

        // 9. Ασύγχρονος μηδενισμός εν μέσω λειτουργίας (χωρίς ακμή clk)
        #2;
        rst_n = 1'b0;
        #1;
        check_acc(16'sd0, "9. Mid-run Async Reset");
        @(negedge clk);
        rst_n = 1'b1;

        // 10. Θετικός κορεσμός (+32767): 515 κύκλοι * (+64) = +32960 -> +32767
        @(negedge clk);
        x = 4'sh8; w = 4'sh8; acc_we = 1'b1; mac_en = 1'b1; load_bias = 1'b0;
        repeat (515) @(posedge clk);
        #1;
        check_acc(16'sh7FFF, "10. Positive Saturation (+32767)");

        // Επαναφορά του acc στο 0 μέσω LOAD_BIAS
        @(negedge clk);
        bias = 8'sd0; acc_we = 1'b1; mac_en = 1'b0; load_bias = 1'b1;
        @(posedge clk);

        // 11. Αρνητικός κορεσμός (-32768): 590 κύκλοι * (-56) = -33040 -> -32768
        @(negedge clk);
        x = 4'sh8; w = 4'sd7; acc_we = 1'b1; mac_en = 1'b1; load_bias = 1'b0;
        repeat (590) @(posedge clk);
        #1;
        check_acc(16'sh8000, "11. Negative Saturation (-32768)");

        // Ολοκλήρωση προσομοίωσης
        @(negedge clk);
        acc_we = 1'b0;
        repeat (2) @(posedge clk);

        if (errors == 0) begin
            $display("=== ΟΛΟΙ ΟΙ ΕΛΕΓΧΟΙ ΕΠΙΤΥΧΕΙΣ (0 errors) ===");
        end else begin
            $display("=== ΑΠΟΤΥΧΙΑ: %0d σφάλματα ===", errors);
        end

        $finish;
    end

endmodule

`default_nettype wire