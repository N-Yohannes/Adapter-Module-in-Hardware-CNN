`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.10.2023 15:25:42
// Design Name: 
// Module Name: relu
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


module relu #(BITWIDTH = 32, BW = BITWIDTH-1)(

    input                           clk,
    input                           rst,
    input                           enable,

    input [BW:0]                    in, //should be [7:0]
    output logic [BW:0]             out

);

    logic [BW:0]                    temp_out;   

    always_comb begin
        case (in[BW])
            1: temp_out = 0;
            0: temp_out = in;
        endcase
    end
    
    always_comb begin
        if (enable)
            out = temp_out;
    end
    
endmodule
