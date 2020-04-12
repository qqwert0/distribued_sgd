`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/03/02 00:06:40
// Design Name: 
// Module Name: xdma_app
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


module xdma_app #(
  parameter TCQ                         = 1,
  parameter C_M_AXI_ID_WIDTH            = 4,
  parameter PL_LINK_CAP_MAX_LINK_WIDTH  = 16,
  parameter C_DATA_WIDTH                = 512,
  parameter C_M_AXI_DATA_WIDTH          = C_DATA_WIDTH,
  parameter C_S_AXI_DATA_WIDTH          = C_DATA_WIDTH,
  parameter C_S_AXIS_DATA_WIDTH         = C_DATA_WIDTH,
  parameter C_M_AXIS_DATA_WIDTH         = C_DATA_WIDTH,
  parameter C_M_AXIS_RQ_USER_WIDTH      = ((C_DATA_WIDTH == 512) ? 137 : 62),
  parameter C_S_AXIS_CQP_USER_WIDTH     = ((C_DATA_WIDTH == 512) ? 183 : 88),
  parameter C_M_AXIS_RC_USER_WIDTH      = ((C_DATA_WIDTH == 512) ? 161 : 75),
  parameter C_S_AXIS_CC_USER_WIDTH      = ((C_DATA_WIDTH == 512) ?  81 : 33),
  parameter C_S_KEEP_WIDTH              = C_S_AXI_DATA_WIDTH / 32,
  parameter C_M_KEEP_WIDTH              = (C_M_AXI_DATA_WIDTH / 32),
  parameter C_XDMA_NUM_CHNL             = 1
)
(

    // Axi Lite Control interface
    //axi_lite.slave     s_axil,
    // AXI MM Control Interface
    axi_mm.slave       s_axim,

    // AXI Stream Interface
    // axi_stream.master   m_axis_c2h_data,
    // axi_stream.slave    s_axis_h2c_data,

  // System IO signals
  input  wire         user_resetn,
  input  wire         sys_rst_n,
 
  input  wire         user_clk,
  input  wire         user_lnk_up,
  output wire   [3:0] leds

);
  // wire/reg declarations
  wire            sys_reset;
  reg  [25:0]     user_clk_heartbeat;


  // The sys_rst_n input is active low based on the core configuration
  assign sys_resetn = sys_rst_n;

  // Create a Clock Heartbeat
  always @(posedge user_clk) begin
    if(!sys_resetn) begin
      user_clk_heartbeat <= #TCQ 26'd0;
    end else begin
      user_clk_heartbeat <= #TCQ user_clk_heartbeat + 1'b1;
    end
  end

  // LEDs for observation
  assign leds[0] = sys_resetn;
  assign leds[1] = user_resetn;
  assign leds[2] = user_lnk_up;
  assign leds[3] = user_clk_heartbeat[25];

      // AXI streaming ports
    //   assign m_axis_c2h_data.data =  s_axis_h2c_data.data;   
    //   assign m_axis_c2h_data.last =  s_axis_h2c_data.last;   
    //   assign m_axis_c2h_data.valid =  s_axis_h2c_data.valid;   
    //   assign m_axis_c2h_data.keep =  s_axis_h2c_data.keep;  
    //   assign s_axis_h2c_data.ready = m_axis_c2h_data.ready;

  // Block ram for the AXI Lite interface
//   blk_mem_gen_0 blk_mem_axiLM_inst (
//     .s_aclk        (user_clk),
//     .s_aresetn     (user_resetn),
//     .s_axi_awaddr  (s_axil.awaddr[31:0]),
//     .s_axi_awvalid (s_axil.awvalid),
//     .s_axi_awready (s_axil.awready),
//     .s_axi_wdata   (s_axil.wdata),
//     .s_axi_wstrb   (s_axil.wstrb),
//     .s_axi_wvalid  (s_axil.wvalid),
//     .s_axi_wready  (s_axil.wready),
//     .s_axi_bresp   (s_axil.bresp),
//     .s_axi_bvalid  (s_axil.bvalid),
//     .s_axi_bready  (s_axil.bready),
//     .s_axi_araddr  (s_axil.araddr[31:0]),
//     .s_axi_arvalid (s_axil.arvalid),
//     .s_axi_arready (s_axil.arready),
//     .s_axi_rdata   (s_axil.rdata),
//     .s_axi_rresp   (s_axil.rresp),
//     .s_axi_rvalid  (s_axil.rvalid),
//     .s_axi_rready  (s_axil.rready)
//   );

  // AXI stream interface for the CQ forwarding
  axi_bram_ctrl_1 axi_bram_gen_bypass_inst (
    .s_axi_aclk      (user_clk),
    .s_axi_aresetn   (user_resetn),
    .s_axi_awid      (s_axim.awid ),
    .s_axi_awaddr    (s_axim.awaddr[18:0]),
    .s_axi_awlen     (s_axim.awlen),
    .s_axi_awsize    (s_axim.awsize),
    .s_axi_awburst   (s_axim.awburst),
    .s_axi_awlock    (1'd0),
    .s_axi_awcache   (4'd0),
    .s_axi_awprot    (3'd0),
    .s_axi_awvalid   (s_axim.awvalid),
    .s_axi_awready   (s_axim.awready),
    .s_axi_wdata     (s_axim.wdata),
    .s_axi_wstrb     (s_axim.wstrb),
    .s_axi_wlast     (s_axim.wlast),
    .s_axi_wvalid    (s_axim.wvalid),
    .s_axi_wready    (s_axim.wready),
    .s_axi_bid       (s_axim.bid),
    .s_axi_bresp     (s_axim.bresp),
    .s_axi_bvalid    (s_axim.bvalid),
    .s_axi_bready    (s_axim.bready),
    .s_axi_arid      (s_axim.arid),
    .s_axi_araddr    (s_axim.araddr[18:0]),
    .s_axi_arlen     (s_axim.arlen),
    .s_axi_arsize    (s_axim.arsize),
    .s_axi_arburst   (s_axim.arburst),
    .s_axi_arlock    (1'd0),
    .s_axi_arcache   (4'd0),
    .s_axi_arprot    (3'd0),
    .s_axi_arvalid   (s_axim.arvalid),
    .s_axi_arready   (s_axim.arready),
    .s_axi_rid       (s_axim.rid),
    .s_axi_rdata     (s_axim.rdata),
    .s_axi_rresp     (s_axim.rresp),
    .s_axi_rlast     (s_axim.rlast),
    .s_axi_rvalid    (s_axim.rvalid),
    .s_axi_rready    (s_axim.rready )
  );


endmodule
