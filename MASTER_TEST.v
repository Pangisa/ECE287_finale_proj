module MASTER_TEST(
	input         CLOCK_50,    // 50MHz Input 1
 
  // Push Button
  input  [3:0]  KEY,         // Pushbutton[3:0]

  // DPDT Switch
  input  [17:0] SW,          // Toggle Switch[17:0]

  
  // VGA
  output        VGA_CLK,     // VGA Clock
  output        VGA_HS,      // VGA H_SYNC
  output        VGA_VS,      // VGA V_SYNC
  output        VGA_BLANK_N, // VGA BLANK
  output        VGA_SYNC_N,  // VGA SYNC
  output [7:0]  VGA_R,       // VGA Red[9:0]
  output [7:0]  VGA_G,       // VGA Green[9:0]
  output [7:0]  VGA_B,       // VGA Blue[9:0]
  output reg [14:0]external_address // going into dub_buf from OnePixel
);


//for the connections between dub_buf and OnePixel
reg  [23:0]external_data;
wire [23:0]data;
wire finished;
wire [14:0]write_mem_address;
reg external_start;


wire [9:0]x;
wire [9:0]y;

wire [17:0]SW_db;
reg [17:0]db_out;
assign clk = CLOCK_50;


debounce_switches db(
.clk(clk),
.rst(KEY[1]),
.SW(SW[17:0]), 
.SW_db(SW_db[17:0])
);


assign clk = CLOCK_50;

always @(*)begin

	external_address = write_mem_address;
	
	external_data = data;
	
	external_start = finished;
	db_out = SW_db;

end

OnePixel pixel (SW[0],clk,SW[1],10'd400,10'd200,24'h000000, finished, write_mem_address,data,x,y);
//entries 4,5,6 are for x position, yposition, and color respectively


vga_driver_memory_double_buf	VGA_MODULE (CLOCK_50, KEY, db_out, external_address, external_data, external_start , VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B);
 


endmodule