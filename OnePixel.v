module OnePixel(rst,clk,draw_en,startx,starty,color, finished, write_mem_address,data,x,y);

//control
input rst;
input clk;
input draw_en;

//data in
input [9:0]startx;
input [9:0]starty;
input [23:0]color;

//data out
output reg finished;
output reg [14:0]write_mem_address;
output reg [23:0]data;
output reg [9:0]x;
output reg [9:0]y;


reg [3:0]S;
reg [3:0]NS;

parameter VGA_WIDTH = 16'd640; 
parameter VGA_HEIGHT = 16'd480; 
parameter PIXEL_VIRTUAL_SIZE = 4'd4;
//virtual pixel needed to limit memory size
parameter VIRTUAL_PIXEL_HEIGHT =  VGA_HEIGHT / PIXEL_VIRTUAL_SIZE;


parameter START = 4'd0,
			BOUNDRY_CHECK = 4'd1,
			DRAW = 4'd2,
			DONE= 4'd3;
			
//FSM transitioner
always @(posedge clk or negedge rst)
	if (rst == 1'b0)
	S <= START;
	else
	S <= NS;
	
	
//Transitions for FSM
always @(*)
begin
		data = color;

	case(S)
	START: if (rst == 1'b0)
			NS = START;
			else
			NS = BOUNDRY_CHECK;
	
	BOUNDRY_CHECK: if (startx <= VGA_WIDTH & starty <= VGA_HEIGHT & draw_en == 1'b1)
		NS = DRAW;
		else if (draw_en == 1'b0)
		NS = START;
		else
		NS = DONE;

	DRAW: NS = DONE;
	
	DONE: if (draw_en == 1'b1)
		NS = DONE;
		else
		NS = START;
	
	endcase
end	
	
always @(posedge clk or negedge rst)

	if (rst == 1'b0)
	begin
	
		x <= startx;
		y <= starty;
		write_mem_address <= 15'd0;
		finished <= 1'b0;
		
	end	
	else
		
		case(S)
		
			START: begin 
				x <= startx;
				y <= starty;
				write_mem_address <= 15'd0;
				finished <= 1'b0;
					end		
			
			// write_mem_address mapping 
			DRAW: write_mem_address <= (x/PIXEL_VIRTUAL_SIZE) * VIRTUAL_PIXEL_HEIGHT + (y/PIXEL_VIRTUAL_SIZE);
			
			DONE: begin 
					finished <= 1'b1;
					x <= 10'd0;
					y <= 10'd0;
					write_mem_address <= 15'd20;
					end
			
		endcase



		

endmodule	