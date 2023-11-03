`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.10.2023 15:27:50
// Design Name: 
// Module Name: neuron
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


module neuron #(BITWIDTH = 32, BW = BITWIDTH-1)(

  input                         clk,				 
  input 				        rst,				 
  input                         clear,

  input                         en,         //Enbale forward propogation

  input [BW:0]                  weight,		  
  input [BW:0]                  data,			  

  output logic[BW:0]	    accum 

);
  logic [BW:0] prod;
  logic [BW:0] mult;

  FPMult_8_23_uid13_comb_uid14_WRAPPER FPMULT_1(.X(weight), .Y(data), .C(prod), .negateAB(1'b0), .negateC(1'b0), .RndMode(2'b0), .R(mult));
  
  always_comb begin
    prod = accum;
  end

  //Sequential Logic for Accumulation
  always_ff @(posedge clk) begin
    //Reset
    if (rst) begin
        // Reset accumulation
        accum <= 32'b0;
    end
    //Clear Accumulation
    else if (clear) begin
      accum <= 32'b0;
    end
    else if (en) begin
      accum <= mult; 
    end
  end
  
endmodule
