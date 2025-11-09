// PROCESSING ELEMENT OF THE 4X4 SYSTOLIC ARRAY

module pe_cell #(
    parameter integer DW_   = 8,
    parameter integer ACCW_ = 20
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         clr,
    input  wire signed [DW_-1:0]        a_in,
    input  wire signed [DW_-1:0]        b_in,
    input  wire                         a_v_in,
    input  wire                         b_v_in,
    output reg  signed [DW_-1:0]        a_out,
    output reg  signed [DW_-1:0]        b_out,
    output reg                          a_v_out,
    output reg                          b_v_out,
    output reg  signed [ACCW_-1:0]      c_acc
);

    wire signed [(2*DW_)-1:0] prod = a_in * b_in;
    wire do_acc = a_v_in & b_v_in;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            a_out   <= 0;
            b_out   <= 0;
            a_v_out <= 0;
            b_v_out <= 0;
        end else begin
            a_out   <= a_in;
            b_out   <= b_in;
            a_v_out <= a_v_in;
            b_v_out <= b_v_in;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) c_acc <= 0;
        else if (clr) c_acc <= 0;
        else if (do_acc) c_acc <= c_acc + prod;
    end

endmodule
