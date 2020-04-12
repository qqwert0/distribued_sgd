`timescale 1ns / 1ps

module tb_h264_dec(
	output 			rst,

	output 			sys_clk,

	input [31:0]    awaddr0,	
	input [3:0]     awregion0,
	input [7:0]     awlen0,
	input [2:0]     awsize0,
	input [1:0]     awburst0,
	input           awlock0,
	input [3:0]     awcache0,
	input [2:0]     awprot0,
	input [3:0]     awqos0,
	input           awvalid0,
	output            awready0,
	input [63:0]	   wdata0,
	input [7:0]     wstrb0,
	input           wlast0,
	input           wvalid0,
	output  	       wready0,
	output  [1:0]     bresp0,	
	output  		   bvalid0,
	input           bready0,	
//M_AXI_1
	input [3:0]      arid0,
	input [31:0]     araddr0,                        
	input[7:0]       arlen0, 
	input[2:0]       arsize0,
	input[1:0]       arburst0,
	input            arlock0,
	input[3:0]       arcache0,
	input[2:0]       arprot0,
	input            arvalid0,
	output             arready0,	
	output [63:0]      rdata0,
	input[1:0]       rresp0,
	output             rlast0, 
	output             rvalid0,
	input            rready0

);

parameter DDR_DEPTH    = 100000000;

parameter WR_CHANNEL_0 = 0;
parameter WR_CHANNEL_1 = 1;
parameter WR_CHANNEL_2 = 2;

parameter AW_READY = 0;
parameter WRITE    = 1;
parameter RESPONSE = 2;

parameter RD_CHANNEL_0 = 0;
parameter RD_CHANNEL_1 = 1;
parameter RD_CHANNEL_2 = 2;

parameter AR_READY 	= 0;
parameter READ 		= 1;

parameter OKAY 		= 2'b00;
parameter EXOKAY 	= 2'b01;
parameter SLVERR 	= 2'b10;
parameter DECERR 	= 2'b11;

parameter awready0_flag = 1;
parameter awready1_flag = 1;
parameter awready2_flag = 1;
parameter arready0_flag = 1;
parameter arready1_flag = 1;
parameter arready2_flag = 1;

//signals of user_logic
reg 			rst;
reg 			sdi_clk;
reg 			sys_clk;

reg [7:0]		ts_data_2_dec;
reg 			ts_data_vld_2_dec;
wire 			dec_almost_full;

//M_AXI_0
wire [31:0]    awaddr0;	
wire [3:0]     awregion0;
wire [7:0]     awlen0;
wire [2:0]     awsize0;
wire [1:0]     awburst0;
wire           awlock0;
wire [3:0]     awcache0;
wire [2:0]     awprot0;
wire [3:0]     awqos0;
wire           awvalid0;
reg            awready0;
wire [63:0]	   wdata0;
wire [7:0]     wstrb0;
wire           wlast0;
wire           wvalid0;
reg  	       wready0;
reg  [1:0]     bresp0;	
reg  		   bvalid0;
wire           bready0;

//M_AXI_1
wire [3:0]      arid0;
wire [31:0]     araddr0;                        
wire[7:0]       arlen0;  
wire[2:0]       arsize0;
wire[1:0]       arburst0;
wire            arlock0;
wire[3:0]       arcache0;
wire[2:0]       arprot0;
wire            arvalid0;
reg             arready0;	
reg [63:0]      rdata0;
wire[1:0]       rresp0;
reg             rlast0; 
reg             rvalid0;
wire            rready0;

//M_AXI_yuv
wire [31:0]     awaddr1;		
wire [7:0]      awlen1;
wire [2:0]      awsize1;
wire [1:0]      awburst1;
wire            awlock1;
wire [3:0]      awcache1;
wire [2:0]      awprot1;
wire [3:0]      awqos1;
wire            awvalid1;
reg             awready1;
wire [255:0]	wdata1;
wire [31:0]     wstrb1;
wire            wlast1;
wire            wvalid1;
reg  	        wready1;
reg  [1:0]      bresp1;		
reg  		    bvalid1;
wire            bready1;

//M_AXI_MC
wire [3:0]      arid1;
wire [31:0]     araddr1;                        
wire [7:0]      arlen1;  ////////////////////
wire [2:0]      arsize1;
wire [1:0]      arburst1;
wire            arlock1;
wire [3:0]      arcache1;
wire [2:0]      arprot1;
wire            arvalid1;
reg             arready1;
reg [255:0]     rdata1;
wire[1:0]       rresp1;
reg             rlast1; 
reg             rvalid1;
wire            rready1;

//M_AXI_DVI
wire [3:0]      arid2;
wire [31:0]     araddr2;                        
wire [7:0]      arlen2;  
wire [2:0]      arsize2;
wire [1:0]      arburst2;
wire            rlock2;
wire [3:0]      arcache2;
wire [2:0]      arprot2;
wire            arvalid2;
reg             arready2;
reg  [255:0]    rdata2;
wire [1:0]      rresp2;
reg             rlast2; 
reg             rvalid2;
wire            rready2; 

//M_AXI_rgb
wire [31:0]     awaddr2;		
wire [7:0]      awlen2;
wire [2:0]      awsize2;
wire [1:0]      awburst2;
wire            awlock2;
wire [3:0]      awcache2;
wire [2:0]      awprot2;
wire [3:0]      awqos2;
wire            awvalid2;
reg             awready2;
wire [31:0]	    wdata2;
wire [3:0]      wstrb2;
wire            wlast2;
wire            wvalid2;
reg  	        wready2;
reg  [1:0]      bresp2;		
reg  		    bvalid2;
wire            bready2;

//ddr_logic
reg  [7:0] 		ddr_mem[0:DDR_DEPTH];

reg  [1:0]		wr_state;
reg  [1:0]		wr_step;
reg  [31:0]		waddr;
reg  [7:0]		wr_cnt;

reg [1:0] 		rd_state;
reg 			rd_step;
reg [7:0]		rd_cnt;
reg [31:0]		raddr;

// user_logic
always #5 sys_clk=~sys_clk;

initial begin
	sys_clk=0;
	rst=1;
	#100;
	rst=0;
end

integer i;
initial begin 
	for(i=0;i<=DDR_DEPTH;i=i+1) begin 
		ddr_mem[i]=8'd0;	
	end 
end 


//ddr write
always @ (posedge sys_clk or posedge rst)
	if(rst) begin
		wr_state<=WR_CHANNEL_0;
		wr_step<=AW_READY;
		waddr<=0;
		wr_cnt<=0;
		awready0<=!awready0_flag;
		wready0<=0;
		awready1<=!awready1_flag;
		wready1<=0;
		awready2<=!awready2_flag;
		wready2<=0;
	end
	else begin
		case(wr_state)
			/////////////WR_CHANNEL_0///////////
			WR_CHANNEL_0: begin
				case(wr_step)
					AW_READY: begin
						bvalid2<=0;
						bvalid0<=0;
						if(awvalid0) begin
							awready0<=awready0_flag;
							waddr<=awaddr0;
							wr_step<=WRITE;
						end
						else begin
							awready0<=!awready0_flag;
							wr_state<=WR_CHANNEL_1;
						end
					end
					WRITE: begin
						awready0<=!awready0_flag;
						if(wvalid0 && wready0) begin
							ddr_mem[waddr+0]<=wdata0[7:0];
							ddr_mem[waddr+1]<=wdata0[15:8];
							ddr_mem[waddr+2]<=wdata0[23:16];
							ddr_mem[waddr+3]<=wdata0[31:24];
							ddr_mem[waddr+4]<=wdata0[39:32];
							ddr_mem[waddr+5]<=wdata0[47:40];
							ddr_mem[waddr+6]<=wdata0[55:48];
							ddr_mem[waddr+7]<=wdata0[63:56];
							waddr<=waddr+8;
							wr_cnt<=wr_cnt+1;
						end 

						if(wlast0 && wr_cnt==awlen0) begin
							wr_step<=RESPONSE;
							wr_cnt<=0;
							wready0<=0;
						end
						else begin
							wready0<=1;
						end
					end
					RESPONSE: begin
						if(bready0) begin
							bvalid0<=1;
							bresp0<=OKAY;
							wr_step<=AW_READY;
							wr_state<=WR_CHANNEL_1;
						end
					end
				endcase
			end
			/////////////WR_CHANNEL_1///////////
			WR_CHANNEL_1: begin
				case(wr_step)
					AW_READY: begin
						bvalid0<=0;
						bvalid1<=0;
						if(awvalid1) begin
							awready1<=awready1_flag;
							waddr<=awaddr1;
							wr_step<=WRITE;
						end
						else begin
							awready1<=!awready1_flag;
							wr_state<=WR_CHANNEL_2;
						end
					end
					WRITE: begin
						awready1<=!awready1_flag;
						if(wvalid1 && wready1) begin
							ddr_mem[waddr+0]<=wdata1[7:0];      ddr_mem[waddr+16]<=wdata1[135:128];
							ddr_mem[waddr+1]<=wdata1[15:8]; 	ddr_mem[waddr+17]<=wdata1[143:136];
							ddr_mem[waddr+2]<=wdata1[23:16];	ddr_mem[waddr+18]<=wdata1[151:144];
							ddr_mem[waddr+3]<=wdata1[31:24];	ddr_mem[waddr+19]<=wdata1[159:152];
							ddr_mem[waddr+4]<=wdata1[39:32];	ddr_mem[waddr+20]<=wdata1[167:160];
							ddr_mem[waddr+5]<=wdata1[47:40];	ddr_mem[waddr+21]<=wdata1[175:168];
							ddr_mem[waddr+6]<=wdata1[55:48];	ddr_mem[waddr+22]<=wdata1[183:176];
							ddr_mem[waddr+7]<=wdata1[63:56];	ddr_mem[waddr+23]<=wdata1[191:184];
							ddr_mem[waddr+8]<=wdata1[71:64];	ddr_mem[waddr+24]<=wdata1[199:192];
							ddr_mem[waddr+9]<=wdata1[79:72];	ddr_mem[waddr+25]<=wdata1[207:200];
							ddr_mem[waddr+10]<=wdata1[87:80];	ddr_mem[waddr+26]<=wdata1[215:208];
							ddr_mem[waddr+11]<=wdata1[95:88];	ddr_mem[waddr+27]<=wdata1[223:216];
							ddr_mem[waddr+12]<=wdata1[103:96]; 	ddr_mem[waddr+28]<=wdata1[231:224];
							ddr_mem[waddr+13]<=wdata1[111:104];	ddr_mem[waddr+29]<=wdata1[239:232];
							ddr_mem[waddr+14]<=wdata1[119:112];	ddr_mem[waddr+30]<=wdata1[247:240];
							ddr_mem[waddr+15]<=wdata1[127:120];	ddr_mem[waddr+31]<=wdata1[255:248];
							waddr<=waddr+32;
							wr_cnt<=wr_cnt+1;
						end 

						if(wlast1 && wr_cnt==awlen1) begin
							wr_step<=RESPONSE;
							wr_cnt<=0;
							wready1<=0;
						end
						else begin
							wready1<=1;
						end
					end
					RESPONSE: begin
						if(bready1) begin
							bvalid1<=1;
							bresp1<=OKAY;
							wr_step<=AW_READY;
							wr_state<=WR_CHANNEL_2;
						end
					end
				endcase
			end
			/////////////WR_CHANNEL_2///////////
			WR_CHANNEL_2: begin
				case(wr_step)
					AW_READY: begin
						bvalid1<=0;
						bvalid2<=0;
						if(awvalid2) begin
							awready2<=awready2_flag;
							waddr<=awaddr2;
							wr_step<=WRITE;
						end
						else begin
							awready2<=!awready2_flag;
							wr_state<=WR_CHANNEL_0;
						end
					end
					WRITE: begin
						awready2<=!awready2_flag;
						if(wvalid2 && wready2) begin
							ddr_mem[waddr+0]<=wdata2[7:0];       
							ddr_mem[waddr+1]<=wdata2[15:8]; 		
							ddr_mem[waddr+2]<=wdata2[23:16];		
							ddr_mem[waddr+3]<=wdata2[31:24];		
							waddr<=waddr+4;
							wr_cnt<=wr_cnt+1;
						end 

						if(wlast2 && wr_cnt==awlen2) begin
							wr_step<=RESPONSE;
							wr_cnt<=0;
							wready2<=0;
						end
						else begin
							wready2<=1;
						end
					end
					RESPONSE: begin
						if(bready2) begin
							bvalid2<=1;
							bresp2<=OKAY;
							wr_step<=AW_READY;
							wr_state<=WR_CHANNEL_0;
						end
					end
				endcase
			end
		endcase
	end

//ddr read
always @ (posedge sys_clk or posedge rst)
	if(rst) begin
		rd_state<=RD_CHANNEL_0;
		rd_step<=AW_READY;
		rd_cnt<=0;
		arready0<=!arready0_flag;
		rvalid0<=0;
		rlast0<=0;
		arready1<=!arready1_flag;
		rvalid1<=0;
		rlast1<=0;
		arready2<=!arready2_flag;
		rvalid2<=0;
		rlast2<=0;
	end
	else begin
		case(rd_state)
			RD_CHANNEL_0: begin
				case(rd_step) 
					AR_READY: begin
						rvalid2<=0;
						rlast2<=0;
						if(arvalid0) begin
							arready0<=arready0_flag;
							rd_step<=READ;
							raddr<=araddr0;
						end
						else begin
							arready0<=!arready0_flag;
							rd_state<=RD_CHANNEL_1;
						end
					end
					READ: begin
						arready0<=!arready0_flag;
						rdata0<={ddr_mem[raddr+7],ddr_mem[raddr+6],ddr_mem[raddr+5],ddr_mem[raddr+4],
								 ddr_mem[raddr+3],ddr_mem[raddr+2],ddr_mem[raddr+1],ddr_mem[raddr]};
						if(rd_cnt==arlen0 && rready0) begin
							rd_cnt<=0;
							rvalid0<=1;
							rlast0<=1;
							rd_step<=AR_READY;
							rd_state<=RD_CHANNEL_1;
						end
						else if(rready0) begin
							rvalid0<=1;
							rd_cnt<=rd_cnt+1;
							raddr<=raddr+8;
						end
					end
				endcase
			end
			RD_CHANNEL_1: begin
				case(rd_step) 
					AR_READY: begin
						rvalid0<=0;
						rlast0<=0;
						if(arvalid1) begin
							arready1<=arready1_flag;
							rd_step<=READ;
							raddr<=araddr1;
						end
						else begin
							arready1<=!arready1_flag;
							rd_state<=RD_CHANNEL_2;
						end
					end
					READ: begin
						arready1<=!arready1_flag;
						rdata1<={ddr_mem[raddr+31],ddr_mem[raddr+30],ddr_mem[raddr+29],ddr_mem[raddr+28],
								 ddr_mem[raddr+27],ddr_mem[raddr+26],ddr_mem[raddr+25],ddr_mem[raddr+24],
								 ddr_mem[raddr+23],ddr_mem[raddr+22],ddr_mem[raddr+21],ddr_mem[raddr+20],
								 ddr_mem[raddr+19],ddr_mem[raddr+18],ddr_mem[raddr+17],ddr_mem[raddr+16],
								 ddr_mem[raddr+15],ddr_mem[raddr+14],ddr_mem[raddr+13],ddr_mem[raddr+12],
								 ddr_mem[raddr+11],ddr_mem[raddr+10],ddr_mem[raddr+9],ddr_mem[raddr+8],
								 ddr_mem[raddr+7],ddr_mem[raddr+6],ddr_mem[raddr+5],ddr_mem[raddr+4],
								 ddr_mem[raddr+3],ddr_mem[raddr+2],ddr_mem[raddr+1],ddr_mem[raddr]};
						if(rd_cnt==arlen1 && rready1) begin
							rd_cnt<=0;
							rvalid1<=1;
							rlast1<=1;
							rd_step<=AR_READY;
							rd_state<=RD_CHANNEL_2;
						end
						else if(rready1) begin
							rvalid1<=1;
							rd_cnt<=rd_cnt+1;
							raddr<=raddr+32;
						end
					end
				endcase
			end
			RD_CHANNEL_2: begin
				case(rd_step) 
					AR_READY: begin
						rvalid1<=0;
						rlast1<=0;
						if(arvalid2) begin
							arready2<=arready2_flag;
							rd_step<=READ;
							raddr<=araddr2;
						end
						else begin
							arready2<=!arready2_flag;
							rd_state<=RD_CHANNEL_0;
						end
					end
					READ: begin
						arready2<=!arready2_flag;
						rdata2<={ddr_mem[raddr+31],ddr_mem[raddr+30],ddr_mem[raddr+29],ddr_mem[raddr+28],
								 ddr_mem[raddr+27],ddr_mem[raddr+26],ddr_mem[raddr+25],ddr_mem[raddr+24],
								 ddr_mem[raddr+23],ddr_mem[raddr+22],ddr_mem[raddr+21],ddr_mem[raddr+20],
								 ddr_mem[raddr+19],ddr_mem[raddr+18],ddr_mem[raddr+17],ddr_mem[raddr+16],
								 ddr_mem[raddr+15],ddr_mem[raddr+14],ddr_mem[raddr+13],ddr_mem[raddr+12],
								 ddr_mem[raddr+11],ddr_mem[raddr+10],ddr_mem[raddr+9],ddr_mem[raddr+8],
								 ddr_mem[raddr+7],ddr_mem[raddr+6],ddr_mem[raddr+5],ddr_mem[raddr+4],
								 ddr_mem[raddr+3],ddr_mem[raddr+2],ddr_mem[raddr+1],ddr_mem[raddr]};
						if(rd_cnt==arlen2 && rready2) begin
							rd_cnt<=0;
							rvalid2<=1;
							rlast2<=1;
							rd_step<=AR_READY;
							rd_state<=RD_CHANNEL_0;
						end
						else if(rready2) begin
							rvalid2<=1;
							rd_cnt<=rd_cnt+1;
							raddr<=raddr+32;
						end
					end
				endcase
			end
		endcase
	end

endmodule