`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/02/11 13:32:27
// Design Name: 
// Module Name: tb_sgd_bw_top
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


module tb_sgd_bw_top(

    );

    reg                                 clk,rst_n;
    reg                                   start_um;
    reg [511:0]                           um_params;

    reg [63:0] addr_a;
    reg [63:0] addr_b;
    reg [63:0] addr_model;
    reg [31:0] mini_batch_size;
    reg [31:0] step_size;
    reg [31:0] number_of_epochs;
    reg [31:0] dimension;
    reg [31:0] number_of_samples;
    reg [31:0] number_of_bits;    

    reg[31:0] a[1866496:0];
    reg[31:0] b[7291:0];


    // TX RD
    //wire  [57:0]                           hbm_axi.araddr; //reg
    wire  [7:0]                            um_tx_rd_tag;  //reg
    wire                                   um_tx_rd_valid;//reg
    wire                                   um_tx_rd_ready; //connected to almost full signal. Send one more request after full signal.
    // RX RD
    
    
    wire                                   um_rx_rd_valid;
    wire                                   um_rx_rd_ready;

    axi_mm          hbm_axi[`ENGINE_NUM]();
    axi_stream      m_axi_c2h_data();


    assign um_params = {128'b0,number_of_bits,number_of_samples,dimension,number_of_epochs,step_size,mini_batch_size,addr_model,addr_b,addr_a};

    always @(posedge clk) 
    begin 
            addr_a           <= 0; //no need of [5:0], cache line aligned... Mohsen
            addr_b           <= 32'h20000000;
            addr_model       <= 32'h40000000;
            mini_batch_size  <= 16;
            step_size        <= 16;
            number_of_epochs <= 3;
            dimension        <= 256;    
            number_of_samples<= 7288;
            number_of_bits   <= 8;    
    end


    initial begin
        $readmemh("/home/ccai/distributed_sgd/a_ups.txt",a,0,1866496);
        $readmemh("/home/ccai/distributed_sgd/b_ups.txt",b,0,7291);
        clk = 1'b1;
        rst_n = 1'b0;
        start_um = 1'b0;
        #1000
        rst_n = 1'b1;
        #1000
        start_um = 1'b1;
    end

    always #5 clk = ~clk;
//generate end generate
genvar i;
// Instantiate engines
generate
for(i = 0; i < `ENGINE_NUM; i++) 
begin
    reg  [511:0]                           um_rx_data;
    reg [7:0]                             um_rx_rd_tag;
    assign hbm_axi[i].arready = cstate[0];

    assign hbm_axi[i].rvalid = cstate[2];

    localparam      IDLE = 4'b0001;
    localparam      ADDR = 4'b0010;
    localparam      DATA = 4'b0100;

    reg [3:0]       cstate;
    reg [3:0]       nstate;

    always @(posedge clk)begin
        if(~rst_n)begin
            cstate  <= IDLE;
        end
        else begin
            cstate <= nstate;
        end        
    end 

    always @(*)begin
        case(cstate)
            IDLE:begin
                if(hbm_axi[i].arvalid & hbm_axi[i].arready)
                    nstate <= ADDR;
                else
                    nstate <= IDLE;
            end
            ADDR:begin
                if(hbm_axi[i].araddr<32'h800000)begin
                    um_rx_data  <= {a[hbm_axi[i].araddr*16+15],a[hbm_axi[i].araddr*16+14],a[hbm_axi[i].araddr*16+13],a[hbm_axi[i].araddr*16+12],
                            a[hbm_axi[i].araddr*16+11],a[hbm_axi[i].araddr*16+10],a[hbm_axi[i].araddr*16+9],a[hbm_axi[i].araddr*16+8],
                            a[hbm_axi[i].araddr*16+7],a[hbm_axi[i].araddr*16+6],a[hbm_axi[i].araddr*16+5],a[hbm_axi[i].araddr*16+4],
                            a[hbm_axi[i].araddr*16+3],a[hbm_axi[i].araddr*16+2],a[hbm_axi[i].araddr*16+1],a[hbm_axi[i].araddr*16]};
                    um_rx_rd_tag <= `MEM_RD_A_TAG;   
                end     
                else begin
                    um_rx_data  <= {b[(hbm_axi[i].araddr-32'h800000)*16+15],b[(hbm_axi[i].araddr-32'h800000)*16+14],b[(hbm_axi[i].araddr-32'h800000)*16+13],b[(hbm_axi[i].araddr-32'h800000)*16+12],
                            b[(hbm_axi[i].araddr-32'h800000)*16+11],b[(hbm_axi[i].araddr-32'h800000)*16+10],b[(hbm_axi[i].araddr-32'h800000)*16+9],b[(hbm_axi[i].araddr-32'h800000)*16+8],
                            b[(hbm_axi[i].araddr-32'h800000)*16+7],b[(hbm_axi[i].araddr-32'h800000)*16+6],b[(hbm_axi[i].araddr-32'h800000)*16+5],b[(hbm_axi[i].araddr-32'h800000)*16+4],
                            b[(hbm_axi[i].araddr-32'h800000)*16+3],b[(hbm_axi[i].araddr-32'h800000)*16+2],b[(hbm_axi[i].araddr-32'h800000)*16+1],b[(hbm_axi[i].araddr-32'h800000)*16]};
                    um_rx_rd_tag <= `MEM_RD_B_TAG;  
                end
                nstate <= DATA;
            end
            DATA:begin
                if(hbm_axi[i].rready && hbm_axi[i].rvalid)
                    nstate <= IDLE;
                else
                    nstate <= DATA;
            end
            default:begin
                nstate <= IDLE;
            end
        endcase

    end   

end
endgenerate
    assign m_axi_c2h_data.ready = 1;

sgd_top_bw inst_sgd_top_bw(
    .clk(clk),
    .rst_n(rst_n),
    //-------------------------------------------------//
    .start_um(start_um),
    .um_params(um_params),
    .um_done(),
    .um_state_counters(),

    .dispatch_axb_a_data(),
    .dispatch_axb_a_wr_en(),
    .dispatch_axb_a_almost_full(),

    .dispatch_axb_b_data(),
    .dispatch_axb_b_wr_en(),   
    .m_axi_c2h_data(m_axi_c2h_data)

);





endmodule