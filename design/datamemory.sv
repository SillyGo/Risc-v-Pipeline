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

  logic [31:0] Datain;
  logic [31:0] Dataout;
  logic [ 3:0] Wr;
  logic [DM_ADDRESS - 1:0] word_aligned_a;
  logic [1:0] byte_offset;
  
  assign word_aligned_a = a & ~3; // Clear the lower 2 bits to get the base word address

  Memoria32Data mem32 (
    .raddress({{22{1'b0}}, word_aligned_a}), // Access the word-aligned address in Memoria32Data
    .waddress({{22{1'b0}}, word_aligned_a}), // Access the word-aligned address in Memoria32Data
    .Clk(~clk), // Your Memoria32Data operates on the negative edge, keep this.
    .Datain(Datain),
    .Dataout(Dataout),
    .Wr(Wr)
  );

  assign byte_offset = a[1:0];

  always_ff @(*) begin
    Datain = wd;
    Wr = 4'b0000;

    if (MemRead) begin
      // Dataout now contains the full 32-bit word from the word-aligned address.
      // We need to extract the correct byte/half-word based on byte_offset.
      case (Funct3)
        3'b000: begin // LB (Load Byte) - Sign-extended
          case (byte_offset)
            2'b00: rd = {{24{Dataout[7]}}, Dataout[7:0]};
            2'b01: rd = {{24{Dataout[15]}}, Dataout[15:8]};
            2'b10: rd = {{24{Dataout[23]}}, Dataout[23:16]};
            2'b11: rd = {{24{Dataout[31]}}, Dataout[31:24]};
          endcase
      end
      3'b001: begin // LH (Load Half-word) - Sign-extended
          case (byte_offset[1]) // Only bit 1 matters for half-word alignment
            1'b0: rd = {{16{Dataout[15]}}, Dataout[15:0]};
            1'b1: rd = {{16{Dataout[31]}}, Dataout[31:16]};
          endcase
      end
      3'b010: begin // LW (Load Word)
        rd = Dataout; // Read the entire word
      end
      3'b100: begin // LBU (Load Byte Unsigned) - Zero-extended
        case (byte_offset)
          2'b00: rd = {24'b0, Dataout[7:0]};
          2'b01: rd = {24'b0, Dataout[15:8]};
          2'b10: rd = {24'b0, Dataout[23:16]};
          2'b11: rd = {24'b0, Dataout[31:24]};
        endcase
      end
      default: rd = Dataout; // Default case for unsupported Funct3 values (e.g., in a test environment)
      endcase
    end else if (MemWrite) begin
      // For SB, SH, SW, we need to prepare Datain and Wr to write to the correct byte lanes
      // of the word_aligned_a address.
      case (Funct3)
        3'b000: begin // SB (Store Byte)
          Wr = 4'b0001 << byte_offset; // Enable only the target byte lane
          Datain = wd << (byte_offset * 8); // Shift the data to the correct byte lane
        end
        3'b001: begin // SH (Store Half-word)
          Wr = 4'b0011 << (byte_offset & ~1); // Enable the target half-word lanes
          Datain = wd << ( (byte_offset & ~1) * 8); // Shift data to the correct half-word lane
        end
        3'b010: begin // SW (Store Word)
          Wr = 4'b1111; // Enable all byte lanes for a full word write
          Datain = wd; // Data is already a full word
        end
        default: begin // Default write to full word for unsupported Funct3
          Wr = 4'b1111;
          Datain = wd;
        end
      endcase
    end
  end

endmodule
