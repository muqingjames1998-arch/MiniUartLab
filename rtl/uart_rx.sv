module uart_rx #(
    parameter int DATA_BITS   = 8,
    parameter int CLK_FREQ_HZ = 100_000_000,
    parameter int BAUD        = 115200
)(
    input  logic clk,
    input  logic rst_n,
    input  logic rx,
    output logic                 data_valid,
    output logic [DATA_BITS-1:0] data_out,
    output logic frame_err
);


localparam int DIV = CLK_FREQ_HZ / BAUD;
logic [3:0] bit_cnt;
logic [DATA_BITS-1:0] shreg;
logic rx_ff1, rx_ff2;
logic [$clog2(DIV):0] cnt;
logic rx_prev;
typedef enum logic [1:0] {IDLE, START, DATA, STOP} rx_state_t;
rx_state_t state;


always_ff @( posedge clk ) begin 

    if (!rst_n) begin
        bit_cnt <= 0;
        data_valid <= 0;
        data_out <= 0;
        frame_err <= 0;
        shreg <= 0;
        cnt <= 0;
        rx_ff1 <= 1;
        rx_ff2 <= 1;
        rx_prev <= 1;
        state <= IDLE;
    end
    else begin
        data_valid <= 0; 
        rx_ff1 <= rx;
        rx_ff2 <= rx_ff1;
        rx_prev <= rx_ff2;
        case (state)
        IDLE: begin
            bit_cnt <= 0;
            cnt <= 0;
           if (rx_ff2 == 0 && rx_prev == 1) begin // Start bit detected
               state <= START;
               cnt <= (DIV / 2)-1; 
           end
        end
        START: begin
            if (cnt == 0) begin
                if (rx_ff2 == 0) begin // Confirm start bit
                    state <= DATA;
                    cnt <= DIV-1;
                    bit_cnt <= 0;
                end
                else begin
                    state <= IDLE; // False start bit
                end
            end
            else begin
                cnt <= cnt - 1;
            end
            
        end
        DATA: begin
            if (cnt == 0) begin
                shreg[bit_cnt] <= rx_ff2; 
                if (bit_cnt == DATA_BITS - 1) begin
                    state <= STOP;
                    bit_cnt <= 0;
                end
                else begin
                    bit_cnt <= bit_cnt + 1;
                end
                cnt <= DIV-1;
            end
            else begin
                cnt <= cnt - 1;

            end
            
        end
        STOP: begin
            if (cnt == 0) begin
                if (rx_ff2 == 1) begin 
                    data_valid <= 1;
                    data_out <= shreg;
                    frame_err <= 0;
                end
                else begin
                    frame_err <= 1; 
                end
                state <= IDLE;
            end
            else begin
                cnt <= cnt - 1;

            end
        end
        endcase
    end
    
end

endmodule