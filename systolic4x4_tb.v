`timescale 1ns/1ps

module tb_systolic_array_final;

  localparam N = 4;
  localparam DW = 8;
  localparam ACCW = 20;
  localparam CW = 16;
  localparam K = 4;

  reg clk, rst, clr;

  // Unpacked arrays for test logic
  reg signed [DW-1:0] a_left_arr [0:N-1];
  reg signed [DW-1:0] b_top_arr  [0:N-1];
  reg a_v_row_arr [0:N-1];
  reg b_v_col_arr [0:N-1];

  // Flattened packed arrays for DUT connection
  reg signed [N*DW-1:0] a_left_flat;
  reg [N-1:0]           a_v_row_flat;
  reg signed [N*DW-1:0] b_top_flat;
  reg [N-1:0]           b_v_col_flat;

  // Outputs
  wire signed [N*N*CW-1:0] C_flat;
  wire done;
  reg signed [CW-1:0] C [0:N-1][0:N-1];

  reg signed [DW-1:0] A [0:N-1][0:N-1];
  reg signed [DW-1:0] B [0:N-1][0:N-1];
  reg signed [CW-1:0] expected_C [0:N-1][0:N-1];
  reg all_match;

  integer i, j, k, t, a_col, b_row;

  // ---------------------------
  // Flatten helper task using loop-based indexing
  // ---------------------------
  task flatten_inputs;
    integer idx;
    begin
      for (idx = 0; idx < N; idx = idx + 1) begin
        a_left_flat[idx*DW +: DW] = a_left_arr[idx];
        b_top_flat[idx*DW +: DW]  = b_top_arr[idx];
        a_v_row_flat[idx] = a_v_row_arr[idx];
        b_v_col_flat[idx] = b_v_col_arr[idx];
      end
    end
  endtask

  // ---------------------------
  // DUT instantiation
  // ---------------------------
  systolic_array_4x4 #(
    .N(N), .DW(DW), .ACCW(ACCW), .CW(CW), .K(K)
  ) dut (
    .clk(clk),
    .rst(rst),
    .clr(clr),
    .a_left_flat(a_left_flat),
    .a_v_row_flat(a_v_row_flat),
    .b_top_flat(b_top_flat),
    .b_v_col_flat(b_v_col_flat),
    .C_flat(C_flat),
    .done(done)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_systolic_array_final);

    // Initialize matrix A
    A[0][0]=1; A[0][1]=2; A[0][2]=3; A[0][3]=4;
    A[1][0]=5; A[1][1]=6; A[1][2]=7; A[1][3]=8;
    A[2][0]=2; A[2][1]=4; A[2][2]=6; A[2][3]=8;
    A[3][0]=1; A[3][1]=3; A[3][2]=5; A[3][3]=7;

    // Initialize matrix B
    B[0][0]=1; B[0][1]=0; B[0][2]=0; B[0][3]=1;
    B[1][0]=0; B[1][1]=1; B[1][2]=0; B[1][3]=1;
    B[2][0]=0; B[2][1]=0; B[2][2]=1; B[2][3]=1;
    B[3][0]=1; B[3][1]=1; B[3][2]=1; B[3][3]=2;

    // Compute expected result
    for (i=0; i<N; i=i+1) begin
      for (j=0; j<N; j=j+1) begin
        expected_C[i][j] = 0;
        for (k=0; k<K; k=k+1)
          expected_C[i][j] = expected_C[i][j] + A[i][k]*B[k][j];
      end
    end

    $display("========================================");
    $display("Systolic Array Matrix Multiplication");
    $display("========================================");
    
    $display("\nMatrix A (4x4):");
    for (i=0; i<N; i=i+1) begin
      for (j=0; j<N; j=j+1)
        $write("%3d ", A[i][j]);
      $display("");
    end

    $display("\nMatrix B (4x4):");
    for (i=0; i<N; i=i+1) begin
      for (j=0; j<N; j=j+1)
        $write("%3d ", B[i][j]);
      $display("");
    end

    $display("\nExpected C = A × B:");
    for (i=0; i<N; i=i+1) begin
      for (j=0; j<N; j=j+1)
        $write("%3d ", expected_C[i][j]);
      $display("");
    end

    // Reset
    rst = 1; clr = 0;
    for (i=0; i<N; i=i+1) begin
      a_left_arr[i] = 0; a_v_row_arr[i] = 0;
      b_top_arr[i]  = 0; b_v_col_arr[i] = 0;
    end
    flatten_inputs();

    #20 rst = 0;
    @(posedge clk);

    // Clear accumulators
    clr = 1; @(posedge clk); clr = 0;

    // PRIMING PHASE - Critical!
    for (i=0; i<N; i=i+1) begin
      a_left_arr[i]  = 0;
      b_top_arr[i]   = 0;
      a_v_row_arr[i] = 1;
      b_v_col_arr[i] = 1;
    end
    flatten_inputs();
    @(posedge clk);

    // Streaming phase
    for (t=0; t < K+N; t=t+1) begin
      for (i=0; i<N; i=i+1) begin
        a_col = t - i;
        if (a_col >= 0 && a_col < K) begin
          a_left_arr[i] = A[i][a_col];
          a_v_row_arr[i] = 1;
        end else begin
          a_left_arr[i] = 0;
          a_v_row_arr[i] = 1;
        end
      end
      
      for (j=0; j<N; j=j+1) begin
        b_row = t - j;
        if (b_row >= 0 && b_row < K) begin
          b_top_arr[j] = B[b_row][j];
          b_v_col_arr[j] = 1;
        end else begin
          b_top_arr[j] = 0;
          b_v_col_arr[j] = 1;
        end
      end
      
      flatten_inputs();
      @(posedge clk);
    end

    // Stop driving
    for (i=0; i<N; i=i+1) begin
      a_v_row_arr[i] = 0; b_v_col_arr[i] = 0;
      a_left_arr[i] = 0; b_top_arr[i] = 0;
    end
    flatten_inputs();

    // Wait for computation
    wait(done);
    #10;

    // Unflatten C output
    for (i=0; i<N; i=i+1)
      for (j=0; j<N; j=j+1)
        C[i][j] = C_flat[(i*N+j)*CW +: CW];

    $display("\n========================================");
    $display("Computed C matrix:");
    $display("========================================");
    for (i=0; i<N; i=i+1) begin
      for (j=0; j<N; j=j+1)
        $write("%3d ", C[i][j]);
      $display("");
    end

    $display("\n========================================");
    $display("Verification:");
    $display("========================================");
    
    all_match = 1;
    for (i=0; i<N; i=i+1) begin
      for (j=0; j<N; j=j+1) begin
        if (C[i][j] !== expected_C[i][j]) begin
          all_match = 0;
          $display("Mismatch at C[%0d][%0d]: Expected %0d, Got %0d", 
                   i, j, expected_C[i][j], C[i][j]);
        end
      end
    end
    
    if (all_match) begin
      $display("PASS - All results match expected values!");
    end else begin
      $display("FAIL - Mismatches found!");
    end

    $display("\n========================================");
    $display("Simulation Complete!");
    $display("========================================");
    #50 $finish;
  end

endmodule
