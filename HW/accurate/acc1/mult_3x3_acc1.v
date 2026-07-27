//-------------------------------------------------------------------------------
// Accurate Design-1 3x3 multiplier
//-------------------------------------------------------------------------------

module mult_3x3_acc1 (
    a,
    b,
    prod
);

  parameter HP = 0;

  input [2:0] a;
  input [2:0] b;
  output [5:0] prod;

  wire [2:0] a;
  wire [2:0] b;
  wire [5:0] prod;

  generate
    if (HP == 1) begin
      assign prod[2:0] = 3'b0;
    end else begin
      LUT6_2 #(
          .INIT(64'h00006AC00000A0A0)
      ) lut_inst0 (
          .I0(a[0]),
          .I1(a[1]),
          .I2(b[0]),
          .I3(b[1]),
          .I4(1'b0),
          .I5(1'b1),
          .O5(prod[0]),
          .O6(prod[1])
      );

      LUT6_2 #(
          .INIT(64'h1E665AAAB4CCF000)
      ) lut_inst1 (
          .I0(a[0]),
          .I1(a[1]),
          .I2(a[2]),
          .I3(b[0]),
          .I4(b[1]),
          .I5(b[2]),
          .O6(prod[2])
      );
    end
  endgenerate

  LUT6_2 #(
      .INIT(64'h54B46CCC38F00000)
  ) lut_inst2 (
      .I0(a[0]),
      .I1(a[1]),
      .I2(a[2]),
      .I3(b[0]),
      .I4(b[1]),
      .I5(b[2]),
      .O6(prod[3])
  );

  LUT6_2 #(
      .INIT(64'h983870F0C0000000)
  ) lut_inst3 (
      .I0(a[0]),
      .I1(a[1]),
      .I2(a[2]),
      .I3(b[0]),
      .I4(b[1]),
      .I5(b[2]),
      .O6(prod[4])
  );

  LUT6_2 #(
      .INIT(64'hE0C0800000000000)
  ) lut_inst4 (
      .I0(a[0]),
      .I1(a[1]),
      .I2(a[2]),
      .I3(b[0]),
      .I4(b[1]),
      .I5(b[2]),
      .O6(prod[5])
  );

endmodule
