module uart_tx #(
    parameter CLK_FREQ  = 50_000_000,   // system clock frequency (Hz)
    parameter BAUD_RATE = 9600          // desired baud rate
) (
    input  wire       clk,
    input  wire       rst_n,      // active-low synchronous reset
    input  wire       tx_start,   // pulse high for 1 cycle to send a byte
    input  wire [7:0] tx_data,    // byte to send
    output reg        tx_line,    // serial output line (idles high)
    output reg        tx_busy     // high while a transmission is in progress
);

    localparam integer CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE;

    localparam [1:0]
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11;

    reg [1:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            tx_line   <= 1'b1;
            tx_busy   <= 1'b0;
            data_reg  <= 8'd0;
        end else begin
            case (state)

                IDLE: begin
                    tx_line <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (tx_start) begin
                        data_reg <= tx_data;
                        tx_busy  <= 1'b1;
                        state    <= START;
                    end else begin
                        tx_busy <= 1'b0;
                    end
                end

                START: begin
                    tx_line <= 1'b0;
                    if (clk_count < CYCLES_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state     <= DATA;
                    end
                end

                DATA: begin
                    tx_line <= data_reg[bit_index];
                    if (clk_count < CYCLES_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state     <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx_line <= 1'b1;
                    if (clk_count < CYCLES_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        tx_busy   <= 1'b0;
                        state     <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule