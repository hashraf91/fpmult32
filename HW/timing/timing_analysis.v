// ============================================================
// Floating-point multipliers
// ============================================================
`define MODE_FPMULT_ACC1                0
`define MODE_FPMULT_ACC2                1
`define MODE_FPMULT_MXA1                2
`define MODE_FPMULT_MXA2                3
`define MODE_FPMULT_LXA                 4
`define MODE_FPMULT_LMUL                5
`define MODE_FPMULT_ACC_VIVADO          6

// ============================================================
// Floating-point multipliers: SSM family
// ============================================================
`define MODE_FPMULT_SSM_M12             10
`define MODE_FPMULT_SSM_M14             11
`define MODE_FPMULT_SSM_M16             12
`define MODE_FPMULT_SSM_M18             13
`define MODE_FPMULT_SSM_M12C            14
`define MODE_FPMULT_SSM_M14C            15
`define MODE_FPMULT_SSM_M16C            16
`define MODE_FPMULT_SSM_M18C            17

// ============================================================
// Integer multipliers - accurate acc1
// ============================================================
`define MODE_MULT_3X3_ACC1              20
`define MODE_MULT_6X6_ACC1              21
`define MODE_MULT_12X12_ACC1            22
`define MODE_MULT_24X24_ACC1            23

// ============================================================
// Integer multipliers - accurate acc2
// ============================================================
`define MODE_MULT_3X3_ACC2              30
`define MODE_MULT_6X6_ACC2              31
`define MODE_MULT_12X12_ACC2            32
`define MODE_MULT_24X24_ACC2            33

// ============================================================
// Integer multipliers - approximate mxa1
// ============================================================
`define MODE_MULT_3X3_MXA1              40
`define MODE_MULT_6X6_MXA1              41
`define MODE_MULT_12X12_MXA1            42
`define MODE_MULT_24X24_MXA1            43

// ============================================================
// Integer multipliers - approximate mxa2
// ============================================================
`define MODE_MULT_3X3_MXA2              50
`define MODE_MULT_6X6_MXA2              51
`define MODE_MULT_12X12_MXA2            52
`define MODE_MULT_24X24_MXA2            53
`define MODE_MULT_24X24_MXA2_PLUS_1     54
`define MODE_MULT_24X24_MXA2_PLUS_2     55
`define MODE_MULT_24X24_MXA2_PLUS_3     56
`define MODE_MULT_24X24_MXA2_PLUS_4     57
`define MODE_MULT_24X24_MXA2_PLUS_5     58
`define MODE_MULT_24X24_MXA2_PLUS_6     59

// ============================================================
// Integer multipliers - approximate
// ============================================================
`define MODE_MULT_24X24_LXA             60

// ============================================================
// Adders
// ============================================================
`define MODE_CARRY_ADDER_3IN_PARALLEL   70
`define MODE_CARRY_ADDER_3IN            71

module timing_analysis_wrapper #(
    parameter MODE = `MODE_FPMULT_MXA1
) (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    input  wire [31:0] c_in,
    output reg  [47:0] prod_out
);

  reg  [31:0] a_reg, b_reg, c_reg;
  wire [47:0] prod_comb;

  always @(posedge clk) begin
    a_reg <= a_in;
    b_reg <= b_in;
    c_reg <= c_in;
  end

  generate
    // ============================================================
    // Floating-point multipliers
    // ============================================================
    if (MODE == `MODE_FPMULT_ACC1) begin : gen_fpmult_acc1
      wire [31:0] prod_tmp;
      fpmult_e8m23_acc1 inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end
    else if (MODE == `MODE_FPMULT_ACC2) begin : gen_fpmult_acc2
      wire [31:0] prod_tmp;
      fpmult_e8m23_acc2 inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end
    else if (MODE == `MODE_FPMULT_MXA1) begin : gen_fpmult_mxa1
      wire [31:0] prod_tmp;
      fpmult_e8m23_mxa1 inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end
    else if (MODE == `MODE_FPMULT_MXA2) begin : gen_fpmult_mxa2
      wire [31:0] prod_tmp;
      fpmult_e8m23_mxa2 inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end
    else if (MODE == `MODE_FPMULT_LXA) begin : gen_fpmult_lxa
      wire [31:0] prod_tmp;
      fpmult_e8m23_lxa inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end
    else if (MODE == `MODE_FPMULT_LMUL) begin : gen_fpmult_lmul
      wire [31:0] prod_tmp;
      fpmult_e8m23_lmul #(
          .TOTAL_BITS(32)
      ) inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end
    else if (MODE == `MODE_FPMULT_ACC_VIVADO) begin : gen_fpmult_acc_vivado
      wire [31:0] prod_tmp;
      wire special_case_unused;
      fpmult_e8m23_acc_vivado #(
          .EXPONENT_BITS(8),
          .MANTISSA_BITS(23)
      ) inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp),
          .special_case(special_case_unused)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end

    // ============================================================
    // Floating-point multipliers: SSM family
    // ============================================================
    else if (MODE == `MODE_FPMULT_SSM_M12) begin : gen_fpmult_ssm_m12
      wire [31:0] prod_tmp;
      fpmult_e8m23_ssm #(
          .USE_CORRECTION(0),
          .MANT_MULT_BITS(12)
      ) inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end
    else if (MODE == `MODE_FPMULT_SSM_M14) begin : gen_fpmult_ssm_m14
      wire [31:0] prod_tmp;
      fpmult_e8m23_ssm #(
          .USE_CORRECTION(0),
          .MANT_MULT_BITS(14)
      ) inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end
    else if (MODE == `MODE_FPMULT_SSM_M16) begin : gen_fpmult_ssm_m16
      wire [31:0] prod_tmp;
      fpmult_e8m23_ssm #(
          .USE_CORRECTION(0),
          .MANT_MULT_BITS(16)
      ) inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end
    else if (MODE == `MODE_FPMULT_SSM_M18) begin : gen_fpmult_ssm_m18
      wire [31:0] prod_tmp;
      fpmult_e8m23_ssm #(
          .USE_CORRECTION(0),
          .MANT_MULT_BITS(18)
      ) inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end
    else if (MODE == `MODE_FPMULT_SSM_M12C) begin : gen_fpmult_ssm_m12c
      wire [31:0] prod_tmp;
      fpmult_e8m23_ssm #(
          .USE_CORRECTION(1),
          .MANT_MULT_BITS(12)
      ) inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end
    else if (MODE == `MODE_FPMULT_SSM_M14C) begin : gen_fpmult_ssm_m14c
      wire [31:0] prod_tmp;
      fpmult_e8m23_ssm #(
          .USE_CORRECTION(1),
          .MANT_MULT_BITS(14)
      ) inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end
    else if (MODE == `MODE_FPMULT_SSM_M16C) begin : gen_fpmult_ssm_m16c
      wire [31:0] prod_tmp;
      fpmult_e8m23_ssm #(
          .USE_CORRECTION(1),
          .MANT_MULT_BITS(16)
      ) inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end
    else if (MODE == `MODE_FPMULT_SSM_M18C) begin : gen_fpmult_ssm_m18c
      wire [31:0] prod_tmp;
      fpmult_e8m23_ssm #(
          .USE_CORRECTION(1),
          .MANT_MULT_BITS(18)
      ) inst0 (
          .a(a_reg),
          .b(b_reg),
          .prod(prod_tmp)
      );
      assign prod_comb = {16'b0, prod_tmp};
    end

    // ============================================================
    // Integer multipliers
    // ============================================================
    else if (MODE == `MODE_MULT_3X3_ACC1) begin : gen_mult_3x3_acc1
      wire [5:0] prod_tmp;
      mult_3x3_acc1 inst0 (
          .a(a_reg[2:0]),
          .b(b_reg[2:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = {42'b0, prod_tmp};
    end
    else if (MODE == `MODE_MULT_6X6_ACC1) begin : gen_mult_6x6_acc1
      wire [11:0] prod_tmp;
      mult_6x6_acc1 inst0 (
          .a(a_reg[5:0]),
          .b(b_reg[5:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = {36'b0, prod_tmp};
    end
    else if (MODE == `MODE_MULT_12X12_ACC1) begin : gen_mult_12x12_acc1
      wire [23:0] prod_tmp;
      mult_12x12_acc1 inst0 (
          .a(a_reg[11:0]),
          .b(b_reg[11:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = {24'b0, prod_tmp};
    end
    else if (MODE == `MODE_MULT_24X24_ACC1) begin : gen_mult_24x24_acc1
      wire [47:0] prod_tmp;
      mult_24x24_acc1 inst0 (
          .zero(1'b0),
          .a(a_reg[23:0]),
          .b(b_reg[23:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = prod_tmp;
    end
    else if (MODE == `MODE_MULT_3X3_ACC2) begin : gen_mult_3x3_acc2
      wire [5:0] prod_tmp;
      mult_3x3_acc2 inst0 (
          .a(a_reg[2:0]),
          .b(b_reg[2:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = {42'b0, prod_tmp};
    end
    else if (MODE == `MODE_MULT_6X6_ACC2) begin : gen_mult_6x6_acc2
      wire [11:0] prod_tmp;
      mult_6x6_acc2 inst0 (
          .a(a_reg[5:0]),
          .b(b_reg[5:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = {36'b0, prod_tmp};
    end
    else if (MODE == `MODE_MULT_12X12_ACC2) begin : gen_mult_12x12_acc2
      wire [23:0] prod_tmp;
      mult_12x12_acc2 inst0 (
          .a(a_reg[11:0]),
          .b(b_reg[11:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = {24'b0, prod_tmp};
    end
    else if (MODE == `MODE_MULT_24X24_ACC2) begin : gen_mult_24x24_acc2
      wire [47:0] prod_tmp;
      mult_24x24_acc2 inst0 (
          .a(a_reg[23:0]),
          .b(b_reg[23:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = prod_tmp;
    end
    else if (MODE == `MODE_MULT_3X3_MXA1) begin : gen_mult_3x3_mxa1
      wire [5:0] prod_tmp;
      mult_3x3_mxa1 inst0 (
          .a(a_reg[2:0]),
          .b(b_reg[2:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = {42'b0, prod_tmp};
    end
    else if (MODE == `MODE_MULT_6X6_MXA1) begin : gen_mult_6x6_mxa1
      wire [11:0] prod_tmp;
      mult_6x6_mxa1 inst0 (
          .a(a_reg[5:0]),
          .b(b_reg[5:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = {36'b0, prod_tmp};
    end
    else if (MODE == `MODE_MULT_12X12_MXA1) begin : gen_mult_12x12_mxa1
      wire [23:0] prod_tmp;
      mult_12x12_mxa1 inst0 (
          .a(a_reg[11:0]),
          .b(b_reg[11:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = {24'b0, prod_tmp};
    end
    else if (MODE == `MODE_MULT_24X24_MXA1) begin : gen_mult_24x24_mxa1
      wire [47:0] prod_tmp;
      mult_24x24_mxa1 inst0 (
          .zero(1'b0),
          .a(a_reg[23:0]),
          .b(b_reg[23:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = prod_tmp;
    end
    else if (MODE == `MODE_MULT_3X3_MXA2) begin : gen_mult_3x3_mxa2
      wire [5:0] prod_tmp;
      mult_3x3_mxa2 inst0 (
          .a(a_reg[2:0]),
          .b(b_reg[2:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = {42'b0, prod_tmp};
    end
    else if (MODE == `MODE_MULT_6X6_MXA2) begin : gen_mult_6x6_mxa2
      wire [11:0] prod_tmp;
      mult_6x6_mxa2 inst0 (
          .a(a_reg[5:0]),
          .b(b_reg[5:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = {36'b0, prod_tmp};
    end
    else if (MODE == `MODE_MULT_12X12_MXA2) begin : gen_mult_12x12_mxa2
      wire [23:0] prod_tmp;
      mult_12x12_mxa2 inst0 (
          .a(a_reg[11:0]),
          .b(b_reg[11:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = {24'b0, prod_tmp};
    end
    else if (MODE == `MODE_MULT_24X24_MXA2) begin : gen_mult_24x24_mxa2
      wire [47:0] prod_tmp;
      mult_24x24_mxa2 inst0 (
          .a(a_reg[23:0]),
          .b(b_reg[23:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = prod_tmp;
    end
    else if (MODE == `MODE_MULT_24X24_MXA2_PLUS_1) begin : gen_mult_24x24_mxa2_plus_1
      wire [47:0] prod_tmp;
      mult_24x24_acc2 #(.N_TRUNC(23)) inst0 (
          .a(a_reg[23:0]),
          .b(b_reg[23:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = prod_tmp;
    end
    else if (MODE == `MODE_MULT_24X24_MXA2_PLUS_2) begin : gen_mult_24x24_mxa2_plus_2
      wire [47:0] prod_tmp;
      mult_24x24_acc2 #(.N_TRUNC(22)) inst0 (
          .a(a_reg[23:0]),
          .b(b_reg[23:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = prod_tmp;
    end
    else if (MODE == `MODE_MULT_24X24_MXA2_PLUS_3) begin : gen_mult_24x24_mxa2_plus_3
      wire [47:0] prod_tmp;
      mult_24x24_acc2 #(.N_TRUNC(21)) inst0 (
          .a(a_reg[23:0]),
          .b(b_reg[23:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = prod_tmp;
    end
    else if (MODE == `MODE_MULT_24X24_MXA2_PLUS_4) begin : gen_mult_24x24_mxa2_plus_4
      wire [47:0] prod_tmp;
      mult_24x24_acc2 #(.N_TRUNC(20)) inst0 (
          .a(a_reg[23:0]),
          .b(b_reg[23:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = prod_tmp;
    end
    else if (MODE == `MODE_MULT_24X24_MXA2_PLUS_5) begin : gen_mult_24x24_mxa2_plus_5
      wire [47:0] prod_tmp;
      mult_24x24_acc2 #(.N_TRUNC(19)) inst0 (
          .a(a_reg[23:0]),
          .b(b_reg[23:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = prod_tmp;
    end
    else if (MODE == `MODE_MULT_24X24_MXA2_PLUS_6) begin : gen_mult_24x24_mxa2_plus_6
      wire [47:0] prod_tmp;
      mult_24x24_acc2 #(.N_TRUNC(18)) inst0 (
          .a(a_reg[23:0]),
          .b(b_reg[23:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = prod_tmp;
    end
    else if (MODE == `MODE_MULT_24X24_LXA) begin : gen_mult_24x24_lxa
      wire [47:0] prod_tmp;
      mult_24x24_lxa inst0 (
          .zero(1'b0),
          .a(a_reg[23:0]),
          .b(b_reg[23:0]),
          .prod(prod_tmp)
      );
      assign prod_comb = prod_tmp;
    end

    // ============================================================
    // Adders
    // ============================================================
    else if (MODE == `MODE_CARRY_ADDER_3IN_PARALLEL) begin : gen_carry_adder_3in_parallel
      wire [8:0] sum_tmp;
      carry_adder_3in_parallel #(
          .INP_WIDTH_LO(8),
          .INP_WIDTH_HI(8),
          .EFF_WIDTH(8),
          .NEG_A(0)
      ) inst0 (
          .a(a_reg[7:0]),
          .b(b_reg[7:0]),
          .c(c_reg[7:0]),
          .sum(sum_tmp)
      );
      assign prod_comb = {39'b0, sum_tmp};
    end
    else if (MODE == `MODE_CARRY_ADDER_3IN) begin : gen_carry_adder_3in
      wire [8:0] sum_tmp;
      carry_adder_3in #(
          .INP_WIDTH_LO(8),
          .INP_WIDTH_HI(8),
          .EFF_WIDTH(8),
          .NEG_A(0)
      ) inst0 (
          .a(a_reg[7:0]),
          .b(b_reg[7:0]),
          .c(c_reg[7:0]),
          .zero(1'b0),
          .sum(sum_tmp)
      );
      assign prod_comb = {39'b0, sum_tmp};
    end
    else begin : gen_default
      assign prod_comb = 48'b0;
    end
  endgenerate

  always @(posedge clk) begin
    prod_out <= prod_comb;
  end

endmodule

module timing_fpmult_e8m23_acc1 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_ACC1)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_fpmult_e8m23_acc2 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_ACC2)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_fpmult_e8m23_mxa1 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_MXA1)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_fpmult_e8m23_mxa2 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_MXA2)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_fpmult_e8m23_lxa (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_LXA)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_fpmult_e8m23_lmul (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_LMUL)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_fpmult_e8m23_acc_vivado (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_ACC_VIVADO)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_fpmult_e8m23_ssm_m12 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_SSM_M12)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_fpmult_e8m23_ssm_m14 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_SSM_M14)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_fpmult_e8m23_ssm_m16 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_SSM_M16)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_fpmult_e8m23_ssm_m18 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_SSM_M18)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_fpmult_e8m23_ssm_m12c (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_SSM_M12C)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_fpmult_e8m23_ssm_m14c (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_SSM_M14C)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_fpmult_e8m23_ssm_m16c (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_SSM_M16C)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_fpmult_e8m23_ssm_m18c (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_FPMULT_SSM_M18C)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_mult_3x3_acc1 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_MULT_3X3_ACC1)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_mult_6x6_acc1 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_MULT_6X6_ACC1)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_mult_12x12_acc1 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_MULT_12X12_ACC1)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_mult_24x24_acc1 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [47:0] prod_out
);
  timing_analysis_wrapper #(.MODE(`MODE_MULT_24X24_ACC1)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out)
  );
endmodule

module timing_mult_3x3_acc2 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_MULT_3X3_ACC2)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_mult_6x6_acc2 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_MULT_6X6_ACC2)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_mult_12x12_acc2 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_MULT_12X12_ACC2)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_mult_24x24_acc2 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [47:0] prod_out
);
  timing_analysis_wrapper #(.MODE(`MODE_MULT_24X24_ACC2)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out)
  );
endmodule

module timing_mult_3x3_mxa1 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_MULT_3X3_MXA1)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_mult_6x6_mxa1 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_MULT_6X6_MXA1)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_mult_12x12_mxa1 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_MULT_12X12_MXA1)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_mult_24x24_mxa1 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [47:0] prod_out
);
  timing_analysis_wrapper #(.MODE(`MODE_MULT_24X24_MXA1)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out)
  );
endmodule

module timing_mult_3x3_mxa2 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_MULT_3X3_MXA2)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_mult_6x6_mxa2 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_MULT_6X6_MXA2)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_mult_12x12_mxa2 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [31:0] prod_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_MULT_12X12_MXA2)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out_wide)
  );
  assign prod_out = prod_out_wide[31:0];
endmodule

module timing_mult_24x24_mxa2 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [47:0] prod_out
);
  timing_analysis_wrapper #(.MODE(`MODE_MULT_24X24_MXA2)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out)
  );
endmodule

module timing_mult_24x24_mxa2_plus_1 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [47:0] prod_out
);
  timing_analysis_wrapper #(.MODE(`MODE_MULT_24X24_MXA2_PLUS_1)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out)
  );
endmodule

module timing_mult_24x24_mxa2_plus_2 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [47:0] prod_out
);
  timing_analysis_wrapper #(.MODE(`MODE_MULT_24X24_MXA2_PLUS_2)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out)
  );
endmodule

module timing_mult_24x24_mxa2_plus_3 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [47:0] prod_out
);
  timing_analysis_wrapper #(.MODE(`MODE_MULT_24X24_MXA2_PLUS_3)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out)
  );
endmodule

module timing_mult_24x24_mxa2_plus_4 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [47:0] prod_out
);
  timing_analysis_wrapper #(.MODE(`MODE_MULT_24X24_MXA2_PLUS_4)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out)
  );
endmodule

module timing_mult_24x24_mxa2_plus_5 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [47:0] prod_out
);
  timing_analysis_wrapper #(.MODE(`MODE_MULT_24X24_MXA2_PLUS_5)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out)
  );
endmodule

module timing_mult_24x24_mxa2_plus_6 (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [47:0] prod_out
);
  timing_analysis_wrapper #(.MODE(`MODE_MULT_24X24_MXA2_PLUS_6)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out)
  );
endmodule

module timing_mult_24x24_lxa (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    output wire [47:0] prod_out
);
  timing_analysis_wrapper #(.MODE(`MODE_MULT_24X24_LXA)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(32'b0), .prod_out(prod_out)
  );
endmodule

module timing_carry_adder_3in_parallel (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    input  wire [31:0] c_in,
    output wire [31:0] sum_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_CARRY_ADDER_3IN_PARALLEL)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(c_in), .prod_out(prod_out_wide)
  );
  assign sum_out = prod_out_wide[31:0];
endmodule

module timing_carry_adder_3in (
    input  wire        clk,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    input  wire [31:0] c_in,
    output wire [31:0] sum_out
);
  wire [47:0] prod_out_wide;
  timing_analysis_wrapper #(.MODE(`MODE_CARRY_ADDER_3IN)) inst0 (
      .clk(clk), .a_in(a_in), .b_in(b_in), .c_in(c_in), .prod_out(prod_out_wide)
  );
  assign sum_out = prod_out_wide[31:0];
endmodule
