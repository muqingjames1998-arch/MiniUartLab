`timescale 1ns/1ps

module tb_top_uart;

  localparam int CLK_FREQ_HZ = 100_000_000;
  localparam int BAUD        = 115200;
  localparam int DATA_BITS   = 8;

  logic clk = 0;
  logic rst_n = 0;

  logic rx;
  logic tx;

  logic                 tx_valid;
  logic [DATA_BITS-1:0] tx_data;
  logic                 tx_ready;

  logic                 rx_valid;
  logic [DATA_BITS-1:0] rx_data;
  logic                 rx_frame_err;

  // 100MHz clock -> 10ns
  always #5 clk = ~clk;

  top_uart #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    .BAUD(BAUD),
    .DATA_BITS(DATA_BITS)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .rx(rx),
    .tx(tx),
    .tx_valid(tx_valid),
    .tx_data(tx_data),
    .tx_ready(tx_ready),
    .rx_valid(rx_valid),
    .rx_data(rx_data),
    .rx_frame_err(rx_frame_err)
  );

  // loopback
  assign rx = tx;

  // expected queue
  byte exp_q[$];

  task automatic send_byte(input byte b);
    begin
      // wait until tx can accept
      @(posedge clk);
      while (!tx_ready) @(posedge clk);

      tx_data  <= b;
      tx_valid <= 1'b1;
      @(posedge clk);
      tx_valid <= 1'b0;
      tx_data  <= '0;

      exp_q.push_back(b);
    end
  endtask

  // timeout to avoid infinite sim
  initial begin
    #2ms;
    $fatal(1, "TIMEOUT: TB did not finish");
  end

  initial begin
    tx_valid = 0;
    tx_data  = '0;

    // reset
    repeat(5) @(posedge clk);
    rst_n = 1;

    // send some bytes
    send_byte(8'hA5);
    send_byte(8'h00);
    send_byte(8'hFF);
    send_byte(8'h3C);
    send_byte(8'h12);
    send_byte(8'h7E);

    // receive and check
    while (exp_q.size() != 0) begin
      @(posedge clk);
      if (rx_frame_err) $fatal(1, "Frame error detected!");

      if (rx_valid) begin
        byte exp;
        exp = exp_q.pop_front();
        if (rx_data !== exp) begin
          $fatal(1, "RX mismatch: expected %02h got %02h", exp, rx_data);
        end
      end
    end

    // wait a bit more to ensure no extra bytes
    repeat(50) @(posedge clk);
    if (rx_valid) $fatal(1, "Unexpected extra RX byte: %02h", rx_data);

    $display("TOP LOOPBACK TEST PASS");
    $finish;
  end

endmodule