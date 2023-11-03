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


module adder #(BITWIDTH = 32, BW = BITWIDTH-1) (

    input                           clk,
    input                           rst,
    input                           enable,
    input                           clear,

    input [BW:0]                    acc, //should be [7:0]
    output logic [BW:0]             sum

);

    logic [BW:0] prod;
    logic [BW:0] mult;

    FPAdd_8_23_comb_uid2_WRAPPER FPADD_adder(.X(acc), .Y(prod), .R(mult));

    always_comb begin
        prod = sum;
    end

    always_ff @(posedge clk) begin
    //Reset
    if (rst) begin
        // Reset accumulation
        sum <= 32'b0;
    end
    //Clear Accumulation
    else if (clear) begin
        sum <= 32'b0;
    end
    else if (enable) begin
        sum <= mult; 
    end
  end

endmodule
