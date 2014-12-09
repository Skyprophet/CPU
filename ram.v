module cache(clk, reset, over, rin, rout, we, waddr, win);
  input clk, we, reset, over;
  input [31:0] win;
  input [15:0] rin, waddr;
  output [31:0] rout;
  reg [31:0] rout;
  
  reg [134:0] lines[255:0];
  integer i;
  
  initial begin
      for (i = 0; i < 256; i = i + 1)
        lines[i] <= 0;
  end
  
  wire [5:0] rtag, wtag;
  wire [1:0] rboffset, wboffset;
  wire [7:0] rindex, windex;
  
  assign rtag = rin[15:10];
  assign rindex = rin[9:2];
  assign rboffset = rin[1:0];
  assign wtag = waddr[15:10];
  assign windex = waddr[9:2];
  assign wboffset = waddr[1:0];
  
  wire [127:0] ram_out1, ram_out2;
  ram memory(.clk(clk), .over(over), .rin1({rtag,rindex,2'b00}), .rout1(ram_out1),
           .rin2({wtag, windex, 2'b00}), .rout2(ram_out2),
           .we(we), .waddr(waddr), .win(win));
  
  always @(*) begin
    if (lines[rindex][128]) begin
      if (lines[rindex][134:129]==rtag) begin
        case (rboffset)
          2'b00:rout <= lines[rindex][31:0];
          2'b01:rout <= lines[rindex][63:32];
          2'b10:rout <= lines[rindex][95:64];
          2'b11:rout <= lines[rindex][127:96];
        endcase
      end else begin
        lines[rindex][134:129] <= rtag;
        lines[rindex][127:0] <= ram_out1;
        case (rboffset)
          2'b00: rout <= ram_out1[31:0];
          2'b01: rout <= ram_out1[63:32];
          2'b10: rout <= ram_out1[95:64];
          2'b11: rout <= ram_out1[127:96];
        endcase
      end
    end else begin
      lines[rindex][134:129] <= rtag;
      lines[rindex][128] <= 1'b1;
      lines[rindex][127:0] <= ram_out1;
      case (rboffset)
          2'b00: rout <= ram_out1[31:0];
          2'b01: rout <= ram_out1[63:32];
          2'b10: rout <= ram_out1[95:64];
          2'b11: rout <= ram_out1[127:96];
      endcase
    end
  end
  
  always @(posedge clk) begin
    if (we) begin
      if (lines[windex][128]) begin
        if (lines[windex][134:129]==wtag) begin
          case (wboffset)
            2'b00:lines[windex][31:0] = win;
            2'b01:lines[windex][63:32] = win;
            2'b10:lines[windex][95:64] = win;
            2'b11:lines[windex][127:96] = win;
          endcase
        end else begin
          lines[windex][134:129] <= wtag;
          lines[windex][127:0] <= ram_out2;
          case (wboffset)
            2'b00:lines[windex][31:0] <= win;
            2'b01:lines[windex][63:32] <= win;
            2'b10:lines[windex][95:64] <= win;
            2'b11:lines[windex][127:96] <= win;
          endcase
        end
      end else begin
        lines[windex][134:129] <= wtag;
        lines[windex][128] <= 1'b1;
        lines[windex][127:0] <= ram_out2;
        case (wboffset)
          2'b00:lines[windex][31:0] <= win;
          2'b01:lines[windex][63:32] <= win;
          2'b10:lines[windex][95:64] <= win;
          2'b11:lines[windex][127:96] <= win;
        endcase
      end
    end
  end
  
endmodule

module ram(clk, over, rin1, rout1, rin2, rout2, we, waddr, win);
  input clk, we, over;
  input [31:0] win;
  input [15:0] rin1, rin2, waddr;
  output [127:0] rout1, rout2;
  
  reg[31:0]  M[65535:0];
  
  integer i;
  
  initial begin
    /*for (i = 18; i < 65536; i = i + 1)
      M[i] <= 0;
    M[0] <= 32'h00000002;
    M[1] <= 32'h00000003;
    M[2] <= 32'h00000004;
    M[3] <= 32'h00000005;
    M[4] <= 32'h00000006;
    M[5] <= 32'h00000007;
    M[6] <= 32'h00000008;
    M[7] <= 32'h00000009;
    M[8] <= 32'h0000000a;
    
    M[9] <= 32'h00000001;
    M[10] <= 32'h00000002;
    M[11] <= 32'h00000003;
    M[12] <= 32'h00000004;
    M[13] <= 32'h00000005;
    M[14] <= 32'h00000006;
    M[15] <= 32'h00000007;
    M[16] <= 32'h00000008;
    M[17] <= 32'h00000009;*/
    $readmemb("memory.vlog",M);
    $display("\nLoad memory successfully !!\n\n");
  end
  
  assign rout1 = {M[rin1+3], M[rin1+2], M[rin1+1], M[rin1]};
  assign rout2 = {M[rin2+3], M[rin2+2], M[rin2+1], M[rin2]};
  
  always @(posedge over) begin
    $writememb("memoryover.vlog",M);
    $display("\nWrite memory successfully !!\n\n");
  end
  
  always @(posedge clk) begin
      if (we===1'b1) M[waddr] <= win;
  end
 endmodule
 
 /*
module cache(clk, reset, rin, rout, we, waddr, win);
  input clk, we, reset;
  input [31:0] win;
  input [15:0] rin, waddr;
  output [31:0] rout;
  
  reg [31:0] M[65535:0];
  
  integer i;
  
  initial begin
    for (i = 18; i < 65536; i = i + 1)
      M[i] <= 0;
    M[0] <= 32'h00000001;
    M[1] <= 32'h00000001;
    M[2] <= 32'h00000001;
    M[3] <= 32'h00000001;
    M[4] <= 32'h00000001;
    M[5] <= 32'h00000001;
    M[6] <= 32'h00000001;
    M[7] <= 32'h00000001;
    M[8] <= 32'h00000001;
    
    M[9] <= 32'h00000001;
    M[10] <= 32'h00000002;
    M[11] <= 32'h00000003;
    M[12] <= 32'h00000004;
    M[13] <= 32'h00000005;
    M[14] <= 32'h00000006;
    M[15] <= 32'h00000007;
    M[16] <= 32'h00000008;
    M[17] <= 32'h00000009;
 
  end
  
  assign rout = M[rin];
  
  always @(posedge clk) begin
    if (we)
      M[waddr] = win;
  end
 endmodule */
