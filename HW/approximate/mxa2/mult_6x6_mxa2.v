module mult_6x6_mxa2 #(
    parameter N = 6
) (
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    output wire [2*N-1:0] prod
);

  localparam N_carry8 = (N / 8 + |(N % 8)) * 8 + 7;

  wire [N_carry8:0] carry[N/2-1:0];
  wire [N_carry8-1:0] gen[N/2-1:0];
  wire [N_carry8-1:0] prop[N/2-1:0];
  wire [N_carry8-1:0] outp[N/2-1:0];

  wire [(N+2)-1:0] ppp_l1[N/2-1:0];

  genvar i, j;
  generate
    for (j = 0; j < N / 2; j = j + 1) begin : row_count
      for (i = 0; i <= N - 2; i = i + 1) begin : type_a
        if (i + 2 * j > N - 2)
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
        else begin
          assign gen[j][i]  = 1'b0;
          assign prop[j][i] = 1'b0;
        end
      end
      LUT2 #(
          .INIT(4'h8)
      ) lut_inst1 (
          .I0(a[N-1]),
          .I1(b[(j*2)+1]),
          .O(prop[j][N-1])
      );
      assign gen[j][N_carry8-1:N-1] = {N_carry8 - N + 1{1'b0}};
      if (N_carry8 > N) begin
        assign prop[j][N_carry8-1:N] = {N_carry8 - N{1'b1}};
      end
    end
    for (j = 1; j < N / 2; j = j + 1) begin : row_control
      assign carry[j][N-2-2*j+1] = 1'b0;
      for (i = 0; i < (2 * j + 1) / 8 + |((2 * j + 1) % 8); i = i + 1) begin : carry_chain_type_a
        CARRY8 #(
            .CARRY_TYPE("SINGLE_CY8")
        ) cci (
            .CO(carry[j][(N-2-2*j+1)+i*8+1+:8]),
            .O(outp[j][(N-2-2*j+1)+i*8+:8]),
            .CI(carry[j][(N-2-2*j+1)+i*8]),
            .DI(gen[j][(N-2-2*j+1)+i*8+:8]),
            .S(prop[j][(N-2-2*j+1)+i*8+:8])
        );
      end
      assign ppp_l1[j][N+1-:2*j+2] = {carry[j][N], outp[j][N-1-:2*j+1]};
    end
    assign ppp_l1[0][N+1:N] = {1'b0, prop[0][N-1]};
  endgenerate

  carry_adder_3in #(
      .INP_WIDTH_LO(4),
      .EFF_WIDTH(5),
      .INP_WIDTH_HI(6),
      .NEG_A(0)
  ) carry_inst0 (
      .a({ppp_l1[2][(N+2)-1-:6]}),
      .b({ppp_l1[1][(N+2)-1-:4]}),
      .c({2'b00, ppp_l1[0][(N+2)-1-:2]}),
      .zero(1'b0),
      .sum(prod[2*N-1:6])
  );

  assign prod[5:0] = 6'b000000;

endmodule
