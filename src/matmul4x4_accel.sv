`timescale 1ns/1ps

module matmul4x4_accel #(
    parameter int DATA_W = 8,
    parameter int ACC_W  = 20
)(
    input  logic clk,
    input  logic rst_n,
    input  logic start,

    input logic signed [DATA_W-1:0] a_matrix [0:3][0:3],
    input logic signed [DATA_W-1:0] b_matrix [0:3][0:3],

    output logic done,

    output logic signed [ACC_W-1:0] c_matrix [0:3][0:3],

    output logic overflow
);

    typedef enum logic [1:0] {
        IDLE,
        CALC,
        FINISH
    } state_t;

    state_t state;

    logic [1:0] row;
    logic [1:0] col;


   

    integer signed accumulator;

    integer signed max_value;
    integer signed min_value;


    always_ff @(posedge clk) begin

        if (!rst_n) begin

            state    <= IDLE;
            row      <= 2'd0;
            col      <= 2'd0;

            done     <= 1'b0;
            overflow <= 1'b0;

            for (int i = 0; i < 4; i = i + 1) begin

                for (int j = 0; j < 4; j = j + 1) begin

                    c_matrix[i][j] <= '0;

                end

            end

        end

        else begin

            case (state)

                // =================================================
                // IDLE
                // =================================================

                IDLE: begin

                    done <= 1'b0;

                    if (start) begin

                        row <= 2'd0;
                        col <= 2'd0;

                        // Clear overflow for new operation
                        overflow <= 1'b0;

                        state <= CALC;

                    end

                end


                // =================================================
                // CALCULATE
                // =================================================

                CALC: begin

                    max_value = (2 ** (ACC_W - 1)) - 1;
                    min_value = -(2 ** (ACC_W - 1));


                

                    accumulator =

                          ($signed(a_matrix[row][0])
                           * $signed(b_matrix[0][col]))

                        + ($signed(a_matrix[row][1])
                           * $signed(b_matrix[1][col]))

                        + ($signed(a_matrix[row][2])
                           * $signed(b_matrix[2][col]))

                        + ($signed(a_matrix[row][3])
                           * $signed(b_matrix[3][col]));

                    if (accumulator > max_value) begin

                        c_matrix[row][col] <= max_value;

                        overflow <= 1'b1;

                    end


                    else if (accumulator < min_value) begin

                        c_matrix[row][col] <= min_value;

                        overflow <= 1'b1;

                    end


                
                    else begin

                        c_matrix[row][col] <= accumulator;

                    end



                    if (col == 2'd3) begin

                        col <= 2'd0;

                        if (row == 2'd3) begin

                            state <= FINISH;

                        end

                        else begin

                            row <= row + 2'd1;

                        end

                    end

                    else begin

                        col <= col + 2'd1;

                    end

                end


                FINISH: begin

                    done <= 1'b1;

                    state <= IDLE;

                end


               

                default: begin

                    state <= IDLE;

                    done <= 1'b0;

                end

            endcase

        end

    end

endmodule