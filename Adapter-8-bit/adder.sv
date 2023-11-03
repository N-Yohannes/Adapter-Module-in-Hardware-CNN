    `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.10.2023 17:47:30
// Design Name: 
// Module Name: adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adder #(BITWIDTH = 12, BW = BITWIDTH+2-1) (

    input                           clk,
    input                           rst,
    input                           enable,
    input                           clear,

    input        [BW:0]             acc, 
    output logic [BW:0]             sum

);

    logic [BW:0] prod;
    logic [BW:0] mult;

    FPADD_12bit_WRAPPER FPAdd_12bit(.X(acc), .Y(prod), .R(mult));

    always_comb begin
        prod = sum;
    end

    always_ff @(posedge clk) begin
    //Reset
    if (rst) begin
        // Reset accumulation
        sum <= 14'b0;
    end
    //Clear Accumulation
    else if (clear) begin
        sum <= 14'b0;
    end
    else if (enable) begin
        sum <= mult; 
    end
  end

endmodule