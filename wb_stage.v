module wb_stage(clk, reset, membus, wbbus, wb_dst);
  input clk, reset;
  input [73:0] membus;
  output [37:0] wbbus;
  output [4:0] wb_dst;
  
  reg [37:0] wbbus;
  reg [4:0] wb_dst;
  
  wire membus_valid;
  wire [3:0] membus_op;
  wire [5:0] membus_dst;
  wire [31:0] membus_res;
  wire [31:0] membus_memres;
  
  reg wbbus_valid;
  reg [4:0] wbbus_dst;
  reg [31:0] wbbus_data;
  
  assign membus_valid = membus[73];
  assign membus_op = membus[72:69];
  assign membus_dst = membus[68:64];
  assign membus_res = membus[63:32];
  assign membus_memres = membus[31:0];
  
  always @(*) begin
    if (membus_valid)
      wb_dst <= membus_dst;
    else
      wb_dst <= 0;
  end
  
  always @(*) begin
    wbbus_valid <= 0;
    wbbus_dst <= 0;
    wbbus_data <= 0;
    if (membus_valid) begin
      if ((membus_op[3]==1'b0)||(membus_op==4'b1000)) begin
        wbbus_valid <= 1'b1;
        wbbus_dst <= membus_dst;
        wbbus_data <= (membus_op==4'b1000)? membus_memres:membus_res;
      end
    end
  end
  
  always @(*) begin
    wbbus[37] <= wbbus_valid;
    wbbus[36:32] <= wbbus_dst;
    wbbus[31:0] <= wbbus_data;
  end
  
endmodule
