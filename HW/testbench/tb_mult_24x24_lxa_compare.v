`timescale 1ns / 1ps
`define SAVE2FILE 1

module tb_mult_24x24_lxa_compare #(
    parameter integer SAMPLES = 2**24
);

    localparam M = 24;
    localparam N = 24;

    integer unsigned MAX_PROD = (2**M - 1) * (2**N - 1);

    wire [M-1:0] a_sig;
    wire [N-1:0] b_sig;

    wire [M+N-1:0] prod_sig_tmp;
    wire [M+N-1:0] prod_sig;
    wire [M+N-1:0] prod_exp;
    wire [M+N-1:0] prod_exp_round;

    reg mid_sig = 0;

    integer i, j, f;
    integer unsigned sample_counter;
    reg signed [M+N-1:0] err_cnt = 0, err_cnt_round = 0;
    reg signed [M+N-1:0] err_mag = 0, err_mag_round = 0;
    reg signed [M+N-1:0] err_mag_max = 0, err_mag_round_max = 0;
    reg signed [2*(M+N)-1:0] err_mag_total = 0, err_mag_round_total = 0;

    reg [1023:0] out_csv_dir;
    reg [1023:0] out_csv_path;

    mult_24x24_lxa inst_mult (
        .a(a_sig),
        .b(b_sig),
        .prod(prod_sig_tmp)
    );

    assign prod_sig = (prod_sig_tmp >> 23) << 23;
    assign a_sig = i;
    assign b_sig = j;
    assign prod_exp = ((i * j) >> 23) << 23;

    function reg round;
      input integer a;
      input integer b;
      automatic integer prod;
      begin
        prod = a * b;
        round = 0;
        if (prod[24] & prod[23])
          round = 1;
        else if (prod[23] && prod[22:0] > 0)
          round = 1;
      end
    endfunction

    assign prod_exp_round = ((((i * j) >> 23) + round(i, j)) << 23);

    initial begin
        sample_counter = SAMPLES;

        if (`SAVE2FILE) begin
            if ($value$plusargs("OUT_CSV_DIR=%s", out_csv_dir)) begin
                $display("Parsed OUT_CSV_DIR = %0s", out_csv_dir);
            end else begin
                out_csv_dir = ".";
                $display("OUT_CSV_DIR not provided, using default = %0s", out_csv_dir);
            end
            $sformat(out_csv_path, "%0s/%0s.csv", out_csv_dir, get_mode_name(MODE));
            $display("Opening CSV output file: %0s", out_csv_path);
            f = $fopen(out_csv_path, "w");
            if (f == 0) begin
                $display("ERROR: Failed to open CSV file: %0s", out_csv_path);
                $finish;
            end
            $fwrite(f, "A, B, Actual_Product, Expected_Product, Expected_Product_Rounded\n");
        end

        if (MAX_PROD > sample_counter) begin
            while (sample_counter > 0) begin
                i = $urandom_range(2**M - 1, 0);
                j = $urandom_range(2**N - 1, 0);
                #1 mid_sig = !mid_sig; #1;
                sample_counter = sample_counter - 1;
            end
        end
        else begin
            for (i = 0; i < 2**M; i = i + 1) begin
                for (j = 0; j < 2**N; j = j + 1) begin
                    #1 mid_sig = !mid_sig; #1;
                end
            end
        end

        if (`SAVE2FILE) begin
            $fclose(f);
        end

        $display("Done: mult_24x24_lxa");
        $display("err_cnt             = %0d", err_cnt);
        $display("err_cnt_round       = %0d", err_cnt_round);
        $display("err_mag_max         = %0d", err_mag_max);
        $display("err_mag_round_max   = %0d", err_mag_round_max);
        $display("err_mag_total       = %0d", err_mag_total);
        $display("err_mag_round_total = %0d", err_mag_round_total);

        $finish;
    end

    always @(mid_sig) begin
        if (`SAVE2FILE) begin
            $fwrite(f, "%0d, %0d, %0d, %0d, %0d\n",
                    a_sig, b_sig, prod_sig, prod_exp, prod_exp_round);
        end

        if (prod_sig != prod_exp) begin
            err_cnt = err_cnt + 1;
        end
        err_mag = prod_sig - prod_exp;
        if (err_mag < 0) begin
            err_mag = -err_mag;
        end
        if (err_mag) begin
            err_mag_total = err_mag_total + err_mag;
        end

        if (prod_sig != prod_exp_round) begin
            err_cnt_round = err_cnt_round + 1;
        end
        err_mag_round = prod_sig - prod_exp_round;
        if (err_mag_round < 0) begin
            err_mag_round = -err_mag_round;
        end
        if (err_mag_round) begin
            err_mag_round_total = err_mag_round_total + err_mag_round;
        end
    end

    always @(err_mag) begin
        if (err_mag_max < err_mag) begin
            err_mag_max = err_mag;
        end
    end

    always @(err_mag_round) begin
        if (err_mag_round_max < err_mag_round) begin
            err_mag_round_max = err_mag_round;
        end
    end

endmodule

module tb_top_mult_24x24_lxa;
    tb_mult_24x24_lxa_compare tb();
endmodule
