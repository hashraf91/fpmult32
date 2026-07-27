
module fpmult_e8m23_mxa2 #(
    parameter EXPONENT_BITS = 8,
    parameter MANTISSA_BITS = 23
)(
    input  [(1+EXPONENT_BITS+MANTISSA_BITS)-1:0] a,
    input  [(1+EXPONENT_BITS+MANTISSA_BITS)-1:0] b,
    output [(1+EXPONENT_BITS+MANTISSA_BITS)-1:0] prod
);

    localparam TOTAL_BITS = 1 + EXPONENT_BITS + MANTISSA_BITS;
    localparam EXPONENT_BIAS = (1 << (EXPONENT_BITS - 1)) - 1;
    localparam S_MANTMULT_BITS = 2 * MANTISSA_BITS;
    localparam L_MANTMULT_BITS = 2 * (MANTISSA_BITS + 1);

    wire sign_a                    = a[TOTAL_BITS-1];
    wire [EXPONENT_BITS-1:0] exp_a = a[TOTAL_BITS-2:MANTISSA_BITS];
    wire [MANTISSA_BITS-1:0] man_a = a[MANTISSA_BITS-1:0];

    wire sign_b                    = b[TOTAL_BITS-1];
    wire [EXPONENT_BITS-1:0] exp_b = b[TOTAL_BITS-2:MANTISSA_BITS];
    wire [MANTISSA_BITS-1:0] man_b = b[MANTISSA_BITS-1:0];

    wire zero = (a[TOTAL_BITS-2:0] == 0) | (b[TOTAL_BITS-2:0] == 0);

    wire [L_MANTMULT_BITS-1:0] mantissa_mult;
    mult_24x24_mxa2 mult_inst0(.a({1'b1,man_a}), .b({1'b1,man_b}), .prod(mantissa_mult));
    wire [(2+MANTISSA_BITS)-1:0] mantissa_result = mantissa_mult[L_MANTMULT_BITS-1:MANTISSA_BITS];

    wire [MANTISSA_BITS-1:0] mantissa_final;
    genvar i;
    generate
      for(i = 0; i < (MANTISSA_BITS/2)*2; i = i + 2) begin
        LUT6_2 #(
            .INIT({16'h0000, 16'hF0CC, 16'h0000, 16'hCCAA})
        ) mantissa_shift_inst (
            .O6(mantissa_final[i+1]),
            .O5(mantissa_final[i]),
            .I5(1'b1),
            .I4(zero),
            .I3(mantissa_result[(2+MANTISSA_BITS)-1]),
            .I2(mantissa_result[i+2]),
            .I1(mantissa_result[i+1]),
            .I0(mantissa_result[i])
        );
      end
      if (MANTISSA_BITS % 2) begin
          LUT4 #(
              .INIT({8'h00, 8'hCA})
          ) mantissa_shift_inst_last (
            .O(mantissa_final[MANTISSA_BITS-1]),
            .I3(zero),
            .I2(mantissa_result[(2+MANTISSA_BITS)-1]),
            .I1(mantissa_result[MANTISSA_BITS]),
            .I0(mantissa_result[MANTISSA_BITS-1])
          );
      end
    endgenerate

    wire exp_cin;
    wire sign_final;
    LUT6_2 #(
        .INIT({24'h0, 8'h0F, 24'h0, 8'h66})
    ) expcin_signfinal_inst (
        .O6(exp_cin),
        .O5(sign_final),
        .I5(1'b1),
        .I4(1'b0),
        .I3(1'b0),
        .I2(mantissa_result[(2+MANTISSA_BITS)-1]),
        .I1(sign_b),
        .I0(sign_a)
    );
    wire [EXPONENT_BITS-1:0] exp_final;
    carry_adder_3in #(
      .INP_WIDTH_LO(EXPONENT_BITS),
      .INP_WIDTH_HI(EXPONENT_BITS),
      .EFF_WIDTH(EXPONENT_BITS),
      .NEG_A(1)
    ) inst2 (
      .a({1'b0,EXPONENT_BIAS[EXPONENT_BITS-2:1],exp_cin}),
      .b(exp_a),
      .c(exp_b),
      .zero(zero),
      .sum(exp_final)
    );

    assign prod = {sign_final, exp_final, mantissa_final};

endmodule
