module debounce_switches(
input clk,
input rst,
input [17:0]SW, 
output reg [17:0] SW_db
);


wire [17:0]no;

DeBounce db0(clk, rst, SW[0], no[0]);
DeBounce db1(clk, rst, SW[1], no[1]);
DeBounce db2(clk, rst, SW[2], no[2]);
DeBounce db3(clk, rst, SW[3], no[3]);
DeBounce db4(clk, rst, SW[4], no[4]);
DeBounce db5(clk, rst, SW[5], no[5]);
DeBounce db6(clk, rst, SW[6], no[6]);
DeBounce db7(clk, rst, SW[7], no[7]);
DeBounce db10(clk, rst, SW[8], no[8]);
DeBounce db11(clk, rst, SW[9], no[9]);
DeBounce db12(clk, rst, SW[10], no[10]);
DeBounce db13(clk, rst, SW[11], no[11]);
DeBounce db14(clk, rst, SW[12], no[12]);
DeBounce db15(clk, rst, SW[13], no[13]);
DeBounce db16(clk, rst, SW[14], no[14]); 
DeBounce db17(clk, rst, SW[15], no[15]);
DeBounce db18(clk, rst, SW[16], no[16]);
DeBounce db19(clk, rst, SW[17], no[17]);

always @(*)

	SW_db = no;
	
endmodule




// DeBounce_v.v


//////////////////////// Button Debounceer ///////////////////////////////////////
//***********************************************************************
// FileName: DeBounce_v.v
// FPGA: MachXO2 7000HE
// IDE: Diamond 2.0.1 
//
// HDL IS PROVIDED "AS IS." DIGI-KEY EXPRESSLY DISCLAIMS ANY
// WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
// BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
// DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
// PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
// BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
// ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
// DIGI-KEY ALSO DISCLAIMS ANY LIABILITY FOR PATENT OR COPYRIGHT
// INFRINGEMENT.
//
// Version History
// Version 1.0 04/11/2013 Tony Storey
// Initial Public Release
// Small Footprint Button Debouncer

`timescale 1 ns / 100 ps
module  DeBounce 
	(
	input 			clk, n_reset, button_in,				// inputs
	output reg 	DB_out													// output
	);
//// ---------------- internal constants --------------
	parameter N = 11 ;		// (2^ (21-1) )/ 38 MHz = 32 ms debounce time
////---------------- internal variables ---------------
	reg  [N-1 : 0]	q_reg;							// timing regs
	reg  [N-1 : 0]	q_next;
	reg DFF1, DFF2;									// input flip-flops
	wire q_add;											// control flags
	wire q_reset;
//// ------------------------------------------------------

////contenious assignment for counter control
	assign q_reset = (DFF1  ^ DFF2);		// xor input flip flops to look for level chage to reset counter
	assign  q_add = ~(q_reg[N-1]);			// add to counter when q_reg msb is equal to 0
	
//// combo counter to manage q_next	
	always @ ( q_reset, q_add, q_reg)
		begin
			case( {q_reset , q_add})
				2'b00 :
						q_next <= q_reg;
				2'b01 :
						q_next <= q_reg + 1;
				default :
						q_next <= { N {1'b0} };
			endcase 	
		end
	
//// Flip flop inputs and q_reg update
	always @ ( posedge clk )
		begin
			if(n_reset ==  1'b0)
				begin
					DFF1 <= 1'b0;
					DFF2 <= 1'b0;
					q_reg <= { N {1'b0} };
				end
			else
				begin
					DFF1 <= button_in;
					DFF2 <= DFF1;
					q_reg <= q_next;
				end
		end
	
//// counter control
	always @ ( posedge clk )
		begin
			if(q_reg[N-1] == 1'b1)
					DB_out <= DFF2;
			else
					DB_out <= DB_out;
		end

	endmodule
