//-------------------------------------------------------------------------------
// More Approximate Design-1 MxA1 6x6 multiplier
//-------------------------------------------------------------------------------

module mult_6x6_mxa1 (
    a,
    b,
    prod
);

  localparam N = 6;

  input wire [N-1:0] a;
  input wire [N-1:0] b;
  output wire [2*N-1:0] prod;

  mult_6x6_acc1 #(.HP(1)) inst_mult (
      .a(a),
      .b(b),
      .prod(prod)
  );

endmodule
