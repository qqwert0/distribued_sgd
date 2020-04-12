//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/02/20 19:18:58
// Design Name: 
// Module Name: sgd_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ps / 1ps
//`default_nettype none

`include "sgd_defines.vh"

module sgd_top(
    output wire[15 : 0] pcie_tx_p,
    output wire[15 : 0] pcie_tx_n,
    input wire[15 : 0]  pcie_rx_p,
    input wire[15 : 0]  pcie_rx_n,

    input wire					 sys_clk_p,
    input wire					 sys_clk_n,
    input wire					 sys_rst_n,

	output wire					led,

     input wire           sys_100M_p,
     input wire           sys_100M_n
    );
    
	assign led = 1'b0;

/*
 * Clock & Reset Signals
 */
wire sys_reset;
wire sys_100M;
wire sys_clk_100M;
// User logic clock & reset
wire user_clk;
wire user_aresetn;




     IBUFDS #(
       .IBUF_LOW_PWR("TRUE")     // Low power="TRUE", Highest performance="FALSE" 
    ) IBUFDS0_inst (
       .O(sys_100M),  // Buffer output
       .I(sys_100M_p),  // Diff_p buffer input (connect directly to top-level port)
       .IB(sys_100M_n) // Diff_n buffer input (connect directly to top-level port)
    );
 
   
      BUFG BUFG0_inst (
       .O(sys_clk_100M), // 1-bit output: Clock output
       .I(sys_100M)  // 1-bit input: Clock input
    );


// DMA Signals
axis_mem_cmd    axis_dma_read_cmd();
axis_mem_cmd    axis_dma_write_cmd();
axi_stream      axis_dma_read_data();
axi_stream      axis_dma_write_data();

//mlweaving parameter
reg         	m_axis_mlweaving_valid;
wire         	m_axis_mlweaving_ready;
reg[511:0]  	m_axis_mlweaving_data;

//test dma speed
reg [31:0]		rd_cnt;
reg [31:0]		wr_cnt;

/*
 * PCIe Signals
 */
wire pcie_lnk_up;
wire pcie_ref_clk;
wire pcie_ref_clk_gt;
wire perst_n;

// PCIe user clock & reset
wire pcie_clk;
wire pcie_aresetn;


  // Ref clock buffer
  IBUFDS_GTE4 # (.REFCLK_HROW_CK_SEL(2'b00)) refclk_ibuf (.O(pcie_ref_clk_gt), .ODIV2(pcie_ref_clk), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));
  // Reset buffer
  IBUF   sys_reset_n_ibuf (.O(perst_n), .I(sys_rst_n));

/*
 * DMA Signals
 */
//Axi Lite Control Bus
axi_lite        axil_control();
axi_mm          axim_control();

wire        c2h_dsc_byp_load_0;
wire        c2h_dsc_byp_ready_0;
wire[63:0]  c2h_dsc_byp_addr_0;
wire[31:0]  c2h_dsc_byp_len_0;

wire        h2c_dsc_byp_load_0;
wire        h2c_dsc_byp_ready_0;
wire[63:0]  h2c_dsc_byp_addr_0;
wire[31:0]  h2c_dsc_byp_len_0;

axi_stream  axis_dma_c2h();
axi_stream  axis_dma_h2c();

wire[7:0] c2h_sts_0;
wire[7:0] h2c_sts_0;


    
/*
 * DMA Driver
 */
dma_driver dma_driver_inst (
  .sys_clk(pcie_ref_clk),                                       // input wire sys_clk
  .sys_clk_gt(pcie_ref_clk_gt),
  .sys_rst_n(perst_n),                                          // input wire sys_rst_n
  .user_lnk_up(pcie_lnk_up),                                    // output wire user_lnk_up
  .pcie_tx_p(pcie_tx_p),                                        // output wire [7 : 0] pci_exp_txp
  .pcie_tx_n(pcie_tx_n),                                        // output wire [7 : 0] pci_exp_txn
  .pcie_rx_p(pcie_rx_p),                                        // input wire [7 : 0] pci_exp_rxp
  .pcie_rx_n(pcie_rx_n),                                        // input wire [7 : 0] pci_exp_rxn
  .pcie_clk(pcie_clk),                                          // output wire axi_aclk
  .pcie_aresetn(pcie_aresetn),                                  // output wire axi_aresetn
  //.usr_irq_req(1'b0),                                         // input wire [0 : 0] usr_irq_req
  //.usr_irq_ack(),                                             // output wire [0 : 0] usr_irq_ack
  //.msi_enable(),                                              // output wire msi_enable
  //.msi_vector_width(),                                        // output wire [2 : 0] msi_vector_width
  
 // Axi Lite Control Master interface   
  .m_axil(axil_control),
  // AXI MM Control Interface 
  .m_axim(axim_control),

  // AXI Stream Interface
  .s_axis_c2h_data(axis_dma_c2h),
  .m_axis_h2c_data(axis_dma_h2c),

  // Descriptor Bypass
  .c2h_dsc_byp_ready_0    (c2h_dsc_byp_ready_0),
  //.c2h_dsc_byp_src_addr_0 (64'h0),
  .c2h_dsc_byp_addr_0     (c2h_dsc_byp_addr_0),
  .c2h_dsc_byp_len_0      (c2h_dsc_byp_len_0),
  //.c2h_dsc_byp_ctl_0      (16'h13), //was 16'h3
  .c2h_dsc_byp_load_0     (c2h_dsc_byp_load_0),
  
  .h2c_dsc_byp_ready_0    (h2c_dsc_byp_ready_0),
  .h2c_dsc_byp_addr_0     (h2c_dsc_byp_addr_0),
  //.h2c_dsc_byp_dst_addr_0 (64'h0),
  .h2c_dsc_byp_len_0      (h2c_dsc_byp_len_0),
  //.h2c_dsc_byp_ctl_0      (16'h13), //was 16'h3
  .h2c_dsc_byp_load_0     (h2c_dsc_byp_load_0),
  
  .c2h_sts_0(c2h_sts_0),                                          // output wire [7 : 0] c2h_sts_0
  .h2c_sts_0(h2c_sts_0)                                           // output wire [7 : 0] h2c_sts_0
);    
    

// XDMA taget application
  xdma_app #(
    .C_M_AXI_ID_WIDTH(4)
  ) xdma_app_i (

    // Axi Lite Control interface
    //.s_axil(axil_control),
    // AXI MM Control Interface
    .s_axim(axim_control),

    // AXI Stream Interface
    // .m_axis_c2h_data(axis_dma_c2h),
    // .s_axis_h2c_data(axis_dma_h2c),

      .user_clk(pcie_clk),
      .user_resetn(pcie_aresetn),
      .user_lnk_up(user_lnk_up),
      .sys_rst_n(perst_n),

      .leds()
  );



/*
 * DMA Interface
 */

dma_inf dma_interface (
    .pcie_clk(pcie_clk),
    .pcie_aresetn(pcie_aresetn),
    .user_clk(pcie_clk),
    .user_aresetn(pcie_aresetn),

    // USER INTERFACE 
    .s_axis_dma_read_cmd            (axis_dma_read_cmd),
    .s_axis_dma_write_cmd           (axis_dma_write_cmd),

    .m_axis_dma_read_data           (axis_dma_read_data),
    .s_axis_dma_write_data          (axis_dma_write_data),

    //mlweaving parameter
    .m_axis_mlweaving_valid             (m_axis_mlweaving_valid),
    .m_axis_mlweaving_ready             (m_axis_mlweaving_ready),
    .m_axis_mlweaving_data              (m_axis_mlweaving_data), 

	////test dma speed
	.rd_cnt							(rd_cnt),
	.wr_cnt							(wr_cnt),				

    // DRIVER INTERFACE 
    // Control interface
    .s_axil(axil_control),

    // Data
    .m_axis_c2h_data(axis_dma_c2h),
    .s_axis_h2c_data(axis_dma_h2c),

    .c2h_dsc_byp_load_0(c2h_dsc_byp_load_0),
    .c2h_dsc_byp_ready_0(c2h_dsc_byp_ready_0),
    .c2h_dsc_byp_addr_0(c2h_dsc_byp_addr_0),
    .c2h_dsc_byp_len_0(c2h_dsc_byp_len_0),

    .h2c_dsc_byp_load_0(h2c_dsc_byp_load_0),
    .h2c_dsc_byp_ready_0(h2c_dsc_byp_ready_0),
    .h2c_dsc_byp_addr_0(h2c_dsc_byp_addr_0),
    .h2c_dsc_byp_len_0(h2c_dsc_byp_len_0),

    .c2h_sts_0(c2h_sts_0),
    .h2c_sts_0(h2c_sts_0)

);

axi_mm          hbm_axi[32]();
wire            hbm_clk;
wire            hbm_rstn;

hbm_driver inst_hbm_driver(

    .sys_clk_100M(sys_clk_100M),
    .hbm_axi(hbm_axi),
    .hbm_clk(hbm_clk),
    .hbm_rstn(hbm_rstn)
    );


hbm_interface inst_hbm_interface(
    .user_clk(pcie_clk),
    .user_aresetn(pcie_aresetn),

    .hbm_clk(hbm_clk),
    .hbm_rstn(hbm_rstn),

    //mlweaving parameter
    .m_axis_mlweaving_valid(m_axis_mlweaving_valid),
    .m_axis_mlweaving_ready(m_axis_mlweaving_ready),
    .m_axis_mlweaving_data(m_axis_mlweaving_data),

    /* DMA INTERFACE */
    //Commands
    .m_axis_dma_read_cmd(axis_dma_read_cmd),
    .m_axis_dma_write_cmd(axis_dma_write_cmd),

    //Data streams
    .m_axis_dma_write_data(axis_dma_write_data),
    .s_axis_dma_read_data(axis_dma_read_data),
    
    /* HBM INTERFACE */
    .hbm_axi(hbm_axi)

    );
//////////////////hbm debug/////////////////


//ila_0 ila_write_inst (
//	.clk(pcie_clk), // input wire clk


//	.probe0(axis_dma_write_cmd.valid), // input wire [0:0]  probe0  
//	.probe1(axis_dma_write_cmd.ready), // input wire [0:0]  probe1 
//	.probe2(axis_dma_write_cmd.address), // input wire [63:0]  probe2 
//	.probe3(axis_dma_write_cmd.length), // input wire [31:0]  probe3 
//	.probe4(axis_dma_write_data.valid), // input wire [0:0]  probe4 
//	.probe5(axis_dma_write_data.ready), // input wire [0:0]  probe5 
//	.probe6(axis_dma_write_data.data) // input wire [511:0]  probe6
//);

//ila_0 ila_read_inst (
//	.clk(pcie_clk), // input wire clk


//	.probe0(axis_dma_read_cmd.valid), // input wire [0:0]  probe0  
//	.probe1(axis_dma_read_cmd.ready), // input wire [0:0]  probe1 
//	.probe2(axis_dma_read_cmd.address), // input wire [63:0]  probe2 
//	.probe3(axis_dma_read_cmd.length), // input wire [31:0]  probe3 
//	.probe4(axis_dma_read_data.valid), // input wire [0:0]  probe4 
//	.probe5(axis_dma_read_data.ready), // input wire [0:0]  probe5 
//	.probe6(axis_dma_read_data.data) // input wire [511:0]  probe6
//);





//MLWEAVING PARAMETER REG
// reg [63:0] addr_a;
// reg [63:0] addr_b;
// reg [63:0] addr_model;
// reg [31:0] mini_batch_size;
// reg [31:0] step_size;
// reg [31:0] number_of_epochs;
// reg [31:0] dimension;
// reg [31:0] number_of_samples;
// reg [31:0] number_of_bits;   
// reg [31:0] data_a_length;
// reg [31:0] array_length;
// reg [31:0] channel_choice;

// reg [511:0] dma_read_data;

//   wire            	start;
//   reg				start_d;


// always @(posedge hbm_clk)begin
// 	start_d <= start;
// end

// always @(posedge hbm_clk)begin
//     if(~hbm_rstn)begin
//         m_axis_mlweaving_data           <= 512'b0;
//     end
//     else begin
//         m_axis_mlweaving_data[ 63:0  ]  <= addr_a;
//         m_axis_mlweaving_data[127:64 ]  <= addr_b;
//         m_axis_mlweaving_data[191:128]  <= addr_model;
//         m_axis_mlweaving_data[223:192]  <= mini_batch_size;
//         m_axis_mlweaving_data[255:224]  <= step_size;
//         m_axis_mlweaving_data[287:256]  <= number_of_epochs;
//         m_axis_mlweaving_data[319:288]  <= dimension;    
//         m_axis_mlweaving_data[351:320]  <= number_of_samples;
//         m_axis_mlweaving_data[383:352]  <= number_of_bits;  
//         m_axis_mlweaving_data[415:384]  <= data_a_length;   
//         m_axis_mlweaving_data[447:416]  <= array_length;
//         m_axis_mlweaving_data[479:448]  <= channel_choice;
//     end
// end

// vio_0 your_instance_name (
//   .clk(hbm_clk),                  // input wire clk
//   .probe_out0(addr_a),    // output wire [63 : 0] probe_out0
//   .probe_out1(addr_b),    // output wire [63 : 0] probe_out1
//   .probe_out2(addr_model),    // output wire [63 : 0] probe_out2
//   .probe_out3(mini_batch_size),    // output wire [31 : 0] probe_out3
//   .probe_out4(step_size),    // output wire [31 : 0] probe_out4
//   .probe_out5(number_of_epochs),    // output wire [31 : 0] probe_out5
//   .probe_out6(dimension),    // output wire [31 : 0] probe_out6
//   .probe_out7(number_of_samples),    // output wire [31 : 0] probe_out7
//   .probe_out8(number_of_bits),    // output wire [31 : 0] probe_out8
//   .probe_out9(data_a_length),    // output wire [31 : 0] probe_out9
//   .probe_out10(array_length),  // output wire [31 : 0] probe_out10
//   .probe_out11(channel_choice),  // output wire [31 : 0] probe_out11
//   .probe_out12(start)  // output wire [0 : 0] probe_out12
// );



// always @(posedge hbm_clk)begin	
// 	if(~hbm_rstn)
// 		m_axis_mlweaving_valid		<= 1'b0;
// 	else if(start & ~start_d)
// 		m_axis_mlweaving_valid		<= 1'b1;
// 	else
// 		m_axis_mlweaving_valid		<= 1'b0;
// end



//     always @(posedge hbm_clk) begin 
//         if(~hbm_rstn)  
//             dma_read_data       <= 0;
//         else if(axis_dma_read_data.valid & axis_dma_read_data.ready)
//             dma_read_data       <= dma_read_data + 1;
//         else
//             dma_read_data       <= dma_read_data;
//     end

// always @(posedge hbm_clk)begin	
// 	if(~hbm_rstn)
// 		axis_dma_read_data.valid		<= 1'b0;
// 	else if(start & ~start_d)
// 		axis_dma_read_data.valid		<= 1'b1;
// 	else
// 		axis_dma_read_data.valid		<= axis_dma_read_data.valid;
// end


//     assign axis_dma_read_cmd.ready = 1;
//     assign axis_dma_write_cmd.ready = 1;
//     assign axis_dma_write_data.ready = 1;
//     //assign axis_dma_read_data.valid = 1;
//     assign axis_dma_read_data.keep = {64{1'b1}};
//     assign axis_dma_read_data.last = 0;
//     assign axis_dma_read_data.data = dma_read_data;


/////////////////////////dma debug///////////
/*
  reg            	read_start;
  reg				read_start_d;
  reg            	write_start;
  reg				write_start_d;
  reg [31:0]		axis_dma_write_data_cnt;
  reg [31:0]		axis_dma_write_data_length;
  reg [31:0]		axis_dma_read_data_cnt;
  reg [31:0]		axis_dma_read_data_length;
  reg [31:0]		ops;

  reg [31:0]		read_cnt;
  reg [31:0]		write_cnt;
  reg 				read_cnt_en;
  reg 				write_cnt_en;
  reg [31:0]		wr_op_cnt;
  reg [31:0]		rd_op_cnt;
  reg [31:0]		wr_op_data_cnt;
  reg [31:0]		rd_op_data_cnt;  

assign user_clk = pcie_clk;
assign user_aresetn = pcie_aresetn;

always @(posedge user_clk)begin
	read_start_d <= read_start;
	write_start_d <= write_start;
end

////dma throughput cnt
always @(posedge user_clk)begin
	if(~pcie_aresetn)
		read_cnt_en <= 1'b0;
	else if(read_start && ~read_start_d)
		read_cnt_en <= 1'b1;
	else if(rd_op_data_cnt == ops)
		read_cnt_en <=  1'b0;
	else 
		read_cnt_en <= read_cnt_en;
end

always @(posedge user_clk)begin
	if(~pcie_aresetn)
		read_cnt <= 0;
	else if(read_cnt_en)
		read_cnt <= read_cnt + 1'b1;
	else 
		read_cnt <= 0;
end

always @(posedge user_clk)begin
	if(~pcie_aresetn)
		rd_cnt <= 0;
	else if((rd_op_data_cnt == (ops-1))&&(axis_dma_read_data_cnt == axis_dma_read_data_length))
		rd_cnt <= read_cnt;
	else 
		rd_cnt <= rd_cnt;
end

always @(posedge user_clk)begin
	if(~pcie_aresetn)
		rd_op_cnt <= 0;
	else if(m_axis_mlweaving_ready && m_axis_mlweaving_valid)
		rd_op_cnt <= 0;
	else if(axis_dma_read_cmd.valid && axis_dma_read_cmd.ready)
		rd_op_cnt <= rd_op_cnt + 1'b1;
	else 
		rd_op_cnt <= rd_op_cnt;
end


always @(posedge user_clk)begin
	if(~pcie_aresetn)
		rd_op_data_cnt <= 0;
	else if(m_axis_mlweaving_ready && m_axis_mlweaving_valid)
		rd_op_data_cnt <= 0;
	else if(axis_dma_read_data_cnt == axis_dma_read_data_length)
		rd_op_data_cnt <= rd_op_data_cnt + 1'b1;
	else 
		rd_op_data_cnt <= rd_op_data_cnt;
end


always @(posedge user_clk)begin
	if(~pcie_aresetn)
		write_cnt_en <= 1'b0;
	else if(write_start && ~write_start_d)
		write_cnt_en <= 1'b1;
	else if(wr_op_data_cnt == ops)
		write_cnt_en <=  1'b0;
	else 
		write_cnt_en <= write_cnt_en;
end

always @(posedge user_clk)begin
	if(~pcie_aresetn)
		write_cnt <= 0;
	else if(write_cnt_en)
		write_cnt <= write_cnt + 1'b1;
	else 
		write_cnt <= 0;
end


always @(posedge user_clk)begin
	if(~pcie_aresetn)
		wr_cnt <= 0;
	else if((wr_op_data_cnt == (ops-1))&&(axis_dma_write_data_cnt == axis_dma_write_data_length))
		wr_cnt <= write_cnt;
	else 
		wr_cnt <= wr_cnt;
end

always @(posedge user_clk)begin
	if(~pcie_aresetn)
		wr_op_cnt <= 0;
	else if(m_axis_mlweaving_ready && m_axis_mlweaving_valid)
		wr_op_cnt <= 0;
	else if(axis_dma_write_cmd.valid && axis_dma_write_cmd.ready)
		wr_op_cnt <= wr_op_cnt + 1'b1;
	else 
		wr_op_cnt <= wr_op_cnt;
end

always @(posedge user_clk)begin
	if(~pcie_aresetn)
		wr_op_data_cnt <= 0;
	else if(m_axis_mlweaving_ready && m_axis_mlweaving_valid)
		wr_op_data_cnt <= 0;
	else if(axis_dma_write_data_cnt == axis_dma_write_data_length)
		wr_op_data_cnt <= wr_op_data_cnt + 1'b1;
	else 
		wr_op_data_cnt <= wr_op_data_cnt;
end

/////////////////////







always @(posedge user_clk)begin
	if(~pcie_aresetn)
		axis_dma_read_cmd.valid <= 1'b0;
	else if(read_start && ~read_start_d)
		axis_dma_read_cmd.valid <= 1'b1;
	else if(axis_dma_read_cmd.valid && axis_dma_read_cmd.ready)
		axis_dma_read_cmd.valid <= 1'b0;
	else 
		axis_dma_read_cmd.valid <= axis_dma_read_cmd.valid;
end

always @(posedge user_clk)begin
	if(~pcie_aresetn)
		axis_dma_write_cmd.valid <= 1'b0;
	else if(write_start && ~write_start_d)
		axis_dma_write_cmd.valid <= 1'b1;
	else if(axis_dma_write_cmd.valid && axis_dma_write_cmd.ready)
		axis_dma_write_cmd.valid <= 1'b0;
	else 
		axis_dma_write_cmd.valid <= axis_dma_write_cmd.valid;
end

always @(posedge user_clk)begin
	if(~pcie_aresetn)
		axis_dma_write_data_cnt <= 1'b0;
	else if(axis_dma_write_data.last)
		axis_dma_write_data_cnt <= 1'b0;
	else if(axis_dma_write_data.valid && axis_dma_write_data.ready)
		axis_dma_write_data_cnt <= axis_dma_write_data_cnt + 1;    
	else
		axis_dma_write_data_cnt <= axis_dma_write_data_cnt;
end

always @(posedge user_clk)begin
	axis_dma_write_data_length <= (axis_dma_write_cmd.length>>6) - 1;
end


always @(posedge user_clk)begin
	if(~pcie_aresetn)
		axis_dma_read_data_cnt <= 1'b0;
	else if((axis_dma_read_data_cnt == axis_dma_read_data_length) && axis_dma_read_data.valid && axis_dma_read_data.ready)
		axis_dma_read_data_cnt <= 1'b0;
	else if(axis_dma_read_data.valid && axis_dma_read_data.ready)
		axis_dma_read_data_cnt <= axis_dma_read_data_cnt + 1;    
	else
		axis_dma_read_data_cnt <= axis_dma_read_data_cnt;
end

always @(posedge user_clk)begin
	axis_dma_read_data_length <= (axis_dma_read_cmd.length>>6) - 1;
end

assign axis_dma_read_data.ready = 1'b1;
assign axis_dma_write_data.valid = 1'b1;
assign axis_dma_write_data.keep = 64'hffff_ffff_ffff_ffff;
assign axis_dma_write_data.data = axis_dma_write_data_cnt;
assign axis_dma_write_data.last = axis_dma_write_data.valid && axis_dma_write_data.ready && (axis_dma_write_data_cnt == axis_dma_write_data_length);
assign m_axis_mlweaving_ready = 1'b1; 

always @(posedge user_clk)begin
	if(~pcie_aresetn)begin
		axis_dma_read_cmd.address		<= 0;
		axis_dma_read_cmd.length		<= 0;
		read_start						<= 0;
		ops								<= 0;
	end	
	else if(m_axis_mlweaving_ready && m_axis_mlweaving_valid)begin
		axis_dma_read_cmd.address		<= m_axis_mlweaving_data[ 63:0  ];
		axis_dma_read_cmd.length		<= m_axis_mlweaving_data[223:192];
		read_start						<= m_axis_mlweaving_data[256];
		ops								<= m_axis_mlweaving_data[319:288];
	end
	else if(axis_dma_read_cmd.valid && axis_dma_read_cmd.ready)begin
		axis_dma_read_cmd.address		<= axis_dma_read_cmd.address;
		read_start						<= 0;
	end
	else if((axis_dma_read_data_cnt > 0) && (rd_op_cnt < ops))begin
		read_start						<= 1'b1;
	end
	else begin
		axis_dma_read_cmd.address		<= axis_dma_read_cmd.address;
		axis_dma_read_cmd.length		<= axis_dma_read_cmd.length;
		read_start						<= read_start;
		ops								<= ops;
	end
end


always @(posedge user_clk)begin
	if(~pcie_aresetn)begin
		axis_dma_write_cmd.address		<= 0;
		axis_dma_write_cmd.length		<= 0;
		write_start						<= 0;
	end	
	else if(m_axis_mlweaving_ready && m_axis_mlweaving_valid)begin
		axis_dma_write_cmd.address		<= m_axis_mlweaving_data[127:64 ];
		axis_dma_write_cmd.length		<= m_axis_mlweaving_data[255:224];
		write_start						<= m_axis_mlweaving_data[257];
	end
	else if(axis_dma_write_cmd.valid && axis_dma_write_cmd.ready)begin
		axis_dma_write_cmd.address		<= axis_dma_write_cmd.address;
		write_start						<= 0;
	end
	else if((axis_dma_write_data_cnt > 0)&&(wr_op_cnt < ops))begin
		write_start						<= 1'b1;
	end
	else begin
		axis_dma_write_cmd.address		<= axis_dma_write_cmd.address;
		axis_dma_write_cmd.length		<= axis_dma_write_cmd.length;
		write_start						<= write_start;	
	end
end

*/



// ila_0 inst_ila_0 (
// 	.clk(user_clk), // input wire clk


// 	.probe0(axis_dma_read_cmd.valid), // input wire [0:0]  probe0  
// 	.probe1(axis_dma_read_cmd.ready), // input wire [0:0]  probe1 
// 	.probe2(axis_dma_write_cmd.valid), // input wire [0:0]  probe2 
// 	.probe3(axis_dma_write_cmd.ready), // input wire [0:0]  probe3 
// 	.probe4(axis_dma_read_data.data), // input wire [511:0]  probe4 
// 	.probe5({32'b0,read_cnt}), // input wire [63:0]  probe5 
// 	.probe6(axis_dma_read_data_cnt), // input wire [31:0]  probe6 
// 	.probe7(axis_dma_read_data.valid), // input wire [0:0]  probe7 
// 	.probe8(axis_dma_write_data.ready), // input wire [0:0]  probe8 
// 	.probe9(axis_dma_write_data.data), // input wire [511:0]  probe9 
// 	.probe10({32'b0,write_cnt}), // input wire [63:0]  probe10 
// 	.probe11(axis_dma_write_data_cnt), // input wire [31:0]  probe11
// 	.probe12(rd_cnt), // input wire [31:0]  probe12 
// 	.probe13(wr_cnt) // input wire [31:0]  probe13
// );







//


/*

sgd_top_bw inst_sgd_top_bw(
    .clk(hbm_clk),
    .rst_n(hbm_rstn),
    //-------------------------------------------------//
    .start_um(1'b1),
    .um_params(512'b0),
    .um_done(),
    .um_state_counters(),

    .um_axi(hbm_axi[0])

);

//generate end generate
genvar i;
// Instantiate engines
generate
for(i = 1; i < 32; i++) 
begin
    
    assign hbm_axi[i].araddr    = 0;
    assign hbm_axi[i].arburst   = 2'b01;
    assign hbm_axi[i].arcache   = 4'b0;
    assign hbm_axi[i].arid      = 0;
    assign hbm_axi[i].arlen     = 8'b0;   
    assign hbm_axi[i].arlock    = 1'b0;   
    assign hbm_axi[i].arprot    = 3'b0;   
    assign hbm_axi[i].arqos     = 4'b0;   
    assign hbm_axi[i].arregion  = 4'b0;   
    assign hbm_axi[i].arsize    = 3'b0;   
    assign hbm_axi[i].arvalid   = 1'b0;   
    assign hbm_axi[i].aruser    = 0;
    assign hbm_axi[i].awaddr    = 0;  
    assign hbm_axi[i].awburst   = 2'b01;
    assign hbm_axi[i].awcache   = 4'b0;   
    assign hbm_axi[i].awid      = 0;
    assign hbm_axi[i].awlen     = 8'b0;   
    assign hbm_axi[i].awlock    = 1'b0;   
    assign hbm_axi[i].awprot    = 3'b0;   
    assign hbm_axi[i].awqos     = 4'b0;   
    assign hbm_axi[i].awregion  = 4'b0;   
    assign hbm_axi[i].awsize    = 3'b0;   
    assign hbm_axi[i].awvalid   = 1'b0;
    assign hbm_axi[i].awuser    = 0;
    assign hbm_axi[i].bready    = 1'b0;    
    assign hbm_axi[i].rready    = 1'b0;   
    assign hbm_axi[i].wdata     = 0;  
    assign hbm_axi[i].wlast     = 1'b0;
    assign hbm_axi[i].wstrb     = 0;  
    assign hbm_axi[i].wvalid    = 1'b0;   
    assign hbm_axi[i].wuser     = 0;



end
endgenerate

*/
    
endmodule
//`default_nettype wire