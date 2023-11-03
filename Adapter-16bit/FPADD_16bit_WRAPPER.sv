`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2023 03:50:30
// Design Name: 
// Module Name: FPADD_16bit_WRAPPER
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


module FPADD_16bit_WRAPPER (

    input                [17:0] X,
    input                [17:0] Y,
    output logic         [17:0] R

);

FPADD_16bit FPADD_16bit_inst1(.X(X), .Y(Y), .R(R));

endmodule
