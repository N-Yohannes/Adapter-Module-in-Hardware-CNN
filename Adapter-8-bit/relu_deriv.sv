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

//12 bit flopoco Ploating Point [wE=4, wF=7]
//`define FLOAT_1 14'b01001110000000 //1.0 in flopoco format
`define FLOAT_1 14'b11111111111111 //1.0 in flopoco format
 
module relu_deriv #(BITWIDTH = 12, BW = BITWIDTH+2-1)(

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

