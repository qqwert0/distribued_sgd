`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/03/06 00:47:07
// Design Name: 
// Module Name: hbm_interface
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
`include "sgd_defines.vh"

module hbm_interface(
    input wire                  user_clk,
    input wire                  user_aresetn,

    input wire                  hbm_clk,
    input wire                  hbm_rstn,

    //mlweaving parameter
    input wire                  m_axis_mlweaving_valid,
    output wire                 m_axis_mlweaving_ready,
    input wire[511:0]           m_axis_mlweaving_data,

    /* DMA INTERFACE */
    //Commands
    axis_mem_cmd.master         m_axis_dma_read_cmd,
    axis_mem_cmd.master         m_axis_dma_write_cmd,

    //Data streams
    axi_stream.master           m_axis_dma_write_data,
    axi_stream.slave            s_axis_dma_read_data,
    
    /* HBM INTERFACE */
    axi_mm.master                hbm_axi[31:0]

    );
    
    

 /*
  * Clock Conversion Command
  */

    axis_mem_cmd                m_axis_dma_to_hbm_read_cmd();
    axis_mem_cmd                m_axis_dma_to_hbm_write_cmd();

    axi_stream                  s_axis_dma_to_hbm_read_data();
    axi_stream                  m_axis_dma_to_hbm_write_data();

    axi_stream                  s_axis_reg_read_data();
    axi_stream                  m_axis_reg_write_data();    
    
    axis_clock_converter_96 hbm_bench_read_cmd_cc_inst (
    .s_axis_aresetn(hbm_rstn),
    .s_axis_aclk(hbm_clk),
    .s_axis_tvalid(m_axis_dma_to_hbm_read_cmd.valid),   // input wire s_axis_tvalid
    .s_axis_tready(m_axis_dma_to_hbm_read_cmd.ready),   // output wire s_axis_tready
    .s_axis_tdata({m_axis_dma_to_hbm_read_cmd.length,m_axis_dma_to_hbm_read_cmd.address}),
    
    .m_axis_aresetn(user_aresetn),
    .m_axis_aclk(user_clk),
    .m_axis_tvalid(m_axis_dma_read_cmd.valid),  // output wire m_axis_tvalid
    .m_axis_tready(m_axis_dma_read_cmd.ready),  // input wire m_axis_tready
    .m_axis_tdata({m_axis_dma_read_cmd.length,m_axis_dma_read_cmd.address})
    );

     axis_clock_converter_96 hbm_bench_write_cmd_cc_inst (
     .s_axis_aresetn(hbm_rstn),
     .s_axis_aclk(hbm_clk),
     .s_axis_tvalid(m_axis_dma_to_hbm_write_cmd.valid),
     .s_axis_tready(m_axis_dma_to_hbm_write_cmd.ready),
     .s_axis_tdata({m_axis_dma_to_hbm_write_cmd.length,m_axis_dma_to_hbm_write_cmd.address}),
    
     .m_axis_aresetn(user_aresetn),
     .m_axis_aclk(user_clk),
     .m_axis_tvalid(m_axis_dma_write_cmd.valid),
     .m_axis_tready(m_axis_dma_write_cmd.ready),
     .m_axis_tdata({m_axis_dma_write_cmd.length,m_axis_dma_write_cmd.address})
     );




    //axis_clock_converter_512 dma_bench_read_data_cc_inst (
    axis_register_slice512 inst_axis_register_slice_read (
    .aclk(user_clk),                    // input wire aclk
    .aresetn(user_aresetn),              // input wire aresetn
    .s_axis_tvalid(s_axis_dma_read_data.valid),  // input wire s_axis_tvalid
    .s_axis_tready(s_axis_dma_read_data.ready),  // output wire s_axis_tready
    .s_axis_tdata(s_axis_dma_read_data.data),    // input wire [511 : 0] s_axis_tdata
    .s_axis_tkeep(s_axis_dma_read_data.keep),    // input wire [63 : 0] s_axis_tkeep
    .s_axis_tlast(s_axis_dma_read_data.last),    // input wire s_axis_tlast
    .m_axis_tvalid(s_axis_reg_read_data.valid),  // output wire m_axis_tvalid
    .m_axis_tready(s_axis_reg_read_data.ready),  // input wire m_axis_tready
    .m_axis_tdata(s_axis_reg_read_data.data),    // output wire [511 : 0] m_axis_tdata
    .m_axis_tkeep(s_axis_reg_read_data.keep),    // output wire [63 : 0] m_axis_tkeep
    .m_axis_tlast(s_axis_reg_read_data.last)    // output wire m_axis_tlast
    );

    axis_data_fifo_512_cc hbm_bench_read_data_cc_inst (
    .s_axis_aresetn(user_aresetn),
    .s_axis_aclk(user_clk),
    .s_axis_tvalid(s_axis_reg_read_data.valid),
    .s_axis_tready(s_axis_reg_read_data.ready),
    .s_axis_tdata(s_axis_reg_read_data.data),
    .s_axis_tkeep(s_axis_reg_read_data.keep),
    .s_axis_tlast(s_axis_reg_read_data.last),

    .m_axis_aclk(hbm_clk),
    .m_axis_tvalid(s_axis_dma_to_hbm_read_data.valid),
    .m_axis_tready(s_axis_dma_to_hbm_read_data.ready),
    .m_axis_tdata(s_axis_dma_to_hbm_read_data.data),
    .m_axis_tkeep(s_axis_dma_to_hbm_read_data.keep),
    .m_axis_tlast(s_axis_dma_to_hbm_read_data.last)
    
    );


     //axis_clock_converter_512 dma_bench_write_data_cc_inst (
      axis_register_slice512 inst_axis_register_slice_write (
      .aclk(user_clk),                    // input wire aclk
      .aresetn(user_aresetn),              // input wire aresetn
      .s_axis_tvalid(m_axis_reg_write_data.valid),  // input wire s_axis_tvalid
      .s_axis_tready(m_axis_reg_write_data.ready),  // output wire s_axis_tready
      .s_axis_tdata(m_axis_reg_write_data.data),    // input wire [511 : 0] s_axis_tdata
      .s_axis_tkeep(m_axis_reg_write_data.keep),    // input wire [63 : 0] s_axis_tkeep
      .s_axis_tlast(m_axis_reg_write_data.last),    // input wire s_axis_tlast
      .m_axis_tvalid(m_axis_dma_write_data.valid),  // output wire m_axis_tvalid
      .m_axis_tready(m_axis_dma_write_data.ready),  // input wire m_axis_tready
      .m_axis_tdata(m_axis_dma_write_data.data),    // output wire [511 : 0] m_axis_tdata
      .m_axis_tkeep(m_axis_dma_write_data.keep),    // output wire [63 : 0] m_axis_tkeep
      .m_axis_tlast(m_axis_dma_write_data.last)    // output wire m_axis_tlast
      );

     axis_data_fifo_512_cc hbm_bench_write_data_cc_inst (
     .s_axis_aresetn(hbm_rstn),
     .s_axis_aclk(hbm_clk),
     .s_axis_tvalid(m_axis_dma_to_hbm_write_data.valid),
     .s_axis_tready(m_axis_dma_to_hbm_write_data.ready),
     .s_axis_tdata(m_axis_dma_to_hbm_write_data.data),
     .s_axis_tkeep(m_axis_dma_to_hbm_write_data.keep),
     .s_axis_tlast(m_axis_dma_to_hbm_write_data.last),
    
     .m_axis_aclk(user_clk),
     .m_axis_tvalid(m_axis_reg_write_data.valid),
     .m_axis_tready(m_axis_reg_write_data.ready),
     .m_axis_tdata(m_axis_reg_write_data.data),
     .m_axis_tkeep(m_axis_reg_write_data.keep),
     .m_axis_tlast(m_axis_reg_write_data.last)
     );





    axis_clock_converter_512 axis_clock_converter_mlweaving_parameter (
    .s_axis_aresetn(user_aresetn),  // input wire s_axis_aresetn
    .s_axis_aclk(user_clk),        // input wire s_axis_aclk
    .s_axis_tvalid(m_axis_mlweaving_valid),    // input wire s_axis_tvalid
    .s_axis_tready(m_axis_mlweaving_ready),    // output wire s_axis_tready
    .s_axis_tdata(m_axis_mlweaving_data),
    
    .m_axis_aclk(hbm_clk),        // input wire m_axis_aclk
    .m_axis_aresetn(hbm_rstn),  // input wire m_axis_aresetn
    .m_axis_tvalid(m_axis_hbm_mlweaving_valid),    // output wire m_axis_tvalid
    .m_axis_tready(m_axis_hbm_mlweaving_ready),    // input wire m_axis_tready
    .m_axis_tdata(m_axis_hbm_mlweaving_data)      // output wire [511 : 0] m_axis_tdata
    );






    //MLWEAVING PARAMETER REG
    reg [63:0]                  addr_a;
    reg [63:0]                  addr_b;
    reg [63:0]                  addr_model;
    reg [31:0]                  mini_batch_size;
    reg [31:0]                  step_size;
    reg [31:0]                  number_of_epochs;
    reg [31:0]                  dimension;
    reg [31:0]                  number_of_samples;
    reg [31:0]                  number_of_bits; 
    reg [31:0]                  data_a_length;
    reg [31:0]                  data_b_length;
    reg [31:0]                  array_length;
    reg [31:0]                  channel_choice;
    wire                        hbm_write_done;
    reg [4:0]                   b_data_channel;

    assign m_axis_hbm_mlweaving_ready = 1'b1; 

    always @(posedge hbm_clk) begin
        if(~hbm_rstn) begin
            addr_a                      <= 0; 
            addr_b                      <= 0;
            addr_model                  <= 0;
            mini_batch_size             <= 0;
            step_size                   <= 0;
            number_of_epochs            <= 0;
            dimension                   <= 0;    
            number_of_samples           <= 0;
            number_of_bits              <= 0; 
            data_a_length               <= 0;
            array_length                <= 0;
            channel_choice              <= 0;
        end
        else if(m_axis_hbm_mlweaving_ready && m_axis_hbm_mlweaving_valid) begin
            addr_a                      <= m_axis_mlweaving_data[ 63:0  ]; 
            addr_b                      <= m_axis_mlweaving_data[127:64 ];
            addr_model                  <= m_axis_mlweaving_data[191:128];
            mini_batch_size             <= m_axis_mlweaving_data[223:192];
            step_size                   <= m_axis_mlweaving_data[255:224];
            number_of_epochs            <= m_axis_mlweaving_data[287:256];
            dimension                   <= m_axis_mlweaving_data[319:288];    
            number_of_samples           <= m_axis_mlweaving_data[351:320];
            number_of_bits              <= m_axis_mlweaving_data[383:352];   
            data_a_length               <= m_axis_mlweaving_data[415:384];
            array_length                <= m_axis_mlweaving_data[447:416];
            channel_choice              <= m_axis_mlweaving_data[479:448];
        end
        else begin
            addr_a                      <= addr_a; 
            addr_b                      <= addr_b;
            addr_model                  <= addr_model;
            mini_batch_size             <= mini_batch_size;
            step_size                   <= step_size;
            number_of_epochs            <= number_of_epochs;
            dimension                   <= dimension;    
            number_of_samples           <= number_of_samples;
            number_of_bits              <= number_of_bits; 
            data_a_length               <= data_a_length;
            array_length                <= array_length; 
            channel_choice              <= channel_choice;      
        end 
    end


    always @(posedge hbm_clk) begin
        if(~hbm_rstn) begin
            data_b_length       <= 32'b0;
        end
        else begin
            data_b_length       <= number_of_samples << 2;    
        end  
    end          

    always @(posedge hbm_clk) begin
        b_data_channel          <= `B_DATA_CHANNEL;
    end


    hbm_write#(
        .ADDR_WIDTH          (33 ),  // 8G-->33 bits
        .DATA_WIDTH          (256),  // 512-bit for DDR4
        .PARAMS_BITS         (256),  // parameter bits from PCIe
        .ID_WIDTH            (6  )   //fixme,
    )hbm_write_inst(
    .hbm_clk                (hbm_clk),
    .hbm_aresetn            (hbm_rstn),

    /* DMA INTERFACE */
    //Commands
    .m_axis_dma_read_cmd    (m_axis_dma_to_hbm_read_cmd),
    // .m_axis_dma_write_cmd   (m_axis_dma_to_hbm_write_cmd),

    //Data streams
    // .m_axis_dma_write_data  (m_axis_dma_to_hbm_write_data),
    .s_axis_dma_read_data   (s_axis_dma_to_hbm_read_data),

    //signal

    .start                  (m_axis_hbm_mlweaving_ready & m_axis_hbm_mlweaving_valid),
    .data_a_length          (data_a_length),  //need to multiple of 512
    .data_b_length          (data_b_length),  //need to multiple of 512
    .dma_addr_a             (addr_a),
    .dma_addr_b             (addr_b),
    .hbm_addr_b             ({b_data_channel,28'h8000000}),  
    .number_of_samples      (number_of_samples),  
    .dimension              (dimension),
    .number_of_bits         (number_of_bits),  
    .araddr_stride          (array_length),    
    .hbm_write_done         (hbm_write_done),              

    /* HBM INTERFACE */
    //Write addr (output)
    .m_axi_AWADDR     (hbm_axi[`B_DATA_CHANNEL].awaddr  ), //wr byte address
    .m_axi_AWBURST    (hbm_axi[`B_DATA_CHANNEL].awburst ), //wr burst type: 01 (INC), 00 (FIXED)
    .m_axi_AWID       (hbm_axi[`B_DATA_CHANNEL].awid    ), //wr address id
    .m_axi_AWLEN      (hbm_axi[`B_DATA_CHANNEL].awlen   ), //wr burst=awlen+1,
    .m_axi_AWSIZE     (hbm_axi[`B_DATA_CHANNEL].awsize  ), //wr 3'b101, 32B
    .m_axi_AWVALID    (hbm_axi[`B_DATA_CHANNEL].awvalid ), //wr address valid
    .m_axi_AWREADY    (hbm_axi[`B_DATA_CHANNEL].awready ), //wr ready to accept address.
    .m_axi_AWLOCK     (), //wr no
    .m_axi_AWCACHE    (), //wr no
    .m_axi_AWPROT     (), //wr no
    .m_axi_AWQOS      (), //wr no
    .m_axi_AWREGION   (), //wr no

    //Write data (output)  
    .m_axi_WDATA      (hbm_axi[`B_DATA_CHANNEL].wdata  ), //wr data
    .m_axi_WLAST      (hbm_axi[`B_DATA_CHANNEL].wlast  ), //wr last beat in a burst
    .m_axi_WSTRB      (hbm_axi[`B_DATA_CHANNEL].wstrb  ), //wr data strob
    .m_axi_WVALID     (hbm_axi[`B_DATA_CHANNEL].wvalid ), //wr data valid
    .m_axi_WREADY     (hbm_axi[`B_DATA_CHANNEL].wready ), //wr ready to accept data
    .m_axi_WID        (), //wr data id

    //Write response (input)  
    .m_axi_BID        (hbm_axi[`B_DATA_CHANNEL].bid    ),
    .m_axi_BRESP      (hbm_axi[`B_DATA_CHANNEL].bresp  ),
    .m_axi_BVALID     (hbm_axi[`B_DATA_CHANNEL].bvalid ), 
    .m_axi_BREADY     (hbm_axi[`B_DATA_CHANNEL].bready )
    );  


    wire [`ENGINE_NUM-1:0][255:0]   dispatch_axb_a_data;
    wire [`ENGINE_NUM-1:0][255:0]   dispatch_axb_b_data;
    wire [`ENGINE_NUM-1:0]          dispatch_axb_a_wr_en;
    wire [`ENGINE_NUM-1:0]          dispatch_axb_b_wr_en;
    wire [`ENGINE_NUM-1:0]          dispatch_axb_a_almost_full;
    wire                            almost_full;


    reg [31:0]                      data_length;
    reg [`ENGINE_NUM-1:0][31:0]     rd_sum_cnt;
    reg [`ENGINE_NUM-1:0][31:0]     rd_addr_cnt;
    reg [`ENGINE_NUM-1:0][31:0]     wr_a_counter;
    reg [`ENGINE_NUM-1:0][31:0]     wr_b_counter;
    reg [`ENGINE_NUM-1:0][31:0]     rd_addr_sum_cnt;

    //generate end generate
    genvar i;
    // Instantiate engines
    generate
    for(i = 0; i < `ENGINE_NUM; i++) begin

    hbm_read#(
        .ADDR_WIDTH       (33) ,  // 8G-->33 bits
        .DATA_WIDTH       (256),  // 512-bit for DDR4
        .PARAMS_BITS      (256),  // parameter bits from PCIe
        .ID_WIDTH         (6)     //fixme,
    )hbm_read_inst(
        .hbm_clk(hbm_clk),
        .hbm_aresetn(hbm_rstn),

        //--------------------------Begin/Stop-----------------------------//
        .start(hbm_write_done),
        .mem_op_done(),

        //---------Input: Parameters (where, how many) from the root module-------//
        .addr_a(0),
        .addr_b(33'h8000000),
        .number_of_epochs(number_of_epochs),
        .number_of_samples(number_of_samples),
        .dimension(dimension),
        .number_of_bits(number_of_bits), 
        .engine_id(i),
        .araddr_stride(array_length),
        //---------------------Memory Inferface----------------------------//

        //Read Address (Output)  
        .m_axi_ARVALID(hbm_axi[i].arvalid) , //rd address valid
        .m_axi_ARADDR(hbm_axi[i].araddr)  , //rd byte address
        .m_axi_ARID(hbm_axi[i].arid)    , //rd address id
        .m_axi_ARLEN(hbm_axi[i].arlen)  , //rd burst=awlen+1,
        .m_axi_ARSIZE(hbm_axi[i].arsize)  , //rd 3'b101, 32B
        .m_axi_ARBURST(hbm_axi[i].arburst) , //rd burst type: 01 (INC), 00 (FIXED)
        .m_axi_ARLOCK(hbm_axi[i].arlock)  , //rd no
        .m_axi_ARCACHE(hbm_axi[i].arcache) , //rd no
        .m_axi_ARPROT(hbm_axi[i].arprot)  , //rd no
        .m_axi_ARQOS(hbm_axi[i].arqos)   , //rd no
        .m_axi_ARREGION(hbm_axi[i].arregion), //rd no
        .m_axi_ARUSER()  ,
        .m_axi_ARREADY(hbm_axi[i].arready),  //rd ready to accept address.
        .rd_sum_cnt(rd_addr_sum_cnt[i]),
        .rd_addr_cnt(rd_addr_cnt[i])

        );


    hbm_dispatch 
    #(
        .DATA_WIDTH       (256),  // 512-bit for DDR4
        .ID_WIDTH         (6)     //fixme,
    )hbm_dispatch_inst(
        .clk(hbm_clk),
        .rst_n(hbm_rstn),
        //--------------------------Begin/Stop-----------------------------//
        .start(hbm_write_done),
        .data_length(data_length),
        
        .state_counters_dispatch(),

        //---------------------Input: External Memory rd response-----------------//
        //Read Data (input)
        .m_axi_RVALID(hbm_axi[i].rvalid)  , //rd data valid
        .m_axi_RDATA(hbm_axi[i].rdata)   , //rd data 
        .m_axi_RLAST(hbm_axi[i].rlast)   , //rd data last
        .m_axi_RID(hbm_axi[i].rid)     , //rd data id
        .m_axi_RRESP(hbm_axi[i].rresp)   , //rd data status. 
        .m_axi_RREADY(hbm_axi[i].rready)  ,



        //banks = 8, bits_per_bank=64...
        //------------------Output: disptach resp data to a ofeach bank---------------//
        . dispatch_axb_a_data(dispatch_axb_a_data[i]), 
        . dispatch_axb_a_wr_en(dispatch_axb_a_wr_en[i]), 
        . dispatch_axb_a_almost_full(dispatch_axb_a_almost_full), //only one of them is used to control...

        //------------------Output: disptach resp data to b of each bank---------------//
        .dispatch_axb_b_data(dispatch_axb_b_data[i]), 
        .dispatch_axb_b_wr_en(dispatch_axb_b_wr_en[i]),
        //input   wire                                     dispatch_axb_b_almost_full[`NUM_OF_BANKS-1:0],
        .wr_a_counter(wr_a_counter[i]),
 	    .wr_b_counter(wr_b_counter[i]), 
 	    .rd_sum_cnt(rd_sum_cnt[i])

    );

    end
    endgenerate


    
    wire [511:0]                     back_data;
    wire                             back_valid;
    // reg [7:0]                       channel_choice_r;

    // always @(posedge hbm_clk)begin
    //     channel_choice_r            <= channel_choice[7:0];
    // end

    // always @(posedge hbm_clk)begin
    //     if(channel_choice == 8'd32)
    //         data_length             <= data_b_length;
    //     else
    //         data_length             <= data_a_length >> `ENGINE_NUM_WIDTH;
    // end

//     ila_hbm_read your_instance_name (
// 	.clk(hbm_clk), // input wire clk


// 	.probe0(rd_addr_cnt[channel_choice_r]), // input wire [31:0]  probe0  
// 	.probe1(rd_addr_sum_cnt[channel_choice_r]), // input wire [31:0]  probe1 
// 	.probe2(rd_sum_cnt[channel_choice_r]), // input wire [31:0]  probe2 
// 	.probe3(wr_b_counter[channel_choice_r]), // input wire [31:0]  probe3 
// 	.probe4(wr_a_counter[channel_choice_r]) // input wire [31:0]  probe4
// );

    // always @(posedge hbm_clk)begin
    //     if(channel_choice == 8'd32)begin
    //         back_data               <= dispatch_axb_b_data[`ENGINE_NUM/2];
    //         back_valid              <= dispatch_axb_b_wr_en[`ENGINE_NUM/2];
    //     end
    //     else begin
    //         back_data               <= dispatch_axb_a_data[channel_choice_r[6:0]];
    //         back_valid              <= dispatch_axb_a_wr_en[channel_choice_r[6:0]];
    //     end
    // end

sgd_top_bw #( 
    .DATA_WIDTH_IN               (4),
    .MAX_DIMENSION_BITS          (18)
)sgd_top_bw_inst (
    .clk                                (hbm_clk),
    .rst_n                              (hbm_rstn),
    //-------------------------------------------------//
    .start_um                           (hbm_write_done),
    .um_params                          (m_axis_mlweaving_data),
    .um_done                            (),
    .um_state_counters                  (),


    .dispatch_axb_a_data                (dispatch_axb_a_data),
    .dispatch_axb_a_wr_en               (dispatch_axb_a_wr_en),
    .dispatch_axb_a_almost_full         (dispatch_axb_a_almost_full),

    .dispatch_axb_b_data                (dispatch_axb_b_data[`ENGINE_NUM/2]),
    .dispatch_axb_b_wr_en               (dispatch_axb_b_wr_en[`ENGINE_NUM/2]),
    .dispatch_axb_b_almost_full         (),
    //---------------------Memory Inferface:write----------------------------//
    //cmd
    .x_data_send_back_start             (x_data_send_back_start),
    .x_data_send_back_addr              (x_data_send_back_addr),
    .x_data_send_back_length            (x_data_send_back_length),

    //data
    .x_data_out                         (back_data),
    .x_data_out_valid                   (back_valid),
    .x_data_out_almost_full             (almost_full)

);
   hbm_send_back  u_hbm_send_back (
       .hbm_clk                                            ( hbm_clk                                             ),
       .hbm_aresetn                                        ( hbm_rstn                                            ),
       .m_axis_dma_write_cmd                               ( m_axis_dma_to_hbm_write_cmd                         ),
       .m_axis_dma_write_data                              ( m_axis_dma_to_hbm_write_data                        ),
       .start                                              ( x_data_send_back_start                              ),
       .addr_x                                             ( addr_modex_data_send_back_addr                      ),
       .data_length                                        ( x_data_send_back_length                             ),
       .back_data                                          ( back_data                                           ),
       .back_valid                                         ( back_valid                                          ),

       .almost_full                                        ( almost_full                                         )
   );

    // hbm_send_back  u_hbm_send_back (
    //     .hbm_clk                                            ( hbm_clk                                             ),
    //     .hbm_aresetn                                        ( hbm_rstn                                            ),
    //     .m_axis_dma_write_cmd                               ( m_axis_dma_to_hbm_write_cmd                         ),
    //     .m_axis_dma_write_data                              ( m_axis_dma_to_hbm_write_data                        ),
    //     .start                                              ( hbm_write_done                                      ),
    //     .addr_x                                             ( addr_model                                          ),
    //     .data_length                                        ( data_length                                         ),
    //     .back_data                                          ( back_data                                           ),
    //     .back_valid                                         ( back_valid                                          ),

    //     .almost_full                                        ( almost_full                                         )
    // );   

// ila_hbm_inf ila_hbm_inf_inst (
// 	.clk(hbm_clk), // input wire clk


// 	.probe0(addr_a), // input wire [63:0]  probe0  
// 	.probe1(addr_b), // input wire [63:0]  probe1 
// 	.probe2(addr_model), // input wire [63:0]  probe2 
// 	.probe3(mini_batch_size), // input wire [31:0]  probe3 
// 	.probe4(step_size), // input wire [31:0]  probe4 
// 	.probe5(number_of_epochs), // input wire [31:0]  probe5 
// 	.probe6(dimension), // input wire [31:0]  probe6 
// 	.probe7(number_of_samples), // input wire [31:0]  probe7 
// 	.probe8(number_of_bits), // input wire [31:0]  probe8 
// 	.probe9(data_a_length), // input wire [31:0]  probe9 
// 	.probe10(array_length) // input wire [31:0]  probe10
// );


endmodule