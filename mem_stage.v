module mem_stage(clk, reset, over, exbus, membus, mem_dst, mem_bypass);
  input clk, reset, over;
  input [73:0] exbus;
  output [73:0] membus;
  output [4:0] mem_dst;
  output [32:0] mem_bypass;
  
  reg [73:0] membus;
  reg [4:0] mem_dst;
  reg [32:0] mem_bypass;
  
  wire exbus_valid;
  wire [3:0] exbus_op;
  wire [4:0] exbus_dst;
  wire [31:0] exbus_res;
  wire [31:0] exbus_stval;
  
  wire membus_valid;
  wire [3:0] membus_op;
  wire [5:0] membus_dst;
  wire [31:0] membus_res;
  wire [31:0] membus_memres;
  
  assign exbus_valid = exbus[73];
  assign exbus_op = exbus[72:69];
  assign exbus_dst = exbus[68:64];
  assign exbus_res = exbus[63:32];
  assign exbus_stval = exbus[31:0];
  
  always @(*) begin
    if (exbus_valid)
      mem_dst <= exbus_dst;
    else
      mem_dst <= 0;
  end
  
  reg rd_we;
  always @(*) begin
    rd_we <= 0;
    if (exbus_op==4'b1001)
      rd_we <= 1;
  end
  
  assign membus_valid = exbus_valid;
  assign membus_op = exbus_op;
  assign membus_dst = exbus_dst;
  assign membus_res = exbus_res;
  
  cache mem_ram(.clk(clk), .reset(reset), .over(over), .rin(exbus_res[17:2]), .rout(membus_memres),
  .we(rd_we), .waddr(exbus_res[17:2]), .win(exbus_stval));
  
  always @(posedge clk) begin
    if (reset)
      membus <= 0;
    else begin
      membus[73] <= membus_valid;
      membus[72:69] <= membus_op;
      membus[68:64] <= membus_dst;
      membus[63:32] <= membus_res;
      membus[31:0] <= membus_memres;
      if ((membus_op[3]==1'b0)||(membus_op==4'b1000)) begin
        mem_bypass[31:0] <= (membus_op==4'b1000)? membus_memres:membus_res;
        mem_bypass[32] <= membus_valid;
      end else begin 
        mem_bypass <= 0;
      end
    end
  end
  
endmodule
