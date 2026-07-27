`timescale 1ns / 1ps
`define SAVE2FILE 1

module tb_fpmult_e8m23_vivado_compare;

    localparam EXPONENT_BITS = 8;
    localparam MANTISSA_BITS = 23;
    localparam TOTAL_BITS    = 1 + EXPONENT_BITS + MANTISSA_BITS;
    localparam integer SAMPLES = 2**20;

    reg clk = 0;
    always #5 clk = ~clk;

    reg  s_axis_a_tvalid;
    wire s_axis_a_tready;
    reg  [TOTAL_BITS-1:0] s_axis_a_tdata;

    reg  s_axis_b_tvalid;
    wire s_axis_b_tready;
    reg  [TOTAL_BITS-1:0] s_axis_b_tdata;

    wire m_axis_result_tvalid;
    reg  m_axis_result_tready;
    wire [TOTAL_BITS-1:0] m_axis_result_tdata;

    wire [TOTAL_BITS-1:0] result_dut;
    wire special_case_dut;

    integer i;
    integer f;
    integer err_count;

    reg [1023:0] out_csv_dir;
    reg [1023:0] out_csv_path;

    fpmult_e8m23_viv_reference dut_ref (
        .aclk(clk),
        .s_axis_a_tvalid(s_axis_a_tvalid),
        .s_axis_a_tready(s_axis_a_tready),
        .s_axis_a_tdata(s_axis_a_tdata),
        .s_axis_b_tvalid(s_axis_b_tvalid),
        .s_axis_b_tready(s_axis_b_tready),
        .s_axis_b_tdata(s_axis_b_tdata),
        .m_axis_result_tvalid(m_axis_result_tvalid),
        .m_axis_result_tready(m_axis_result_tready),
        .m_axis_result_tdata(m_axis_result_tdata)
    );

    fpmult_e8m23_acc_vivado #(
        .EXPONENT_BITS(EXPONENT_BITS),
        .MANTISSA_BITS(MANTISSA_BITS)
    ) dut (
        .a(s_axis_a_tdata),
        .b(s_axis_b_tdata),
        .prod(result_dut),
        .special_case(special_case_dut)
    );

    initial begin
        err_count = 0;

        s_axis_a_tvalid = 0;
        s_axis_b_tvalid = 0;
        s_axis_a_tdata  = 0;
        s_axis_b_tdata  = 0;
        m_axis_result_tready = 1;

        if (`SAVE2FILE) begin
            if ($value$plusargs("OUT_CSV_DIR=%s", out_csv_dir)) begin
                $display("Parsed OUT_CSV_DIR = %0s", out_csv_dir);
            end else begin
                out_csv_dir = ".";
                $display("OUT_CSV_DIR not provided, using default = %0s", out_csv_dir);
            end
            $sformat(out_csv_path, "%0s/%0s.csv", out_csv_dir, "fpmult_e8m23_viv_reference");
            $display("Opening CSV output file: %0s", out_csv_path);
            f = $fopen(out_csv_path, "w");
            if (f == 0) begin
                $display("ERROR: Failed to open CSV file: %0s", out_csv_path);
                $finish;
            end
            $fwrite(f, "A, B, Actual_Product, Expected_Product\n");
        end

        for (i = 0; i < SAMPLES; i = i + 1) begin
            @(posedge clk);
            s_axis_a_tdata  <= $urandom;
            s_axis_b_tdata  <= $urandom;

            @(posedge clk);
            s_axis_a_tvalid <= 1'b1;
            s_axis_b_tvalid <= 1'b1;

            wait (s_axis_a_tready && s_axis_b_tready);
            @(posedge clk);

            wait (m_axis_result_tvalid);
            @(posedge clk);
            s_axis_a_tvalid <= 1'b0;
            s_axis_b_tvalid <= 1'b0;

            if (m_axis_result_tdata !== result_dut) begin
                err_count = err_count + 1;
                $display("Mismatch: A=%08x B=%08x ref=%08x dut=%08x",
                         s_axis_a_tdata, s_axis_b_tdata, m_axis_result_tdata, result_dut);
            end

            if (`SAVE2FILE) begin
                $fwrite(f, "%08x, %08x, %08x, %08x\n", s_axis_a_tdata, s_axis_b_tdata, result_dut, m_axis_result_tdata);
            end
        end

        $display("Done: tb_fpmult_vivado_compare");
        $display("Total mismatches = %0d", err_count);

        if (`SAVE2FILE) begin
            $fclose(f);
        end

        $finish;
    end

endmodule

module tb_top_fpmult_e8m23_vivado_compare;
    tb_fpmult_e8m23_vivado_compare tb();
endmodule
