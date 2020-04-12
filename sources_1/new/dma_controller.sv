/*
 * Copyright (c) 2019, Systems Group, ETH Zurich
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
 `timescale 1ns / 1ps
`default_nettype none

//`include "davos_types.svh"

module dma_controller
(
    //clk
    input  wire         pcie_clk,
    input  wire         pcie_aresetn,
    // user clk
    input wire          user_clk,
    input wire          user_aresetn,

    // Control Interface
    // axi_lite.slave      s_axil,
    input wire bram_en_a,          // output wire bram_en_a
    input wire[3:0] bram_we_a,          // output wire [3 : 0] bram_we_a
    input wire[15:0] bram_addr_a,      // output wire [15 : 0] bram_addr_a
    input wire[31:0] bram_wrdata_a,  // output wire [31 : 0] bram_wrdata_a
    output wire[31:0] bram_rddata_a,  // input wire [31 : 0] bram_rddata_a
    // TLB command
    output reg         m_axis_tlb_interface_valid,
    input wire         m_axis_tlb_interface_ready,
    output reg[135:0]  m_axis_tlb_interface_data,

    //mlweaving parameter
    output reg         m_axis_mlweaving_valid,
    input wire         m_axis_mlweaving_ready,
    output reg[511:0]  m_axis_mlweaving_data,

    //tlb on same clock
    input wire[31:0]    tlb_miss_counter,
    input wire[31:0]    tlb_boundary_crossing_counter,

    //same clock
    input wire[31:0]    dma_write_cmd_counter,
    input wire[31:0]    dma_write_word_counter,
    input wire[31:0]    dma_write_pkg_counter,
    input wire[31:0]    dma_read_cmd_counter,
    input wire[31:0]    dma_read_word_counter,
    input wire[31:0]    dma_read_pkg_counter,
    output reg          reset_dma_write_length_counter,
    input wire[47:0]    dma_write_length_counter,
    output reg          reset_dma_read_length_counter,
    input wire[47:0]    dma_read_length_counter,
    input wire          dma_reads_flushed

);

localparam AXI_RESP_OK = 2'b00;
localparam AXI_RESP_SLVERR = 2'b10;


//WRITE states
localparam WRITE_IDLE = 0;
localparam WRITE_DATA = 1;
localparam WRITE_RESPONSE = 2;
localparam WRITE_TLB = 5;
localparam WRITE_MLWEAVING = 6;

//READ states
localparam READ_IDLE = 0;
//localparam READ_DATA = 1;
localparam READ_RESPONSE = 1;
localparam READ_RESPONSE2 = 2;
localparam WAIT_BRAM = 3;

//ADDRESES
localparam GPIO_REG_TLB         = 8'h02;
localparam GPIO_REG_DMA_BENCH   = 8'h03;
localparam GPIO_REG_DISTRIBUTE  = 8'h04;
localparam GPIO_REG_BOARDNUM    = 8'h07;
localparam GPIO_REG_IPADDR      = 8'h08;
localparam GPIO_REG_DMA_READS   = 8'h0A;
localparam GPIO_REG_DMA_WRITES  = 8'h0B;
//localparam GPIO_REG_DEBUG       = 8'h0C;
localparam GPIO_REG_DEBUG2      = 8'h0D;
//localparam GPIO_REG_DMA_BENCH_CYCLES = 8'h0E;

localparam NUM_DMA_DEBUG_REGS = 10;

localparam DEBUG_WRITE_CMD  = 8'h00;
localparam DEBUG_WRITE_WORD = 8'h01;
localparam DEBUG_WRITE_PKG  = 8'h02;
localparam DEBUG_WRITE_LEN  = 8'h03;
localparam DEBUG_READ_CMD   = 8'h04;
localparam DEBUG_READ_WORD  = 8'h05;
localparam DEBUG_READ_PKG   = 8'h06;
localparam DEBUG_READ_LEN   = 8'h07;
localparam DEBUG_TLB_MISS   = 8'h08;
localparam DEBUG_TLB_PAGE_CROSS = 8'h09;

//MLWEAVING PARAMETER REG
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
reg [31:0] array_length;
reg [31:0] channel_choice;

always @(posedge user_clk)begin
    if(~user_aresetn)begin
        m_axis_mlweaving_data           <= 512'b0;
    end
    else begin
        m_axis_mlweaving_data[ 63:0  ]  <= addr_a;
        m_axis_mlweaving_data[127:64 ]  <= addr_b;
        m_axis_mlweaving_data[191:128]  <= addr_model;
        m_axis_mlweaving_data[223:192]  <= mini_batch_size;
        m_axis_mlweaving_data[255:224]  <= step_size;
        m_axis_mlweaving_data[287:256]  <= number_of_epochs;
        m_axis_mlweaving_data[319:288]  <= dimension;    
        m_axis_mlweaving_data[351:320]  <= number_of_samples;
        m_axis_mlweaving_data[383:352]  <= number_of_bits;  
        m_axis_mlweaving_data[415:384]  <= data_a_length;   
        m_axis_mlweaving_data[447:416]  <= array_length;
        m_axis_mlweaving_data[479:448]  <= channel_choice;
    end
end



// ACTUAL LOGIC

reg[7:0] writeState;
reg[7:0] readState;

reg[31:0] writeAddr;
reg[31:0] readAddr;

reg[31:0] writeData;
reg[31:0] readData;   

reg[7:0] word_counter;

//handle writes
always @(posedge user_clk)
begin
    if (~user_aresetn) begin
        m_axis_tlb_interface_valid <= 1'b0;
        m_axis_mlweaving_valid <= 1'b0;
        word_counter <= 0;
        
        writeState <= WRITE_IDLE;
    end
    else begin
        case (writeState)
            WRITE_IDLE: begin
                m_axis_tlb_interface_valid <= 1'b0;                
                reset_dma_write_length_counter <= 1'b0;
                reset_dma_read_length_counter <= 1'b0;                
                if (bram_en_a && bram_we_a[0]) begin
                    writeState <= WRITE_DATA;
                    writeAddr <= (bram_addr_a[11:0] >> 5);
                    writeData <= bram_wrdata_a;
                end
            end //WRITE_IDLE
            WRITE_DATA: begin
                writeState <= WRITE_IDLE;
                case (writeAddr)
                    GPIO_REG_TLB: begin
                        word_counter <= word_counter + 1;
                        case(word_counter)
                            0: begin
                                m_axis_tlb_interface_data[31:0] <= writeData;
                            end
                            1: begin
                                m_axis_tlb_interface_data[63:32] <= writeData;
                            end
                            2: begin
                                m_axis_tlb_interface_data[95:64] <= writeData;
                            end
                            3: begin
                                m_axis_tlb_interface_data[127:96] <= writeData;
                            end
                            4: begin
                                m_axis_tlb_interface_data[128] <= writeData;
                                m_axis_tlb_interface_valid <= 1'b1;
                                word_counter <= 0;
                                writeState <= WRITE_TLB;
                            end
                        endcase
                    end
                    GPIO_REG_DISTRIBUTE:begin
                        word_counter <= word_counter + 1;
                        case(word_counter)
                            0:begin
                                addr_a[31:0]                    <= writeData;
                            end
                            1:begin
                                addr_a[63:32]                   <= writeData;
                            end
                            2:begin
                                addr_b[31:0]                    <= writeData;
                            end
                            3:begin
                                addr_b[63:32]                   <= writeData;
                            end
                            4:begin
                                addr_model[31:0]                <= writeData;
                            end
                            5:begin
                                addr_model[63:32]               <= writeData;
                            end
                            6:begin
                                mini_batch_size                 <= writeData;
                            end
                            7:begin
                                step_size                       <= writeData;
                            end
                            8:begin
                                number_of_epochs                <= writeData;
                            end
                            9:begin
                                dimension                       <= writeData;
                            end
                            10:begin
                                number_of_samples               <= writeData;
                            end
                            11:begin
                                number_of_bits                  <= writeData;
                            end
                            12:begin
                                data_a_length                   <= writeData;
                            end
                            13:begin
                                array_length                    <= writeData;
                            end
                            14:begin
                                channel_choice                  <= writeData;                                
                                // m_axis_mlweaving_valid          <= 1'b1;
                                word_counter <= 0;
                                writeState <= WRITE_MLWEAVING;
                            end
                        endcase
                    end                            
                    GPIO_REG_DMA_READS: begin
                        reset_dma_read_length_counter <= 1'b1;
                        writeState <= WRITE_IDLE;
                    end
                    GPIO_REG_DMA_WRITES: begin
                        reset_dma_write_length_counter <= 1'b1;
                        writeState <= WRITE_IDLE;
                    end
                endcase
            end //WRITE_DATA
            WRITE_TLB: begin
                m_axis_tlb_interface_valid <= 1'b1;
                if (m_axis_tlb_interface_valid && m_axis_tlb_interface_ready) begin
                    m_axis_tlb_interface_valid <= 1'b0;
                    writeState <= WRITE_IDLE;
                end
            end
            WRITE_MLWEAVING: begin
                m_axis_mlweaving_valid <= 1'b1;
                if (m_axis_mlweaving_valid && m_axis_mlweaving_ready) begin
                    m_axis_mlweaving_valid <= 1'b0;
                    writeState <= WRITE_IDLE;
                end
            end            
        endcase
    end
end

//reads are currently not available
reg [7:0] debugRegAddr;
reg dma_read_length_upper;
reg dma_write_length_upper;
assign bram_rddata_a = readData;
always @(posedge user_clk)
begin
    if (~user_aresetn) begin
        readState <= READ_IDLE;
        //read_addr <= 0;
        debugRegAddr <= 0;
        dma_read_length_upper <= 0;
        dma_write_length_upper <= 0;
    end
    else begin      
        case (readState)
            READ_IDLE: begin
                //read_en <= 1;
                if (bram_en_a && (~bram_we_a[0])) begin
                    readAddr <= (bram_addr_a[11:0] >> 5);
                    readState <= READ_RESPONSE;
                end
                if (debugRegAddr == NUM_DMA_DEBUG_REGS) begin
                    debugRegAddr <= 0;
                end
            end
            READ_RESPONSE: begin
                case (readAddr)
                    GPIO_REG_DMA_READS: begin
                        if (dma_reads_flushed) begin
                            if (!dma_read_length_upper) begin
                                readData <= dma_read_length_counter[31:0];
                            end
                            else begin
                                readData[15:0] <= dma_read_length_counter[47:32];
                                readData[31:16] <= 0;
                            end
                        end
                        else begin
                            readData <= 0;
                        end
                    end
                    GPIO_REG_DMA_WRITES: begin
                        if (!dma_write_length_upper) begin
                            readData <= dma_write_length_counter[31:0];
                        end
                        else begin
                            readData[15:0] <= dma_write_length_counter[47:32];
                            readData[31:16] <= 0;
                        end
                    end
                    /*GPIO_REG_DEBUG: begin
                        s_axil.rdata <= read_data;
                    end*/
                    GPIO_REG_DEBUG2: begin
                        case (debugRegAddr)
                            DEBUG_WRITE_CMD: begin
                                 readData <= dma_write_cmd_counter;
                            end
                            DEBUG_WRITE_WORD: begin
                                 readData <= dma_write_word_counter;
                            end
                            DEBUG_WRITE_PKG: begin
                                 readData <= dma_write_pkg_counter;
                            end
                            DEBUG_WRITE_LEN: begin
                                readData <= dma_write_length_counter[31:0];
                            end
                            DEBUG_READ_CMD: begin
                                 readData <= dma_read_cmd_counter;
                            end
                            DEBUG_READ_WORD: begin
                                 readData <= dma_read_word_counter;
                            end
                            DEBUG_READ_PKG: begin
                                 readData <= dma_read_pkg_counter;
                            end
                            DEBUG_READ_LEN: begin
                                readData <= dma_read_length_counter[31:0];
                            end
                            DEBUG_TLB_MISS: begin
                                readData <= tlb_miss_counter;
                            end
                            DEBUG_TLB_PAGE_CROSS: begin
                                readData <= tlb_boundary_crossing_counter;
                            end
                            default: begin
                                readData <= 0;
                            end
                        endcase
                    end
                    default: begin
                        readData <= 32'hdeadbeef;
                    end
                endcase
                if (readAddr == GPIO_REG_DEBUG2) begin
                    debugRegAddr <= debugRegAddr + 1;
                end
                if (readAddr == GPIO_REG_DMA_READS) begin
                    dma_read_length_upper <= ~dma_read_length_upper;
                end
                if (readAddr == GPIO_REG_DMA_WRITES) begin
                    dma_write_length_upper <= ~dma_write_length_upper;
                end
                readState <= READ_IDLE;
            end
        endcase
    end
end


//ila_4 ila4 (
//	.clk(user_clk), // input wire clk


//	.probe0(debugRegAddr), // input wire [7:0]  probe0  
//	.probe1(readAddr), // input wire [31:0]  probe1 
//	.probe2(dma_write_word_counter), // input wire [31:0]  probe2 
//	.probe3(dma_read_word_counter) // input wire [31:0]  probe3
//);


endmodule
`default_nettype wire
