`timescale 1ns/1ps

module tb_overflow;

    localparam int DATA_W = 8;
    localparam int ACC_W  = 12; // Deliberately reduced from specified 20 bits.

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic start = 1'b0;
    logic signed [DATA_W-1:0] a_matrix [0:3][0:3];
    logic signed [DATA_W-1:0] b_matrix [0:3][0:3];
    logic done;
    logic signed [ACC_W-1:0] c_matrix [0:3][0:3];
    logic overflow;

    matmul4x4_accel #(.DATA_W(DATA_W), .ACC_W(ACC_W)) dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .a_matrix(a_matrix), .b_matrix(b_matrix),
        .done(done), .c_matrix(c_matrix), .overflow(overflow)
    );

    always #5 clk = ~clk;

    initial begin
        for (int i=0; i<4; i++)
            for (int j=0; j<4; j++) begin
                a_matrix[i][j] = 8'sd127; // +7.9375
                b_matrix[i][j] = 8'sd127;
            end

        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        wait(done);
        // 4 * 127 * 127 = 64516, beyond signed 12-bit +2047.
        if (!overflow) $fatal(1, "FAIL: overflow flag was not asserted");
        if ($signed(c_matrix[0][0]) !== 2047)
            $fatal(1, "FAIL: positive result was not saturated to +2047");
        $display("PASS overflow: C[0][0]=%0d, overflow=%0b",
                 $signed(c_matrix[0][0]), overflow);
        $finish;
    end

endmodule
