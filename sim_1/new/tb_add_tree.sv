`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/08 20:45:55
// Design Name: 
// Module Name: tb_add_tree
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


module tb_add_tree(

    );
    parameter TREE_WIDTH = 16;
    parameter TREE_DEPTH = 4;
    reg clk;
    reg rst_n;
    reg  signed                    [31:0] v_input[7:0];       //
    reg                                   v_input_valid;
    reg                                   v_input_enable[7:0];  //    

    initial begin
        clk = 1;
        rst_n = 0;
        v_input_valid = 0;
        #200
        rst_n = 1;
        #100
        v_input_valid = 1;
        #10
        v_input_valid = 0;
    end

    //generate end generate
    genvar i;
    // Instantiate engines
    generate
    for(i = 0; i < 8; i++) begin
//        always @(posedge clk)begin
//            if(~rst_n)
//                v_input_enable[i] =  i;
//            else 
//                v_input_enable[i] =  ~v_input_enable[i];
//        end
        initial begin
            v_input_enable[i] = i;
            #400
            v_input_enable[i] = ~v_input_enable[i];
            #30
            v_input_enable[i] = ~v_input_enable[i];
            #30
            v_input_enable[i] = ~v_input_enable[i];                        
        end
    end
    endgenerate
    generate
    for(i = 0; i < 8; i++) begin
        always @(posedge clk)begin
            if(~rst_n)
                v_input[i] =  i;
            else 
                v_input[i] =  v_input[i] + 1;
        end
    end
    endgenerate


    always #5 clk = ~clk;

sgd_dsp_add_tree #(
    .TREE_DEPTH          (3)
)inst(
    .clk(clk),
    .rst_n(rst_n),
    //--------------------------Begin/Stop-----------------------------//

    //---------------------Input: External Memory rd response-----------------//
    .v_input(v_input),       //
    .v_input_valid(v_input_valid),  //
    .v_input_enable(v_input_enable),

    //------------------Output: disptach resp data to b of each bank---------------//
    .v_output(), 
    .v_output_valid() 
);

endmodule
