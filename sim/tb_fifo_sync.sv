`timescale 1ns/1ps

module tb_fifo_sync;

  localparam int WIDTH = 8;
  localparam int DEPTH = 16;

  logic clk = 0;
  logic rst_n = 0;

  logic             wr_en;
  logic [WIDTH-1:0] wr_data;
  logic             full;

  logic             rd_en;
  logic [WIDTH-1:0] rd_data;
  logic             empty;

  // 100MHz clock
  always #5 clk = ~clk;

  fifo_sync #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .full(full),
    .rd_en(rd_en),
    .rd_data(rd_data),
    .empty(empty)
  );

  // ---- helper tasks ----
  task automatic push(input logic [WIDTH-1:0] d);
    begin
      @(negedge clk);
      wr_en   = 1;
      wr_data = d;
      rd_en   = 0;
      @(negedge clk);
      wr_en   = 0;
      wr_data = '0;
    end
  endtask

  task automatic pop(output logic [WIDTH-1:0] d);
    begin
      @(negedge clk);
      rd_en = 1;
      wr_en = 0;
      @(negedge clk);
      rd_en = 0;
      d = rd_data; // rd_data 在 posedge 更新，等到下一个 negedge 读取稳定值
    end
  endtask

  // ---- test ----
  logic [WIDTH-1:0] tmp;

  initial begin
    // init
    wr_en = 0; rd_en = 0; wr_data = '0;

    // reset
    repeat(5) @(negedge clk);
    rst_n = 1;

    // 1) reset state check
    @(negedge clk);
    if (!empty) $fatal(1, "After reset, empty should be 1");
    if (full)   $fatal(1, "After reset, full should be 0");

    // 2) push 1,2,3 then pop 1,2,3
    push(8'h01);
    push(8'h02);
    push(8'h03);

    pop(tmp); if (tmp !== 8'h01) $fatal(1, "Expected 01, got %02h", tmp);
    pop(tmp); if (tmp !== 8'h02) $fatal(1, "Expected 02, got %02h", tmp);
    pop(tmp); if (tmp !== 8'h03) $fatal(1, "Expected 03, got %02h", tmp);

    if (!empty) $fatal(1, "After popping all, empty should be 1");

    // 3) fill to full
    for (int i = 0; i < DEPTH; i++) begin
      push(i[7:0]);
    end
    @(negedge clk);
    if (!full) $fatal(1, "After DEPTH pushes, full should be 1");
    if (empty) $fatal(1, "After DEPTH pushes, empty should be 0");

    // 4) pop all, should become empty
    for (int i = 0; i < DEPTH; i++) begin
      pop(tmp);
      if (tmp !== i[7:0]) $fatal(1, "Order wrong at %0d: got %02h", i, tmp);
    end
    @(negedge clk);
    if (!empty) $fatal(1, "After DEPTH pops, empty should be 1");
    if (full)   $fatal(1, "After DEPTH pops, full should be 0");

    $display("TEST PASS");
    $finish;
  end

endmodule