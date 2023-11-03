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


module neuron #(BITWIDTH = 12, BW = BITWIDTH+2-1)(

  input                         clk,				 
  input 				        rst,				 
  input                         clear,

  input                         en,         //Enbale forward propogation

  input        [BW:0]           weight,		  
  input        [BW:0]           data,			  

  output logic [BW:0]	        accum 

);

  logic [BW:0] prod;
  logic [BW:0] accum_r;
  
  FPMult_12bit_WRAPPER FPMult_12bit(.X(weight), .Y(data), .R(prod));
  FPADD_12bit_WRAPPER FPAdd_12bit(.X(prod), .Y(accum), .R(accum_r)); 

  //Sequential Logic for Accumulation
  always_ff @(posedge clk) begin
    //Reset
    if (rst) begin
        // Reset accumulation
        accum <= 14'b0;
    end
    //Clear Accumulation
    else if (clear) begin
      accum <= 14'b0;
    end
    else if (en) begin
      accum <= accum_r; 
    end
    else ;
  end
  
endmodule
