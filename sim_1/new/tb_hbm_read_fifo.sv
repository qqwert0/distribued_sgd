`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2020 10:11:33 AM
// Design Name: 
// Module Name: tb_hbm_read_fifo
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


module tb_hbm_read_fifo(

    );
    
    reg hbm_clk;
    reg user_clk;
    reg hbm_rstn;
    
    

    reg  [1*2-1:0][255:0]   hbm_read_a_data_in_r;
    wire [1*2-1:0][255:0]   hbm_read_a_data_out;
    reg  [1*2-1:0][255:0]   hbm_read_a_data_o;
    reg  [1*2-1:0]          hbm_read_a_wr_en_r;
    reg  [1*2-1:0]          hbm_read_a_rd_en;
    wire [1*2-1:0]          hbm_read_a_almost_full;
    wire [1*2-1:0]          hbm_read_a_empty;
    reg  [1*2-1:0]          hbm_read_a_empty_r;
    reg  [1*2-1:0]          hbm_read_a_valid_o;
    wire [1*2-1:0]          hbm_read_a_valid;


    reg  [1-1:0][511:0]     dispatch_axb_a_data;
    reg  [1-1:0][511:0]     dispatch_axb_a_data_r1;  
    reg  [1-1:0]            dispatch_axb_a_wr_en;
    reg  [1-1:0]            dispatch_axb_a_wr_en_r1;
//    wire [1-1:0]            dispatch_axb_a_almost_full;
    reg  [1-1:0]            dispatch_axb_a_almost_full_r1;


     reg[1-1:0][511:0]   dispatch_axb_a_data_o;
     reg[1-1:0]                                         dispatch_axb_a_wr_en_o;
     reg [1-1:0]                                   dispatch_axb_a_almost_full;

    
    initial begin
        hbm_clk = 1;
        user_clk = 1;
        hbm_rstn = 0;
        hbm_read_a_wr_en_r = 0;
        dispatch_axb_a_almost_full = 0;
        #500
        hbm_rstn = 1;

        #200
        hbm_read_a_wr_en_r = 2'b11;
        #200    
        hbm_read_a_wr_en_r = 2'b00;
        #200
        hbm_read_a_wr_en_r = 2'b11;
        #200    
        hbm_read_a_wr_en_r = 2'b00;
        #200
        hbm_read_a_wr_en_r = 2'b11;
        #200    
        hbm_read_a_wr_en_r = 2'b00;                
    end
     

    always #2 hbm_clk = ~hbm_clk;
    always #3 user_clk = ~user_clk;

    always @(posedge hbm_clk)begin
        if(~hbm_rstn)begin
            hbm_read_a_data_in_r[0] <= 0;
            hbm_read_a_data_in_r[1] <= 0;
        end
        else if(hbm_read_a_wr_en_r)begin
            hbm_read_a_data_in_r[0] <= hbm_read_a_data_in_r[0] + 1;
            hbm_read_a_data_in_r[1] <= hbm_read_a_data_in_r[1] + 1;            
        end
        else begin
            hbm_read_a_data_in_r[0] <= hbm_read_a_data_in_r[0];
            hbm_read_a_data_in_r[1] <= hbm_read_a_data_in_r[1];
        end
    end


    inde_fifo_256w_128d inst_a0_fifo (
    .rst(~hbm_rstn),              // input wire rst
    .wr_clk(hbm_clk),        // input wire wr_clk
    .rd_clk(user_clk),        // input wire rd_clk
    .din(hbm_read_a_data_in_r[0]),              // input wire [255 : 0] din
    .wr_en(hbm_read_a_wr_en_r[0]),          // input wire wr_en
    .rd_en(hbm_read_a_rd_en[0]),          // input wire rd_en
    .dout(hbm_read_a_data_out[0]),            // output wire [255 : 0] dout
    .full(),            // output wire full
    .empty(hbm_read_a_empty[0]),          // output wire empty
    .valid(hbm_read_a_valid[0]),          // output wire valid
    .prog_full(hbm_read_a_almost_full[0])  // output wire prog_full
    ); 

    inde_fifo_256w_128d inst_a1_fifo (
    .rst(~hbm_rstn),              // input wire rst
    .wr_clk(hbm_clk),        // input wire wr_clk
    .rd_clk(user_clk),        // input wire rd_clk
    .din(hbm_read_a_data_in_r[0+1]),              // input wire [255 : 0] din
    .wr_en(hbm_read_a_wr_en_r[0+1]),          // input wire wr_en
    .rd_en(hbm_read_a_rd_en[0+1]),          // input wire rd_en
    .dout(hbm_read_a_data_out[0+1]),            // output wire [255 : 0] dout
    .full(),            // output wire full
    .empty(hbm_read_a_empty[0+1]),          // output wire empty
    .valid(hbm_read_a_valid[0+1]),          // output wire valid
    .prog_full(hbm_read_a_almost_full[0+1])  // output wire prog_full
    );

    always @(posedge user_clk) begin
        hbm_read_a_valid_o[0]         <= hbm_read_a_valid[0];
        hbm_read_a_valid_o[0+1]       <= hbm_read_a_valid[0+1];
        hbm_read_a_empty_r[0]         <= hbm_read_a_empty[0];
        hbm_read_a_empty_r[0+1]       <= hbm_read_a_empty[0+1];
        hbm_read_a_data_o[0]          <= hbm_read_a_data_out[0];
        hbm_read_a_data_o[0+1]        <= hbm_read_a_data_out[0+1];
    end     
    
    always @(posedge user_clk) begin
        dispatch_axb_a_data[0]          <= {hbm_read_a_data_o[0+1],hbm_read_a_data_o[0]};
        dispatch_axb_a_wr_en[0]         <= hbm_read_a_valid_o[0] ;//& ~hbm_read_a_empty_r[0];
    end       

    always @(posedge user_clk) begin
        if((~hbm_read_a_empty[0+1]) && (~hbm_read_a_empty[0]) && (~dispatch_axb_a_almost_full_r1[0])) begin
            hbm_read_a_rd_en[0]       <= 1'b1;
            hbm_read_a_rd_en[0+1]     <= 1'b1;
        end
        else begin
            hbm_read_a_rd_en[0]       <= 1'b0;
            hbm_read_a_rd_en[0+1]     <= 1'b0;
        end            
    end  

///////add reg
     always @(posedge user_clk) begin
        dispatch_axb_a_almost_full_r1[0]<= dispatch_axb_a_almost_full[0];
        dispatch_axb_a_data_o[0]       <= dispatch_axb_a_data[0];
        dispatch_axb_a_wr_en_o[0]      <= dispatch_axb_a_wr_en[0];
    end  




    
endmodule
