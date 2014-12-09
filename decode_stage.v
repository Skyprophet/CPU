module decode_stage(clk, reset, inst, ex_dst, mem_dst, wb_dst, wbbus, ctrbus, idbus);
  input clk, reset;
  input [31:0] inst;
  input [4:0] ex_dst, mem_dst, wb_dst;
  input [37:0] wbbus;
  output [105:0] idbus;
  output [34:0] ctrbus;
  
  reg [105:0] idbus;
  reg kill;
  
  wire wbbus_valid;
  wire [4:0] wbbus_dst;
  wire [31:0] wbbus_data;
  
  reg idbus_valid;
  wire [3:0] idbus_op;
  reg [4:0] idbus_dst;
  wire [31:0] idbus_r1;
  wire [31:0] idbus_r2;
  reg [31:0] idbus_imm;
  
  reg ctrbus_valid;
  reg ctrbus_brch;
  reg ctrbus_kill;
  reg [31:0] ctrbus_addr;
  
  assign wbbus_valid = wbbus[37];
  assign wbbus_dst = wbbus[36:32];
  assign wbbus_data = wbbus[31:0];
  
  reg [31:0] saved_inst;
  reg saved;
  
  always @(posedge clk) begin
    if (reset) begin
      saved <= 1'b0;
      saved_inst <= 0;
    end else begin
      if (ctrbus_valid) begin
        saved <= 1'b0;
        saved_inst <= 0;
      end else if (!saved) begin
        saved <= 1'b1;
        saved_inst <= inst;
      end
    end
  end
  
  reg [31:0] cur_inst;
  
  always @(*) begin
    if (!saved)
      cur_inst <= inst;
    else
      cur_inst <= saved_inst;
  end
  
  reg [4:0] reg_addr1, reg_addr2;
  always @(*) begin
    if (cur_inst[31:28]==4'b1011 || cur_inst[31:28]==4'b1100 ||
        cur_inst[31:28]==4'b1101 || cur_inst[31:28]==4'b1110 || cur_inst[31:28]==4'b1111) begin
      reg_addr1 <= cur_inst[27:23];
      reg_addr2 <= 0;
      idbus_dst <= 0;
      idbus_imm <= {9'b000000000, cur_inst[22:0]};
    end else if (cur_inst[31:28]==4'b1001) begin
      reg_addr1 <= cur_inst[27:23];
      reg_addr2 <= cur_inst[22:18];
      idbus_dst <= 0;
      idbus_imm <= {{15{cur_inst[17]}}, cur_inst[16:0]};
    end else if (cur_inst[31:28]==4'b0100 || cur_inst[31:28]==4'b0101 ||
        cur_inst[31:28]==4'b0110 || cur_inst[31:28]==4'b0111 || cur_inst[31:28]==4'b1000) begin
      reg_addr1 <= cur_inst[22:18];
      reg_addr2 <= 0;
      idbus_dst <= cur_inst[27:23];
      idbus_imm <= {{15{cur_inst[17]}}, cur_inst[16:0]};
    end else if (cur_inst[31:28]==4'b0001 || cur_inst[31:28]==4'b0010 ||
        cur_inst[31:28]==4'b0011) begin
      reg_addr1 <= cur_inst[22:18];
      reg_addr2 <= cur_inst[17:13];
      idbus_dst <= cur_inst[27:23];
      idbus_imm <= 0;
    end else if (cur_inst[31:28]==4'b1010) begin
      reg_addr1 <= 0;
      reg_addr2 <= 0;
      idbus_dst <= 0;
      idbus_imm <= {4'b0000, cur_inst[27:0]};
    end else begin
      reg_addr1 <= 0;
      reg_addr2 <= 0;
      idbus_dst <= 0;
      idbus_imm <= 0;
    end
  end
  
  register_file registers(.clk(clk), .reset(reset), .rin1(reg_addr1), .rout1(idbus_r1),
  .rin2(reg_addr2), .rout2(idbus_r2), .we(wbbus_valid), .waddr(wbbus_dst), .win(wbbus_data));
  
  assign idbus_op = cur_inst[31:28];
  
  reg reset_over;
  always @(posedge clk) begin
    if (reset)
      reset_over <= 0;
    else
      reset_over <= 1;
  end
  
  always @(*) begin
    if (reset_over) begin
      ctrbus_valid <= 1'b1;
    end else begin
      ctrbus_valid <= 1'b0;
    end
    
    if (cur_inst[31:28]==4'b1011 || cur_inst[31:28]==4'b1100 ||
        cur_inst[31:28]==4'b1101 || cur_inst[31:28]==4'b1110 || cur_inst[31:28]==4'b1111) begin
       if ((cur_inst[27:23]!=0)&&((cur_inst[27:23]==ex_dst)||(cur_inst[27:23]==mem_dst)||(cur_inst[27:23]==wb_dst)))
         ctrbus_valid <= 1'b0;
    end else if (cur_inst[31:28]==4'b1001) begin
      if (((cur_inst[27:23]!=0)&&((cur_inst[27:23]==ex_dst)||(cur_inst[27:23]==mem_dst)||(cur_inst[27:23]==wb_dst)))||
          ((cur_inst[22:18]!=0)&&((cur_inst[22:18]==ex_dst)||(cur_inst[22:18]==mem_dst)||(cur_inst[22:18]==wb_dst))))
         ctrbus_valid <= 1'b0;
    end else if (cur_inst[31:28]==4'b0100 || cur_inst[31:28]==4'b0101 ||
        cur_inst[31:28]==4'b0110 || cur_inst[31:28]==4'b0111 || cur_inst[31:28]==4'b1000) begin
      if ((cur_inst[22:18]!=0)&&((cur_inst[22:18]==ex_dst)||(cur_inst[22:18]==mem_dst)||(cur_inst[22:18]==wb_dst)))
         ctrbus_valid <= 1'b0;
    end else if (cur_inst[31:28]==4'b0001 || cur_inst[31:28]==4'b0010 || cur_inst[31:28]==4'b0011) begin
      if (((cur_inst[22:18]!=0)&&((cur_inst[22:18]==ex_dst)||(cur_inst[22:18]==mem_dst)||(cur_inst[22:18]==wb_dst)))||
          ((cur_inst[17:13]!=0)&&((cur_inst[17:13]==ex_dst)||(cur_inst[17:13]==mem_dst)||(cur_inst[17:13]==wb_dst))))
         ctrbus_valid <= 1'b0;
    end
  end
  
  always @(*) begin
    ctrbus_brch <= 1'b0;
    ctrbus_addr <= 32'h00000000;
    if (cur_inst[31:28]==4'b1010) begin
      ctrbus_brch <= 1'b1;
      ctrbus_addr <= {4'b0000, cur_inst[27:0]};
      ctrbus_kill <= 1'b1;
    end else if (cur_inst[31:28]==4'b1011 || cur_inst[31:28]==4'b1100 ||
        cur_inst[31:28]==4'b1101 || cur_inst[31:28]==4'b1110 || cur_inst[31:28]==4'b1111) begin
          //ctrbus_kill <= 1'b0;
          if ((cur_inst[27:23]!=ex_dst)&&(cur_inst[27:23]!=mem_dst)&&(cur_inst[27:23]!=wb_dst)) begin
            case(cur_inst[31:28])
              4'b1011:begin
                  if (idbus_r1==0) begin
                    ctrbus_brch <= 1'b1;
                    ctrbus_addr <= {9'b000000000, cur_inst[22:0]};
                    ctrbus_kill <= 1'b1;
                  end
                end
              4'b1100:begin
                  if (idbus_r1[31]==0&&idbus_r1[30:0]!=0) begin
                    ctrbus_brch <= 1'b1;
                    ctrbus_addr <= {9'b000000000, cur_inst[22:0]};
                    ctrbus_kill <= 1'b1;
                  end
                end
              4'b1101:begin
                  if (idbus_r1[31]==1) begin
                    ctrbus_brch <= 1'b1;
                    ctrbus_addr <= {9'b000000000, cur_inst[22:0]};
                    ctrbus_kill <= 1'b1;
                  end
                end
              4'b1110:begin
                  if (idbus_r1[31]==0) begin
                    ctrbus_brch <= 1'b1;
                    ctrbus_addr <= {9'b000000000, cur_inst[22:0]};
                    ctrbus_kill <= 1'b1;
                  end
                end
              4'b1101:begin
                  if (idbus_r1[31]==1||idbus_r1==0) begin
                    ctrbus_brch <= 1'b1;
                    ctrbus_addr <= {9'b000000000, cur_inst[22:0]};
                    ctrbus_kill <= 1'b1;
                  end
                end
            endcase
          end
    end
  end
  
  always @(posedge clk) begin
    if (reset)
      idbus_valid <= 0;
    else
      idbus_valid <= ctrbus_valid;
  end
  
  assign ctrbus[34] = ctrbus_valid;
  assign ctrbus[33] = ctrbus_brch;
  assign ctrbus[32] = ctrbus_kill;
  assign ctrbus[31:0] = ctrbus_addr;
  
  always @(*) begin
    if (reset) begin
      ctrbus_kill <= 0;
    end
  end
  
  always @(posedge clk) begin
    if (reset) begin
      idbus <= 0;
    end else if (ctrbus_kill) begin
      ctrbus_kill <= 0;
    end else begin
      idbus[105] <= (!reset)&(ctrbus_valid);
      idbus[104:101] <= idbus_op;
      idbus[100:96] <= idbus_dst;
      idbus[95:64] <= idbus_r1;
      idbus[63:32] <= idbus_r2;
      idbus[31:0] <= idbus_imm;
    end
  end
  
endmodule
  