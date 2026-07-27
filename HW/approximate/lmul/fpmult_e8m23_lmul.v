
module fpmult_e8m23_lmul #(
    parameter TOTAL_BITS = 32
)(
    input  [TOTAL_BITS-1:0] a,
    input  [TOTAL_BITS-1:0] b,
    output [TOTAL_BITS-1:0] prod
);

    wire sign_a                    = a[TOTAL_BITS-1];
    wire [TOTAL_BITS-2:0] rvalue_a = a[TOTAL_BITS-2:0];

    wire sign_b                    = b[TOTAL_BITS-1];
    wire [TOTAL_BITS-2:0] rvalue_b = b[TOTAL_BITS-2:0];

    assign zero = (rvalue_a == 0) | (rvalue_b == 0);

    assign prod[TOTAL_BITS-1] = sign_a ^ sign_b;

    carry_adder_3in #(
      .INP_WIDTH_LO(TOTAL_BITS-1),
      .INP_WIDTH_HI(TOTAL_BITS-1),
      .EFF_WIDTH(TOTAL_BITS-1),
      .NEG_A(1)
    ) inst0 (
      .a(31'h3F780000),
      .b(rvalue_a[0+:TOTAL_BITS-1]),
      .c(rvalue_b[0+:TOTAL_BITS-1]),
      .zero(zero),
      .sum(prod[0+:TOTAL_BITS-1])
    );

endmodule
