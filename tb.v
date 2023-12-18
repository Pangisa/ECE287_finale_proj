`timescale 1 ps / 1 ps

module tb;

	reg[7:0] step_val;
	
	task step();
	begin
		$write("%d: ", step_val);
		step_val = step_val + 1;
	end
	endtask


reg clk;
reg rst;
reg draw_en;
//wire [4:0]W;
//wire [4:0]H;
//wire er;
//wire wtest;//
wire finished;
wire [14:0]write_mem_address;
wire [23:0]data;


	
	parameter simdelay = 20;
	parameter clock_delay = 5;
	
	// here is my sum digits

DrawBox draw (rst,clk,draw_en,8'd50,8'd60,8'd70,8'd110,24'hFFFFFF, finished, write_mem_address, data);

	initial
	begin
		
		#(simdelay) clk = 1'b0; rst = 1'b0; draw_en = 1'b0;
		#(simdelay) draw_en = 1'b1;
		
		
 // start the algorithm				
						
		#300; // let simulation finish
	
	end

/* this checks done every clock and when it goes high ends the simulation */
	always @(clk)
	begin
		if (finished == 1'b1)
		begin
			$write("DONE:"); $write("\n"); 
			$stop;
		end
		else
		begin
			step(); $write("\n"); 
		end
	end
	
	// this generates a clock
	always
	begin
		#(clock_delay) clk = !clk;
	end
	
	// this makes the simulation go for 1000 steps
	initial
		#50000 $stop;

endmodule


