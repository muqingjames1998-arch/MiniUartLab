module uart_tx #(
    parameter int DATA_BITS = 8   
)(
    input  logic clk,
    input  logic rst_n,
    input  logic baud_tick,
    input  logic                  data_valid,
    input  logic [DATA_BITS-1:0]  data_in,
    output logic                  data_ready,
    output logic tx
);

logic busy;
logic [3:0] bit_cnt;
logic [DATA_BITS-1:0] shreg;

assign data_ready = !busy;
always_ff @(posedge clk)begin
    if (!rst_n) begin
        busy <= 0;
        tx <= 1;
        bit_cnt <= 0;
        shreg <= 0;
    end else begin
    if (!busy && data_valid) begin
        busy <= 1;
        shreg <= data_in;
        bit_cnt <= 0;
        tx <= 1;
    end
    if (busy &&baud_tick)begin
        if (bit_cnt == 0)begin
        tx <= 0; 
        bit_cnt <= bit_cnt + 1;   
        end
        else if (bit_cnt == 9)begin
        tx <= 1;
        busy <= 0;
        bit_cnt <= 0;
        end
        else begin
        tx <= shreg [bit_cnt-1];
        bit_cnt <= bit_cnt + 1;
        end
    end   
end
end


endmodule