`timescale 1ns / 1ps

module alu#(
        parameter DATA_WIDTH = 32,
        parameter OPCODE_LENGTH = 4
        )
        (
        input logic [DATA_WIDTH-1:0]    SrcA,
        input logic [DATA_WIDTH-1:0]    SrcB,

        input logic [OPCODE_LENGTH-1:0]    Operation,
        output logic[DATA_WIDTH-1:0] ALUResult
        );
    
        always_comb
        begin
            case(Operation)
            4'b0000:        // AND
                    ALUResult = SrcA & SrcB;
            4'b0010:        // ADD
                    ALUResult = SrcA + SrcB;
            4'b1000:        // Equal
                    ALUResult = (SrcA == SrcB) ? 1 : 0;
            4'b0110:        // SUB
                    ALUResult = SrcA - SrcB;
            4'b0001:        //OR
                    ALUResult = SrcA | SrcB;
            4'b0011:        //XOR
                    ALUResult = SrcA ^ SrcB;
            4'b0101:        //SRL
                    ALUResult = SrcA >> SrcB;
            4'b0100:        //SLL
                    ALUResult = SrcA << SrcB;
            4'b0111:        //SRA
                    ALUResult = (SrcA[31] == 1) ? ((~(32'hFFFFFFFF >> SrcB[4:0])) | (SrcA >> SrcB[4:0])): (SrcA >> SrcB[4:0]);
            4'b1100:        //SLT
                    ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 1 : 0;
            4'b1001: // BGE
                    ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 0 : 1;
            4'b1010: //BNE
                    ALUResult = (SrcA == SrcB) ? 0 : 1;
            default:
                    ALUResult = 0;
            endcase
        end
endmodule
