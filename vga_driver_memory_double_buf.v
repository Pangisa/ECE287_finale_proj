module vga_driver_memory_double_buf	(
  // Clock Inputs
  input         CLOCK_50,    // 50MHz Input 1


  // Push Button
  input  [3:0]  KEY,         // Pushbutton[3:0]

  // DPDT Switch
  input  [17:0] SW,          // Toggle Switch[17:0]

  input [14:0]external_address,
  input [23:0]external_data,
  input external_start,

  // VGA
  output        VGA_CLK,     // VGA Clock
  output        VGA_HS,      // VGA H_SYNC
  output        VGA_VS,      // VGA V_SYNC
  output        VGA_BLANK_N, // VGA BLANK
  output        VGA_SYNC_N,  // VGA SYNC
  output reg [7:0]  VGA_R,       // VGA Red[9:0]
  output reg [7:0]  VGA_G,       // VGA Green[9:0]
  output reg [7:0]  VGA_B			// VGA Blue[9:0]
  
  
);
/////////////////////////////////////////////////////////////////////////////


/* HANDLE SIGNALS FOR CIRCUIT */
wire clk;
wire rst;

assign clk = CLOCK_50;
assign rst = KEY[0];

wire [17:0]SW_db;

debounce_switches db(
.clk(clk),
.rst(rst),
.SW(SW), 
.SW_db(SW_db)
);
/* -------------------------------- */

/* DEBUG SIGNALS */
//assign LEDR[0] = active_pixels;

/* -------------------------------- */
// VGA DRIVER
wire active_pixels; // is on when we're in the active draw space
wire frame_done;

wire [9:0]x; // current x
wire [9:0]y; // current y - 10 bits = 1024 ... a little bit more than we need

/* signals that will be combinationally swapped in each cycle */
reg [1:0]wr_id;	
reg [14:0] write_buf_mem_address;
reg [23:0] write_buf_mem_data;
reg write_buf_mem_wren;
reg [23:0]read_buf_mem_q;
reg [14:0] read_buf_mem_address;

vga_driver the_vga(
.clk(clk),
.rst(rst),

.vga_clk(VGA_CLK),

.hsync(VGA_HS),
.vsync(VGA_VS),

.active_pixels(active_pixels),
.frame_done(frame_done),

.xPixel(x),
.yPixel(y),

.VGA_BLANK_N(VGA_BLANK_N),
.VGA_SYNC_N(VGA_SYNC_N)
);

always @(*)
begin
	/* This part is for taking the memory value read out from memory and sending to the VGA */
	if (S == RFM_INIT_WAIT || S == RFM_INIT_START || S == RFM_DRAWING)
	begin
		{VGA_R, VGA_G, VGA_B} = read_buf_mem_q;
	end
	else // BLACK OTHERWISE
		{VGA_R, VGA_G, VGA_B} = 24'hFFFFFF;
end

/* -------------------------------- */
/* 	FSM to control the writing and reading of the framebuffer. */
reg [15:0]i;
reg [7:0]S;
reg [7:0]NS;
parameter 
	START 			= 8'd0,
//	// W2M is write to memory
//	W2M_INIT 		= 8'd1,
//	W2M_COND 		= 8'd2,
//	W2M_INC 		= 8'd3,
	W2M_DONE 		= 8'd4,
	// The RFM = READ_FROM_MEMOERY reading cycles
	RFM_INIT_START 	= 8'd5,
	RFM_INIT_WAIT 	= 8'd6,
	RFM_DRAWING 	= 8'd7,
	//Error
	ERROR 			= 8'hFF;

parameter MEMORY_SIZE = 16'd19200; // 160*120 // Number of memory spots ... highly reduced since memory is slow
parameter PIXEL_VIRTUAL_SIZE = 16'd4; // Pixels per spot - therefore 4x4 pixels per memory location

/* ACTUAL VGA RESOLUTION */
parameter VGA_WIDTH = 16'd640; 
parameter VGA_HEIGHT = 16'd480;

/* Our reduced RESOLUTION */
parameter VIRTUAL_PIXEL_WIDTH = VGA_WIDTH / PIXEL_VIRTUAL_SIZE; // 160
parameter VIRTUAL_PIXEL_HEIGHT = VGA_HEIGHT / PIXEL_VIRTUAL_SIZE; // 120

/* Calculate NS */
always @(*)
	case (S)
		START: 	
		NS = W2M_DONE;
		
		W2M_DONE: 
			if (frame_done == 1'b1)
				NS = RFM_INIT_START;
			else
				NS = W2M_DONE;
				
	
		RFM_INIT_START: NS = RFM_INIT_WAIT;
		RFM_INIT_WAIT: 
			if (frame_done == 1'b0)
				NS = RFM_DRAWING;
			else	
				NS = RFM_INIT_WAIT;
		RFM_DRAWING:
			if (frame_done == 1'b1)
				NS = RFM_INIT_START;
			else
				NS = RFM_DRAWING;
		default:	NS = ERROR;
	endcase

always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
			S <= START;
	end
	else
	begin
			S <= NS;
	end
end

/* 
The code goes through a write phase (after reset) and an endless read phase once writing is done.

The W2M (write to memory) code is roughly:
for (i = 0; i < MEMORY_SIZE; i++)
	mem[i] = color // where color is a hard coded on off is on SW[16:14] for {R, G, B}

The RFM (read from memory) is synced with the VGA display (via vga_driver modules x and y) which goes row by row
for (y = 0; y < 480; y++) // height
	for (x = 0; x < 640; x++) // width
		color = mem[(x/4 * VP_HEIGHT) + j/4] reads from one of the buffers while you can write to the other buffer
*/
always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0) 
	begin
		write_buf_mem_address <= 14'd0;
		write_buf_mem_data <= 24'd0;
		write_buf_mem_wren <= 1'd0;
		i <= 16'd0;
		wr_id <= MEM_INIT_WRITE;
	end
	else
	begin
		case (S)
			START:
			begin
				write_buf_mem_address <= 14'd0;
				write_buf_mem_data <= 24'd0;
				write_buf_mem_wren <= 1'd0;
				i <= 16'd0;
				wr_id <= MEM_INIT_WRITE;
			end

			
			W2M_DONE: write_buf_mem_wren <= 1'd0; // turn off writing to memory
			RFM_INIT_START: 
			begin
				write_buf_mem_wren <= 1'd0; // turn off writing to memory
				
				/* swap the buffers after each frame...the double buffer */
				if (wr_id == MEM_INIT_WRITE)
					wr_id <= MEM_M0_READ_M1_WRITE;
				else if (wr_id == MEM_M0_READ_M1_WRITE)
					wr_id <= MEM_M0_WRITE_M1_READ;
				else
					wr_id <= MEM_M0_READ_M1_WRITE;
					
				////////////////////////^BUFFER^////////////////////////////
								
				if (y < VGA_HEIGHT-1 && x < VGA_WIDTH-1) // or use the active_pixels signal
					read_buf_mem_address <= (x/PIXEL_VIRTUAL_SIZE) * VIRTUAL_PIXEL_HEIGHT + (y/PIXEL_VIRTUAL_SIZE) ;
			end
			RFM_INIT_WAIT: //(frame_done = 1'b1) means loop state // else next state
			begin
				if (y < VGA_HEIGHT-1 && x < VGA_WIDTH-1) // or use the active_pixels signal
					read_buf_mem_address <= (x/PIXEL_VIRTUAL_SIZE) * VIRTUAL_PIXEL_HEIGHT + (y/PIXEL_VIRTUAL_SIZE) ;
			end 
			RFM_DRAWING: //(frame_done == 1'b1) loops back to RFM_INIT_START (frame_done == 1'b0) Loop this state
			begin		
				if (y < VGA_HEIGHT-1 && x < VGA_WIDTH-1)
					read_buf_mem_address <= (x/PIXEL_VIRTUAL_SIZE) * VIRTUAL_PIXEL_HEIGHT + (y/PIXEL_VIRTUAL_SIZE) ;
				
				if (external_start == 1'b1) 
				begin
					write_buf_mem_address <= external_address;
					write_buf_mem_data <= external_data;
					write_buf_mem_wren <= 1'b1;
				end
				else
					write_buf_mem_wren <= 1'b0;
					
			end	
		endcase
	end
end



/* -------------------------------- */
/* MEMORY to STORE a MINI framebuffer.  Problem is the FPGA's on-chip memory can't hold an entire frame 640*480 , so some
form of compression is needed.  I show a simple compress the image to 16 pixels or a 4 by 4, but this memory
could handle more */
reg [14:0] frame_buf_mem_address0;
reg [23:0] frame_buf_mem_data0;
reg frame_buf_mem_wren0;
wire [23:0]frame_buf_mem_q0;

vga_frame vga_memory0(
	frame_buf_mem_address0,
	clk,
	frame_buf_mem_data0,
	frame_buf_mem_wren0,
	frame_buf_mem_q0);
	
reg [14:0] frame_buf_mem_address1;
reg [23:0] frame_buf_mem_data1;
reg frame_buf_mem_wren1;
wire [23:0]frame_buf_mem_q1;


vga_frame vga_memory1(
	frame_buf_mem_address1,
	clk,
	frame_buf_mem_data1,
	frame_buf_mem_wren1,
	frame_buf_mem_q1);


parameter MEM_INIT_WRITE = 2'd0,
		  MEM_M0_READ_M1_WRITE = 2'd1,
		  MEM_M0_WRITE_M1_READ = 2'd2,
		  MEM_ERROR = 2'd3;

/* signals that will be combinationally swapped in each buffer output that swaps between wr_id where wr_id = 0 is for initialize */
always @(*)
begin
	if (wr_id == MEM_INIT_WRITE) // WRITING to BOTH
	begin
		frame_buf_mem_address0 = write_buf_mem_address;
		frame_buf_mem_data0 = write_buf_mem_data;
		frame_buf_mem_wren0 = write_buf_mem_wren;
		frame_buf_mem_address1 = write_buf_mem_address;
		frame_buf_mem_data1 = write_buf_mem_data;
		frame_buf_mem_wren1 = write_buf_mem_wren;
		
		read_buf_mem_q = frame_buf_mem_q1; // doesn't matter
	end
	else if (wr_id == MEM_M0_WRITE_M1_READ) // WRITING to MEM 0 READING FROM MEM 1
	begin
		// MEM 0 - WRITE
		frame_buf_mem_address0 = write_buf_mem_address;
		frame_buf_mem_data0 = write_buf_mem_data;
		frame_buf_mem_wren0 = write_buf_mem_wren;
		// MEM 1 - READ
		frame_buf_mem_address1 = read_buf_mem_address;
		frame_buf_mem_data1 = 24'd0;
		frame_buf_mem_wren1 = 1'b0;
		read_buf_mem_q = frame_buf_mem_q1;
	end
	else //if (wr_id == MEM_M0_READ_M1_WRITE) WRITING to MEM 1 READING FROM MEM 0
	begin
		// MEM 0 - READ
		frame_buf_mem_address0 = read_buf_mem_address;
		frame_buf_mem_data0 = 24'd0;
		frame_buf_mem_wren0 = 1'b0;
		read_buf_mem_q = frame_buf_mem_q0;
		// MEM 1 - WRITE
		frame_buf_mem_address1 = write_buf_mem_address;
		frame_buf_mem_data1 = write_buf_mem_data;
		frame_buf_mem_wren1 = write_buf_mem_wren;
	end
end

endmodule