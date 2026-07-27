(* use_dsp = "no" *)
module mult_nxn_acc_vivado (
    a,
    b,
    prod
);
    parameter N = 24;

    input [N-1:0] a;
    input [N-1:0] b;
    output [2*N-1:0] prod;

    wire [N-1:0] a;
    wire [N-1:0] b;
    wire [2*N-1:0] prod;

    assign prod = a * b;
endmodule
