module cpu(clk, reset);
  input clk, reset;
  
  wire [34:0] ctrbus;
  wire [31:0] inst;
  wire [4:0] ex_dst, mem_dst, wb_dst;
  wire [37:0] wbbus;
  wire [105:0] idbus;
  wire [73:0] exbus;
  wire [73:0] membus;
  wire over;
  
  fetch_stage fetch(.clk(clk), .reset(reset), .ctrbus(ctrbus), .inst(inst), .over(over));
  decode_stage decode(.clk(clk), .reset(reset), .inst(inst), .ex_dst(ex_dst), .mem_dst(mem_dst),
                      .wb_dst(wb_dst), .wbbus(wbbus), .ctrbus(ctrbus), .idbus(idbus));
  alu_stage alu(.clk(clk), .reset(reset), .idbus(idbus), .exbus(exbus), .ex_dst(ex_dst));
  mem_stage mem(.clk(clk), .reset(reset), .over(over), .exbus(exbus), .membus(membus), .mem_dst(mem_dst));
  wb_stage wb(.clk(clk), .reset(reset), .membus(membus), .wbbus(wbbus), .wb_dst(wb_dst));
  
  always @(posedge over) begin
    #70 $stop;
  end
endmodule

module system();
    reg clk;
    reg reset;   
    initial begin
        clk <= 1'b0;
        forever #5 clk <= ~clk;
    end
            
    initial 
    begin
        #0 reset<=1'b1;
        #20 reset<=1'b0;
    end
    
    cpu cpu00(.clk(clk),.reset(reset));
endmodule
