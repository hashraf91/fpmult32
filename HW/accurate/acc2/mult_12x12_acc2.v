module mult_12x12_acc2 (
    input wire [N-1:0] a,
    input wire [N-1:0] b,
    output wire [2*N-1:0] prod
);

  parameter N = 12;
  localparam N_CARRY8 = (N / 8 + |(N % 8)) * 8;

  wire [N_CARRY8:0]  carry[N/2-1:0];
  wire [N_CARRY8-1:0]  gen[N/2-1:0];
  wire [N_CARRY8-1:0] prop[N/2-1:0];
  wire [N_CARRY8-1:0] outp[N/2-1:0];

  wire [(N+2)-1:0] ppp_l1[N/2-1:0];

  wire [(N+6)-1:0] ppp_l2[N/6-1:0];

  genvar i, j;
  generate
    for (j = 0; j <= N / 2 - 1; j = j + 1) begin : set_initial_carry
      assign carry[j][0] = 1'b0;
    end
    for (j = 0; j <= N / 2 - 1; j = j + 1) begin : row_count
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
      assign gen[j][N_CARRY8-1:N-1] = {N_CARRY8-N+1{1'b0}};
      if (N_CARRY8 > N) begin
        assign prop[j][N_CARRY8-1:N] = {N_CARRY8-N{1'b1}};
      end
    end
    for (j = 0; j <= N / 2 - 1; j = j + 1) begin : row_control
      for (i = 0; i <= N_CARRY8 / 8 - 1; i = i + 1) begin : carry_chain_type_a
        CARRY8 #(
            .CARRY_TYPE("SINGLE_CY8")
        ) cci (
            .CO(carry[j][(i+1)*8:i*8+1]),
            .O(outp[j][i*8+7:i*8]),
            .CI(carry[j][i*8]),
            .DI(gen[j][i*8+7:i*8]),
            .S(prop[j][i*8+7:i*8])
        );
      end
      assign ppp_l1[j][N+1:1] = {carry[j][N],outp[j][N-1:0]};
    end
  endgenerate

  carry_adder_3in #(
      .INP_WIDTH_LO(N+2),
      .EFF_WIDTH(N+3),
      .INP_WIDTH_HI(N+4),
      .NEG_A(0)
  ) carry_inst0 (
      .a({ppp_l1[2][(N+2)-1:0],2'b00}),
      .b({ppp_l1[1][(N+2)-1:0]}),
      .c({2'b00,ppp_l1[0][(N+2)-1:2]}),
      .zero(1'b0),
      .sum(ppp_l2[0][N+6-1:2])
  );
  assign ppp_l2[0][1:0] = ppp_l1[0][1:0];

  carry_adder_3in #(
      .INP_WIDTH_LO(N+2),
      .EFF_WIDTH(N+3),
      .INP_WIDTH_HI(N+4),
      .NEG_A(0)
  ) carry_inst1 (
      .a({ppp_l1[5][(N+2)-1:0],2'b00}),
      .b({ppp_l1[4][(N+2)-1:0]}),
      .c({2'b00,ppp_l1[3][(N+2)-1:2]}),
      .zero(1'b0),
      .sum(ppp_l2[1][N+6-1:2])
  );
  assign ppp_l2[1][1:0] = ppp_l1[3][1:0];

  carry_adder_2in #(
      .INP_WIDTH_LO(N),
      .INP_WIDTH_HI(N+6),
      .NEG_A(0)
  ) carry_inst2 (
      .a({ppp_l2[1][(N+6)-1:0]}),
      .b({ppp_l2[0][(N+6)-1:6]}),
      .sum(prod[2*N-1:6])
  );
  assign prod[5:0] = ppp_l2[0][5:0];

endmodule
