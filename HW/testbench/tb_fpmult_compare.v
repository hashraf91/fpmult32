`timescale 1ns / 1ps
`define SAVE2FILE 1

// ============================================================
// Floating-point modes
// ============================================================
`define TB_FP_FPMULT_ACC_VIVADO          0
`define TB_FP_FPMULT_ACC1                1
`define TB_FP_FPMULT_ACC2                2
`define TB_FP_FPMULT_MXA1                3
`define TB_FP_FPMULT_MXA2                4
`define TB_FP_FPMULT_LXA                 5
`define TB_FP_FPMULT_LMUL                6
`define TB_FP_FPMULT_SSM_M12             10
`define TB_FP_FPMULT_SSM_M14             11
`define TB_FP_FPMULT_SSM_M16             12
`define TB_FP_FPMULT_SSM_M18             13
`define TB_FP_FPMULT_SSM_M12C            14
`define TB_FP_FPMULT_SSM_M14C            15
`define TB_FP_FPMULT_SSM_M16C            16
`define TB_FP_FPMULT_SSM_M18C            17

module tb_fpmult_compare #(
    parameter MODE = `TB_FP_FPMULT_MXA1,
    parameter integer SAMPLES = 2**20
);

    localparam TOTAL_BITS = 32;

    integer unsigned MAX_PROD = {TOTAL_BITS{1'b1}};

    wire [TOTAL_BITS-1:0] a_sig;
    wire [TOTAL_BITS-1:0] b_sig;

    wire [TOTAL_BITS-1:0] prod_sig;
    wire [TOTAL_BITS-1:0] prod_exp;

    wire special_case_ref;

    reg mid_sig = 0;
    reg sample_valid = 0;

    reg [TOTAL_BITS-1:0] i, j;
    integer f;
    integer unsigned sample_counter;
    reg signed [2*TOTAL_BITS-1:0] err_cnt = 0, err_cnt_mag1 = 0, err_cnt_mag2 = 0, err_mag = 0, err_mag_max = 0;
    reg signed [2*(2*TOTAL_BITS)-1:0] err_mag_total = 0;

    reg [1023:0] out_csv_dir;
    reg [1023:0] out_csv_path;

    assign a_sig = i;
    assign b_sig = j;

    generate
        if (MODE == `TB_FP_FPMULT_ACC_VIVADO) begin : gen_fpmult_acc_vivado
            wire special_case_unused;
            fpmult_e8m23_acc_vivado #(
                .EXPONENT_BITS(8),
                .MANTISSA_BITS(23)
            ) inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig),
                .special_case(special_case_unused)
            );
        end
        else if (MODE == `TB_FP_FPMULT_ACC1) begin : gen_fpmult_acc1
            fpmult_e8m23_acc1 inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_FP_FPMULT_ACC2) begin : gen_fpmult_acc2
            fpmult_e8m23_acc2 inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_FP_FPMULT_MXA1) begin : gen_fpmult_mxa1
            fpmult_e8m23_mxa1 inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_FP_FPMULT_MXA2) begin : gen_fpmult_mxa2
            fpmult_e8m23_mxa2 inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_FP_FPMULT_LXA) begin : gen_fpmult_lxa
            fpmult_e8m23_lxa inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_FP_FPMULT_LMUL) begin : gen_fpmult_lmul
            fpmult_e8m23_lmul #(
                .TOTAL_BITS(32)
            ) inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_FP_FPMULT_SSM_M12) begin : gen_fpmult_ssm_m12
            fpmult_e8m23_ssm #(
                .USE_CORRECTION(0),
                .MANT_MULT_BITS(12)
            ) inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_FP_FPMULT_SSM_M14) begin : gen_fpmult_ssm_m14
            fpmult_e8m23_ssm #(
                .USE_CORRECTION(0),
                .MANT_MULT_BITS(14)
            ) inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_FP_FPMULT_SSM_M16) begin : gen_fpmult_ssm_m16
            fpmult_e8m23_ssm #(
                .USE_CORRECTION(0),
                .MANT_MULT_BITS(16)
            ) inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_FP_FPMULT_SSM_M18) begin : gen_fpmult_ssm_m18
            fpmult_e8m23_ssm #(
                .USE_CORRECTION(0),
                .MANT_MULT_BITS(18)
            ) inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_FP_FPMULT_SSM_M12C) begin : gen_fpmult_ssm_m12c
            fpmult_e8m23_ssm #(
                .USE_CORRECTION(1),
                .MANT_MULT_BITS(12)
            ) inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_FP_FPMULT_SSM_M14C) begin : gen_fpmult_ssm_m14c
            fpmult_e8m23_ssm #(
                .USE_CORRECTION(1),
                .MANT_MULT_BITS(14)
            ) inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_FP_FPMULT_SSM_M16C) begin : gen_fpmult_ssm_m16c
            fpmult_e8m23_ssm #(
                .USE_CORRECTION(1),
                .MANT_MULT_BITS(16)
            ) inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else if (MODE == `TB_FP_FPMULT_SSM_M18C) begin : gen_fpmult_ssm_m18c
            fpmult_e8m23_ssm #(
                .USE_CORRECTION(1),
                .MANT_MULT_BITS(18)
            ) inst1_mult (
                .a(a_sig),
                .b(b_sig),
                .prod(prod_sig)
            );
        end
        else begin : gen_invalid_mode
            assign prod_sig = 32'b0;
        end
    endgenerate

    fpmult_e8m23_acc_vivado #(
        .EXPONENT_BITS(8),
        .MANTISSA_BITS(23)
    ) inst2_mult (
        .a(a_sig),
        .b(b_sig),
        .prod(prod_exp),
        .special_case(special_case_ref)
    );

    function [1023:0] get_mode_name;
        input integer mode;
        begin
            case (mode)
                `TB_FP_FPMULT_ACC_VIVADO:        get_mode_name = "fpmult_e8m23_acc_vivado";
                `TB_FP_FPMULT_ACC1:              get_mode_name = "fpmult_e8m23_acc1";
                `TB_FP_FPMULT_ACC2:              get_mode_name = "fpmult_e8m23_acc2";
                `TB_FP_FPMULT_MXA1:              get_mode_name = "fpmult_e8m23_mxa1";
                `TB_FP_FPMULT_MXA2:              get_mode_name = "fpmult_e8m23_mxa2";
                `TB_FP_FPMULT_LXA:               get_mode_name = "fpmult_e8m23_lxa";
                `TB_FP_FPMULT_LMUL:              get_mode_name = "fpmult_e8m23_lmul";
                `TB_FP_FPMULT_SSM_M12:           get_mode_name = "fpmult_e8m23_ssm_m12";
                `TB_FP_FPMULT_SSM_M14:           get_mode_name = "fpmult_e8m23_ssm_m14";
                `TB_FP_FPMULT_SSM_M16:           get_mode_name = "fpmult_e8m23_ssm_m16";
                `TB_FP_FPMULT_SSM_M18:           get_mode_name = "fpmult_e8m23_ssm_m18";
                `TB_FP_FPMULT_SSM_M12C:          get_mode_name = "fpmult_e8m23_ssm_m12c";
                `TB_FP_FPMULT_SSM_M14C:          get_mode_name = "fpmult_e8m23_ssm_m14c";
                `TB_FP_FPMULT_SSM_M16C:          get_mode_name = "fpmult_e8m23_ssm_m16c";
                `TB_FP_FPMULT_SSM_M18C:          get_mode_name = "fpmult_e8m23_ssm_m18c";
                default:                         get_mode_name = "unknown_fp_mode";
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
            $fwrite(f, "A, B, Actual_Product, Expected_Product\n");
        end

        if (MAX_PROD > sample_counter) begin
            while (sample_counter > 0) begin
                i = $urandom();
                j = $urandom();
                #1 mid_sig = !mid_sig; #1;
                sample_counter = sample_counter - 1;
            end
        end
        else begin
            for (i = 0; i < 2**TOTAL_BITS; i = i + 1) begin
                for (j = 0; j < 2**TOTAL_BITS; j = j + 1) begin
                    #1 mid_sig = !mid_sig; #1;
                end
            end
        end

        if (`SAVE2FILE) begin
            $fclose(f);
        end

        $display("Done: %0s", get_mode_name(MODE));
        $display("err_cnt       = %0d", err_cnt);
        $display("err_cnt_mag1  = %0d", err_cnt_mag1);
        $display("err_cnt_mag2  = %0d", err_cnt_mag2);
        $display("err_mag_max   = %0d", err_mag_max);
        $display("err_mag_total = %0d", err_mag_total);

        $finish;
    end

    always @(mid_sig) begin
        if (!sample_valid) begin
            sample_valid = 1;
        end
        else begin
            if ((MODE == `TB_FP_FPMULT_ACC_VIVADO) ||
                (MODE == `TB_FP_FPMULT_ACC1) ||
                (MODE == `TB_FP_FPMULT_ACC2)) begin
                if (`SAVE2FILE) begin
                    $fwrite(f, "%08x, %08x, %08x, %08x\n", a_sig, b_sig, prod_sig, prod_exp);
                end
                if (prod_sig != prod_exp) begin
                    err_cnt = err_cnt + 1;
                end
                err_mag = prod_sig - prod_exp;
                if (err_mag < 0) begin
                    err_mag = -err_mag;
                end
                if (err_mag == 1) begin
                    err_cnt_mag1 = err_cnt_mag1 + 1;
                end
                if (err_mag == 2) begin
                    err_cnt_mag2 = err_cnt_mag2 + 1;
                end
                if (err_mag) begin
                    err_mag_total = err_mag_total + err_mag;
                end
            end
            else begin
                if (special_case_ref == 0) begin
                    if (`SAVE2FILE) begin
                        $fwrite(f, "%08x, %08x, %08x, %08x\n", a_sig, b_sig, prod_sig, prod_exp);
                    end
                    if (prod_sig != prod_exp) begin
                        err_cnt = err_cnt + 1;
                    end
                    err_mag = prod_sig - prod_exp;
                    if (err_mag < 0) begin
                        err_mag = -err_mag;
                    end
                    if (err_mag == 1) begin
                        err_cnt_mag1 = err_cnt_mag1 + 1;
                    end
                    if (err_mag == 2) begin
                        err_cnt_mag2 = err_cnt_mag2 + 1;
                    end
                    if (err_mag) begin
                        err_mag_total = err_mag_total + err_mag;
                    end
                end
                else begin
                    sample_counter = sample_counter + 1;
                end
            end
        end
    end

    always @(err_mag) begin
        if (err_mag_max < err_mag) begin
            err_mag_max = err_mag;
        end
    end

endmodule

module tb_top_fpmult_e8m23_acc_vivado;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_ACC_VIVADO)) tb();
endmodule

module tb_top_fpmult_e8m23_acc1;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_ACC1)) tb();
endmodule

module tb_top_fpmult_e8m23_acc2;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_ACC2)) tb();
endmodule

module tb_top_fpmult_e8m23_mxa1;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_MXA1)) tb();
endmodule

module tb_top_fpmult_e8m23_mxa2;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_MXA2)) tb();
endmodule

module tb_top_fpmult_e8m23_lxa;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_LXA)) tb();
endmodule

module tb_top_fpmult_e8m23_lmul;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_LMUL)) tb();
endmodule

module tb_top_fpmult_e8m23_ssm_m12;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_SSM_M12)) tb();
endmodule

module tb_top_fpmult_e8m23_ssm_m14;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_SSM_M14)) tb();
endmodule

module tb_top_fpmult_e8m23_ssm_m16;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_SSM_M16)) tb();
endmodule

module tb_top_fpmult_e8m23_ssm_m18;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_SSM_M18)) tb();
endmodule

module tb_top_fpmult_e8m23_ssm_m12c;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_SSM_M12C)) tb();
endmodule

module tb_top_fpmult_e8m23_ssm_m14c;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_SSM_M14C)) tb();
endmodule

module tb_top_fpmult_e8m23_ssm_m16c;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_SSM_M16C)) tb();
endmodule

module tb_top_fpmult_e8m23_ssm_m18c;
    tb_fpmult_compare #(.MODE(`TB_FP_FPMULT_SSM_M18C)) tb();
endmodule
