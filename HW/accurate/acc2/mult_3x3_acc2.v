module mult_3x3_acc2 (
    a,
    b,
    prod
);

  input [2:0] a;
  input [2:0] b;
  output [5:0] prod;

  wire [2:0] a;
  wire [2:0] b;
  wire [5:0] prod;

  wire [3:0] gen;
  wire [3:0] prop;
  wire [3:0] outp;
  wire [4:0] carry;

  wire [3:0] propi;

  assign carry[0] = 1'b0;
  assign gen[0] = 1'b0;

  LUT6_2 #(
      .INIT(64'h7888788880008000)
  ) lut_inst0 (
      .I0(b[0]),
      .I1(a[1]),
      .I2(b[1]),
      .I3(a[0]),
      .I4(1'b1),
      .I5(1'b1),
      .O5(gen[1]),
      .O6(prop[0])
  );

  LUT6 #(
      .INIT(64'hE888A000C0000000)
  ) lut_inst10 (
      .I0(b[2]),
      .I1(b[1]),
      .I2(b[0]),
      .I3(a[2]),
      .I4(a[1]),
      .I5(a[0]),
      .O(gen[2])
  );
  LUT6 #(
      .INIT(64'h96665AAA3CCCF000)
  ) lut_inst11 (
      .I0(b[2]),
      .I1(b[1]),
      .I2(b[0]),
      .I3(a[2]),
      .I4(a[1]),
      .I5(a[0]),
      .O(propi[1])
  );
  LUT2 #(
      .INIT(4'h6)
  ) lut_inst12 (
      .I0(gen[1]),
      .I1(propi[1]),
      .O(prop[1])
  );

  LUT6_2 #(
      .INIT(64'h8777788880008000)
  ) lut_inst2 (
      .I0(b[1]),
      .I1(a[2]),
      .I2(b[2]),
      .I3(a[1]),
      .I4(gen[2]),
      .I5(1'b1),
      .O5(gen[3]),
      .O6(prop[2])
  );

  LUT6_2 #(
      .INIT(64'h0FFFF00088888888)
  ) lut_inst3 (
      .I0(a[0]),
      .I1(b[0]),
      .I2(a[2]),
      .I3(b[2]),
      .I4(gen[3]),
      .I5(1'b1),
      .O5(prod[0]),
      .O6(prop[3])
  );

  CARRY4 carry_inst0 (
      .DI(gen[3:0]),
      .S(prop[3:0]),
      .O(outp[3:0]),
      .CO(carry[4:1]),
      .CI(carry[0]),
      .CYINIT(1'b0)
  );

  assign prod[5:1] = {carry[4],outp[3:0]};

endmodule
