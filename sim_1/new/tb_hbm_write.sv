`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/03/29 23:11:53
// Design Name: 
// Module Name: tb_hbm_write
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

module tb_hbm_write(

    );

axi_mm          hbm_axi[32]();
reg             sys_clk_100M;
reg             hbm_clk;
reg             hbm_rstn;
// DMA Signals
axis_mem_cmd    axis_dma_read_cmd();
axis_mem_cmd    axis_dma_write_cmd();
axi_stream      axis_dma_read_data();
axi_stream      axis_dma_write_data();

//mlweaving parameter
reg         	m_axis_mlweaving_valid;
wire         	m_axis_mlweaving_ready;
wire[511:0]  	m_axis_mlweaving_data;

//

    reg [63:0] addr_a;
    reg [63:0] addr_b;
    reg [63:0] addr_model;
    reg [31:0] mini_batch_size;
    reg [31:0] step_size;
    reg [31:0] number_of_epochs;
    reg [31:0] dimension;
    reg [31:0] number_of_samples;
    reg [31:0] number_of_bits; 
    reg [31:0] data_a_length;
    reg        start;
    reg [31:0] array_length;

//
    reg [511:0] dma_read_data;

    initial begin
        hbm_clk = 1;
        hbm_rstn = 0;
        start = 0;
        m_axis_mlweaving_valid = 0;
        #500
        hbm_rstn = 1;
        #500
        m_axis_mlweaving_valid = 1;
        #10
        m_axis_mlweaving_valid = 0;
        #200
        start = 1;
        #10
        start = 0;
        #800000
        m_axis_mlweaving_valid = 1;
        #10
        m_axis_mlweaving_valid = 0;
    end

    always #5 hbm_clk = ~hbm_clk;

    assign m_axis_mlweaving_data = {64'b0,array_length,data_a_length,number_of_bits,number_of_samples,dimension,number_of_epochs,step_size,mini_batch_size,addr_model,addr_b,addr_a};


    always @(posedge hbm_clk) 
    begin 
            addr_a           <= 0; //no need of [5:0], cache line aligned... Mohsen
            addr_b           <= 32'h20000000;
            addr_model       <= 32'h40000000;
            mini_batch_size  <= 16;
            step_size        <= 16;
            number_of_epochs <= 3;
            dimension        <= 10;    
            number_of_samples<= 16;
            number_of_bits   <= 8;  
            data_a_length    <= 4096;  
            array_length     <= 5120;
    end

    always @(posedge hbm_clk) begin 
        if(~hbm_rstn)  
            dma_read_data       <= 0;
        else if(axis_dma_read_data.valid & axis_dma_read_data.ready)
            dma_read_data       <= dma_read_data + 1;
        else
            dma_read_data       <= dma_read_data;
    end




    assign axis_dma_read_cmd.ready = 1;
    assign axis_dma_write_cmd.ready = 1;
    assign axis_dma_write_data.ready = 1;
    assign axis_dma_read_data.valid = 1;
    assign axis_dma_read_data.keep = {64{1'b1}};
    assign axis_dma_read_data.last = 0;
    assign axis_dma_read_data.data = dma_read_data;


// hbm_driver inst_hbm_driver(

//     .sys_clk_100M(sys_clk_100M),
//     .hbm_axi(hbm_axi),
//     .hbm_clk(hbm_clk),
//     .hbm_rstn(hbm_rstn)
//     );


//     assign hbm_axi[8].awready = 1;
//     assign hbm_axi[8].wready = 1;
//     assign hbm_axi[8].bid = 0;
//     assign hbm_axi[8].bresp = 0;
//     assign hbm_axi[8].bvalid = 1;
//     assign hbm_axi[8].buser = 0;            

    // //generate end generate
    // genvar i;
    // // Instantiate engines
    // generate
    // for(i = 0; i < `ENGINE_NUM; i++) begin

    // assign hbm_axi[i].arready = 1;
    // assign hbm_axi[i].rvalid =1;
    // assign hbm_axi[i].rdata = 0;
    // assign hbm_axi[i].rlast = 0;
    // assign hbm_axi[i].rid = 0;
    // assign hbm_axi[i].rresp = 0;

    // assign hbm_axi[i].awready = 1;
    // assign hbm_axi[i].wready = 1;
    // assign hbm_axi[i].bid = 0;
    // assign hbm_axi[i].bresp = 0;
    // assign hbm_axi[i].bvalid = 1;
    // assign hbm_axi[i].buser = 0; 



    // end
    // endgenerate

//hbm_driver inst_hbm_driver(

//    .sys_clk_100M(hbm_clk),
//    .hbm_axi(hbm_axi),
//    .hbm_clk(),
//    .hbm_rstn()
//    );

//hbm_interface inst_hbm_interface(
//    .user_clk(hbm_clk),
//    .user_aresetn(hbm_rstn),

//    .hbm_clk(hbm_clk),
//    .hbm_rstn(hbm_rstn),

//    //mlweaving parameter
//    .m_axis_mlweaving_valid(m_axis_mlweaving_valid),
//    .m_axis_mlweaving_ready(m_axis_mlweaving_ready),
//    .m_axis_mlweaving_data(m_axis_mlweaving_data),

//    /* DMA INTERFACE */
//    //Commands
//    .m_axis_dma_read_cmd(axis_dma_read_cmd),
//    .m_axis_dma_write_cmd(axis_dma_write_cmd),

//    //Data streams
//    .m_axis_dma_write_data(axis_dma_write_data),
//    .s_axis_dma_read_data(axis_dma_read_data),
    
//    /* HBM INTERFACE */
//    .hbm_axi(hbm_axi)

//    );

hbm_write inst_hbm_write(
    .hbm_clk(hbm_clk),
    .hbm_aresetn(hbm_rstn),

    /* DMA INTERFACE */
    //Commands
    .m_axis_dma_read_cmd(axis_dma_read_cmd),
    // axis_mem_cmd.master         m_axis_dma_write_cmd,

    //Data streams
    // axi_stream.master           m_axis_dma_write_data,
    .s_axis_dma_read_data(axis_dma_read_data),

    //signal

    .start(m_axis_mlweaving_valid),
    .data_a_length(data_a_length),  //need to multiple of 512
    .data_b_length(number_of_samples << 2),  //need to multiple of 512
    .dma_addr_a(addr_a),
    .dma_addr_b(addr_b),
    .hbm_addr_b(33'h80000000),  
    .number_of_samples(number_of_samples),  
    .dimension(dimension),
    .number_of_bits(number_of_bits),  
    .araddr_stride(array_length),   

    .hbm_write_done(),               

    /* HBM INTERFACE */
    //Write addr (output)
    .m_axi_AWVALID (), //wr address valid
    .m_axi_AWADDR  (), //wr byte address
    .m_axi_AWID    (), //wr address id
    .m_axi_AWLEN   (), //wr burst=awlen+1,
    .m_axi_AWSIZE  (), //wr 3'b101, 32B
    .m_axi_AWBURST (), //wr burst type: 01 (INC), 00 (FIXED)
    .m_axi_AWLOCK  (), //wr no
    .m_axi_AWCACHE (), //wr no
    .m_axi_AWPROT  (), //wr no
    .m_axi_AWQOS   (), //wr no
    .m_axi_AWREGION(), //wr no
    .m_axi_AWREADY (1), //wr ready to accept address.

    //Write data (output)  
    .m_axi_WVALID  (), //wr data valid
    .m_axi_WDATA   (), //wr data
    .m_axi_WSTRB   (), //wr data strob
    .m_axi_WLAST   (), //wr last beat in a burst
    .m_axi_WID     (), //wr data id
    .m_axi_WREADY  (1), //wr ready to accept data

    //Write response (input)  
    .m_axi_BVALID  (1), 
    .m_axi_BRESP   (0),
    .m_axi_BID     (0),
    .m_axi_BREADY  ()

    ); 

endmodule
