# TITLE: Pixel Drawer using VGA on FPGA Board DE2-115
-DISCLAIMER: Nothing in this project works as intended.\
-Tools Needed: Quartus Prime Lite Edition ver 16.1 (Publisher: Intel)\
-Recommended Skills: Knowledge of Verilog HDL and ModelSim (version used is 10.5b)\

## PROJECT HIGH LEVEL DESCRIPTION: 

This project intends to draw a colored pixel onto a monitor using the VGA port of a DE2-115 board.  The code is written to be hierarchical so that complexity can be layered on top of existing modules. The top level module (in MASTER_TEST.v) will parse signals to and from “child” modules but will not perform any other function. This project has two main child modules before the VGA module which are contained in files debounce_switches.v and DrawBox.v. debounce_switches makes it so that the toggle-able switches behave as perfect switches and DrawBox sends coordinates and color signals in the form of a memory address and memory data signal.  The VGA module vga_driver_memory_double_buf.v receives these inputs and when it is enabled (a signal sent by DrawBox) writes the inputs to a memory of 19200 words each of which is 24 bits long.  There are two instantiations of this memory and each frame the reading is swapped so that data can be written to the other.

## GENERAL NOTES:
 
All clock signal are synced to a 50 MHz clock and are referenced within the project as clk or by the pin CLOCK_50. The project in most cases is default to a reset condition. Reset is turned off when the appropriate control goes high. For most of the project that is SW[0].  This also includes module vga_driver_memory_double_buf , but since the reset is controlled by KEY[0] which is sending the 1bit signal when not pressed the module skips the reset stage.

The VGA coordinate system has 0,0 in the top left. It extends to a width of 640 pixels and height of 460 pixels. See the following sections for a more detailed description.

Pin assignments for the DE2-115 have been included in a .csv file in the repository. These may have to be imported into the project file.

## DESCRIPTION AND USE BY MODULE: 

The following description are ordered in loose order to how the finite state machine in MASTER_TEST travels through the project. Refer to figure 1 for a visual description.

1.
module MASTER_TEST(input  CLOCK_50, input  [3:0]  KEY, input  [17:0] SW, output        VGA_CLK,  
output        VGA_HS, output        VGA_VS, output        VGA_BLANK_N, output        VGA_SYNC_N,
output [7:0]  VGA_R, output [7:0]  VGA_G, output [7:0]  VGA_B, output reg [14:0]external_address);

MASTER_TEST parses signal for the debouncer, OnePixel and the VGA module. There is no finite state machine in it.

2.
module debounce_switches(input clk, input rst, input [17:0]SW,  output reg [17:0] SW_db); 

This module instantiates the next module 18 times. Note the reset signal that this accepts cannot be one of these 18 switches. Instead, it has to be from one of the KEYs. The KEYs are debounced by the manufacturer. This module is instantiated in MASTER_TEST.  
3.
DeBounce (Input clk, n_reset, button_in,output reg DB_out, output);
DeBounce was written by Tony Storey for debouncing the KEY buttons on his board, but it works for switches as well if you change the reset condition. The code has been left in its original state except for the reset condition. How it works/
This module is instantiated in debounce_switches.
Source: 

4.
OnePixel(rst,clk,draw_en ,startx,starty,color, finished, write_mem_address,data, x, y);
input rst; input clk; input draw_en;
input [9:0]startx; input [9:0]starty; input [23:0]color;
output reg finished; output reg [14:0]write_mem_address; output reg [23:0]data;
output reg [9:0]x; output reg [9:0]y;

To draw a pixel input send the appropriate coordinates into startx and starty. The finite state machine will calculate the appropriate memory address and send a 1bit from the reg finished when done.  Outputs x and y are for debugging. The single pixel function is adapted from a module which drew a box, hence much of the state machine is written with that in mind.  This module partially works. It can send the appropriate address but it also sends a duplicate pixel to the coordinates approximately 4,40. This pixel is always there independent of the other pixels coordinates. 

This bug is potentially due to a timing de-sync between the VGA module and the finished signal. Since the VGA module is synced to vga_driver.v the puzzle is figuring out how to sync to the frame_done signal sent by the driver. 

This module is instantiated in MASTER_TEST. 

5. 

module vga_driver(input clk, input rst, output reg vga_clk, output reg hsync, output reg vsync,  
output reg active_pixels, output reg frame_done, output reg [9:0]xPixel, output reg [9:0]yPixel, 
output reg VGA_BLANK_N, output reg VGA_SYNC_N );
This module is constantly running throughout the runtime of the project.  This sends an x and y signal  which is used to calculate the memory address in vga_driver_memory_double_buf.v.  This module also includes the calculations for the front and back porch of the VGA port and sends new signals every 25 MHz, as this is the frequency of the VGA. 
 It is instantiated in vga_driver_memory_double_buf.
Credit: Dr. Peter Jamieson. Personal website: http://drpeterjamieson.com/
There is no way to post a link to the original module.

6. 

vga_frame.v
This is the module created by the IP tool on Quartus. There is an initialization image which serves as a plain color background and is the initial read from the module. This is instantiated twice in vga_driver_memory_double_buf.

7. vga_driver_memory_double_buf.

Barring the names of variables and states in the finite state machine this module works as follows.  1. Set the initialization file image.mif so that it is displayed. Image.mif has entries as 24 bits where 8 bits are for RGB, in that order. 2.  Activate one of the instantiations of vga_frame. 3. Wait until the frame has finished, meanwhile read the data from vga_frame. 4. If the drawing signal has been sent (from outside the module) start drawing in the new data. Continue until the frame is done and then loop to 2. Which will switch to the other instantiation of vga_frame.

## FIGURE DESCRIPTIONS AND DEMO LINK
Figure 1 is a visual flow chart description of the project (the code can also be viewed by looking in MASTER_TEST)

demo link: https://youtu.be/U7vFMT5p2JE?si=qiWJUj6thcOwXFSa
