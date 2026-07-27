//-------------------------------------------------------------------------------
// More Approximate Design-1 MxA1 24x24 multiplier
//-------------------------------------------------------------------------------

module mult_24x24_mxa1 (
    zero,
    a,
    b,
    prod
);

  localparam N = 24;

  input wire zero;
  input wire [N-1:0] a;
  input wire [N-1:0] b;
  output wire [2*N-1:0] prod;

  mult_24x24_acc1 #(.HP(1)) inst_mult (
      .zero(zero),
      .a(a),
      .b(b),
      .prod(prod)
  );

endmodule
