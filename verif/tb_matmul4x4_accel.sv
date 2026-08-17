`timescale 1ns/1ps

module tb_matmul4x4_accel;

    localparam int DATA_W = 8;
    localparam int ACC_W  = 20;

    logic clk;
    logic rst_n;
    logic start;
    logic done;



    logic signed [DATA_W-1:0] a_matrix [0:3][0:3];
    logic signed [DATA_W-1:0] b_matrix [0:3][0:3];


    

    logic signed [ACC_W-1:0] c_matrix [0:3][0:3];

    logic overflow;


    

    integer signed expected [0:3][0:3];


   

    integer total_tests;
    integer total_failures;
    integer seed;


   

    matmul4x4_accel #(
        .DATA_W(DATA_W),
        .ACC_W (ACC_W)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (start),
        .a_matrix (a_matrix),
        .b_matrix (b_matrix),
        .done     (done),
        .c_matrix (c_matrix),
        .overflow (overflow)
    );


   

    initial begin
        clk = 1'b0;
    end

    always #5 clk = ~clk;


   
    task automatic clear_matrices;

        begin

            for (int i = 0; i < 4; i = i + 1) begin

                for (int j = 0; j < 4; j = j + 1) begin

                    a_matrix[i][j] = 0;
                    b_matrix[i][j] = 0;

                end

            end

        end

    endtask


   

    task automatic calculate_expected;

        integer signed sum;

        begin

            for (int i = 0; i < 4; i = i + 1) begin

                for (int j = 0; j < 4; j = j + 1) begin

                    sum = 0;

                    sum = sum
                        + $signed(a_matrix[i][0])
                        * $signed(b_matrix[0][j]);

                    sum = sum
                        + $signed(a_matrix[i][1])
                        * $signed(b_matrix[1][j]);

                    sum = sum
                        + $signed(a_matrix[i][2])
                        * $signed(b_matrix[2][j]);

                    sum = sum
                        + $signed(a_matrix[i][3])
                        * $signed(b_matrix[3][j]);

                    expected[i][j] = sum;

                end

            end

        end

    endtask


    

    task automatic start_operation;

        begin

            @(negedge clk);

            start = 1'b1;

            @(negedge clk);

            start = 1'b0;

        end

    endtask

    task automatic wait_for_done;

        integer timeout;

        begin

            timeout = 0;

            while ((done !== 1'b1) && (timeout < 1000)) begin

                @(posedge clk);

                timeout = timeout + 1;

            end

            if (timeout >= 1000) begin

                $display("");
                $display("ERROR: DUT TIMEOUT");
                $display("");

                $fatal(1);

            end

        end

    endtask


    task automatic check_result;

        integer errors;

        begin

            errors = 0;

            // Wait until accelerator finishes
            wait_for_done();



            for (int i = 0; i < 4; i = i + 1) begin

                for (int j = 0; j < 4; j = j + 1) begin

                    if ($signed(c_matrix[i][j]) !== expected[i][j]) begin

                        $display(
                            "ERROR: C[%0d][%0d] = %0d, expected = %0d",
                            i,
                            j,
                            $signed(c_matrix[i][j]),
                            expected[i][j]
                        );

                        errors = errors + 1;

                    end

                end

            end


            if (overflow !== 1'b0) begin

                $display(
                    "ERROR: overflow = %0b, expected = 0",
                    overflow
                );

                errors = errors + 1;

            end



            if (errors == 0) begin

                $display("PASS");

            end

            else begin

                $display(
                    "FAIL - %0d errors",
                    errors
                );

                total_failures = total_failures + 1;

            end

        end

    endtask


    

    task automatic test_identity;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("TEST 1: IDENTITY x MATRIX");
            $display("----------------------------------------------");


            clear_matrices();


            // Identity matrix A
            //
            // 1.0 = 16 in Q4.4

            a_matrix[0][0] = 8'sd16;
            a_matrix[0][1] = 8'sd0;
            a_matrix[0][2] = 8'sd0;
            a_matrix[0][3] = 8'sd0;

            a_matrix[1][0] = 8'sd0;
            a_matrix[1][1] = 8'sd16;
            a_matrix[1][2] = 8'sd0;
            a_matrix[1][3] = 8'sd0;

            a_matrix[2][0] = 8'sd0;
            a_matrix[2][1] = 8'sd0;
            a_matrix[2][2] = 8'sd16;
            a_matrix[2][3] = 8'sd0;

            a_matrix[3][0] = 8'sd0;
            a_matrix[3][1] = 8'sd0;
            a_matrix[3][2] = 8'sd0;
            a_matrix[3][3] = 8'sd16;


            // Matrix B

            b_matrix[0][0] = 8'sd1;
            b_matrix[0][1] = 8'sd2;
            b_matrix[0][2] = 8'sd3;
            b_matrix[0][3] = 8'sd4;

            b_matrix[1][0] = 8'sd5;
            b_matrix[1][1] = 8'sd6;
            b_matrix[1][2] = 8'sd7;
            b_matrix[1][3] = 8'sd8;

            b_matrix[2][0] = 8'sd9;
            b_matrix[2][1] = 8'sd10;
            b_matrix[2][2] = 8'sd11;
            b_matrix[2][3] = 8'sd12;

            b_matrix[3][0] = 8'sd13;
            b_matrix[3][1] = 8'sd14;
            b_matrix[3][2] = 8'sd15;
            b_matrix[3][3] = 8'sd16;


            calculate_expected();

            start_operation();

            check_result();

            total_tests = total_tests + 1;

        end

    endtask


    task automatic test_zero;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("TEST 2: ZERO x ZERO");
            $display("----------------------------------------------");


            clear_matrices();

            calculate_expected();

            start_operation();

            check_result();

            total_tests = total_tests + 1;

        end

    endtask



    task automatic test_all_ones;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("TEST 3: ALL ONES x ALL ONES");
            $display("----------------------------------------------");


            for (int i = 0; i < 4; i = i + 1) begin

                for (int j = 0; j < 4; j = j + 1) begin

                    a_matrix[i][j] = 8'sd16;
                    b_matrix[i][j] = 8'sd16;

                end

            end


            calculate_expected();

            start_operation();

            check_result();

            total_tests = total_tests + 1;

        end

    endtask



    task automatic test_random;

        integer signed value_a;
        integer signed value_b;

        begin

            for (int i = 0; i < 4; i = i + 1) begin

                for (int j = 0; j < 4; j = j + 1) begin

                    value_a = ($urandom(seed) % 15) - 7;

                    value_b = ($urandom(seed) % 15) - 7;

                    a_matrix[i][j] = value_a;
                    b_matrix[i][j] = value_b;

                end

            end


            calculate_expected();

            start_operation();

            check_result();

            total_tests = total_tests + 1;

        end

    endtask


    initial begin

 

        clk = 1'b0;

        start = 1'b0;

        rst_n = 1'b0;

        total_tests = 0;

        total_failures = 0;

        seed = 12345;


        clear_matrices();


       

        $display("");
        $display("==============================================");
        $display("4x4 MATRIX MULTIPLIER - SIM1");
        $display("==============================================");
        $display("");


        

        $display("Applying reset...");

        repeat (3) begin
            @(posedge clk);
        end

        rst_n = 1'b1;

        $display("Reset released.");


      
        // Test 1
    

        test_identity();
        // Test 2
    

        test_zero();

        // Test 3
    

        test_all_ones();

        // Tests 4-8
        

        $display("");
        $display("----------------------------------------------");
        $display("RANDOM TESTS");
        $display("----------------------------------------------");


        for (int test_number = 1;
             test_number <= 5;
             test_number = test_number + 1) begin

            $display(
                "RANDOM TEST %0d",
                test_number
            );

            test_random();

        end



        $display("");
        $display("==============================================");
        $display("SIM1 SUMMARY");
        $display("==============================================");

        $display(
            "Total tests    = %0d",
            total_tests
        );

        $display(
            "Total failures = %0d",
            total_failures
        );


        if (total_failures == 0) begin

            $display("");
            $display("==============================================");
            $display("ALL SIM1 TESTS PASSED");
            $display("==============================================");
            $display("");

        end

        else begin

            $display("");
            $display("==============================================");
            $display("SIM1 FAILED");
            $display("==============================================");
            $display("");

            $fatal(1);

        end


        $finish;

    end

endmodule