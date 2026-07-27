`timescale 1ns / 1ps
`define SAVE2FILE 1

// ============================================================
// Integer multiplier modes
// ============================================================
`define TB_INT_MULT_3X3_ACC1             0
`define TB_INT_MULT_3X3_ACC2             1

`define TB_INT_MULT_6X6_ACC1             10
`define TB_INT_MULT_6X6_ACC2             11

`define TB_INT_MULT_12X12_ACC1           20
`define TB_INT_MULT_12X12_ACC2           21

`define TB_INT_MULT_24X24_ACC1           30
`define TB_INT_MULT_24X24_ACC2           31
`define TB_INT_MULT_24X24_LXA            32

module tb_mult_compare #(
    parameter MODE = `TB_INT_MULT_24X24_ACC1,
    parameter integer SAMPLES = 2**24
);

    localparam M = (MODE < 10) ? 3  :
                   (MODE < 20) ? 6  :
                   (MODE < 30) ? 12 : 24;
    localparam N = M;

    integer unsigned MAX_PROD = (2**M - 1) * (2**N - 1);

    wire [M-1:0] a_sig;
    wire [N-1:0] b_sig;

    wire [M+N-1:0] prod_sig;
    wire [M+N-1:0] prod_exp;

    reg mid_sig = 0;
    reg sample_valid = 0;

    integer i, j, f;
    integer unsigned sample_counter;
    reg signed [M+N-1:0] err_cnt = 0, err_mag = 0, err_mag_max = 0;
    reg signed [2*(M+N)-1:0] err_mag_total = 0;

    reg [1023:0] out_csv_dir;
    reg [1023:0] out_csv_path;

    assign a_sig = i;
    assign b_sig = j;

    generate
        if (MODE == `TB_INT_MULT_3X3_ACC1) begin : gen_mult_3x3_acc1
            mult_3x3_acc1 inst_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_INT_MULT_3X3_ACC2) begin : gen_mult_3x3_acc2
            mult_3x3_acc2 inst_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_INT_MULT_6X6_ACC1) begin : gen_mult_6x6_acc1
            mult_6x6_acc1 inst_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_INT_MULT_6X6_ACC2) begin : gen_mult_6x6_acc2
            mult_6x6_acc2 inst_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_INT_MULT_12X12_ACC1) begin : gen_mult_12x12_acc1
            mult_12x12_acc1 inst_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_INT_MULT_12X12_ACC2) begin : gen_mult_12x12_acc2
            mult_12x12_acc2 inst_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_INT_MULT_24X24_ACC1) begin : gen_mult_24x24_acc1
            mult_24x24_acc1 inst_mult (
                .zero(1'b0),
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_INT_MULT_24X24_ACC2) begin : gen_mult_24x24_acc2
            mult_24x24_acc2 inst_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_INT_MULT_24X24_LXA) begin : gen_mult_24x24_lxa
            mult_24x24_lxa inst_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else begin : gen_invalid_mode
            assign prod_sig = {(M+N){1'b0}};
        end
    endgenerate

    assign prod_exp = i * j;

    function [1023:0] get_mode_name;
        input integer mode;
        begin
            case (mode)
                `TB_INT_MULT_3X3_ACC1:        get_mode_name = "mult_3x3_acc1";
                `TB_INT_MULT_3X3_ACC2:        get_mode_name = "mult_3x3_acc2";
                `TB_INT_MULT_6X6_ACC1:        get_mode_name = "mult_6x6_acc1";
                `TB_INT_MULT_6X6_ACC2:        get_mode_name = "mult_6x6_acc2";
                `TB_INT_MULT_12X12_ACC1:      get_mode_name = "mult_12x12_acc1";
                `TB_INT_MULT_12X12_ACC2:      get_mode_name = "mult_12x12_acc2";
                `TB_INT_MULT_24X24_ACC1:      get_mode_name = "mult_24x24_acc1";
                `TB_INT_MULT_24X24_ACC2:      get_mode_name = "mult_24x24_acc2";
                `TB_INT_MULT_24X24_LXA:       get_mode_name = "mult_24x24_lxa";
                default:                      get_mode_name = "unknown_int_mode";
            endcase
        end
    endfunction

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
            $fwrite(f, "Actual_Product, Expected_Product\n");
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

        $display("Done: %0s", get_mode_name(MODE));
        $display("err_cnt       = %0d", err_cnt);
        $display("err_mag_max   = %0d", err_mag_max);
        $display("err_mag_total = %0d", err_mag_total);

        $finish;
    end

    always @(mid_sig) begin
        if (!sample_valid) begin
            sample_valid = 1;
        end
        else begin
            if (`SAVE2FILE) begin
                $fwrite(f, "%0d, %0d\n", prod_sig, prod_exp);
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
        end
    end

    always @(err_mag) begin
        if (err_mag_max < err_mag) begin
            err_mag_max = err_mag;
        end
    end

endmodule

module tb_top_mult_3x3_acc1;
    tb_mult_compare #(.MODE(`TB_INT_MULT_3X3_ACC1)) tb();
endmodule

module tb_top_mult_3x3_acc2;
    tb_mult_compare #(.MODE(`TB_INT_MULT_3X3_ACC2)) tb();
endmodule

module tb_top_mult_6x6_acc1;
    tb_mult_compare #(.MODE(`TB_INT_MULT_6X6_ACC1)) tb();
endmodule

module tb_top_mult_6x6_acc2;
    tb_mult_compare #(.MODE(`TB_INT_MULT_6X6_ACC2)) tb();
endmodule

module tb_top_mult_12x12_acc1;
    tb_mult_compare #(.MODE(`TB_INT_MULT_12X12_ACC1)) tb();
endmodule

module tb_top_mult_12x12_acc2;
    tb_mult_compare #(.MODE(`TB_INT_MULT_12X12_ACC2)) tb();
endmodule

module tb_top_mult_24x24_acc1;
    tb_mult_compare #(.MODE(`TB_INT_MULT_24X24_ACC1)) tb();
endmodule

module tb_top_mult_24x24_acc2;
    tb_mult_compare #(.MODE(`TB_INT_MULT_24X24_ACC2)) tb();
endmodule

module tb_top_mult_24x24_lxa;
    tb_mult_compare #(.MODE(`TB_INT_MULT_24X24_LXA)) tb();
endmodule
