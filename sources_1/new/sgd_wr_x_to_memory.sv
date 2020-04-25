/*
 * Copyright 2017 - 2018 Systems Group, ETH Zurich
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
//The objective of the module sgd_mem_rd is to generate the memory read request for the SGD computing task...
// (number_of_epochs, number_of_samples). Memory traffic: ((features+63)/64) * bits * (samples/8). 
// It is independent of the computing pipeline since the training dataset is not changed during the training...
//
// The reason for stalling is that um_tx_rd_ready is not asserted. 
// The back pressure is from the signal um_rx_rd_ready, whose negative value can cause um_tx_rd_ready to be 0.
// The batch size should be a multiple of #Banks, i.e., 8. 


`include "sgd_defines.vh"

module sgd_wr_x_to_memory #( 
                        parameter ADDR_WIDTH      = 33 ,  // 8G-->33 bits
                        parameter DATA_WIDTH      = 256,  // 512-bit for DDR4
                        parameter ID_WIDTH        = 5  ,  //fixme,
                        parameter DATA_WIDTH_IN      = 4 ,
                     parameter MAX_DIMENSION_BITS = `MAX_BIT_WIDTH_OF_X  ) ( //16
    input   wire                                   clk,
    input   wire                                   rst_n,
    //--------------------------Begin/Stop-----------------------------//
    input   wire                                   started,
    output  wire [31:0]                            state_counters_wr_x_to_memory,

    //---------Input: Parameters (where, how many) from the root module-------//
    input   wire [63:0]                            addr_model,

    //input   wire [63:0]                            addr_model,
    input   wire [31:0]                            dimension,
    input   wire [31:0]                             numEpochs,

    input                                          writing_x_to_host_memory_en,
    output  reg                                    writing_x_to_host_memory_done,

    ///////////////////rd part of x_updated//////////////////////
    output  reg                [`DIS_X_BIT_DEPTH-1:0]  x_mem_rd_addr,
    input   [`ENGINE_NUM-1:0][`NUM_BITS_PER_BANK*32-1:0]  x_mem_rd_data,

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
//From parameters from sgd_defines.svh:::

parameter MAX_BURST_BITS = MAX_DIMENSION_BITS - 9; //7..... Each chunk contains 512 features...

//to make sure that the parameters has been assigned...
reg       started_r, started_r2, started_r3;   //one cycle delay from started...
reg [2:0] state; 
reg [3:0] error_state; //0000: ok; 0001: dimension is zero; 

    reg                                     writing_x_to_host_memory_en_r,writing_x_to_host_memory_en_r2,writing_x_to_host_memory_en_r3,writing_x_to_host_memory_en_r4;
    reg [1:0]                               inner_index;
    reg [8:0][1:0]                          inner_index_r;
    reg [7:0]                               engine_index;
    reg [8:0][3:0]                          engine_index_r;
    reg [31:0]                              dimension_index,dimension_index_r,dimension_minus;  
    reg [31:0]                              epoch_index;
    reg [8:0]                               rd_en_r;
    wire                                    rd_en;

    reg[511:0]                              x_data_out_pre1,x_data_out_pre2,x_data_out_pre3;
    reg                                     x_data_out_valid_pre1,x_data_out_valid_pre2,x_data_out_valid_pre3;
    reg                                     x_data_out_almost_full_r1,x_data_out_almost_full_r2,x_data_out_almost_full_r3;


    always @(posedge clk) begin
        if(~rst_n)begin
            started_r  <= 1'b0;
            started_r2 <= 1'b0;
            started_r3 <= 1'b0; //1'b0;
        end 
        else begin
            started_r  <= started;   //1'b0;
            started_r2 <= started_r; //1'b0;
            started_r3 <= started_r2; //1'b0;
        end 
    end

    always @(posedge clk) begin
        inner_index_r                       <= {inner_index_r[7:0],inner_index};
        engine_index_r                      <= {engine_index_r[7:0],engine_index};
        dimension_index_r                   <= dimension_index;
        rd_en_r                             <= {rd_en_r[7:0],rd_en};
    end


    always @(posedge clk) begin
        if(~rst_n)begin
            writing_x_to_host_memory_en_r   <= 1'b0;
            writing_x_to_host_memory_en_r2  <= 1'b0;
            writing_x_to_host_memory_en_r3  <= 1'b0;
            writing_x_to_host_memory_en_r4  <= 1'b0;
        end 
        else begin
            writing_x_to_host_memory_en_r   <= writing_x_to_host_memory_en;
            writing_x_to_host_memory_en_r2  <= writing_x_to_host_memory_en_r;
            writing_x_to_host_memory_en_r3  <= writing_x_to_host_memory_en_r2;
            writing_x_to_host_memory_en_r4  <= writing_x_to_host_memory_en_r3;
        end 
    end

    always @(posedge clk) begin
        if(dimension < `ENGINE_NUM * `NUM_BITS_PER_BANK)
            dimension_minus                 <= 0;
        else
            dimension_minus                 <= dimension - `ENGINE_NUM * `NUM_BITS_PER_BANK;
    end

    always @(posedge clk) begin
        x_data_send_back_length             <= dimension << 5;
    end


    always @(posedge clk) begin
        if(~rst_n) begin
            x_data_out_pre1                 <= 0;  
            x_data_out_valid_pre1           <= 1'b0;                  
        end
        else if(rd_en_r[8])begin
            x_data_out_valid_pre1           <= 1'b1;
            case(inner_index_r[8])
                2'b00:begin
                    x_to_mem_wr_addr        <= engine_index_r[8];
                    x_to_mem_wr_data        <= x_mem_rd_data[engine_index_r[8]];
                    // x_data_out_pre1         <= x_mem_rd_data[engine_index_r[8]][511:0];
                end
                2'b01:begin
                    // x_data_out_pre1         <= x_mem_rd_data[engine_index_r[8]][1023:512];
                end
                2'b10:begin
                    // x_data_out_pre1         <= x_mem_rd_data[engine_index_r[8]][1535:1024];
                end
                2'b11:begin
                    // x_data_out_pre1         <= x_mem_rd_data[engine_index_r[8]][2047:1536];
                end
            endcase
        end
        else begin
            x_data_out_valid_pre1           <= 1'b0;
        end
    end



distram_2port #(.DATA_WIDTH      (512),    
                 .DEPTH_BIT_WIDTH (6         )
) inst_x_updated (
    .clock     ( clk                ),
    .data      ( x_to_mem_wr_data  ),
    .wraddress ( x_to_mem_wr_addr  ),
    .wren      ( x_to_mem_wr_en    ),
    .rdaddress ( x_to_mem_rd_addr), 
    .q         ( x_to_mem_rd_data  )
);



    always @(posedge clk) begin
        x_data_out_pre2                     <= x_data_out_pre1;
        x_data_out_pre3                     <= x_data_out_pre2;
        x_data_out                          <= x_data_out_pre3;
        x_data_out_valid_pre2               <= x_data_out_valid_pre1;
        x_data_out_valid_pre3               <= x_data_out_valid_pre2;
        x_data_out_valid                    <= x_data_out_valid_pre3;
        x_data_out_almost_full_r1           <= x_data_out_almost_full;
        x_data_out_almost_full_r2           <= x_data_out_almost_full_r1;
        x_data_out_almost_full_r3           <= x_data_out_almost_full_r2;
    end

    

    localparam [3:0]    IDLE            = 4'b0001,
                        WRITE_MEM_EPOCH = 4'b0010,
                        WRITE_MEM_DATA  = 4'b0100,
                        WRITE_MEM_END   = 4'b1000;

    reg [3:0]                           cstate,nstate;                    

    assign rd_en                        = ~x_data_out_almost_full_r3 & cstate[2];

    always @(posedge clk) begin
        if(~rst_n)
            cstate                      <= IDLE;
        else
            cstate                      <= nstate;
    end

    always @(*) begin
        case(cstate)
            IDLE:begin
                if(started_r3)
                    nstate              = WRITE_MEM_EPOCH;
                else
                    nstate              = IDLE;
            end
            WRITE_MEM_EPOCH:begin
                if(epoch_index == numEpochs)begin
                    nstate              = WRITE_MEM_END;
                end
                if((~writing_x_to_host_memory_en_r4) & writing_x_to_host_memory_en_r3)begin
                    nstate              = WRITE_MEM_DATA;
                end
                else begin
                    nstate              = WRITE_MEM_EPOCH;
                end
            end
            WRITE_MEM_DATA:begin
                if(rd_en) begin
                    nstate                      = WRITE_MEM_DATA;
                    if(inner_index == 2'b11) begin
                        nstate                  = WRITE_MEM_DATA;
                        if(engine_index >= `ENGINE_NUM-1)begin
                            nstate              = WRITE_MEM_DATA;
                            if(dimension_index >= dimension_minus)begin
                                nstate          = WRITE_MEM_EPOCH;
                            end
                        end
                    end
                end
            end
            WRITE_MEM_END:begin
                nstate                          = IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        case(cstate)
            IDLE:begin
                inner_index                     <= 1'b0;
                engine_index                    <= 8'b0;
                dimension_index                 <= 32'b0;
                epoch_index                     <= 32'b0;
                writing_x_to_host_memory_done   <= 1'b0;

                x_data_send_back_start          <= 1'b0;
                x_data_send_back_addr           <= addr_model;

                x_mem_rd_addr                   <= 0;

            end
            WRITE_MEM_EPOCH:begin
                if(epoch_index == numEpochs)begin
                end
                if((~writing_x_to_host_memory_en_r4) & writing_x_to_host_memory_en_r3)begin
                    epoch_index                 <= epoch_index + 1'b1;
                    x_data_send_back_start      <= 1'b1;
                    x_data_send_back_addr       <= x_data_send_back_addr + x_data_send_back_length;
                end
                else begin
                end
            end
            WRITE_MEM_DATA:begin
                if(rd_en) begin
                    inner_index         <= inner_index + 1 ;
                    if(inner_index == 2'b11) begin
                        engine_index    <= engine_index + 1;
                        if(engine_index >= `ENGINE_NUM-1)begin
                            engine_index        <= 0;
                            dimension_index     <= dimension_index + `ENGINE_NUM * `NUM_BITS_PER_BANK;
                            x_mem_rd_addr       <= x_mem_rd_addr + 1;
                            if(dimension_index >= dimension_minus)begin
                                dimension_index <= 0;
                                x_mem_rd_addr   <= 0;
                            end
                        end
                    end
                end
            end
            WRITE_MEM_END:begin
                writing_x_to_host_memory_done   <= 1'b1;
            end
        endcase
    end




endmodule
