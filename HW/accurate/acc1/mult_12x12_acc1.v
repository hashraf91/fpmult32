//-------------------------------------------------------------------------------
// Accurate Design-1 12x12 multiplier with accurate adder
//-------------------------------------------------------------------------------

module mult_12x12_acc1 (
    a,
    b,
    prod
);

  parameter HP = 0;
  localparam N = 12;

  input [N-1:0] a;
  input [N-1:0] b;
  output [2*N-1:0] prod;

  wire [  N-1:0] a;
  wire [  N-1:0] b;
  wire [2*N-1:0] prod;

  wire [  N-1:0] prod_sig[3:0];

  generate
    if (HP == 1) begin
      assign prod_sig[0] = {(N) {1'b0}};
    end else begin
      mult_6x6_acc1 #(
          .HP(0)
      ) inst0_mult (
          .a(a[N/2-1:0]),
          .b(b[N/2-1:0]),
          .prod(prod_sig[0])
      );
    end
  endgenerate

  mult_6x6_acc1 #(
      .HP(HP)
  ) inst1_mult (
      .a(a[N/2-1:0]),
      .b(b[N-1:N/2]),
      .prod(prod_sig[1])
  );

  mult_6x6_acc1 #(
      .HP(HP)
  ) inst2_mult (
      .a(a[N-1:N/2]),
      .b(b[N/2-1:0]),
      .prod(prod_sig[2])
  );

  mult_6x6_acc1 #(
      .HP(0)
  ) inst3_mult (
      .a(a[N-1:N/2]),
      .b(b[N-1:N/2]),
      .prod(prod_sig[3])
  );

  adder #(
      .N (N),
      .HP(HP)
  ) inst_add (
      .prod1(prod_sig[0]),
      .prod2(prod_sig[1]),
      .prod3(prod_sig[2]),
      .prod4(prod_sig[3]),
      .prod (prod)
  );

endmodule
