module fifo_sync #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 16
)(
    input  logic clk,
    input  logic rst_n,

    input  logic             wr_en,
    input  logic [WIDTH-1:0] wr_data,
    output logic             full,

    input  logic             rd_en,
    output logic [WIDTH-1:0] rd_data,
    output logic             empty
);

logic [WIDTH-1:0] fifo_mem [DEPTH-1:0];
logic [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
logic [$clog2(DEPTH+1)-1:0] count;
logic do_wr, do_rd;

assign full  = (count == DEPTH);
assign empty = (count == 0);
assign do_wr = wr_en && !full;
assign do_rd = rd_en && !empty;

always_ff @(posedge clk)begin
    if(!rst_n)begin
        count <= 0;
        wr_ptr <= 0;
        rd_ptr <= 0;
        rd_data <= 0;
    end
    else begin
        count <= count + do_wr - do_rd;
        if (do_wr) begin
            fifo_mem[wr_ptr] <= wr_data;
            wr_ptr <= wr_ptr + 1;
        end
        if (do_rd) begin
            rd_data <= fifo_mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end
end


endmodule