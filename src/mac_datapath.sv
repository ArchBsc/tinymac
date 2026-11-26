`default_nettype none

module mac_datapath (
    input  logic               clk,
    input  logic               rst_n,
    input  logic signed [3:0]  x,
    input  logic signed [3:0]  w,
    input  logic signed [7:0]  bias,
    input  logic               acc_we,
    input  logic               mac_en,
    input  logic               load_bias,
    output logic signed [15:0] acc
);

    // Εσωτερικά σήματα (καλώδια) του datapath
    logic signed [7:0]  product;
    logic signed [15:0] bias_ext;
    logic signed [16:0] sum_ext;
    logic signed [15:0] sum_sat;
    logic signed [15:0] acc_next;

    // ---------------------------------------------------------
    // 1. Συνδυαστική λογική δεδομένων (συνεχείς αναθέσεις)
    // ---------------------------------------------------------
    // Πολλαπλασιασμός: signed 4-bit * signed 4-bit -> signed 8-bit
    assign product  = x * w;

    // Επέκταση προσήμου (sign extension) του 8-bit bias στα 16 bits
    assign bias_ext = $signed({{8{bias[7]}}, bias});

    // Πρόσθεση σε 17 bits για ασφαλή εντοπισμό υπερχείλισης (overflow)
    assign sum_ext  = $signed({acc[15], acc}) + $signed({{9{product[7]}}, product});

    // Κορεσμός (saturation) στα όρια signed 16-bit [+32767, -32768]
    assign sum_sat  = (sum_ext > 17'sd32767)  ? 16'sh7FFF :
                      (sum_ext < -17'sd32768) ? 16'sh8000 :
                                                $signed(sum_ext[15:0]);

    // ---------------------------------------------------------
    // 2. Πολυπλέκτης επιλογής επόμενης τιμής συσσωρευτή
    // ---------------------------------------------------------
    always_comb begin
        acc_next = acc; // Προεπιλογή: διατήρηση τρέχουσας τιμής (και για μη έγκυρους συνδυασμούς)
        if (acc_we) begin
            if (mac_en && !load_bias) begin
                acc_next = sum_sat;   // Λειτουργία MAC: ACC + (x * w)
            end else if (!mac_en && load_bias) begin
                acc_next = bias_ext;  // Λειτουργία LOAD_BIAS: φόρτωση bias
            end
        end
    end

    // ---------------------------------------------------------
    // 3. Ακολουθιακή λογική (καταχωρητής συσσωρευτή 16-bit)
    // ---------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= 16'sd0;      // Ασύγχρονος μηδενισμός όταν rst_n = 0
        end else begin
            acc <= acc_next;    // Ενημέρωση στην ανερχόμενη ακμή του clk
        end
    end

endmodule

`default_nettype wire