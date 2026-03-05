module top_uart #(
    parameter int CLK_FREQ_HZ = 100_000_000,
    parameter int BAUD        = 115200,
    parameter int DATA_BITS   = 8
)(
    input  logic clk,
    input  logic rst_n,

    // UART pins
    input  logic rx,
    output logic tx,

    // TX streaming input (valid/ready)
    input  logic                 tx_valid,
    input  logic [DATA_BITS-1:0] tx_data,
    output logic                 tx_ready,

    // RX streaming output (valid pulse)
    output logic                 rx_valid,
    output logic [DATA_BITS-1:0] rx_data,
    output logic                 rx_frame_err
);

    logic baud_tick;

    // bit-time tick generator
    baud_gen #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD(BAUD)
    ) u_baud (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick)
    );

    // transmitter
    uart_tx #(
        .DATA_BITS(DATA_BITS)
    ) u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .data_valid(tx_valid),
        .data_in(tx_data),
        .data_ready(tx_ready),
        .tx(tx)
    );

    // receiver
    uart_rx #(
        .DATA_BITS(DATA_BITS),
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD(BAUD)
    ) u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .data_valid(rx_valid),
        .data_out(rx_data),
        .frame_err(rx_frame_err)
    );

endmodule