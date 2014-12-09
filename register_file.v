module register_file(clk, reset, rin1, rout1, rin2, rout2, we, waddr, win);
  input clk, reset, we;
  input [4:0] rin1, rin2, waddr;
  input [31:0] win;
  output [31:0] rout1, rout2;
  
  reg [31:0] R[31:0];
  assign rout1 = R[rin1];
  assign rout2 = R[rin2];
  
  integer i;
  
  always @(posedge clk)
    begin
      if (reset)
        for (i = 0; i <= 31; i = i + 1)
          R[i] <= 32'b0;
    end
  
  always @(posedge clk) begin
    R[0] <= 32'b0;
    if (we)
      if (waddr!=0)
        R[waddr] <= win;
  end
endmodule
  