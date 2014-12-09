module alu_stage(clk, reset, idbus, exbus, ex_dst, ex_bypass);
  input clk, reset;
  input [105:0] idbus;
  output [73:0] exbus;
  output [4:0] ex_dst;
  output [32:0] ex_bypass;
  reg [32:0] ex_bypass;
  
  reg [73:0] exbus;
  reg [4:0] ex_dst;
  
  wire idbus_valid;
  wire [3:0] idbus_op;
  wire [4:0] idbus_dst;
  wire [31:0] idbus_r1;
  wire [31:0] idbus_r2;
  wire [31:0] idbus_imm;
  
  reg exbus_valid;
  reg [3:0] exbus_op;
  reg [4:0] exbus_dst;
  reg [31:0] exbus_res;
  reg [31:0] exbus_stval;
  
  assign idbus_valid = idbus[105];
  assign idbus_op = idbus[104:101];
  assign idbus_dst = idbus[100:96];
  assign idbus_r1 = idbus[95:64];
  assign idbus_r2 = idbus[63:32];
  assign idbus_imm = idbus[31:0];
  
  always @(*) begin
    if (idbus_valid)
      ex_dst <= idbus_dst;
    else
      ex_dst <= 0;
  end
  
  always @(*) begin
    exbus_valid <= 0;
    exbus_op <= 0;
    exbus_dst <= 0;
    exbus_res <= 32'h00000000;
    exbus_stval <= 32'h00000000;
    if (idbus_valid) begin
      exbus_valid <= 1'b1;
      exbus_op <= idbus_op;
      exbus_dst <= idbus_dst;
      case(idbus_op)
        4'b0001:begin
          exbus_res <= idbus_r1 + idbus_r2;
        end
        4'b0010:begin
          exbus_res <= idbus_r1 - idbus_r2;
        end
        4'b0011:begin
          exbus_res <= idbus_r1 * idbus_r2;
        end
        4'b0100:begin
          exbus_res <= idbus_r1 + idbus_imm;
        end
        4'b0101:begin
          exbus_res <= idbus_r1 - idbus_imm;
        end
        4'b0110:begin
          exbus_res <= idbus_r1 * idbus_imm;
        end
        4'b0111:begin
          exbus_res <= idbus_r1 << idbus_imm[3:0];
        end
        4'b1000:begin
          exbus_res <= idbus_r1 + idbus_imm;
        end
        4'b1001:begin
          exbus_res <= idbus_r2 + idbus_imm;
          exbus_stval <= idbus_r1;
        end
      endcase
    end
  end
  
  always @(posedge clk) begin
    if (reset)
      exbus <= 0;
    else begin
      exbus[73] <= exbus_valid;
      exbus[72:69] <= exbus_op;
      exbus[68:64] <= exbus_dst;
      exbus[63:32] <= exbus_res;
      exbus[31:0] <= exbus_stval;
      if ((exbus_op[3]==1'b0)) begin
        ex_bypass[31:0] <= exbus_res;
        ex_bypass[32] <= exbus_valid;
      end else begin 
        ex_bypass <= 0;
      end
    end
  end
endmodule
