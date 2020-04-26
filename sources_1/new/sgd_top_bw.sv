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

/////////////////////////////////////////////////////////// 
//This file is provided to implement to BitWeaving-based SGD...
// Each cache line contains the bit information from 8 samples.  
///////////////////////////////////////////////////////////
////Timing issues.
////1, the configuration signal "dimension" violates the timing constraint. --> insert the registers...
////
//Configuration of the SGD 
`include "sgd_defines.vh"

module sgd_top_bw #(parameter DATA_WIDTH_IN  = 4,
                parameter MAX_DIMENSION_BITS = 18
                 ) (
    input   wire                                   clk,
    input   wire                                   rst_n,
    input   wire                                   dma_clk,
    //-------------------------------------------------//
    input   wire                                   start_um,
    input   wire [511:0]                           um_params,
    output  wire                                   um_done,
    output  reg  [255:0]                           um_state_counters,


    input [`ENGINE_NUM-1:0][`NUM_BITS_PER_BANK*`NUM_OF_BANKS-1:0]   dispatch_axb_a_data,
    input [`ENGINE_NUM-1:0]                                         dispatch_axb_a_wr_en,
    output wire [`ENGINE_NUM-1:0]                                   dispatch_axb_a_almost_full,

    input                  [32*`NUM_OF_BANKS-1:0]  dispatch_axb_b_data,
    input                                          dispatch_axb_b_wr_en,
    output  wire                                    dispatch_axb_b_almost_full,
    //---------------------Memory Inferface:write----------------------------//
    //cmd
    output  reg                                     x_data_send_back_start,
    output  reg[63:0]                               x_data_send_back_addr,
    output  reg[31:0]                               x_data_send_back_length,

    //data
    output  reg[511:0]                              x_data_out,
    output  reg                                     x_data_out_valid,
    input   wire                                    x_data_out_almost_full

);
/////debuginggggggggggggggggggggggggggg
wire [`ENGINE_NUM-1:0][31:0] state_counters_mem_rd;
wire [`ENGINE_NUM-1:0][31:0] state_counters_x_wr;
wire [31:0] state_counters_bank_0, state_counters_wr_x_to_memory, state_counters_dispatch;

reg [5:0] counter_for_rst;
reg rst_n_afu, rst_n_reg;

always @(posedge clk) 
begin
    rst_n_reg             <= rst_n;

    rst_n_afu             <= (counter_for_rst == 6'b0);
end

always @(posedge clk) 
begin
    if (rst_n_reg & (~rst_n))
        counter_for_rst             <= 6'h7;
    else if (counter_for_rst != 6'b0)
        counter_for_rst             <= counter_for_rst - 6'b1;
end




reg rst_n_g, rst_n_mem_rd, rst_n_dispatch, rst_n_x_updated_rd_wr;
reg rst_n_x_wr, rst_n_wr_x_to_memory;
reg rst_n_banks[`NUM_OF_BANKS-1:0];
reg rst_n_adder_tree[`NUM_BITS_PER_BANK-1:0];

always @(posedge clk) 
begin
    rst_n_g               <= rst_n; //rst_n_afu;//rst_n;
    rst_n_mem_rd          <= rst_n; //rst_n_afu;
    rst_n_dispatch        <= rst_n; //rst_n_afu;
    rst_n_x_updated_rd_wr <= rst_n; //rst_n_afu;
    rst_n_x_wr            <= rst_n; //rst_n_afu;
    rst_n_wr_x_to_memory  <= rst_n; //rst_n_afu;
end

genvar k;
generate for( k = 0; k < `NUM_OF_BANKS; k = k + 1)
begin: inst_banks_rst 
always @(posedge clk) 
begin
    rst_n_banks[k]            <= rst_n; //rst_n_afu;
end
end 
endgenerate

generate for( k = 0; k < `NUM_BITS_PER_BANK; k = k + 1)
begin: inst_adder_tree_rst 
always @(posedge clk) 
begin
    rst_n_adder_tree[k]       <= rst_n; //rst_n_afu;
end
end 
endgenerate



reg        started, done;
wire       mem_op_done;
wire [`ENGINE_NUM-1:0] sgd_execution_done;
wire [31:0] num_issued_mem_rd_reqs;


reg [57:0] addr_a;
reg [57:0] addr_b;
reg [57:0] addr_model;
reg [31:0] mini_batch_size;
reg [31:0] step_size;
reg [31:0] number_of_epochs;
reg [31:0] dimension;
reg [31:0] number_of_samples;
reg [31:0] number_of_bits;

always @(posedge clk) 
begin
    if(~rst_n_g) 
        started <= 1'b0;
    else if (start_um & (!started)) 
        started <= 1'b1;
end



/////////////////////////////////////////////////////////////////////////////////
////////////////////////////////Get the parameters///////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
always @(posedge clk) 
begin 
        addr_a           <= um_params[ 63:6  ]; //no need of [5:0], cache line aligned... Mohsen
        addr_b           <= um_params[127:70 ];
        addr_model       <= um_params[191:134];
        mini_batch_size  <= um_params[223:192];
        step_size        <= um_params[255:224];
        number_of_epochs <= um_params[287:256];
        dimension        <= um_params[319:288];    
        number_of_samples<= um_params[351:320];
        number_of_bits   <= um_params[383:352];    
end





//Completion of operations...
//wire       mem_op_done;
//reg [63:0] num_issued_mem_rd_reqs;
reg [31:0] num_received_rds;
reg [63:0] num_cycles;
always @(posedge clk) 
begin
    if(~rst_n_g) 
        num_cycles <= 1'b0;
    else if ( (~done) & started ) 
        num_cycles <= num_cycles + 1'b1;
end




assign um_done = done;

// always @(posedge clk) 
// begin
//     if(~rst_n_g) 
//         num_received_rds <= 1'b0;
//     else if ( m_axi_c2h_data.valid & m_axi_c2h_data.ready & started ) 
//         num_received_rds <= num_received_rds + 1'b1;
// end


always @(posedge clk) 
begin 
    if(~rst_n_g) 
        done           <= 1'h0;
    else //if ( mem_op_done  & (num_received_rds == num_issued_mem_rd_reqs) & sgd_execution_done )
        done           <=  sgd_execution_done[0]; //1'h1; ( mem_op_done  & (num_received_rds == num_issued_mem_rd_reqs) & )
end





//dot product -->serial loss
wire signed [`ENGINE_NUM-1:0][`NUM_OF_BANKS-1:0][31:0] dot_product_signed;      
wire        [`ENGINE_NUM-1:0][`NUM_OF_BANKS-1:0]       dot_product_signed_valid;
 



wire [`ENGINE_NUM-1:0] writing_x_to_host_memory_en;
wire                    writing_x_to_host_memory_done;
//serial loss -->gradient
wire signed                          [31:0] ax_minus_b_sign_shifted_result[`NUM_OF_BANKS-1:0]; 
wire                                        ax_minus_b_sign_shifted_result_valid[`NUM_OF_BANKS-1:0];
reg signed                          [31:0] ax_minus_b_sign_shifted_result_r1[`ENGINE_NUM/4-1][`NUM_OF_BANKS-1:0]; 
reg signed                          [31:0] ax_minus_b_sign_shifted_result_r2[`ENGINE_NUM/2-1][`NUM_OF_BANKS-1:0]; 
reg                                        ax_minus_b_sign_shifted_result_valid_r1[`ENGINE_NUM/4-1][`NUM_OF_BANKS-1:0];
reg                                        ax_minus_b_sign_shifted_result_valid_r2[`ENGINE_NUM/2-1][`NUM_OF_BANKS-1:0];

///////////////////rd part of x//////////////////////
wire  [`ENGINE_NUM-1:0]         [`DIS_X_BIT_DEPTH-1:0] x_updated_rd_addr;
reg  [`ENGINE_NUM-1:0]         [`DIS_X_BIT_DEPTH-1:0] x_updated_rd_addr_r1,x_updated_rd_addr_r2;
wire  [`ENGINE_NUM-1:0][`NUM_BITS_PER_BANK*32-1:0] x_updated_rd_data;
reg  [`ENGINE_NUM-1:0][`NUM_BITS_PER_BANK*32-1:0] x_updated_rd_data_r1,x_updated_rd_data_r2,x_updated_rd_data_r3;

wire  [`ENGINE_NUM-1:0]         [`DIS_X_BIT_DEPTH-1:0] x_batch_rd_addr;
wire           [`DIS_X_BIT_DEPTH-1:0] x_mem_rd_addr;



//generate end generate
genvar i;
// Instantiate engines
generate
for(i = 0; i < `ENGINE_NUM; i++) 
begin




////////////////////////////////////////////////////////////////////
//////////////////////......model x......//////////////////////////
////////////////////////////////////////////////////////////////////
///////////////////wr part of x//////////////////////
wire                               x_wr_en;     
wire   [`DIS_X_BIT_DEPTH-1:0]      x_wr_addr;
wire   [`NUM_BITS_PER_BANK*32-1:0] x_wr_data;
///////////////////rd part of x//////////////////////
//wire          [`NUM_OF_BANKS-1:0]  x_rd_en;     
wire  [`DIS_X_BIT_DEPTH-1:0]       x_rd_addr;
wire  [`NUM_BITS_PER_BANK*32-1:0]  x_rd_data;



//Compute the wr_counter to make sure ...
ultraram_2port #(.DATA_WIDTH      (`NUM_BITS_PER_BANK*32),    
                 .DEPTH_BIT_WIDTH (`DIS_X_BIT_DEPTH)
) inst_x (
    .clock     ( clk             ),
    .data      ( x_wr_data    ),
    .wraddress ( x_wr_addr    ),
    .wren      ( x_wr_en      ),
    .rdaddress ( x_rd_addr    ), //can be any one of the address.
    .q         ( x_rd_data    )
);


////////////////////counter to avoid RAW hazard.////////////////////
wire [7:0]  x_wr_credit_counter; //x_rd_credit_counter: generate in each bank.







//dot product -->gradient
wire                                        buffer_a_rd_data_valid;
wire [`NUM_BITS_PER_BANK*`NUM_OF_BANKS-1:0] buffer_a_rd_data;
//gradient to x-updated 
wire signed                         [31:0] acc_gradient[`NUM_BITS_PER_BANK-1:0]; //
wire                                       acc_gradient_valid[`NUM_BITS_PER_BANK-1:0];   //


////////////////////wr part of fifo a///////////////////
reg                                         fifo_a_wr_en_pre,   fifo_a_wr_en;     
reg  [`NUM_BITS_PER_BANK*`NUM_OF_BANKS-1:0] fifo_a_wr_data_pre, fifo_a_wr_data; 
wire                                        fifo_a_wr_almostfull;
////////////////////rd part of fifo a///////////////////
wire                                        fifo_a_rd_en;     //rd 
wire [`NUM_BITS_PER_BANK*`NUM_OF_BANKS-1:0] fifo_a_rd_data;
wire                                        fifo_a_empty;
wire               [`A_FIFO_DEPTH_BITS-1:0] fifo_a_counter; 
wire                                        fifo_a_data_valid;

always @(posedge clk) 
begin
    fifo_a_wr_en_pre     <= buffer_a_rd_data_valid; //wr
    fifo_a_wr_data_pre   <= buffer_a_rd_data;    

    fifo_a_wr_en         <= fifo_a_wr_en_pre  ;     //wr
    fifo_a_wr_data       <= fifo_a_wr_data_pre;    
end

blockram_fifo #( .FIFO_WIDTH      (`NUM_BITS_PER_BANK*`NUM_OF_BANKS ), //64 
                 .FIFO_DEPTH_BITS (`A_FIFO_DEPTH_BITS )  //determine the size of 16  13
) inst_a_fifo (
    .clk        (clk),
    .reset_n    (rst_n_reg),

    //Writing side....
    .we         (fifo_a_wr_en     ), //or one cycle later...
    .din        (fifo_a_wr_data   ),
    .almostfull (fifo_a_wr_almostfull), //back pressure to  

    //reading side.....
    .re         (fifo_a_rd_en     ),
    .dout       (fifo_a_rd_data   ),
    .valid      (fifo_a_data_valid),
    .empty      (fifo_a_empty     ),
    .count      (fifo_a_counter   )
);


////////////////////////////////////////////////////////////////////
////////////////////////model x_updated/////////////////////////////
////////////////////////////////////////////////////////////////////
///////////////////wr part of x//////////////////////
wire                              x_updated_wr_en;     
wire           [`DIS_X_BIT_DEPTH-1:0] x_updated_wr_addr;
wire  [`NUM_BITS_PER_BANK*32-1:0] x_updated_wr_data;







reg writing_x_to_host_memory_en_r;
always @(posedge clk) 
begin
    //if(~rst_n) 
    //    writing_x_to_host_memory_en_r <= 1'b0;
    //else
        writing_x_to_host_memory_en_r <= writing_x_to_host_memory_en[i];
end


    sgd_dot_product inst_sgd_dot_product (
    .clk                        (clk        ),
    .rst_n                      (rst_n_reg      ), //rst_n
    .started                    (started    ),
    .state_counters_dot_product (           ),    

    .mini_batch_size            (mini_batch_size  ),
    .number_of_epochs           (number_of_epochs ),
    .number_of_samples          (number_of_samples),
    .dimension                  (dimension        ),
    .number_of_bits             (number_of_bits   ),
    .step_size                  (step_size        ),

    .dispatch_axb_a_data        (dispatch_axb_a_data[i]        ),
    .dispatch_axb_a_wr_en       (dispatch_axb_a_wr_en[i]       ),
    .dispatch_axb_a_almost_full (dispatch_axb_a_almost_full[i] ),

    //.x_rd_en                    (x_rd_en                    ), 
    .x_rd_addr                  (x_rd_addr                  ),
    .x_rd_data                  (x_rd_data                  ),  
    //.x_rd_data_valid            (x_rd_data_valid          ),
    .x_wr_credit_counter        (x_wr_credit_counter        ),
    .writing_x_to_host_memory_done(writing_x_to_host_memory_done),

    //to 
    .buffer_a_rd_data_valid     (buffer_a_rd_data_valid     ),
    .buffer_a_rd_data           (buffer_a_rd_data           ), 

    .dot_product_signed_valid   (dot_product_signed_valid[i]   ),
    .dot_product_signed         (dot_product_signed[i]         ) 
  );


  sgd_gradient inst_sgd_gradient (
    .clk                        (clk        ),
    .rst_n                      (rst_n_reg      ), //rst_n
    .started                    (started    ),

    .number_of_epochs           (number_of_epochs ),
    .number_of_samples          (number_of_samples),
    .dimension                  (dimension        ),
    .number_of_bits             (number_of_bits   ),

    .fifo_a_rd_en               (fifo_a_rd_en     ),
    .fifo_a_rd_data             (fifo_a_rd_data   ),

    .ax_minus_b_sign_shifted_result_valid (ax_minus_b_sign_shifted_result_valid_r2[i/2] ),
    .ax_minus_b_sign_shifted_result       (ax_minus_b_sign_shifted_result_r2[i/2]      ), 

    .acc_gradient_valid         (acc_gradient_valid),
    .acc_gradient               (acc_gradient      )
  );



//Maybe add registers after x_updated_rd_addr...

reg           [`DIS_X_BIT_DEPTH-1:0] x_mem_rd_addr_r1,x_mem_rd_addr_r2,x_mem_rd_addr_r3;

always @(posedge clk)begin
    x_mem_rd_addr_r1            <= x_mem_rd_addr;
    x_mem_rd_addr_r2            <= x_mem_rd_addr_r1;
    x_mem_rd_addr_r3            <= x_mem_rd_addr_r2;
    x_updated_rd_data_r1[i]     <= x_updated_rd_data[i];
    x_updated_rd_data_r2[i]     <= x_updated_rd_data_r1[i];
    x_updated_rd_data_r3[i]     <= x_updated_rd_data_r2[i];
    x_updated_rd_addr_r1[i]     <= x_updated_rd_addr[i];
    x_updated_rd_addr_r2[i]     <= x_updated_rd_addr_r1[i];
end

assign x_updated_rd_addr[i] = writing_x_to_host_memory_en_r? x_mem_rd_addr_r3 : x_batch_rd_addr[i];

//Compute the wr_counter to make sure ...add reigster to any rd/wr ports. 
blockram_2port #(.DATA_WIDTH      (`NUM_BITS_PER_BANK*32),    
                 .DEPTH_BIT_WIDTH (`DIS_X_BIT_DEPTH         )
) inst_x_updated (
    .clock     ( clk                ),
    .data      ( x_updated_wr_data  ),
    .wraddress ( x_updated_wr_addr  ),
    .wren      ( x_updated_wr_en    ),
    .rdaddress ( x_updated_rd_addr_r2[i]), 
    .q         ( x_updated_rd_data[i]  )
);

//reg x_updated_rd_en_pre;
//always @(posedge clk) 
//begin
//    x_updated_rd_en_pre <= v_input_valid[0][0];
//end


////////////////Read/write ports of x_updated////////////////////////
sgd_x_updated_rd_wr inst_x_updated_rd_wr(
    .clk                        (clk    ),
    .rst_n                      (rst_n_reg ),

    .started                    (started            ), 
    .dimension                  (dimension          ),

    .acc_gradient               (acc_gradient       ),//[`NUM_BITS_PER_BANK-1:0] 
    .acc_gradient_valid         (acc_gradient_valid ),//[`NUM_BITS_PER_BANK-1:0]

    .x_updated_rd_addr          ( x_batch_rd_addr[i]   ), //x_updated_rd_addr
    .x_updated_rd_data          (x_updated_rd_data[i]  ),

    .x_updated_wr_addr          (x_updated_wr_addr  ),
    .x_updated_wr_data          (x_updated_wr_data  ),
    .x_updated_wr_en            (x_updated_wr_en    )
);



////////////////Write ports of x////////////////////////
sgd_x_wr inst_x_wr (
    .clk                        (clk    ),
    .rst_n                      (rst_n_reg         ),

    .state_counters_x_wr        (state_counters_x_wr[i]),
    .started                    (started            ), 
    .mini_batch_size            (mini_batch_size    ),
    .number_of_epochs           (number_of_epochs   ),
    .number_of_samples          (number_of_samples  ),
    .dimension                  (dimension          ),

    .sgd_execution_done         (sgd_execution_done[i] ),
    .x_wr_credit_counter        (x_wr_credit_counter),//[`NUM_BITS_PER_BANK-1:0]

    .writing_x_to_host_memory_en   (writing_x_to_host_memory_en[i]),
    .writing_x_to_host_memory_done (writing_x_to_host_memory_done),

    .x_updated_wr_addr          (x_updated_wr_addr  ),
    .x_updated_wr_data          (x_updated_wr_data  ),
    .x_updated_wr_en            (x_updated_wr_en    ),

    .x_wr_addr                  (x_wr_addr          ),
    .x_wr_data                  (x_wr_data          ),
    .x_wr_en                    (x_wr_en            )
);

end
endgenerate

  sgd_serial_loss inst_sgd_serial_loss (
    .clk                        (clk                      ),
    .rst_n                      (rst_n_reg                    ), 

    .step_size                  (step_size                ),

    .dispatch_axb_b_data        (dispatch_axb_b_data      ),
    .dispatch_axb_b_wr_en       (dispatch_axb_b_wr_en     ),
    .dispatch_axb_b_almost_full (dispatch_axb_b_almost_full),  

    .dot_product_signed_valid   (dot_product_signed_valid ),
    .dot_product_signed         (dot_product_signed       ), 

    .ax_minus_b_sign_shifted_result_valid (ax_minus_b_sign_shifted_result_valid),
    .ax_minus_b_sign_shifted_result       (ax_minus_b_sign_shifted_result      )
  );



genvar m,n;
generate for( m = 0; m < `ENGINE_NUM/4; m = m + 1)begin
    for( n = 0; n < `NUM_OF_BANKS; n = n + 1)begin
        always @(posedge clk) 
        begin
            ax_minus_b_sign_shifted_result_r1[m][n]            <= ax_minus_b_sign_shifted_result[n]; 
            ax_minus_b_sign_shifted_result_valid_r1[m][n]      <= ax_minus_b_sign_shifted_result_valid[n];
        end
    end
end 
endgenerate

genvar s,t;
generate for( s = 0; s < `ENGINE_NUM/2; s = s + 1)begin
    for( t = 0; t < `NUM_OF_BANKS; t = t + 1)begin
        always @(posedge clk) 
        begin
            ax_minus_b_sign_shifted_result_r2[s][t]           <= ax_minus_b_sign_shifted_result_r1[s/2][t]; 
            ax_minus_b_sign_shifted_result_valid_r2[s][t]      <= ax_minus_b_sign_shifted_result_valid_r1[s/2][t];
        end
    end
end 
endgenerate



////////////Writing back to the host memory////////////
sgd_wr_x_to_memory inst_wr_x_to_memory (
    .clk                        (clk    ),
    .rst_n                      (rst_n_reg ),
    .dma_clk                    (dma_clk),

    .state_counters_wr_x_to_memory (state_counters_wr_x_to_memory),
    .started                    (started            ),
    .dimension                  (dimension          ),
    .numEpochs                  (number_of_epochs   ),
    .addr_model                 (addr_model         ),

    .writing_x_to_host_memory_en   (writing_x_to_host_memory_en[0]  ),
    .writing_x_to_host_memory_done (writing_x_to_host_memory_done),

    .x_mem_rd_addr              (x_mem_rd_addr      ),
    .x_mem_rd_data              (x_updated_rd_data_r3  ),

    //---------------------Memory Inferface:write----------------------------//
    //cmd
    .x_data_send_back_start(x_data_send_back_start),
    .x_data_send_back_addr(x_data_send_back_addr),
    .x_data_send_back_length(x_data_send_back_length),

    //data
    .x_data_out(x_data_out),
    .x_data_out_valid(x_data_out_valid),
    .x_data_out_almost_full(x_data_out_almost_full)

);







////////////Debug output....////////////

//um_state_counters[255:0]
always @(posedge clk) 
begin 
    um_state_counters[31:0]     <= state_counters_mem_rd[0];
    um_state_counters[63:32]    <= state_counters_dispatch;
    um_state_counters[95:64]    <= state_counters_bank_0;
    um_state_counters[127:96]   <= 32'b0; //state_counters_wr_x_to_memory;
    um_state_counters[159:128]  <= 32'b0; //num_received_rds[31:0];
    um_state_counters[191:160]  <= 32'b0; //num_issued_mem_rd_reqs[31:0];
    um_state_counters[223:192]  <= 32'b0; //state_counters_x_wr;

    um_state_counters[255:224]  <= num_cycles[39:8];//32'b0;

end

//num_received_rds == num_issued_mem_rd_reqs)
endmodule