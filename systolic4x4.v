`timescale 1ns/1ps

module systolic_array_4x4 #( 
    parameter integer N    = 4,
    parameter integer DW   = 8,
    parameter integer ACCW = 20,
    parameter integer CW   = 16,
    parameter integer K    = 4
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         clr,
  input  wire signed [N*DW-1:0]       a_left_flat,   // Flattened  arrays start
    input  wire [N-1:0]                 a_v_row_flat,   
    input  wire signed [N*DW-1:0]       b_top_flat,    
    input  wire [N-1:0]                 b_v_col_flat,  
  output wire signed [N*N*CW-1:0]     C_flat,         // Flattened  arrays end
    output reg                          done
);

    // ---------------------------
    // Unflatten inputs to internal arrays
    // ---------------------------
    wire signed [DW-1:0] a_left [0:N-1];
    wire                 a_v_row[0:N-1];
    wire signed [DW-1:0] b_top [0:N-1];
    wire                 b_v_col[0:N-1];

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : UNFLATTEN
            assign a_left[i]  = a_left_flat[i*DW +: DW];
            assign a_v_row[i] = a_v_row_flat[i];
            assign b_top[i]   = b_top_flat[i*DW +: DW];
            assign b_v_col[i] = b_v_col_flat[i];
        end
    endgenerate

    // ---------------------------
    // Interconnect wires
    // ---------------------------
    wire signed [DW-1:0] a_bus [0:N-1][0:N];
    wire                 av_bus[0:N-1][0:N];
    wire signed [DW-1:0] b_bus [0:N][0:N-1];
    wire                 bv_bus[0:N][0:N-1];
    wire signed [ACCW-1:0] c_acc [0:N-1][0:N-1];

    // ---------------------------
    // Boundary injection
    // ---------------------------
    generate
        for (i = 0; i < N; i = i + 1) begin : BOUNDARY
            assign a_bus[i][0]  = a_left[i];
            assign av_bus[i][0] = a_v_row[i];
            assign b_bus[0][i]  = b_top[i];
            assign bv_bus[0][i] = b_v_col[i];
        end
    endgenerate

    // ---------------------------
    // Mesh of PE cells
    // ---------------------------
    genvar r, c;
    generate
        for (r = 0; r < N; r = r + 1) begin : ROW
            for (c = 0; c < N; c = c + 1) begin : COL
                pe_cell #(.DW_(DW), .ACCW_(ACCW)) u_pe (
                    .clk(clk), .rst(rst), .clr(clr),
                    .a_in(a_bus[r][c]), .b_in(b_bus[r][c]),
                    .a_v_in(av_bus[r][c]), .b_v_in(bv_bus[r][c]),
                    .a_out(a_bus[r][c+1]), .b_out(b_bus[r+1][c]),
                    .a_v_out(av_bus[r][c+1]), .b_v_out(bv_bus[r+1][c]),
                    .c_acc(c_acc[r][c])
                );
            end
        end
    endgenerate

    // ---------------------------
    // Saturation function
    // ---------------------------
    function [CW-1:0] sat16;
        input signed [ACCW-1:0] x;
        reg signed [CW-1:0] max16, min16;
        begin
            max16 = 16'sh7FFF;
            min16 = -16'sh8000;
            if (x > max16)       sat16 = max16;
            else if (x < min16)  sat16 = min16;
            else                 sat16 = x[CW-1:0];
        end
    endfunction

    // ---------------------------
    // Flatten C output
    // ---------------------------
    generate
        for (r = 0; r < N; r = r + 1) begin : FLATTEN_C_ROW
            for (c = 0; c < N; c = c + 1) begin : FLATTEN_C_COL
                assign C_flat[(r*N + c)*CW +: CW] = sat16(c_acc[r][c]);
            end
        end
    endgenerate

    // ---------------------------
    // DONE logic
    // ---------------------------
    localparam integer LATENCY = K + (N-1) + (N-1);
    reg [7:0] cnt;
    reg running;
    reg any_a, any_b;
    integer idx;

    always @* begin
        any_a = 0; any_b = 0;
        for (idx = 0; idx < N; idx = idx + 1) begin
            any_a = any_a | a_v_row[idx];
            any_b = any_b | b_v_col[idx];
        end
    end

    wire start_beat = any_a & any_b;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            running <= 0;
            done <= 0;
        end else begin
            done <= 0;
            if (!running && start_beat) begin
                running <= 1;
                cnt <= 0;
            end else if (running) begin
                cnt <= cnt + 1;
                if (cnt == LATENCY - 1) begin
                    done <= 1;
                    running <= 0;
                end
            end
        end
    end

endmodule
