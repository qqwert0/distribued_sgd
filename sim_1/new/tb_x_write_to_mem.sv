`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/04/11 15:57:03
// Design Name: 
// Module Name: tb_x_write_to_mem
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

module tb_x_write_to_mem(

    );
    reg                                 clk,rst_n;  
    reg                                 writing_x_to_host_memory_en,start;  
    reg   [`ENGINE_NUM-1:0][`NUM_BITS_PER_BANK*32-1:0]  x_mem_rd_data;

    initial begin
        clk = 1'b1;
        rst_n = 1'b0;
        start = 1'b0;
        writing_x_to_host_memory_en = 1'b0;
        #1000
        rst_n = 1'b1;
        #1000
        start = 1'b1;
        #2000
        writing_x_to_host_memory_en = 1'b1;
    end

    always #5 clk = ~clk;


    //generate end generate
    genvar i;
    // Instantiate engines
    generate
    for(i = 0; i < `ENGINE_NUM; i++) begin
    
    always @(posedge clk)begin
        if(~rst_n)
            x_mem_rd_data[i]        <= 1;
        else
            x_mem_rd_data[i]        <= x_mem_rd_data[i] + i;
    end

    end
    endgenerate


    sgd_wr_x_to_memory inst_sgd_wr_x_to_memory( //16
    .clk(clk),
    .rst_n(rst_n),
    .dma_clk(clk),
    //--------------------------Begin/Stop-----------------------------//
    .started(start),
    .state_counters_wr_x_to_memory(),

    //---------Input: Parameters (where, how many) from the root module-------//
    .addr_model(64'h1234),

    //input   wire [63:0]                            addr_model,
    .dimension(256),
    .numEpochs(3),

    .writing_x_to_host_memory_en(writing_x_to_host_memory_en),
    .writing_x_to_host_memory_done(),

    ///////////////////rd part of x_updated//////////////////////
    .x_mem_rd_addr(),
    .x_mem_rd_data(x_mem_rd_data),

    //---------------------Memory Inferface:write----------------------------//
    //cmd
    .x_data_send_back_start(),
    .x_data_send_back_addr(),
    .x_data_send_back_length(),

    //data
    .x_data_out(),
    .x_data_out_valid(),
    .x_data_out_almost_full(0)

);
    
    
    
endmodule
