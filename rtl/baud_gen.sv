module baud_gen #(
    parameter int CLK_FREQ_HZ = 100_000_000,
    parameter int BAUD        = 115200
)(
    input  logic clk,
    input  logic rst_n,
    output logic baud_tick
);

localparam int DIV = CLK_FREQ_HZ / BAUD;
logic [$clog2(DIV)-1:0] counter;
always_ff @(posedge clk)begin
    if(!rst_n)begin
        counter <= 0;
        baud_tick <= 0;
    end
    else begin
        if(counter == DIV-1)begin
            counter <= 0;
            baud_tick <= 1;
        end
        else begin
            counter <= counter + 1;
            baud_tick <= 0;
        end
    end
end
endmodule