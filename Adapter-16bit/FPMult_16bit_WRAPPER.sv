`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.10.2023 20:15:25
// Design Name: 
// Module Name: FPMult_16bit_WRAPPER
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


module FPMult_16bit_WRAPPER(

    input                [17:0] X,
    input                [17:0] Y,
    output logic         [17:0] R

);

FPMult_16bit FPMult_16bit_inst1(.X(X), .Y(Y), .R(R));

endmodule
