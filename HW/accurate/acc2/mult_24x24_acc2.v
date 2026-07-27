module mult_24x24_acc2 #(
    parameter N_TRUNC = 0
) (
    a,
    b,
    prod
);

  localparam N = 24;
  localparam N_CARRY8 = (N / 8 + |(N % 8)) * 8 + 7;
  localparam N_L1 = N + 2;
  localparam N_L2 = N_L1 + 4;
  localparam N_L3 = N_L2 + 6;

  input wire [N-1:0] a;
  input wire [N-1:0] b;
  output wire [2*N-1:0] prod;

  function integer col_start;
    input integer row_idx;
    begin
      col_start = N_TRUNC - 1 - 2 * row_idx;
      if (col_start < 0) col_start = 0;
    end
  endfunction

  wire [N_CARRY8:0] carry[N/2-1:0];
  wire [N_CARRY8-1:0] gen[N/2-1:0];
  wire [N_CARRY8-1:0] prop[N/2-1:0];
  wire [N_CARRY8-1:0] outp[N/2-1:0];

  wire [N_L1-1:0] ppp_l1[N/2-1:0];
  wire [N_L2-1:0] pp_l2[N/6-1:0];
  wire [N_L3-1:0] pp_l3[N/12-1:0];

  genvar i, j;
  generate
    for (j = 0; j < N / 2; j = j + 1) begin : row_count
      for (i = 0; i < col_start(j); i = i + 1) begin
        assign gen[j][i]  = 1'b0;
        assign prop[j][i] = 1'b0;
      end
      for (i = col_start(j); i < N - 1; i = i + 1) begin : type_a
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
      if (col_start(j) == 0) begin
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
      end else begin
        LUT2 #(
            .INIT(4'h8)
        ) lut_inst1 (
            .I0(a[N-1]),
            .I1(b[(j*2)+1]),
            .O(prop[j][N-1])
        );
        assign ppp_l1[j][0] = 1'b0;
      end
      assign gen[j][N_CARRY8-1:N-1] = {N_CARRY8 - N + 1{1'b0}};
      if (N_CARRY8 > N) begin
        assign prop[j][N_CARRY8-1:N] = {N_CARRY8 - N{1'b1}};
      end
    end

    for (j = 0; j < N / 2; j = j + 1) begin : row_control
      if (N - col_start(j) < 1) begin
        assign ppp_l1[j][N_L1-1:1] = 'b0;
      end else if (N - col_start(j) == 1) begin
        assign ppp_l1[j][N_L1-1-:2] = {1'b0, prop[j][N-1]};
        assign ppp_l1[j][N_L1-3:1]  = 'b0;
      end else begin
        assign carry[j][col_start(j):0] = 'b0;
        for (i = 0; i < (N - col_start(j)) / 8 + |((N - col_start(j)) % 8); i = i + 1) begin : carry_chain_type_a
          CARRY8 #(
              .CARRY_TYPE("SINGLE_CY8")
          ) cci (
              .CO(carry[j][col_start(j)+i*8+1+:8]),
              .O(outp[j][col_start(j)+i*8+:8]),
              .CI(carry[j][col_start(j)+i*8]),
              .DI(gen[j][col_start(j)+i*8+:8]),
              .S(prop[j][col_start(j)+i*8+:8])
          );
        end
        assign ppp_l1[j][N_L1-1:col_start(j)+1] = {carry[j][N], outp[j][N-1:col_start(j)]};
        if (col_start(j) > 1) assign ppp_l1[j][col_start(j):1] = 'b0;
      end
    end
  endgenerate

  localparam N_L2_SUM_MAX = N_L2 - 2;
  localparam N_L2_0_SUM = N_L2 - ((N_TRUNC > 2) ? N_TRUNC : 2);

  generate
    if (N_L2_0_SUM > 2) begin
      wire [2+N_L1-1:0] ppp_l1_2z;
      assign ppp_l1_2z[2+N_L1-1:0] = {ppp_l1[2][N_L1-1:0], 2'b00};
      carry_adder_3in #(
          .INP_WIDTH_LO(N_L2_0_SUM - 2),
          .EFF_WIDTH(N_L2_0_SUM - 1),
          .INP_WIDTH_HI(N_L2_0_SUM),
          .NEG_A(0)
      ) carry_inst_l2_0 (
          .a(ppp_l1_2z[2+N_L1-1-:(N_L2_0_SUM>2+N_L1)?2+N_L1 : N_L2_0_SUM]),
          .b(ppp_l1[1][N_L1-1-:N_L2_0_SUM-2]),
          .c({2'b00, ppp_l1[0][N_L1-1-:N_L2_0_SUM-4]}),
          .zero(1'b0),
          .sum(pp_l2[0][N_L2-1-:N_L2_0_SUM])
      );
      if (N_L2_0_SUM < N_L2_SUM_MAX) begin
        assign pp_l2[0][N_L2-N_L2_0_SUM-1:2] = 'b0;
      end
    end else if (N_L2_0_SUM > 0) begin
      assign pp_l2[0][N_L2-1-:N_L2_0_SUM]  = ppp_l1[2][N_L1-1-:N_L2_0_SUM];
      assign pp_l2[0][N_L2-N_L2_0_SUM-1:2] = 'b0;
    end else begin
      assign pp_l2[0][N_L2-1:2] = 'b0;
    end
    assign pp_l2[0][1:0] = ppp_l1[0][1:0];

    localparam N_L2_1_SUM = N_L2 - ((N_TRUNC - 6 > 2) ? N_TRUNC - 6 : 2);

    if (N_L2_1_SUM > 2) begin
      wire [2+N_L1-1:0] ppp_l1_5z;
      assign ppp_l1_5z[2+N_L1-1:0] = {ppp_l1[5][N_L1-1:0], 2'b00};
      carry_adder_3in #(
          .INP_WIDTH_LO(N_L2_1_SUM - 2),
          .EFF_WIDTH(N_L2_1_SUM - 1),
          .INP_WIDTH_HI(N_L2_1_SUM),
          .NEG_A(0)
      ) carry_inst_l2_1 (
          .a(ppp_l1_5z[2+N_L1-1-:(N_L2_1_SUM>2+N_L1)?2+N_L1 : N_L2_1_SUM]),
          .b(ppp_l1[4][N_L1-1-:N_L2_1_SUM-2]),
          .c({2'b00, ppp_l1[3][N_L1-1-:N_L2_1_SUM-4]}),
          .zero(1'b0),
          .sum(pp_l2[1][N_L2-1-:N_L2_1_SUM])
      );
      if (N_L2_1_SUM < N_L2_SUM_MAX) begin
        assign pp_l2[1][N_L2-N_L2_1_SUM-1:2] = 'b0;
      end
    end else if (N_L2_1_SUM > 0) begin
      assign pp_l2[1][N_L2-1-:N_L2_1_SUM]  = ppp_l1[5][N_L1-1-:N_L2_1_SUM];
      assign pp_l2[1][N_L2-N_L2_1_SUM-1:2] = 'b0;
    end else begin
      assign pp_l2[1][N_L2-1:2] = 'b0;
    end
    assign pp_l2[1][1:0] = ppp_l1[3][1:0];

    localparam N_L2_2_SUM = N_L2 - ((N_TRUNC - 12 > 2) ? N_TRUNC - 12 : 2);

    if (N_L2_2_SUM > 2) begin
      wire [2+N_L1-1:0] ppp_l1_8z;
      assign ppp_l1_8z[2+N_L1-1:0] = {ppp_l1[8][N_L1-1:0], 2'b00};
      carry_adder_3in #(
          .INP_WIDTH_LO(N_L2_2_SUM - 2),
          .EFF_WIDTH(N_L2_2_SUM - 1),
          .INP_WIDTH_HI(N_L2_2_SUM),
          .NEG_A(0)
      ) carry_inst_l2_2 (
          .a(ppp_l1_8z[2+N_L1-1-:(N_L2_2_SUM>2+N_L1)?2+N_L1 : N_L2_2_SUM]),
          .b(ppp_l1[7][N_L1-1-:N_L2_2_SUM-2]),
          .c({2'b00, ppp_l1[6][N_L1-1-:N_L2_2_SUM-4]}),
          .zero(1'b0),
          .sum(pp_l2[2][N_L2-1-:N_L2_2_SUM])
      );
      if (N_L2_2_SUM < N_L2_SUM_MAX) begin
        assign pp_l2[2][N_L2-N_L2_2_SUM-1:2] = 'b0;
      end
    end else if (N_L2_2_SUM > 0) begin
      assign pp_l2[2][N_L2-1-:N_L2_2_SUM]  = ppp_l1[8][N_L1-1-:N_L2_2_SUM];
      assign pp_l2[2][N_L2-N_L2_2_SUM-1:2] = 'b0;
    end else begin
      assign pp_l2[2][N_L2-1:2] = 'b0;
    end
    assign pp_l2[2][1:0] = ppp_l1[6][1:0];

    localparam N_L2_3_SUM = N_L2 - ((N_TRUNC - 18 > 2) ? N_TRUNC - 18 : 2);

    if (N_L2_3_SUM > 2) begin
      wire [2+N_L1-1:0] ppp_l1_11z;
      assign ppp_l1_11z[2+N_L1-1:0] = {ppp_l1[11][N_L1-1:0], 2'b00};
      carry_adder_3in #(
          .INP_WIDTH_LO(N_L2_3_SUM - 2),
          .EFF_WIDTH(N_L2_3_SUM - 1),
          .INP_WIDTH_HI(N_L2_3_SUM),
          .NEG_A(0)
      ) carry_inst_l2_3 (
          .a(ppp_l1_11z[2+N_L1-1-:(N_L2_3_SUM>2+N_L1)?2+N_L1 : N_L2_3_SUM]),
          .b(ppp_l1[10][N_L1-1-:N_L2_3_SUM-2]),
          .c({2'b00, ppp_l1[9][N_L1-1-:N_L2_3_SUM-4]}),
          .zero(1'b0),
          .sum(pp_l2[3][N_L2-1-:N_L2_3_SUM])
      );
      if (N_L2_3_SUM < N_L2_SUM_MAX) begin
        assign pp_l2[3][N_L2-N_L2_3_SUM-1:2] = 'b0;
      end
    end else if (N_L2_3_SUM > 0) begin
      assign pp_l2[3][N_L2-1-:N_L2_3_SUM]  = ppp_l1[11][N_L1-1-:N_L2_3_SUM];
      assign pp_l2[3][N_L2-N_L2_3_SUM-1:2] = 'b0;
    end else begin
      assign pp_l2[3][N_L2-1:2] = 'b0;
    end
    assign pp_l2[3][1:0] = ppp_l1[9][1:0];

    localparam N_L3_SUM_MAX = N_L3 - 6;
    localparam N_L3_0_SUM = N_L3 - ((N_TRUNC > 6) ? N_TRUNC : 6);

    if (N_L3_0_SUM > 6) begin
      carry_adder_2in #(
          .INP_WIDTH_LO(N_L3_0_SUM - 6),
          .INP_WIDTH_HI(N_L3_0_SUM),
          .NEG_A(0)
      ) carry_inst_l3_0 (
          .a(pp_l2[1][N_L2-1-:N_L3_0_SUM]),
          .b(pp_l2[0][N_L2-1-:N_L3_0_SUM-6]),
          .sum(pp_l3[0][N_L3-1-:N_L3_0_SUM])
      );
      if (N_L3_0_SUM < N_L3_SUM_MAX) begin
        assign pp_l3[0][N_L3-N_L3_0_SUM-1:6] = 'b0;
      end
    end else if (N_L3_0_SUM > 0) begin
      assign pp_l3[0][N_L3-1-:N_L3_0_SUM]  = pp_l2[1][N_L2-1-:N_L3_0_SUM];
      assign pp_l3[0][N_L3-N_L3_0_SUM-1:6] = 'b0;
    end else begin
      assign pp_l3[0][N_L3-1:6] = 'b0;
    end
    assign pp_l3[0][5:0] = pp_l2[0][5:0];

    localparam N_L3_1_SUM = N_L3 - ((N_TRUNC - 12 > 6) ? N_TRUNC - 12 : 6);

    if (N_L3_0_SUM > 6) begin
      carry_adder_2in #(
          .INP_WIDTH_LO(N_L3_1_SUM - 6),
          .INP_WIDTH_HI(N_L3_1_SUM),
          .NEG_A(0)
      ) carry_inst_l3_1 (
          .a(pp_l2[3][N_L2-1-:N_L3_1_SUM]),
          .b(pp_l2[2][N_L2-1-:N_L3_1_SUM-6]),
          .sum(pp_l3[1][N_L3-1-:N_L3_1_SUM])
      );
      if (N_L3_1_SUM < N_L3_SUM_MAX) begin
        assign pp_l3[1][N_L3-N_L3_1_SUM-1:6] = 'b0;
      end
    end else if (N_L3_1_SUM > 0) begin
      assign pp_l3[1][N_L3-1-:N_L3_1_SUM]  = pp_l2[3][N_L2-1-:N_L3_1_SUM];
      assign pp_l3[1][N_L3-N_L3_1_SUM-1:6] = 'b0;
    end else begin
      assign pp_l3[1][N_L3-1:6] = 'b0;
    end
    assign pp_l3[1][5:0] = pp_l2[2][5:0];

    localparam N_FINAL_SUM_MAX = 2 * N - 12;
    localparam N_FINAL_SUM = 2 * N - ((N_TRUNC > 12) ? N_TRUNC : 12);

    if (N_FINAL_SUM > 12) begin
      carry_adder_2in #(
          .INP_WIDTH_LO(N_FINAL_SUM - 12),
          .INP_WIDTH_HI(N_FINAL_SUM),
          .NEG_A(0)
      ) carry_inst_final (
          .a(pp_l3[1][N_L3-1-:N_FINAL_SUM]),
          .b(pp_l3[0][N_L3-1-:N_FINAL_SUM-12]),
          .sum(prod[2*N-1-:N_FINAL_SUM])
      );
      if (N_FINAL_SUM < N_FINAL_SUM_MAX) begin
        assign prod[2*N-N_FINAL_SUM-1:12] = 'b0;
      end
    end else if (N_FINAL_SUM > 0) begin
      assign prod[2*N-1-:N_FINAL_SUM]   = pp_l3[1][N_L3-1-:N_FINAL_SUM];
      assign prod[2*N-N_FINAL_SUM-1:12] = 'b0;
    end else begin
      assign prod[2*N-1:12] = 'b0;
    end
    assign prod[11:0] = pp_l3[0][11:0];
  endgenerate

endmodule
