`timescale 1ns / 1ps

module BranchUnit #(
    parameter PC_W = 9
) (
    input logic [PC_W-1:0] Cur_PC,
    input logic [31:0] Imm,
    input logic [31:0] Rd1,
    input logic Branch,
    input logic JalrSel,
    input logic halt_com,
    input logic [31:0] AluResult,
    output logic [31:0] PC_Imm,
    output logic [31:0] PC_Four,
    output logic [31:0] BrPC,
    output logic PcSel
);

  logic Branch_Sel;
  logic [31:0] PC_Full;

  assign PC_Full = {23'b0, Cur_PC};

  assign PC_Imm = PC_Full + Imm;
  assign PC_Four = PC_Full + 32'b100;
  assign Branch_Sel = (Branch && AluResult[0]) || (Branch && JalrSel);  

  //assign BrPC = (Branch == 0 && JalrSel == 1) ? {Imm + Rd1} : {(Branch_Sel) ? PC_Imm : 32'b0};  // Branch -> PC+Imm   // Otherwise, BrPC value is not important
  assign BrPC = (halt_com == 1) ? PC_Four - 4 : {(Branch == 0 && JalrSel == 1) ? {Rd1 + Imm} : {(Branch_Sel == 1) ? PC_Imm : PC_Four}}; //jalr
  assign PcSel = Branch_Sel || (Branch == 0 && JalrSel == 1) || (halt_com);  // 1:branch is taken; 0:branch is not taken(choose pc+4)

endmodule
