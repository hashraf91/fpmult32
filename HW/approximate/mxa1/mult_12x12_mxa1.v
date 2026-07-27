//-------------------------------------------------------------------------------
// More Approximate Design-1 MxA1 12x12 multiplier
//-------------------------------------------------------------------------------

module mult_12x12_mxa1 (
    a,
    b,
    prod
);

  localparam N = 12;

  input wire [N-1:0] a;
  input wire [N-1:0] b;
  output wire [2*N-1:0] prod;

  mult_12x12_acc1 #(.HP(1)) inst_mult (
      .a(a),
      .b(b),
      .prod(prod)
  );

endmodule
