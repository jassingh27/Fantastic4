module UART_RX (
    input wire clk,                // Clock input
    input wire rst,                // Reset input
    input wire rx,                 // UART receive data input
    output reg data_received       // Data received output
);

    reg [3:0] detect_count = 4'd0;  // Counter for detecting multiple transitions

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_received <= 0;    // Reset data_received on reset
            detect_count <= 0;     // Reset detect_count on reset
        end else begin
            if (rx) begin
                detect_count <= detect_count + 1; // Increment detect_count on rx
                if (detect_count >= 4'd4) begin   // Detect multiple transitions to confirm data receipt
                    data_received <= 1;         // Set data_received when data is confirmed
                end
            end else begin
                detect_count <= 0;     // Reset detect_count if rx is low
            end
        end
    end

endmodule

module GPS_Parser (
    input wire data_received,       // Data received signal
    input wire [7:0] gps_data,     // GPS data input
    output wire [15:0] latitude,   // Latitude output
    output wire [15:0] longitude   // Longitude output
);

    reg [7:0] gps_buffer [0:3];     // GPS data buffer
    reg [2:0] buffer_index = 3'b000; // Buffer index
    reg parsing = 1'b0;             // Parsing flag
    reg [7:0] latitude_h;            // Latitude high byte
    reg [7:0] latitude_l;            // Latitude low byte
    reg [7:0] longitude_h;           // Longitude high byte
    reg [7:0] longitude_l;           // Longitude low byte

    always @(posedge data_received) begin
        if (data_received) begin
            gps_buffer[buffer_index] <= gps_data;  // Store GPS data in the buffer
            if (buffer_index == 3'b011) begin      // Check if 4 bytes of data have been received
                parsing <= 1'b1;                   // Set parsing flag to indicate data parsing
            end
            buffer_index <= buffer_index + 1;      // Increment buffer index
        end
    end

    always @(posedge parsing) begin
        if (parsing) begin
            latitude_h <= gps_buffer[0];           // Extract latitude high byte
            latitude_l <= gps_buffer[1];           // Extract latitude low byte
            longitude_h <= gps_buffer[2];          // Extract longitude high byte
            longitude_l <= gps_buffer[3];          // Extract longitude low byte
        end
    end

    assign latitude = {latitude_h, latitude_l};     // Combine latitude high and low bytes
    assign longitude = {longitude_h, longitude_l};   // Combine longitude high and low bytes

endmodule

module LED_Display (
    input wire data_received,        // Data received signal
    input wire [7:0] gps_data,      // GPS data input
    output wire [7:0] leds          // LED data output
);

    assign leds = data_received ? gps_data : 8'b00000000;  // Display GPS data on LEDs when data is received, otherwise all zeros

endmodule

module TOP_MODULE (
    input wire clk,                  // Clock input
    input wire rst,                  // Reset input
    input wire rx,                   // UART receive data input
    input wire [7:0] gps_data,       // GPS data input
    output wire [7:0] leds,          // LED data output
    output wire [15:0] latitude,     // Latitude output
    output wire [15:0] longitude    // Longitude output
);

    wire data_received;              // Data received signal

    UART_RX uart_rx (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .data_received(data_received)  // Connect UART_RX module
    );

    GPS_Parser gps_parser (
        .data_received(data_received),
        .gps_data(gps_data),
        .latitude(latitude),
        .longitude(longitude)          // Connect GPS_Parser module
    );

    LED_Display led_display (
        .data_received(data_received),
        .gps_data(gps_data),
        .leds(leds)                    // Connect LED_Display module
    );

endmodule
