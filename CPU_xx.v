module rom(raddr,rout);
    input [11:0] raddr;
    output [15:0] rout;
    
    reg [15:0] rom[4095:0];
    initial
    begin
        $readmemb("rom.vlog",rom);
        $display("\nLoad rom successfully !!\n\n");
    end
    assign rout = rom[raddr];
endmodule
module ram(clock,raddr,rout,wen,waddr,win);
    input clock; 
    input wen; 
    input [15:0] win;
    input [11:0] raddr;
    input [11:0] waddr;
    output [15:0] rout;
    
    reg [15:0] ram[4095:0];
    assign rout = ram[raddr];
    
    always @(posedge clock) begin
        if (wen) begin
            ram[waddr] = win;
        end
    end
endmodule
module regfile(clock,raddr1,rout1,raddr2,rout2,wen,waddr,win);
    input clock;    
    input wen; 
    input [15:0] win;
    input [2:0] raddr1,raddr2;
    input [2:0] waddr;
    output [15:0] rout1,rout2;
    
    reg [15:0] ram[7:0];
    assign rout1 = ram[raddr1];
    assign rout2 = ram[raddr2];
    
    always @(posedge clock) 
    begin
        ram[0]<=16'b0;
        if (wen) 
        begin
            if(waddr!=0) ram[waddr]<= win;
        end
    end
endmodule
module fetch_module(clock,reset,brbus,inst);
    input clock;
    input reset;
    input [17:0]brbus;
    output [15:0]inst; //instruction
    reg [15:0]inst;
    
    reg [15:0] pc;
    
    wire brbus_valid; // pipeline stall if it equals to 0
    wire brbus_taken; // branch instruction if it equals to 1
    wire [15:0]brbus_offset;
    
    assign brbus_valid=brbus[17];
    assign brbus_taken=brbus[16];
    assign brbus_offset=brbus[15:0];
    
    wire [15:0]rom_out;
    rom instruction_rom(.raddr(pc[12:1]),.rout(rom_out));
    
    reg rom_en;
    always @(posedge clock) begin
        if(reset==1) begin
            rom_en<=0;
        end
        else begin
            rom_en<=1;
        end
    end
    always @(posedge clock) begin
        if(reset==1) begin
            pc<=0;
        end
        else if(brbus_taken==1) begin
            pc<=pc+brbus_offset;
        end
        else if(brbus_valid==1) begin
            pc<=pc+2;
        end
    end
    always @(posedge clock) begin
        if(reset==1) begin
            inst<=0;
        end
        else begin
            inst<=(rom_en==1)? rom_out:16'h0000;
        end
    end
endmodule // fetch module
module decode_module(clock,reset,inst,ex_dest,mem_dest,wb_dest,wbbus,brbus,idbus);
    input clock;
    input reset;
    input [15:0]inst;
    input [2:0] ex_dest,mem_dest,wb_dest;
    input [19:0]wbbus;
    output [55:0]idbus;
    reg [55:0] idbus;
    output [17:0]brbus;
    
    wire wbbus_valid;
    wire [2:0]wbbus_dest;
    wire [15:0]wbbus_value;
    
    reg idbus_valid;
    wire [3:0]idbus_op;
    wire [2:0]idbus_dest;
    wire [15:0]idbus_value1;
    wire [15:0]idbus_value2;
    wire [15:0]idbus_stvalue;
    
    reg brbus_valid;
    reg brbus_taken;
    reg [15:0]brbus_offset;
    
    assign wbbus_valid=wbbus[19];
    assign wbbus_dest=wbbus[18:16];
    assign wbbus_value=wbbus[15:0];
    
    reg [15:0] inst_save;
    reg inst_save_valid;
    always @(posedge clock) begin
        if(reset==1) begin
            inst_save<=0;
            inst_save_valid<=1'b0;
        end
        else begin
            if(brbus_valid==1) begin
                inst_save<=0;
                inst_save_valid<=1'b0;
            end
            else if(inst_save_valid==1'b0) begin
                inst_save<=inst;
                inst_save_valid<=1'b1;
            end
        end
    end
    reg [15:0] cur_inst;
    always @(*) begin
        if(inst_save_valid==0) begin
            cur_inst<=inst;
        end
        else begin
            cur_inst<=inst_save;
        end
    end
    
    reg [2:0]reg_rd_addr2;
    always @(*) begin
        if(inst[15:12]==4'b1011) begin // store
            reg_rd_addr2<=cur_inst[11:9];
        end
        else begin
            reg_rd_addr2<=cur_inst[5:3];
        end
    end
    regfile registers(.clock(clock),.raddr1(cur_inst[8:6]),.rout1(idbus_value1),.raddr2(reg_rd_addr2),
                .rout2(idbus_value2),.wen(wbbus_valid),.waddr(wbbus_dest),.win(wbbus_value));
    
    assign idbus_stvalue={{11{inst[5]}},inst[4:0]};
    assign idbus_op=inst[15:12];
    assign idbus_dest=inst[11:9];
    
    reg reset_over;
    always @(posedge clock) begin
        if(reset==1) begin
            reset_over<=0;
        end
        else begin
            reset_over<=1;
        end
    end
    always @(*) begin
        if(reset_over==1) begin
            brbus_valid<=1'b1;
        end
        else begin
            brbus_valid<=1'b0;
        end
        // all 14 instructions
        if((cur_inst[8:6]!=0)&&((cur_inst[8:6]==ex_dest)||(cur_inst[8:6]==mem_dest)||(cur_inst[8:6]==wb_dest))) begin
            brbus_valid<=1'b0;
        end
        if(cur_inst[15:14]!=4'b11) begin
            // non-branch instruction
            if((cur_inst[11:9]!=0)&&((cur_inst[11:9]==ex_dest)||(cur_inst[11:9]==mem_dest)||(cur_inst[11:9]==wb_dest))) begin
                brbus_valid<=1'b0;
            end
            if((cur_inst[15]==1'b0)&&(cur_inst[15:12]!=4'b1000)) begin
                // three registers instruction("NOT" instruction's value is 0)
                if((cur_inst[5:3]!=0)&&((cur_inst[5:3]==ex_dest)||(cur_inst[5:3]==mem_dest)||(cur_inst[5:3]==wb_dest))) begin
                    brbus_valid<=1'b0;
                end
            end
        end
    end
    
    always @(*) begin
        brbus_taken<=1'b0;
        brbus_offset<=16'h0000;
        if(cur_inst[15:14]==2'b11) begin // branch instuctions
            if((cur_inst[8:6]!=ex_dest)&&(cur_inst[8:6]!=mem_dest)&&(cur_inst[8:6]!=wb_dest)) begin
                case(cur_inst[10:9])
                    2'b00: begin // BZ
                        if(idbus_value1==0) begin
                            brbus_taken<=1'b1;
                            brbus_offset<={{11{cur_inst[5]}},cur_inst[4:0]};
                        end
                    end
                    2'b01: begin // BGT
                        if((idbus_value1[15]==0)&&(idbus_value1[14:0]!=0)) begin
                            brbus_taken<=1'b1;
                            brbus_offset<={{11{cur_inst[5]}},cur_inst[4:0]};
                        end
                    end
                    2'b10: begin // BLE
                        if((idbus_value1[15]==1)||(idbus_value1==0)) begin
                            brbus_taken<=1'b1;
                            brbus_offset<={{11{cur_inst[5]}},cur_inst[4:0]};
                        end
                    end
                endcase
            end
        end
    end
    
    always @(posedge clock) begin
        if(reset==1) begin
            idbus_valid<=0;
        end
        else begin
            idbus_valid<=brbus_valid;
        end
    end
    
    assign brbus[17]=brbus_valid;
    assign brbus[16]=brbus_taken;
    assign brbus[15:0]=brbus_offset;
    
    always @(posedge clock) begin
        if(reset==1) begin
            idbus<=0;
        end
        else begin
            idbus[55]<=(brbus_valid==1)? idbus_valid:1'b0;
            idbus[54:51]<=idbus_op;
            idbus[50:48]<=idbus_dest;
            idbus[47:32]<=idbus_value1;
            idbus[31:16]<=idbus_value2;
            idbus[15:0]<=idbus_stvalue;
        end
    end
endmodule
module alu_module(clock,reset,idbus,exbus,ex_dest);
    input clock;
    input reset;
    input [55:0]idbus;
    output [39:0]exbus;
    reg [39:0]exbus;
    output [2:0]ex_dest;
    reg [2:0]ex_dest;
    
    wire idbus_valid;
    wire [3:0]idbus_op;
    wire [2:0]idbus_dest;
    wire [15:0]idbus_value1;
    wire [15:0]idbus_value2;
    wire [15:0]idbus_stvalue;
    
    reg exbus_valid;
    reg [3:0]exbus_op;
    reg [2:0]exbus_dest;
    reg [15:0]exbus_exresult;
    reg [15:0]exbus_stvalue;
    
    assign idbus_valid=idbus[55];
    assign idbus_op=idbus[54:51];
    assign idbus_dest=idbus[50:48];
    assign idbus_value1=idbus[47:32];
    assign idbus_value2=idbus[31:16];
    assign idbus_stvalue=idbus[15:0];
    
    always @(*) begin
        if(idbus_valid==1) begin
            ex_dest<=idbus_dest;
        end
        else begin
            ex_dest<=0;
        end
    end
    
    always @(*) begin
        exbus_valid<=0;
        exbus_op<=0;
        exbus_dest<=0;
        exbus_exresult<=16'h0000;
        exbus_stvalue<=16'h0000;
        if(idbus_valid==1'b1) begin
            exbus_valid<=1;
            exbus_op<=idbus_op;
            exbus_dest<=idbus_dest;
            case(idbus_op)
                4'b0001: begin // ADD
                    exbus_exresult<=idbus_value1+idbus_value2;
                end
                4'b0010: begin // SUB
                    exbus_exresult<=idbus_value1-idbus_value2;
                end
                4'b0011: begin // AND
                    exbus_exresult<=idbus_value1&idbus_value2;
                end
                4'b0100: begin // OR
                    exbus_exresult<=idbus_value1|idbus_value2;
                end
                4'b0101: begin // NOT
                    exbus_exresult<=~idbus_value1;
                end
                4'b0110: begin // SL
                    exbus_exresult<=idbus_value1<<idbus_value2[3:0];
                end
                4'b0111: begin // SR
                    exbus_exresult<=(~(16'hffff>>idbus_value2[3:0]))|(idbus_value1>>idbus_value2[3:0]);
                end
                4'b1000: begin // SRU
                    exbus_exresult<=idbus_value1>>idbus_value2[3:0];
                end
                4'b1001: begin // ADDI
                    exbus_exresult<=idbus_value1+idbus_stvalue;
                end
                4'b1010: begin // LD
                    exbus_exresult<=idbus_value1+idbus_stvalue;
                end
                4'b1011: begin // ST
                    exbus_exresult<=idbus_value1+idbus_stvalue;
                    exbus_stvalue<=idbus_value2;
                end
            endcase
        end
    end
    
    always @(posedge clock) begin
        if(reset==1) begin
            exbus<=0;
        end
        else begin
            exbus[39]<=exbus_valid;
            exbus[38:35]<=exbus_op;
            exbus[34:32]<=exbus_dest;
            exbus[31:16]<=exbus_exresult;
            exbus[15:0]<=exbus_stvalue;
        end
    end
endmodule//alu_module
module mem_module(clock,reset,exbus,membus,mem_dest);
    input clock;
    input reset;
    input [39:0]exbus;
    output [39:0]membus;
    reg [39:0] membus;
    output [2:0]mem_dest;
    reg [2:0]mem_dest;
    
    wire exbus_valid;
    wire [3:0]exbus_op;
    wire [2:0]exbus_dest;
    wire [15:0]exbus_exresult;
    wire [15:0]exbus_stvalue;
    
    wire membus_valid;
    wire [3:0]membus_op;
    wire [2:0]membus_dest;
    wire [15:0]membus_exresult;
    wire [15:0]membus_memresult;
    
    assign exbus_valid=exbus[39];
    assign exbus_op=exbus[38:35];
    assign exbus_dest=exbus[34:32];
    assign exbus_exresult=exbus[31:16];
    assign exbus_stvalue=exbus[15:0];
    always @(*) begin
        if(exbus_valid==1) begin
            mem_dest<=exbus_dest;
        end
        else begin
            mem_dest<=0;
        end
end
    
    reg rd_wr; // if read, rd_wr=0; else rd_wr=1;
    always @(*) begin
        rd_wr<=0;
        if(exbus_op==4'b1011) begin // store instruction
            rd_wr<=1;
        end
    end
    
    assign membus_valid=exbus_valid;
    assign membus_op=exbus_op;
    assign membus_dest=exbus_dest;
    assign membus_exresult=exbus_exresult;
    ram mem_ram(.clock(clock),.raddr(exbus_exresult[11:0]),.rout(membus_memresult),.wen(rd_wr),
                .waddr(exbus_exresult[11:0]),.win(exbus_stvalue));
    
    always @(posedge clock) begin
        if(reset==1) begin
            membus<=0;
        end
        else begin
            membus[39]<=membus_valid;
            membus[38:35]<=membus_op;
            membus[34:32]<=membus_dest;
            membus[31:16]<=membus_exresult;
            membus[15:0]<=membus_memresult;
        end
    end
endmodule//mem_module
module wb_module(clock,reset,membus,wbbus,wb_dest);
    input clock;
    input reset;
    input [39:0]membus;
    output [19:0]wbbus;
    reg [19:0]wbbus;
    output [2:0]wb_dest;
    reg [2:0]wb_dest;
    
    wire membus_valid;
    wire [3:0]membus_op;
    wire [2:0]membus_dest;
    wire [15:0]membus_exresult;
    wire [15:0]membus_memresult;
    
    reg wbbus_valid;
    reg [2:0]wbbus_dest;
    reg [15:0]wbbus_value;
    
    assign membus_valid=membus[39];
    assign membus_op=membus[38:35];
    assign membus_dest=membus[34:32];
    assign membus_exresult=membus[31:16];
    assign membus_memresult=membus[15:0];
    always @(*) begin
        if(membus_valid==1) begin
            wb_dest<=membus_dest;
        end
        else begin
            wb_dest<=0;
        end
    end
    
    always @(*) begin
        wbbus_valid<=0;
        wbbus_dest<=0;
        wbbus_value<=0;
        if(membus_valid==1) begin
            if((membus_op[3]==1'b0)||((membus_op[3:2]==2'b10)&&(membus_op[1:0]!=2'b11))) begin
                // write back instructions
                wbbus_valid<=1;
                wbbus_dest<=membus_dest;
                wbbus_value<=(membus_op[3:1]==3'b101)? membus_memresult:membus_exresult;
            end
        end
    end
    
    always @(*) begin
        wbbus[19]<=wbbus_valid;
        wbbus[18:16]<=wbbus_dest;
        wbbus[15:0]<=wbbus_value;
    end
endmodule
module cpu(clock,reset);
    input clock;
    input reset;
    
    wire [17:0]brbus;
    wire [15:0]inst;
    wire [2:0] ex_dest,mem_dest,wb_dest;
    wire [19:0]wbbus;
    wire [55:0]idbus;
    wire [39:0]exbus;
    wire [39:0]membus;
    fetch_module fetch(.clock(clock),.reset(reset),.brbus(brbus),.inst(inst));
    decode_module decode(.clock(clock),.reset(reset),.inst(inst),.ex_dest(ex_dest),.mem_dest(mem_dest),
                        .wb_dest(wb_dest),.wbbus(wbbus),.brbus(brbus),.idbus(idbus));
    alu_module alu(.clock(clock),.reset(reset),.idbus(idbus),.exbus(exbus),.ex_dest(ex_dest));
    mem_module mem(.clock(clock),.reset(reset),.exbus(exbus),.membus(membus),.mem_dest(mem_dest));
    wb_module wb(.clock(clock),.reset(reset),.membus(membus),.wbbus(wbbus),.wb_dest(wb_dest));
endmodule