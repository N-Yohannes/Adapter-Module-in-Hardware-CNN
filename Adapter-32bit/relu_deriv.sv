`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.10.2023 14:36:53
// Design Name: 
// Module Name: relu_deriv
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

//32 bit IEEE Floating Point
`define FLOAT_1 32'h3F800000 //1.0

module relu_deriv #(BITWIDTH = 32, BW = BITWIDTH-1)(

    input                           clk,
    input                           rst,
    input                           enable,

    input                           in, 
    output logic [BW:0]             out

);

    logic [BW:0]                    temp_out; 

    always_comb begin
        case (in)
            1: temp_out = 0;
            0: temp_out = `FLOAT_1;
        endcase
    end 
 
    always_ff @(posedge clk or posedge rst) begin

        if(rst) begin
            out <= 0;
        end else if (enable) begin
            out <= temp_out;
        end
    
    end

endmodule 
