//-------------------------------------------------------------------------------
// More Approximate Design-1 MxA1 3x3 multiplier
//-------------------------------------------------------------------------------

module mult_3x3_mxa1 (
    a,
    b,
    prod
);

  localparam N = 3;

  input wire [N-1:0] a;
  input wire [N-1:0] b;
  output wire [2*N-1:0] prod;

  mult_3x3_acc1 #(.HP(1)) inst_mult (
      .a(a),
      .b(b),
      .prod(prod)
  );

endmodule
