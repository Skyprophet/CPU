module rom(raddr,rout);
    input [11:0] raddr;
    output [31:0] rout;
    
    reg [31:0] rom[4095:0];
    initial
    begin
        $readmemb("rom.vlog",rom);
        $display("\nLoad rom successfully !!\n\n");
    end
    assign rout = rom[raddr];
endmodule

module fetch_stage(clk, reset, ctrbus, inst, over);
  input clk, reset;
  input [34:0] ctrbus;
  output [31:0] inst;
  reg [31:0] inst;
  output over;
  reg over;
  
  reg [31:0] pc;
  wire valid;
  wire brch;
  wire kill;
  wire [31:0] brchaddr;
  
  assign valid = ctrbus[34];
  assign brch = ctrbus[33];
  assign kill = ctrbus[32];
  assign brchaddr = ctrbus[31:0];
  
  wire [31:0] rom_out;
  reg rom_en;
  rom instruction_rom(.raddr(pc[13:2]), .rout(rom_out));
  
  always @(*) begin
    if (reset) over <= 0;
    else if (!over) over <= (rom_out[31:28]==4'b1111);
  end
  
  always @(posedge clk) begin
    if (reset)
      rom_en <= 0;
    else
      rom_en <= 1;
  end
  
  always @(posedge clk) begin
    if (reset) begin
      pc <= 0;
    end else if (brch) begin
      pc <= brchaddr;
    end else if (valid) begin
      pc <= pc + 4;
    end else begin
      pc <= pc;
    end
  end
  
  always @(posedge clk) begin
    if (reset)
      inst <= 0;
    else if (kill)
      inst <= 0;
    else
      inst <= (!over&&rom_en&&!(rom_out[31:28]==4'b1111))? rom_out:32'h00000000;
  end
endmodule  
