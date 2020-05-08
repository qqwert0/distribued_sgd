`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/04 21:11:58
// Design Name: 
// Module Name: hbm_send_back
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


module hbm_send_back(
    input wire                  hbm_clk,
    input wire                  hbm_aresetn,

    /* DMA INTERFACE */
    //Commands
    axis_mem_cmd.master         m_axis_dma_write_cmd,

    //Data streams
    axi_stream.master           m_axis_dma_write_data,

    input wire                  start,
    input wire [63:0]           addr_x,
    input wire [31:0]           data_length,

    //
    input wire [511:0]          back_data,
    input wire                  back_valid,
    output reg                  almost_full

    );

    reg                                     start_d0,start_d1;
    reg [63:0]                              addr_x_r;
    reg [31:0]                              data_length_r; 
    wire                                    fifo_almost_full;
    
    always @(posedge hbm_clk) begin
        start_d0                            <= start;
        start_d1                            <= start_d0;
        addr_x_r                            <= addr_x;
        data_length_r                       <= data_length;
        almost_full                         <= fifo_almost_full;
    end


    /*dma write cmd logic*/

    reg [63:0]                              dma_write_cmd_address;
    reg [31:0]                              dma_write_cmd_length;

    assign m_axis_dma_write_cmd.valid        = cstate[1];
    assign m_axis_dma_write_cmd.address      = dma_write_cmd_address;
    assign m_axis_dma_write_cmd.length       = dma_write_cmd_length;

    /*dma write data*/
    
    assign m_axis_dma_write_data.keep       = {64{1'b1}};
    assign m_axis_dma_write_data.data       = fifo_data_out;
    assign m_axis_dma_write_data.valid      = fifo_rd_en;


    reg [511:0]                 fifo_data_in;
    reg                         fifo_wr_en;
    wire                        fifo_empty;
    wire [511:0]                fifo_data_out;
    wire                        fifo_rd_en;

    always @(posedge hbm_clk)begin
        fifo_data_in            <= back_data;
        fifo_wr_en              <= back_valid;
    end

    assign fifo_rd_en           = ~fifo_empty & m_axis_dma_write_data.ready & cstate[2];


    fifo_256i_512o_fwft fifo_256i_512o_fwft_inst (
    .clk(hbm_clk),                  // input wire clk
    .srst(~hbm_aresetn),                // input wire srst
    .din(fifo_data_in),                  // input wire [255 : 0] din
    .wr_en(fifo_wr_en),              // input wire wr_en
    .rd_en(fifo_rd_en),              // input wire rd_en
    .dout(fifo_data_out),                // output wire [511 : 0] dout
    .full(),                // output wire full
    .empty(fifo_empty),              // output wire empty
    .prog_full(fifo_almost_full),      // output wire prog_full
    .wr_rst_busy(),  // output wire wr_rst_busy
    .rd_rst_busy()  // output wire rd_rst_busy
    );

    reg[31:0]                   data_counter;
    reg[31:0]                   data_length_minus;

    always @(posedge hbm_clk)begin
        data_length_minus                   <= data_length_r - 32'd64;
    end

    always @(posedge hbm_clk)begin
        if(~hbm_aresetn)
            data_counter                    <= 32'b0;
        else if(start_d1)
            data_counter                    <= 32'b0;
        else if(m_axis_dma_write_data.ready & m_axis_dma_write_data.valid)
            data_counter                    <= data_counter + 32'd64;
        else
            data_counter                    <= data_counter;
    end




    localparam [2:0]                IDLE                = 8'b001,
                                    SEND_WR_CMD         = 8'b010,
                                    SEND_WR_DATA        = 8'b100;
    
    reg [2:0]                       cstate;
    reg [2:0]                       nstate;


    always @(posedge hbm_clk)begin
        if(~hbm_aresetn)
            cstate                          <= IDLE;
        else
            cstate                          <= nstate;
    end

    always @(*)begin
        case(cstate)
            IDLE:begin
                if(start_d1)begin
                    nstate                  = SEND_WR_CMD;
                    dma_write_cmd_address   = addr_x_r;
                    dma_write_cmd_length    = data_length_r;
                end
                else
                    nstate                  = IDLE;
            end
            SEND_WR_CMD:begin
                if(m_axis_dma_write_cmd.valid & m_axis_dma_write_cmd.ready)
                    nstate                  = SEND_WR_DATA;
                else
                    nstate                  = SEND_WR_CMD;
            end
            SEND_WR_DATA:begin
                if( data_counter >= data_length_r)
                    nstate                  = IDLE;
                else
                    nstate                  = SEND_WR_DATA;
            end
        endcase
    end


//////debug

//ila_hbm_sendback your_instance_name (
//	.clk(hbm_clk), // input wire clk


//	.probe0(fifo_wr_en), // input wire [0:0]  probe0  
//	.probe1(fifo_rd_en), // input wire [0:0]  probe1 
//	.probe2(cstate), // input wire [2:0]  probe2 
//	.probe3(data_counter), // input wire [31:0]  probe3 
//	.probe4(data_length_minus) // input wire [31:0]  probe4
//);


endmodule
