// For backwards compatibility
module adder #(
    parameter N = 6,
    parameter HP = 0
) (
    input wire [N-1:0] prod1,
    input wire [N-1:0] prod2,
    input wire [N-1:0] prod3,
    input wire [N-1:0] prod4,
    output wire [2*N-1:0] prod
);

  adder_with_zero #(.HP(HP), .N(N)) adder_inst(
      .zero(1'b0),
      .prod1(prod1),
      .prod2(prod2),
      .prod3(prod3),
      .prod4(prod4),
      .prod(prod)
  );

endmodule

module adder_with_zero #(
    parameter N = 6,
    parameter HP = 0
) (
    input wire zero,
    input wire [N-1:0] prod1,
    input wire [N-1:0] prod2,
    input wire [N-1:0] prod3,
    input wire [N-1:0] prod4,
    output wire [2*N-1:0] prod
);

  generate
    if (HP == 1) begin
      carry_adder_3in #(
          .INP_WIDTH_LO(N / 2),
          .INP_WIDTH_HI(N),
          .EFF_WIDTH(N / 2 + 1),
          .NEG_A(0)
      ) carry_inst0 (
          .a(prod4[N-1:0]),
          .b(prod2[N-1:N/2]),
          .c(prod3[N-1:N/2]),
          .zero(zero),
          .sum(prod[2*N-1:N])
      );
      assign prod[N-1:0] = 0;
    end else begin
      carry_adder_3in #(
          .INP_WIDTH_LO(N),
          .INP_WIDTH_HI(N + N / 2),
          .EFF_WIDTH(N + 1),
          .NEG_A(0)
      ) carry_inst0 (
          .a({prod4[N-1:0], prod1[N-1:N/2]}),
          .b(prod2),
          .c(prod3),
          .zero(zero),
          .sum(prod[2*N-1:N/2])
      );
      assign prod[N/2-1:0] = prod1[N/2-1:0];
    end
  endgenerate

endmodule

module carry_adder_3in #(
    parameter INP_WIDTH_LO = 3,
    parameter INP_WIDTH_HI = INP_WIDTH_LO + 1,
    parameter EFF_WIDTH = INP_WIDTH_HI,
    parameter NEG_A = 1'b0
) (
    a,
    b,
    c,
    zero,
    sum
);

  generate
    if (EFF_WIDTH > INP_WIDTH_HI || EFF_WIDTH < INP_WIDTH_LO) begin : param_error
      ERROR_PARAM_WIDTH_OUT_OF_RANGE param_inst ();
    end
  endgenerate

  localparam OUT_WIDTH = INP_WIDTH_HI + 1;
  localparam CARRY8_WIDTH = 8 * (INP_WIDTH_HI / 8 + |(INP_WIDTH_HI % 8));

  input wire [INP_WIDTH_HI-1:0] a;
  input wire [INP_WIDTH_LO-1:0] b;
  input wire [INP_WIDTH_LO-1:0] c;
  input wire zero;
  output wire [OUT_WIDTH-1:0] sum;

  wire [EFF_WIDTH-1:0] a_eff = a;
  wire [EFF_WIDTH-1:0] b_eff = {{EFF_WIDTH - INP_WIDTH_LO{1'b0}}, b};
  wire [EFF_WIDTH-1:0] c_eff = {{EFF_WIDTH - INP_WIDTH_LO{1'b0}}, c};

  wire [CARRY8_WIDTH-1:0] g;
  wire [CARRY8_WIDTH-1:0] p;
  wire [CARRY8_WIDTH:0] carry;
  wire [CARRY8_WIDTH-1:0] sum_tmp;

  assign g[0] = 1'b0;
  assign carry[0] = NEG_A;
  assign sum[INP_WIDTH_HI-1:0] = sum_tmp[INP_WIDTH_HI-1:0];

  generate
    if (NEG_A == 1) assign sum[OUT_WIDTH-1] = ~carry[OUT_WIDTH-1];
    else assign sum[OUT_WIDTH-1] = carry[OUT_WIDTH-1];
  endgenerate

  generate
    if (EFF_WIDTH < INP_WIDTH_HI) begin
      assign g[INP_WIDTH_HI-1:EFF_WIDTH] = {INP_WIDTH_HI - EFF_WIDTH{1'b0}};
      assign p[INP_WIDTH_HI-1:EFF_WIDTH] = a[INP_WIDTH_HI-1:EFF_WIDTH];
    end
  endgenerate

  generate
    if (INP_WIDTH_HI < CARRY8_WIDTH) begin
      assign g[CARRY8_WIDTH-1:INP_WIDTH_HI] = {CARRY8_WIDTH - INP_WIDTH_HI{1'b0}};
      assign p[CARRY8_WIDTH-1:INP_WIDTH_HI] = {CARRY8_WIDTH - INP_WIDTH_HI{1'b1}};
    end
  endgenerate

  genvar i;
  generate
    for (i = 0; i < EFF_WIDTH; i = i + 1) begin
      if (i < EFF_WIDTH - 1)
        LUT6_2 #(
            .INIT({
              {32{NEG_A[0]}} ^ 32'h00006996, 16'h0000, {2{2'b00, {4{NEG_A[0]}}, 2'b00}} ^ 16'hE8E8
            })
        ) PGi (
            .O6(p[i]),
            .O5(g[i+1]),
            .I5(1'b1),
            .I4(zero),
            .I3(g[i]),
            .I2(c_eff[i]),
            .I1(b_eff[i]),
            .I0(a_eff[i])
        );
      else
        LUT5 #(
            .INIT({32{NEG_A[0]}} ^ 32'h00006996)
        ) PGn (
            .O (p[i]),
            .I4(zero),
            .I3(g[i]),
            .I2(c_eff[i]),
            .I1(b_eff[i]),
            .I0(a_eff[i])
        );
    end
  endgenerate

  generate
    for (i = 0; i < CARRY8_WIDTH / 8; i = i + 1) begin
      CARRY8 #(
          .CARRY_TYPE("SINGLE_CY8")
      ) CC2i (
          .CO(carry[8*(i+1):8*i+1]),
          .O(sum_tmp[8*(i+1)-1:8*i]),
          .CI(carry[8*i]),
          .DI(g[8*(i+1)-1:8*i]),
          .S(p[8*(i+1)-1:8*i])
      );
    end
  endgenerate

endmodule

module carry_adder_3in_carryin #(
    parameter INP_WIDTH_LO = 3,
    parameter INP_WIDTH_HI = INP_WIDTH_LO + 1,
    parameter EFF_WIDTH = INP_WIDTH_HI,
    parameter ZERO = 1'b0
) (
    a,
    b,
    c,
    cin,
    zero,
    sum
);

  generate
    if (EFF_WIDTH > INP_WIDTH_HI || EFF_WIDTH < INP_WIDTH_LO) begin : param_error
      ERROR_PARAM_WIDTH_OUT_OF_RANGE param_inst ();
    end
  endgenerate

  localparam OUT_WIDTH = INP_WIDTH_HI + 1;
  localparam CARRY8_WIDTH = 8 * (INP_WIDTH_HI / 8 + |(INP_WIDTH_HI % 8));

  input wire [INP_WIDTH_HI-1:0] a;
  input wire [INP_WIDTH_LO-1:0] b;
  input wire [INP_WIDTH_LO-1:0] c;
  input wire cin;
  input wire zero;
  output wire [OUT_WIDTH-1:0] sum;

  wire [EFF_WIDTH-1:0] a_eff = a;
  wire [EFF_WIDTH-1:0] b_eff = {{EFF_WIDTH - INP_WIDTH_LO{1'b0}}, b};
  wire [EFF_WIDTH-1:0] c_eff = {{EFF_WIDTH - INP_WIDTH_LO{1'b0}}, c};

  wire [CARRY8_WIDTH-1:0] g;
  wire [CARRY8_WIDTH-1:0] p;
  wire [CARRY8_WIDTH:0] carry;
  wire [CARRY8_WIDTH-1:0] sum_tmp;

  assign g[0] = 1'b0;
  generate
    if (ZERO) assign carry[0] = zero ? 1'b0 : cin;
    else assign carry[0] = cin;
  endgenerate
  assign sum[INP_WIDTH_HI-1:0] = sum_tmp[INP_WIDTH_HI-1:0];

  assign sum[OUT_WIDTH-1] = carry[OUT_WIDTH-1];

  generate
    if (EFF_WIDTH < INP_WIDTH_HI) begin
      assign g[INP_WIDTH_HI-1:EFF_WIDTH] = {INP_WIDTH_HI - EFF_WIDTH{1'b0}};
      assign p[INP_WIDTH_HI-1:EFF_WIDTH] = a[INP_WIDTH_HI-1:EFF_WIDTH];
    end
  endgenerate

  generate
    if (INP_WIDTH_HI < CARRY8_WIDTH) begin
      assign g[CARRY8_WIDTH-1:INP_WIDTH_HI] = {CARRY8_WIDTH - INP_WIDTH_HI{1'b0}};
      assign p[CARRY8_WIDTH-1:INP_WIDTH_HI] = {CARRY8_WIDTH - INP_WIDTH_HI{1'b1}};
    end
  endgenerate

  genvar i;
  generate
    for (i = 0; i < EFF_WIDTH; i = i + 1) begin
      if (i < EFF_WIDTH - 1)
        if (ZERO)
          LUT6_2 #(
              .INIT({
                32'h00006996, 16'h0000, 16'hE8E8
              })
          ) PGi (
              .O6(p[i]),
              .O5(g[i+1]),
              .I5(1'b1),
              .I4(zero),
              .I3(g[i]),
              .I2(c_eff[i]),
              .I1(b_eff[i]),
              .I0(a_eff[i])
          );
        else
          LUT6_2 #(
              .INIT({
                32'h69966996, 32'hE8E8E8E8
              })
          ) PGi (
              .O6(p[i]),
              .O5(g[i+1]),
              .I5(1'b1),
              .I4(1'b1),
              .I3(g[i]),
              .I2(c_eff[i]),
              .I1(b_eff[i]),
              .I0(a_eff[i])
          );
      else
        if (ZERO)
          LUT5 #(
              .INIT(32'h00006996)
          ) PGn (
              .O (p[i]),
              .I4(zero),
              .I3(g[i]),
              .I2(c_eff[i]),
              .I1(b_eff[i]),
              .I0(a_eff[i])
          );
        else
          LUT4 #(
              .INIT(16'h6996)
          ) PGn (
              .O (p[i]),
              .I3(g[i]),
              .I2(c_eff[i]),
              .I1(b_eff[i]),
              .I0(a_eff[i])
          );
    end
  endgenerate

  generate
    for (i = 0; i < CARRY8_WIDTH / 8; i = i + 1) begin
      CARRY8 #(
          .CARRY_TYPE("SINGLE_CY8")
      ) CC2i (
          .CO(carry[8*(i+1):8*i+1]),
          .O(sum_tmp[8*(i+1)-1:8*i]),
          .CI(carry[8*i]),
          .DI(g[8*(i+1)-1:8*i]),
          .S(p[8*(i+1)-1:8*i])
      );
    end
  endgenerate

endmodule

module carry_adder_2in_carryin #(
    parameter INP_WIDTH_LO = 3,
    parameter INP_WIDTH_HI = INP_WIDTH_LO
) (
    a,
    b,
    cin,
    sum
);

  localparam OUT_WIDTH = INP_WIDTH_HI + 1;

  input wire [INP_WIDTH_HI-1:0] a;
  input wire [INP_WIDTH_LO-1:0] b;
  input wire cin;
  output wire [OUT_WIDTH-1:0] sum;

  carry_adder_2in_carryin_with_zero #(
      .INP_WIDTH_LO(INP_WIDTH_LO),
      .INP_WIDTH_HI(INP_WIDTH_HI),
      .ZERO(1'b0)
    ) adder_inst(
      .zero(1'b0),
      .a(a),
      .b(b),
      .cin(cin),
      .sum(sum)
  );

endmodule

module carry_adder_2in_carryin_with_zero #(
    parameter INP_WIDTH_LO = 3,
    parameter INP_WIDTH_HI = INP_WIDTH_LO,
    parameter ZERO = 1'b0
) (
    zero,
    a,
    b,
    cin,
    sum
);

  localparam OUT_WIDTH = INP_WIDTH_HI + 1;
  localparam CARRY8_WIDTH = 8 * (INP_WIDTH_HI / 8 + |(INP_WIDTH_HI % 8));

  input wire zero;
  input wire [INP_WIDTH_HI-1:0] a;
  input wire [INP_WIDTH_LO-1:0] b;
  input wire cin;
  output wire [OUT_WIDTH-1:0] sum;

  wire [CARRY8_WIDTH-1:0] g;
  wire [CARRY8_WIDTH-1:0] p;
  wire [CARRY8_WIDTH:0] carry;
  wire [CARRY8_WIDTH-1:0] sum_tmp;

  assign sum[INP_WIDTH_HI-1:0] = sum_tmp[INP_WIDTH_HI-1:0];
  assign sum[OUT_WIDTH-1] = carry[OUT_WIDTH-1];

  generate
    if (INP_WIDTH_LO < INP_WIDTH_HI) begin
      assign g[INP_WIDTH_HI-1:INP_WIDTH_LO] = {INP_WIDTH_HI - INP_WIDTH_LO{1'b0}};
      assign p[INP_WIDTH_HI-1:INP_WIDTH_LO] = a[INP_WIDTH_HI-1:INP_WIDTH_LO];
    end
  endgenerate

  generate
    if (INP_WIDTH_HI < CARRY8_WIDTH) begin
      assign g[CARRY8_WIDTH-1:INP_WIDTH_HI] = {CARRY8_WIDTH - INP_WIDTH_HI{1'b0}};
      assign p[CARRY8_WIDTH-1:INP_WIDTH_HI] = {CARRY8_WIDTH - INP_WIDTH_HI{1'b1}};
    end
  endgenerate

  genvar i;
  generate
    for (i = 0; i < INP_WIDTH_LO; i = i + 1) begin
      if (ZERO == 1'b1) begin
        LUT6_2 #(
            .INIT({24'h0, 8'h0C, 24'h0, 8'h06})
        ) PGi (
            .O6(g[i]),
            .O5(p[i]),
            .I5(1'b1),
            .I4(1'b0),
            .I3(1'b0),
            .I2(zero),
            .I1(b[i]),
            .I0(a[i])
        );
      end
      else begin
        assign g[i] = b[i];
        if (i % 2) begin
          LUT6_2 #(
              .INIT({{2{16'h0FF0}}, {2{16'h6666}}})
          ) P2i (
              .O6(p[i]),
              .O5(p[i-1]),
              .I5(1'b1),
              .I4(1'b0),
              .I3(b[i]),
              .I2(a[i]),
              .I1(b[i-1]),
              .I0(a[i-1])
          );
        end
        else if (i + 1 == INP_WIDTH_LO) begin
          LUT2 #(
              .INIT(4'h6)
          ) Pi (
              .O (p[i]),
              .I1(b[i]),
              .I0(a[i])
          );
        end
      end
    end
  endgenerate

  assign carry[0] = cin;
  generate
    for (i = 0; i < CARRY8_WIDTH / 8; i = i + 1) begin
      CARRY8 #(
          .CARRY_TYPE("SINGLE_CY8")
      ) CC2i (
          .CO(carry[8*(i+1):8*i+1]),
          .O(sum_tmp[8*(i+1)-1:8*i]),
          .CI(carry[8*i]),
          .DI(g[8*(i+1)-1:8*i]),
          .S(p[8*(i+1)-1:8*i])
      );
    end
  endgenerate

endmodule

module carry_adder_2in #(
    parameter INP_WIDTH_LO = 3,
    parameter INP_WIDTH_HI = INP_WIDTH_LO,
    parameter NEG_A = 1'b0
) (
    a,
    b,
    sum
);

  localparam OUT_WIDTH = INP_WIDTH_HI + 1;

  input wire [INP_WIDTH_HI-1:0] a;
  input wire [INP_WIDTH_LO-1:0] b;
  output wire [OUT_WIDTH-1:0] sum;

  carry_adder_2in_with_zero #(
      .ZERO(1'b0),
      .INP_WIDTH_LO(INP_WIDTH_LO),
      .INP_WIDTH_HI(INP_WIDTH_HI),
      .NEG_A(NEG_A)
    ) adder_inst(
      .zero(1'b0),
      .a(a),
      .b(b),
      .sum(sum)
  );

endmodule

module carry_adder_2in_with_zero #(
    parameter INP_WIDTH_LO = 3,
    parameter INP_WIDTH_HI = INP_WIDTH_LO,
    parameter NEG_A = 1'b0,
    parameter ZERO = 1'b0
) (
    zero,
    a,
    b,
    sum
);

  localparam OUT_WIDTH = INP_WIDTH_HI + 1;
  localparam CARRY8_WIDTH = 8 * (INP_WIDTH_HI / 8 + |(INP_WIDTH_HI % 8));

  input wire zero;
  input wire [INP_WIDTH_HI-1:0] a;
  input wire [INP_WIDTH_LO-1:0] b;
  output wire [OUT_WIDTH-1:0] sum;

  wire [CARRY8_WIDTH-1:0] g;
  wire [CARRY8_WIDTH-1:0] p;
  wire [CARRY8_WIDTH:0] carry;
  wire [CARRY8_WIDTH-1:0] sum_tmp;

  assign sum[INP_WIDTH_HI-1:0] = sum_tmp[INP_WIDTH_HI-1:0];

  generate
    if (NEG_A == 1) begin
      assign sum[OUT_WIDTH-1] = ~carry[OUT_WIDTH-1];
    end
    else begin
      assign sum[OUT_WIDTH-1] = carry[OUT_WIDTH-1];
    end
  endgenerate

  generate
    if (INP_WIDTH_LO < INP_WIDTH_HI) begin
      assign g[INP_WIDTH_HI-1:INP_WIDTH_LO] = {INP_WIDTH_HI - INP_WIDTH_LO{1'b0}};
      assign p[INP_WIDTH_HI-1:INP_WIDTH_LO] = a[INP_WIDTH_HI-1:INP_WIDTH_LO];
    end
  endgenerate

  generate
    if (INP_WIDTH_HI < CARRY8_WIDTH) begin
      assign g[CARRY8_WIDTH-1:INP_WIDTH_HI] = {CARRY8_WIDTH - INP_WIDTH_HI{1'b0}};
      assign p[CARRY8_WIDTH-1:INP_WIDTH_HI] = {CARRY8_WIDTH - INP_WIDTH_HI{1'b1}};
    end
  endgenerate

  genvar i;
  generate
    for (i = 0; i < INP_WIDTH_LO; i = i + 1) begin
      if (ZERO == 1'b1) begin
        LUT6_2 #(
            .INIT({24'h0, 8'h0C, 24'h0, {{8{NEG_A[0]}}^{4'h0,4'h6}}})
        ) PGi (
            .O6(g[i]),
            .O5(p[i]),
            .I5(1'b1),
            .I4(1'b0),
            .I3(1'b0),
            .I2(zero),
            .I1(b[i]),
            .I0(a[i])
        );
      end
      else begin
        assign g[i] = b[i];
        if (i % 2) begin
          LUT6_2 #(
              .INIT({{2{{16{NEG_A[0]}} ^ 16'h0FF0}}, {2{{16{NEG_A[0]}} ^ 16'h6666}}})
          ) P2i (
              .O6(p[i]),
              .O5(p[i-1]),
              .I5(1'b1),
              .I4(1'b0),
              .I3(b[i]),
              .I2(a[i]),
              .I1(b[i-1]),
              .I0(a[i-1])
          );
        end
        else if (i + 1 == INP_WIDTH_LO) begin
          LUT2 #(
              .INIT({4{NEG_A[0]}} ^ 4'h6)
          ) Pi (
              .O (p[i]),
              .I1(b[i]),
              .I0(a[i])
          );
        end
      end
    end
  endgenerate

  assign carry[0] = NEG_A[0];
  generate
    for (i = 0; i < CARRY8_WIDTH / 8; i = i + 1) begin
      CARRY8 #(
          .CARRY_TYPE("SINGLE_CY8")
      ) CC2i (
          .CO(carry[8*(i+1):8*i+1]),
          .O(sum_tmp[8*(i+1)-1:8*i]),
          .CI(carry[8*i]),
          .DI(g[8*(i+1)-1:8*i]),
          .S(p[8*(i+1)-1:8*i])
      );
    end
  endgenerate

endmodule

module carry_adder_3in_parallel #(
    parameter INP_WIDTH_LO = 23,
    parameter INP_WIDTH_HI = INP_WIDTH_LO + 1,
    parameter EFF_WIDTH = INP_WIDTH_HI,
    parameter NEG_A = 1'b0
) (
    a,
    b,
    c,
    sum
);

  localparam OUT_WIDTH = INP_WIDTH_HI + 1;

  input wire [INP_WIDTH_HI-1:0] a;
  input wire [INP_WIDTH_LO-1:0] b;
  input wire [INP_WIDTH_LO-1:0] c;
  output wire [OUT_WIDTH-1:0] sum;

  wire [EFF_WIDTH-1:0] sum_tmp;

  carry_adder_2in #(
      .INP_WIDTH_LO(INP_WIDTH_LO),
      .INP_WIDTH_HI(INP_WIDTH_LO),
      .NEG_A(0)
  ) carry_inst0 (
      .a(b),
      .b(c),
      .sum(sum_tmp)
  );

  carry_adder_2in #(
      .INP_WIDTH_LO(EFF_WIDTH),
      .INP_WIDTH_HI(INP_WIDTH_HI),
      .NEG_A(NEG_A)
  ) carry_inst1 (
      .a(a),
      .b(sum_tmp),
      .sum(sum)
  );

endmodule

module popcount_3bits(
    input  wire [2:0] inp,
    output wire [1:0] res
);

    LUT6_2 #(
        .INIT({{32'h000000E8},{32'h00000096}})
    ) inst0 (
        .O6(res[1]),
        .O5(res[0]),
        .I5(1'b1),
        .I4(1'b0),
        .I3(1'b0),
        .I2(inp[2]),
        .I1(inp[1]),
        .I0(inp[0])
    );

endmodule

module popcount_6bits(
    input  wire [5:0] inp,
    output wire [2:0] res
);

    LUT6 #(
        .INIT(64'h6996966996696996)
    ) inst0 (
        .O(res[0]),
        .I5(inp[5]),
        .I4(inp[4]),
        .I3(inp[3]),
        .I2(inp[2]),
        .I1(inp[1]),
        .I0(inp[0])
    );

    LUT6 #(
        .INIT(64'h8117177E177E7EE8)
    ) inst1 (
        .O(res[1]),
        .I5(inp[5]),
        .I4(inp[4]),
        .I3(inp[3]),
        .I2(inp[2]),
        .I1(inp[1]),
        .I0(inp[0])
    );

    LUT6 #(
        .INIT(64'hFEE8E880E8808000)
    ) inst2 (
        .O(res[2]),
        .I5(inp[5]),
        .I4(inp[4]),
        .I3(inp[3]),
        .I2(inp[2]),
        .I1(inp[1]),
        .I0(inp[0])
    );

endmodule
