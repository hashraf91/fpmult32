module mult_6x6_acc2 #(
    parameter N = 6
) (
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    output wire [2*N-1:0] prod
);

  localparam N_carry8 = (N / 8 + |(N % 8)) * 8;

  wire [N_carry8:0] carry[N/2-1:0];
  wire [N_carry8-1:0] gen[N/2-1:0];
  wire [N_carry8-1:0] prop[N/2-1:0];
  wire [N_carry8-1:0] outp[N/2-1:0];

  wire [(N+2)-1:0] ppp_l1[N/2-1:0];

  genvar i, j;
  generate
    for (j = 0; j < N / 2; j = j + 1) begin : row_count
      for (i = 0; i <= N - 2; i = i + 1) begin : type_a
        LUT6_2 #(
            .INIT(64'h7888788880008000)
        ) lut_inst0 (
            .I0(b[j*2]),
            .I1(a[i+1]),
            .I2(b[(j*2)+1]),
            .I3(a[i]),
            .I4(1'b1),
            .I5(1'b1),
            .O5(gen[j][i]),
            .O6(prop[j][i])
        );
      end
      LUT6_2 #(
          .INIT(64'hF000F00088888888)
      ) lut_inst1 (
          .I0(a[0]),
          .I1(b[j*2]),
          .I2(a[N-1]),
          .I3(b[(j*2)+1]),
          .I4(1'b1),
          .I5(1'b1),
          .O5(ppp_l1[j][0]),
          .O6(prop[j][N-1])
      );
      assign gen[j][N_carry8-1:N-1] = {N_carry8 - N + 1{1'b0}};
      assign prop[j][N_carry8-1:N]  = {N_carry8 - N{1'b1}};
    end

    for (j = 0; j < N / 2; j = j + 1) begin : row_control
      assign carry[j][0] = 1'b0;
      for (i = 0; i < N_carry8 / 8; i = i + 1) begin : carry_chain_type_a
        CARRY8 #(
            .CARRY_TYPE("SINGLE_CY8")
        ) cci (
            .DI(gen[j][i*8+:8]),
            .S(prop[j][i*8+:8]),
            .O(outp[j][i*8+:8]),
            .CO(carry[j][i*8+1+:8]),
            .CI(carry[j][i*8])
        );
      end
      assign ppp_l1[j][N+1:1] = {carry[j][N], outp[j][N-1:0]};
    end
  endgenerate

  carry_adder_3in #(
      .INP_WIDTH_LO(N + 2),
      .EFF_WIDTH(N + 3),
      .INP_WIDTH_HI(N + 4),
      .NEG_A(0)
  ) carry_inst0 (
      .a({ppp_l1[2][(N+2)-1:0], 2'b00}),
      .b({ppp_l1[1][(N+2)-1:0]}),
      .c({2'b00, ppp_l1[0][(N+2)-1:2]}),
      .zero(1'b0),
      .sum(prod[2*N-1:2])
  );

  assign prod[1:0] = ppp_l1[0][1:0];

endmodule
