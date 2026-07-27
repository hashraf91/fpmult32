module mult_24x24_mxa2 (
    a,
    b,
    prod
);

  localparam N = 24;

  input wire [N-1:0] a;
  input wire [N-1:0] b;
  output wire [2*N-1:0] prod;

  mult_24x24_acc2 #(.N_TRUNC(24)) mult_inst (
    .a(a),
    .b(b),
    .prod(prod)
  );

endmodule
