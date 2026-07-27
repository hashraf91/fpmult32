module mult_3x3_mxa2 (
    input  wire [2:0] a,
    input  wire [2:0] b,
    output wire [5:0] prod
);

  wire [3:0] gen;
  wire [3:0] prop;
  wire [3:0] outp;
  wire [4:0] carry;

  assign gen[0]   = 1'b0;
  assign carry[0] = 1'b0;

  assign gen[1]  = 1'b0;
  assign prop[0] = 1'b0;
  assign gen[2]  = 1'b0;
  assign prop[1] = 1'b0;

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

  assign prop[3] = a[2] & b[2];

  CARRY4 carry_inst0 (
      .DI(gen[3:0]), .S(prop[3:0]), .O(outp[3:0]), .CO(carry[4:1]), .CI(carry[0]), .CYINIT(1'b0)
  );

  assign prod = {carry[4], outp[3], outp[2], 3'b000};
endmodule
