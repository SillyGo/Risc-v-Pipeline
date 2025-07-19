`timescale 1ns / 1ps

module datamemory #(
    parameter DM_ADDRESS = 9,
    parameter DATA_W = 32
) (
    input logic clk,
    input logic MemRead,  // comes from control unit
    input logic MemWrite,  // Comes from control unit
    input logic [DM_ADDRESS - 1:0] a,  // Read / Write address - 9 LSB bits of the ALU output
    input logic [DATA_W - 1:0] wd,  // Write Data
    input logic [2:0] Funct3,  // bits 12 to 14 of the instruction
    output logic [DATA_W - 1:0] rd  // Read Data
);

  logic [31:0] raddress;
  logic [31:0] waddress;
  logic [31:0] Datain;
  logic [31:0] Dataout;
  logic [ 3:0] Wr;

  Memoria32Data mem32 (
      .raddress(raddress),
      .waddress(waddress),
      .Clk(~clk),
      .Datain(Datain),
      .Dataout(Dataout),
      .Wr(Wr)
  );

  always_ff @(*) begin
    raddress = {{22{1'b0}}, a};
    waddress = {{22{1'b0}}, a};
    Datain = wd;
    Wr = 4'b0000;

    if (MemRead) begin
      case (Funct3)
        3'b000:  //LB
          rd = {24'b0, Dataout[7:0]};  // Read byte
        3'b001:  //LH
          rd = {16'b0, Dataout[15:0]};  // Read half-word
        3'b010:  //LW
          rd = Dataout;  // Read word
        default: rd = 32'b0;  // Default case for unsupported operations
      endcase
    end else begin
      rd = 32'b0;  // No read operation if not reading
    end
    if (MemWrite) begin
      case (Funct3)
        3'b000:  //SB
          Wr = 4'b0001;  // Write byte
        3'b001:  //SH
          Wr = 4'b0011;  // Write half-word
        3'b010:  //SW
          Wr = 4'b1111;  // Write word
        default: Wr = 4'b0000;  // No write operation
      endcase
      Datain = wd;
    end else begin
      Datain = 32'b0;  // No data to write if not writing
    end
  end

endmodule
