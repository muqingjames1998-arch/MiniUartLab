`timescale 1ns/1ps

module tb_uart_tx;

  localparam int CLK_FREQ_HZ = 100_000_000;
  localparam int BAUD        = 115200;
  localparam int DIV         = CLK_FREQ_HZ / BAUD;

  logic clk = 0;
  logic rst_n = 0;

  // baud tick
  logic baud_tick;

  // tx interface
  logic        data_valid;
  logic [7:0]  data_in;
  logic        data_ready;
  logic        tx;

  // clock 100MHz -> 10ns period
  always #5 clk = ~clk;

  // instantiate baud_gen
  baud_gen #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    .BAUD(BAUD)
  ) u_baud (
    .clk(clk),
    .rst_n(rst_n),
    .baud_tick(baud_tick)
  );

  // instantiate uart_tx (DATA_BITS=8)
  uart_tx #(.DATA_BITS(8)) u_tx (
    .clk(clk),
    .rst_n(rst_n),
    .baud_tick(baud_tick),
    .data_valid(data_valid),
    .data_in(data_in),
    .data_ready(data_ready),
    .tx(tx)
  );

  // helper: wait for next baud_tick rising edge (on clk domain)
  task automatic wait_tick();
    begin
      // wait until baud_tick becomes 1 on a clock edge
      @(posedge clk);
      while (baud_tick !== 1'b1) @(posedge clk);
    end
  endtask

  // sample tx at each tick and compare expected bits
  task automatic send_and_check(input logic [7:0] b);
    logic [9:0] exp; // {stop, data[7:0], start}
    begin
      // build expected frame: start=0, data LSB first, stop=1
      exp = {1'b1, b, 1'b0};

      // drive request for 1 cycle when ready
      @(posedge clk);
      while (!data_ready) @(posedge clk);
      data_in    <= b;
      data_valid <= 1'b1;
      @(posedge clk);
      data_valid <= 1'b0;

      // Now check 10 ticks worth of tx
      for (int i = 0; i < 10; i++) begin
        wait_tick();
        // At each tick, uart_tx should output the corresponding bit
        if (tx !== exp[i]) begin
          $fatal(1, "Mismatch at bit %0d: expected %0b, got %0b (byte=%02h)", i, exp[i], tx, b);
        end
      end

      // after frame, tx should return to idle=1
      wait_tick();
      if (tx !== 1'b1) $fatal(1, "TX not idle high after frame");
    end
  endtask

  initial begin
    data_valid = 0;
    data_in    = '0;

    // reset
    repeat(5) @(posedge clk);
    rst_n = 1;

    // give some time
    repeat(10) @(posedge clk);

    // test a couple bytes
    send_and_check(8'hA5);
    send_and_check(8'h00);
    send_and_check(8'hFF);
    send_and_check(8'h3C);

    $display("UART_TX TEST PASS");
    $finish;
  end

endmodule