/*
 * Copyright 2017 - 2018, Zeke Wang, Systems Group, ETH Zurich
 *
 * This hardware operator is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
//The objective of the module is to compute the dot products for eight banks.
//
//Fixme: we can tune the precision of computation in this part....

`include "sgd_defines.vh"

module sgd_serial_loss (
    input   wire                                   clk,
    input   wire                                   rst_n,

    input   wire                                   hbm_clk,
    //------------------------Configuration-----------------------------//
    input   wire [31:0]                            step_size,

    //------------------Input: disptach resp data to b of each bank---------------//
    input                  [32*`NUM_OF_BANKS-1:0]  dispatch_axb_b_data, //256.
    input                                          dispatch_axb_b_wr_en, 
    output  wire                                    dispatch_axb_b_almost_full,
    //input   wire                                   dispatch_axb_b_almost_full[`NUM_OF_BANKS-1:0],

    //------------------Input: dot products for all the banks. ---------------//
    input wire signed [`ENGINE_NUM-1:0][`NUM_OF_BANKS-1:0][31:0] dot_product_signed,       //
    input wire        [`ENGINE_NUM-1:0][`NUM_OF_BANKS-1:0]        dot_product_signed_valid,  //
    //------------------Output: dot products for all the banks. ---------------//
    output reg signed                      [31:0] ax_minus_b_sign_shifted_result[`NUM_OF_BANKS-1:0],         //
    output reg                                    ax_minus_b_sign_shifted_result_valid[`NUM_OF_BANKS-1:0],
    //----------------------debug------------------------
    output reg [31:0]                               b_data_cnt,        
    output reg [31:0]                               a_minus_b_cnt  

);




////////////////////////////////////////fifo for a////////////////////////////////////////
//Warning: Make sure the buffer_b has the enough space for the 

reg     [`ENGINE_NUM-1:0]                       buffer_a_wr_en;     //rd
reg     [`ENGINE_NUM-1:0][32*`NUM_OF_BANKS-1:0] buffer_a_wr_data;   //rd_data

reg     [`ENGINE_NUM-1:0]                       buffer_a_rd_en,buffer_a_rd_en_r1,buffer_a_rd_en_r2;     //rd
wire    [`ENGINE_NUM-1:0][32*`NUM_OF_BANKS-1:0] buffer_a_rd_data;   //rd_data
wire    [`ENGINE_NUM-1:0]                       buffer_a_data_valid;
wire    [`ENGINE_NUM-1:0]                       buffer_a_data_empty;
reg     [`ENGINE_NUM-1:0]                       buffer_a_data_empty_r1,buffer_a_data_empty_r2;  
reg     [`ENGINE_NUM-1:0][3:0]                  buffer_a_rd_cnt;

//////////////////////add engine signal/
reg signed[31:0]          add_tree_in[`NUM_OF_BANKS-1:0][`ENGINE_NUM-1:0];
reg     [`NUM_OF_BANKS-1:0]                                 add_tree_in_valid;
reg signed[31:0]          add_tree_in_r[`NUM_OF_BANKS-1:0][`ENGINE_NUM-1:0];
reg     [`NUM_OF_BANKS-1:0]                                 add_tree_in_valid_r;
wire    [`NUM_OF_BANKS-1:0][31:0]                           add_tree_out;
wire    [`NUM_OF_BANKS-1:0]                                 add_tree_out_valid;


//generate end generate
genvar m,n;
// Instantiate engines
generate 
for(m = 0; m < `ENGINE_NUM; m++) begin
    always @(posedge clk) begin
        buffer_a_wr_en[m]      <= dot_product_signed_valid[m]; 
    end
    for(n = 0;n < `NUM_OF_BANKS; n++)begin
        always @(posedge clk) begin
            buffer_a_wr_data[m][n*32+31:n*32]    <= dot_product_signed[m][n];
        end
    end


    //assign buffer_a_rd_en[m]          = buffer_a_data_empty ? 1'b0 : 1'b1;

    always @(posedge clk) begin
        buffer_a_data_empty_r1[m]   <= buffer_a_data_empty[m];
        buffer_a_data_empty_r2[m]   <= buffer_a_data_empty_r1[m];
        buffer_a_rd_en_r1[m]        <= buffer_a_rd_en[m]; 
        buffer_a_rd_en_r2[m]        <= buffer_a_rd_en_r1[m];     
    end     

    always @(posedge clk) begin
        if(~rst_n)
            buffer_a_rd_cnt[m]         <= 4'b0;
        else if(buffer_a_rd_cnt[m][3] & (buffer_a_data_empty_r2 == 0) )
            buffer_a_rd_cnt[m]         <= 4'b0;
        else if(buffer_a_rd_cnt[m][3])
            buffer_a_rd_cnt[m]         <= buffer_a_rd_cnt[m];
        else 
            buffer_a_rd_cnt[m]         <= buffer_a_rd_cnt[m] + 1'b1;
    end

    always @(posedge clk) begin
        if(buffer_a_rd_cnt[m][3] & (buffer_a_data_empty_r2 == 0))
            buffer_a_rd_en[m]       <= 1'b1;
        else
            buffer_a_rd_en[m]       <= 1'b0;
    end



    distram_fifo  #( .FIFO_WIDTH      (32*`NUM_OF_BANKS), 
                    .FIFO_DEPTH_BITS (       6        ) 
    ) inst_a_fifo (
        .clk        (clk),
        .reset_n    (rst_n),

        //Writing side. from sgd_dispatch...
        .we         ( buffer_a_wr_en[m]    ),
        .din        ( buffer_a_wr_data[m]  ),
        .almostfull (                   ), 

        //reading side.....
        .re         (buffer_a_rd_en_r2[m]  ),
        .dout       (buffer_a_rd_data[m]   ),
        .valid      (buffer_a_data_valid[m]),
        .empty      (buffer_a_data_empty[m]),
        .count      (                   )
    );

    for(n = 0;n < `NUM_OF_BANKS; n++)begin
        always @(posedge clk) begin
            add_tree_in[n][m]           <= buffer_a_rd_data[m][n*32+31:n*32];
            add_tree_in_r[n][m]         <= add_tree_in[n][m];
        end
    end

end 
endgenerate


//generate end generate
genvar k;
// Instantiate engines
generate 
for(k = 0; k < `NUM_OF_BANKS; k++) begin
    always @(posedge clk) begin
        add_tree_in_valid[k]        <= buffer_a_data_valid[0];
        add_tree_in_valid_r[k]      <= add_tree_in_valid[k];
    end
/////////////////////add engine///////
    sgd_adder_tree #(
        .TREE_DEPTH (`ENGINE_NUM_WIDTH), //2**8 = 64 
        .TREE_TRI_DEPTH(`ENGINE_NUM_TRI_WIDTH)
    ) inst_ax (
        .clk              ( clk                   ),
        .rst_n            ( rst_n                 ), 
        .v_input          ( add_tree_in_r[k]      ),
        .v_input_valid    ( add_tree_in_valid_r[k]),
        .v_output         ( add_tree_out[k]       ),   //output...
        .v_output_valid   ( add_tree_out_valid[k] ) 
    ); 
end 
endgenerate

////////////////////////////////////////fifo for b////////////////////////////////////////
//Warning: Make sure the buffer_b has the enough space for the 

reg                           buffer_b_wr_en;     //rd
reg    [32*`NUM_OF_BANKS-1:0] buffer_b_wr_data;   //rd_data

always @(posedge hbm_clk) begin
    buffer_b_wr_en      <= dispatch_axb_b_wr_en; 
    buffer_b_wr_data    <= dispatch_axb_b_data;
end


wire                          buffer_b_rd_en;     //rd
wire   [32*`NUM_OF_BANKS-1:0] buffer_b_rd_data;   //rd_data
wire                          buffer_b_data_valid;

assign buffer_b_rd_en  = add_tree_out_valid[0]; 
//on-chip buffer for b 
inde_fifo_256w_128d inst_b_fifo (
  .rst(~rst_n),              // input wire rst
  .wr_clk(hbm_clk),        // input wire wr_clk
  .rd_clk(clk),        // input wire rd_clk
  .din(buffer_b_wr_data),              // input wire [255 : 0] din
  .wr_en(buffer_b_wr_en),          // input wire wr_en
  .rd_en(buffer_b_rd_en),          // input wire rd_en
  .dout(buffer_b_rd_data),            // output wire [255 : 0] dout
  .full(),            // output wire full
  .empty(),          // output wire empty
  .valid(buffer_b_data_valid),          // output wire valid
  .prog_full(dispatch_axb_b_almost_full)  // output wire prog_full
);



reg signed           [31:0] buffer_b_rd_data_signed[`NUM_OF_BANKS-1:0];
reg signed           [31:0] ax_dot_product_reg[`NUM_OF_BANKS-1:0], ax_dot_product_reg2[`NUM_OF_BANKS-1:0];         //cycle synchronization. 
reg                         ax_dot_product_valid_reg[`NUM_OF_BANKS-1:0], ax_dot_product_valid_reg2[`NUM_OF_BANKS-1:0];
reg signed           [31:0] ax_minus_b_result[`NUM_OF_BANKS-1:0];          //
reg                         ax_minus_b_result_valid[`NUM_OF_BANKS-1:0];

reg signed                      [31:0] ax_minus_b_sign_shifted_result_pre[`NUM_OF_BANKS-1:0];         //
reg                                    ax_minus_b_sign_shifted_result_valid_pre[`NUM_OF_BANKS-1:0];

reg                   [4:0] num_shift_bits[`NUM_OF_BANKS-1:0];

genvar i, j;
generate for( i = 0; i < `NUM_OF_BANKS; i = i + 1) begin: inst_bank

    always @(posedge clk) begin
            num_shift_bits[i]          <= step_size[4:0]; // - 5'h0  - 5'h6
    end


    always @(posedge clk) begin
            buffer_b_rd_data_signed[i] <= buffer_b_rd_data[32*(i+1)-1:32*i];
    end
    
    always @(posedge clk) begin
        if(~rst_n) 
        begin
            ax_minus_b_result_valid[i]              <=  1'b0;
            ax_minus_b_sign_shifted_result_valid[i] <=  1'b0;
        end
        else
        begin
            //one-cycle delay
            ax_dot_product_valid_reg[i]             <= add_tree_out_valid[i];
            ax_dot_product_reg[i]                   <= add_tree_out[i];
         
             //two-cycles delay         
            ax_dot_product_valid_reg2[i]            <= ax_dot_product_valid_reg[i];
            ax_dot_product_reg2[i]                  <= ax_dot_product_reg[i];
             
             //three-cycles delay         
            ax_minus_b_result_valid[i]              <= ax_dot_product_valid_reg2[i];
            ax_minus_b_result[i]                    <= ax_dot_product_reg2[i] - buffer_b_rd_data_signed[i]; // buffer_b_rd_data;

             //four-cycles delay         
            ax_minus_b_sign_shifted_result_valid_pre[i] <=  ax_minus_b_result_valid[i];
            ax_minus_b_sign_shifted_result_pre[i]       <= (ax_minus_b_result[i]>>>num_shift_bits[i] ); //should be signed reg.

             //four-cycles delay         
            ax_minus_b_sign_shifted_result_valid[i]     <= ax_minus_b_sign_shifted_result_valid_pre[i];
            ax_minus_b_sign_shifted_result[i]           <= ax_minus_b_sign_shifted_result_pre[i]; //should be signed reg.

        end 
    end



end 
endgenerate

/////------------------debug---------------------------

    always @(posedge hbm_clk)begin
        if(~rst_n)
            b_data_cnt                      <= 1'b0;
        else if(dispatch_axb_b_wr_en)
            b_data_cnt                      <= b_data_cnt + 1'b1;
        else 
            b_data_cnt                      <= b_data_cnt;   
    end

    always @(posedge clk)begin
        if(~rst_n)
            a_minus_b_cnt                 <= 1'b0;
        else if(ax_minus_b_sign_shifted_result_valid[0])
            a_minus_b_cnt                 <= a_minus_b_cnt + 1'b1;
        else 
            a_minus_b_cnt                 <= a_minus_b_cnt;   
    end   


//ila_serial probe_ila_serial(
//.clk(hbm_clk),

//.probe0(dispatch_axb_b_wr_en), // input wire [1:0]
//.probe1(dispatch_axb_b_data), // input wire [256:0]
//.probe2(b_data_cnt) // input wire [32:0]
//);



endmodule
