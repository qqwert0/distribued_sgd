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
    parameter TREE_WIDTH = 8;
    parameter TREE_DEPTH = 3;
    reg clk;
    reg rst_n;
    reg  signed                    [31:0] v_input[9-1:0];       //
    reg                                   v_input_valid;  //    

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
    for(i = 0; i < 9; i++) begin
        assign v_input[i] = i;
    end
    endgenerate



    always #5 clk = ~clk;

sgd_adder_tree #(
    .TREE_DEPTH          (3)
)inst(
    .clk(clk),
    .rst_n(rst_n),
    //--------------------------Begin/Stop-----------------------------//

    //---------------------Input: External Memory rd response-----------------//
    .v_input(v_input),       //
    .v_input_valid(v_input_valid),  //

    //------------------Output: disptach resp data to b of each bank---------------//
    .v_output(), 
    .v_output_valid() 
);

endmodule
