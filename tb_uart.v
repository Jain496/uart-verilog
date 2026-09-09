`timescale 1ns/1ps

module tb_uart;

    localparam CLK_FREQ  = 1000;
    localparam BAUD_RATE = 100;
    localparam CLK_PERIOD_NS = 10;

    reg clk;
    reg rst_n;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx_line;
    wire       tx_busy;
    wire [7:0] rx_data;
    wire       rx_done;

    integer errors;
    integer sent_count;
    reg [7:0] test_bytes [0:4];
    integer i;

    uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) DUT_TX (
        .clk(clk), .rst_n(rst_n), .tx_start(tx_start),
        .tx_data(tx_data), .tx_line(tx_line), .tx_busy(tx_busy)
    );

    uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) DUT_RX (
        .clk(clk), .rst_n(rst_n), .rx_line(tx_line),
        .rx_data(rx_data), .rx_done(rx_done)
    );

    always #(CLK_PERIOD_NS/2) clk = ~clk;

    always @(posedge clk) begin
        if (rx_done) begin
            if (rx_data === test_bytes[sent_count]) begin
                $display("PASS: sent 0x%0h  received 0x%0h", test_bytes[sent_count], rx_data);
            end else begin
                $display("FAIL: sent 0x%0h  received 0x%0h", test_bytes[sent_count], rx_data);
                errors = errors + 1;
            end
            sent_count = sent_count + 1;
        end
    end

    task send_byte(input [7:0] b);
        begin
            @(posedge clk);
            tx_data  = b;
            tx_start = 1'b1;
            @(posedge clk);
            tx_start = 1'b0;
            wait (tx_busy == 1'b0);
        end
    endtask

    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, tb_uart);

        clk = 0; rst_n = 0; tx_start = 0; tx_data = 0;
        errors = 0; sent_count = 0;

        test_bytes[0] = 8'h41;  // 'A'
        test_bytes[1] = 8'h00;  // edge case
        test_bytes[2] = 8'hFF;  // edge case
        test_bytes[3] = 8'h55;  // alternating bits
        test_bytes[4] = 8'hAA;  // alternating bits

        #(CLK_PERIOD_NS*5);
        rst_n = 1;

        for (i = 0; i < 5; i = i + 1) begin
            send_byte(test_bytes[i]);
        end

        #(CLK_PERIOD_NS * (CLK_FREQ/BAUD_RATE) * 12);

        if (errors == 0 && sent_count == 5)
            $display("\n*** ALL %0d TESTS PASSED ***", sent_count);
        else
            $display("\n*** TEST FAILED: %0d errors, %0d bytes checked ***", errors, sent_count);

        $finish;
    end

endmodule