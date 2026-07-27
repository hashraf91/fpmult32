(* use_dsp = "no" *)
module fpmult_e8m23_acc2 #(
    parameter EXPONENT_BITS = 8,
    parameter MANTISSA_BITS = 23
)(
    input  [(1+EXPONENT_BITS+MANTISSA_BITS)-1:0] a,
    input  [(1+EXPONENT_BITS+MANTISSA_BITS)-1:0] b,
    output [(1+EXPONENT_BITS+MANTISSA_BITS)-1:0] prod,
    output special_case
);

    localparam TOTAL_BITS = 1 + EXPONENT_BITS + MANTISSA_BITS;
    localparam S_MANTMULT_BITS = 2 * MANTISSA_BITS;
    localparam L_MANTMULT_BITS = 2 * (MANTISSA_BITS + 1);
    localparam EXPONENT_BIAS = (1 << (EXPONENT_BITS - 1)) - 1;

    wire sign_a                    = a[TOTAL_BITS-1];
    wire [EXPONENT_BITS-1:0] exp_a = a[TOTAL_BITS-2:MANTISSA_BITS];
    wire [MANTISSA_BITS-1:0] man_a = a[MANTISSA_BITS-1:0];

    wire sign_b                    = b[TOTAL_BITS-1];
    wire [EXPONENT_BITS-1:0] exp_b = b[TOTAL_BITS-2:MANTISSA_BITS];
    wire [MANTISSA_BITS-1:0] man_b = b[MANTISSA_BITS-1:0];

    wire a_zero = (exp_a == 0) && (man_a == 0);
    wire b_zero = (exp_b == 0) && (man_b == 0);
    wire zero = a_zero | b_zero;

    wire exception = ((&exp_a) | (&exp_b));
    wire exception_1 = (&exp_a) & ((|man_a) | (exp_b == 0));
    wire exception_2 = (&exp_b) & ((|man_b) | (exp_a == 0));

    wire [L_MANTMULT_BITS-1:0] mantissa_result;
    mult_24x24_acc2 mult_inst0(.a({1'b1,man_a}), .b({1'b1,man_b}), .prod(mantissa_result));

    wire [(2+MANTISSA_BITS)-1:0] mantissa_rounded_2b = mantissa_result[L_MANTMULT_BITS-1:MANTISSA_BITS]
                                                     + (&mantissa_result[MANTISSA_BITS:MANTISSA_BITS-1])
                                                     + (mantissa_result[MANTISSA_BITS:MANTISSA_BITS-1] == 2'b01 & (|mantissa_result[MANTISSA_BITS-2:0]));
    wire [(1+MANTISSA_BITS)-1:0] mantissa_rounded_3b = mantissa_result[L_MANTMULT_BITS-1:MANTISSA_BITS+1]
                                                     + (&mantissa_result[MANTISSA_BITS+1:MANTISSA_BITS])
                                                     + (mantissa_result[MANTISSA_BITS+1:MANTISSA_BITS] == 2'b01 & (|mantissa_result[MANTISSA_BITS-1:0]));

    wire [EXPONENT_BITS:0] exp_sum = exp_a + exp_b - EXPONENT_BIAS;

    assign normalized = mantissa_rounded_3b[MANTISSA_BITS];

    wire [MANTISSA_BITS-1:0] mantissa_final = (normalized) ? mantissa_rounded_3b[MANTISSA_BITS-1:0] : mantissa_rounded_2b[MANTISSA_BITS-1:0];
    wire [EXPONENT_BITS:0] exp_final = (normalized) ? exp_sum + 1 : exp_sum;

    wire underflow = ((exp_sum[EXPONENT_BITS] & exp_sum[EXPONENT_BITS-1]) || exp_a == 0 || exp_b == 0 || exp_final[EXPONENT_BITS:0] == 0);
    wire overflow = ((exp_final[EXPONENT_BITS] & ~exp_final[EXPONENT_BITS-1]) || (&exp_final[EXPONENT_BITS-1:0]));

    wire result_sign = sign_a ^ sign_b;

    assign prod = (exception_1 | exception_2) ? {1'b0, {EXPONENT_BITS{1'b1}}, 1'b1, {MANTISSA_BITS-1{1'b0}}}
                                              : exception
                                                ? {result_sign, {EXPONENT_BITS{1'b1}}, {MANTISSA_BITS{1'b0}}}
                                                : (zero | underflow)
                                                  ? {result_sign,{TOTAL_BITS-1{1'b0}}}
                                                  : (overflow)
                                                    ? {result_sign, {EXPONENT_BITS{1'b1}}, {MANTISSA_BITS{1'b0}}}
                                                    : {result_sign, exp_final[EXPONENT_BITS-1:0], mantissa_final};

    assign special_case = underflow | overflow | exception | exception_1 | exception_2;
endmodule
