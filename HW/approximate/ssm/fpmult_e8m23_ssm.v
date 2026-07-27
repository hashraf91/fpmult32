module fpmult_e8m23_ssm #(
    parameter USE_CORRECTION = 1,
    parameter MANT_MULT_BITS = 18
) (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] prod
);

  localparam N  = 32;
  localparam NE = 8;
  localparam NM = 23;
  localparam EXP_BIAS = 2**(NE-1)-1;

  wire sign_a, sign_b;
  wire [NE-1:0] exp_a, exp_b;
  wire [NM-1:0] man_a, man_b;

  assign sign_a = a[N-1];
  assign sign_b = b[N-1];

  assign exp_a = a[N-2:(N-2)-NE+1];
  assign exp_b = b[N-2:(N-2)-NE+1];

  assign man_a = a[(N-2)-NE:0];
  assign man_b = b[(N-2)-NE:0];

  wire [NM+2:0] mantissa_mult;
  wire sel;
  wire [NM+1:0] mantissa_norm;

  generate
    if (USE_CORRECTION == 0 && MANT_MULT_BITS == 12) begin : gen_mult_23x23_ssm_m12
      mult_23x23_ssm_m12 mult_inst (
          .a(man_a),
          .b(man_b),
          .ris(mantissa_mult)
      );
    end
    else if (USE_CORRECTION == 0 && MANT_MULT_BITS == 14) begin : gen_mult_23x23_ssm_m14
      mult_23x23_ssm_m14 mult_inst (
          .a(man_a),
          .b(man_b),
          .ris(mantissa_mult)
      );
    end
    else if (USE_CORRECTION == 0 && MANT_MULT_BITS == 16) begin : gen_mult_23x23_ssm_m16
      mult_23x23_ssm_m16 mult_inst (
          .a(man_a),
          .b(man_b),
          .ris(mantissa_mult)
      );
    end
    else if (USE_CORRECTION == 0 && MANT_MULT_BITS == 18) begin : gen_mult_23x23_ssm_m18
      mult_23x23_ssm_m18 mult_inst (
          .a(man_a),
          .b(man_b),
          .ris(mantissa_mult)
      );
    end
    else if (USE_CORRECTION == 1 && MANT_MULT_BITS == 12) begin : gen_mult_23x23_ssm_m12c
      mult_23x23_ssm_m12c mult_inst (
          .a(man_a),
          .b(man_b),
          .ris(mantissa_mult)
      );
    end
    else if (USE_CORRECTION == 1 && MANT_MULT_BITS == 14) begin : gen_mult_23x23_ssm_m14c
      mult_23x23_ssm_m14c mult_inst (
          .a(man_a),
          .b(man_b),
          .ris(mantissa_mult)
      );
    end
    else if (USE_CORRECTION == 1 && MANT_MULT_BITS == 16) begin : gen_mult_23x23_ssm_m16c
      mult_23x23_ssm_m16c mult_inst (
          .a(man_a),
          .b(man_b),
          .ris(mantissa_mult)
      );
    end
    else if (USE_CORRECTION == 1 && MANT_MULT_BITS == 18) begin : gen_mult_23x23_ssm_m18c
      mult_23x23_ssm_m18c mult_inst (
          .a(man_a),
          .b(man_b),
          .ris(mantissa_mult)
      );
    end
    else begin : gen_invalid_cfg
      ERROR_INVALID_SSM_CONFIGURATION invalid_cfg ();
    end
  endgenerate

  assign sel = mantissa_mult[NM+2] || mantissa_mult[NM+1];

  assign mantissa_norm = {~mantissa_mult[NM+1], mantissa_mult[NM:0]} + {sel, ~sel};
  assign prod[NM-1:0] = (sel == 1'b1)
                      ? mantissa_norm[NM+1:2]
                      : mantissa_norm[NM:1];

  wire [NE-1:0] exp_tmp;
  assign exp_tmp = exp_a + exp_b - EXP_BIAS;
  assign prod[N-2:NM] = exp_tmp + sel;

  assign prod[N-1] = sign_a ^ sign_b;

endmodule

module ERROR_INVALID_SSM_CONFIGURATION;
endmodule
