module badicecream(input         Clk,                // 50 MHz clock
                             Reset,              // Active-high reset signal
                             frame_clk,          // The clock indicating a new frame (~60Hz)
                input [9:0]   DrawX, DrawY ,   // Current pixel coordinates
				input [31:0]   keycode,				 // keycodes for handling presses
               	output logic is_BI	,			// Whether current pixel belongs to ball or background
				output logic [9:0] BI_X, BI_Y,
				input logic up_wall, down_wall , left_wall, right_wall,
				output logic [9:0] BI_X_Pos, BI_Y_Pos,
				output logic [4:0] BI_BlkX_Pos, BI_BlkY_Pos, 
              );
				  
				  
   
	enum logic[2:0] { 
					 up, 
					 down,
					 left,
					 right,
					 Halted} Dir, Dir_in, Dir_delayed, Dir_delayed_in;

    parameter [9:0] BI_X_Corner = 10'd63;  // Center position on the X axis
    parameter [9:0] BI_Y_Corner = 10'd95;  // Center position on the Y axis
    parameter [4:0] BI_Blk_X_Corner = 5'd1;  // Center position on the X axis
    parameter [4:0] BI_Blk_Y_Corner = 5'd1;  // Center position on the Y axis	
//    parameter [9:0] Pac_X_Min = 10'd0;       // Leftmost point on the X axis
//    parameter [9:0] Pac_X_Max = 10'd639;     // Rightmost point on the X axis
//    parameter [9:0] Pac_Y_Min = 10'd0;       // Topmost point on the Y axis
//    parameter [9:0] Pac_Y_Max = 10'd479;     // Bottommost point on the Y axis
    parameter [9:0] BI_X_Step = 10'd1;      // Step size on the X axis
    parameter [9:0] BI_Y_Step = 10'd1;      // Step size on the Y axis
    parameter [5:0] BI_sizeX = 6'd32;        // Pac size
	parameter [5:0] BI_sizeY = 6'd48;

	logic [5:0] frame_counter;   
    logic [9:0] BI_X_Motion, BI_Y_Motion;
    logic [9:0] BI_X_Pos_in, BI_X_Motion_in, BI_Y_Pos_in, BI_Y_Motion_in;
	logic [4:0] BI_BlkX_Pos_in, BI_BlkY_Pos_in;
	logic [2:0] health;
	

	initial 
	begin
			BI_X_Pos <= BI_X_Corner;
            BI_Y_Pos <= BI_Y_Corner;
			BI_BlkX_Pos <= BI_Blk_X_Corner;
			BI_BlkY_Pos <= BI_Blk_Y_Corner;
            BI_X_Motion <= 10'd0;
            BI_Y_Motion <= 10'd0;
			frame_counter <=0;
				Dir <= Halted;
				Dir_delayed <= down;
	end
	     //////// Do not modify the always_ff blocks. ////////
    // Detect rising edge of frame_clk
    logic frame_clk_delayed, frame_clk_rising_edge;
    always_ff @ (posedge Clk) 
	begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
		if ((frame_clk == 1'b1) && (frame_clk_delayed == 1'b0))
			begin
				if(frame_counter == 9)
				begin
					frame_counter<=0
				end
				else
				begin
					frame_counter <= frame_counter+1;
				end
			end
    end
    // Update registers
    always_ff @ (posedge Clk)
    begin
        if (Reset)
        begin
            BI_X_Pos <= BI_X_Corner;
            BI_Y_Pos <= BI_Y_Corner;
			BI_BlkX_Pos <= BI_Blk_X_Corner;
			BI_BlkY_Pos <= BI_Blk_Y_Corner;
            BI_X_Motion <= 10'd0;
            BI_Y_Motion <= 10'd0;
				Dir <= Halted;
				Dir_delayed <= down;
        end
        else
        begin
            BI_X_Pos <= BI_X_Pos_in;
            BI_Y_Pos <= BI_Y_Pos_in;
            BI_X_Motion <= BI_X_Motion_in;
            BI_Y_Motion <= BI_Y_Motion_in;
			BI_BlkX_Pos <= BI_BlkX_Pos_in;
			BI_BlkY_Pos <= BI_BlkY_Pos_in;
			Dir <= Dir_in;
			Dir_delayed <= Dir_delayed_in;
        end
    end
    //////// Do not modify the always_ff blocks. ////////
    
    // You need to modify always_comb block.
    always_comb
    begin
        // By default, keep motion and position unchanged
        BI_X_Pos_in = BI_X_Pos;
        BI_Y_Pos_in = BI_Y_Pos;
        BI_X_Motion_in = (BI_X_Pos+1-32)>>5;   //divid by 32, 
        BI_Y_Motion_in = (BI_Y_Pos+1-32)>>5-1;
		BI_BlkX_Pos_in = BI_BlkX_Pos;
		BI_BlkY_Pos_in = BI_BlkY_Pos;
		Dir_in = Dir;
		Dir_delayed_in = Dir_delayed;
        
        // Update position and motion only at rising edge of frame clock
            // Be careful when using comparators with "logic" datatype because compiler treats 
            //   both sides of the operator as UNSIGNED numbers.
            // e.g. BI_Y_Pos - BI_sizeX <= Pac_Y_Min 
            // If BI_Y_Pos is 0, then BI_Y_Pos - BI_sizeX will not be -4, but rather a large positive number.
//            if( BI_Y_Pos + BI_sizeX >= Pac_Y_Max )  // Pac is at the bottom edge, BOUNCE!
//                BI_Y_Motion_in = (~(BI_Y_Step) + 1'b1);  // 2's complement.  
//            else if ( BI_Y_Pos <= Pac_Y_Min)  // Pac is at the top edge, BOUNCE!
//                BI_Y_Motion_in = BI_Y_Step;
//            TODO: Add other boundary detections and handle keypress here.
//				else if( BI_X_Pos + BI_sizeX >= Pac_X_Max )  // Pac is at the right edge, BOUNCE!
//                BI_X_Motion_in = (~(BI_X_Step) + 1'b1);  // 2's complement.  
//            else if ( BI_X_Pos <= Pac_X_Min)  // Pac is at the left edge, BOUNCE!
//                BI_X_Motion_in = BI_X_Step;
		if(health != 0)
		begin
			if (frame_clk_rising_edge)
			begin
				if (Dir == Halted) //only stop can we do futher operation
				begin
					if (((keycode & 16'h00ff) == 16'd26) || ((keycode & 32'h0000ff00) == 32'h00001a00)) //W
					begin
						if(up_wall)
						begin
							BI_Y_Motion_in = 0;
							BI_X_Motion_in = 0;
							Dir_in = Halted;
						end
						else
						begin
							BI_Y_Motion_in = -BI_Y_Step;
							BI_X_Motion_in = 0;
							Dir_in = up;
							Dir_delayed_in = up;	
						end
					end
					else if (((keycode & 16'h00ff) == 16'd4) || ((keycode & 16'hff00) == 16'h0400)) //A
						begin
							if (left_wall)			
							begin
								BI_X_Motion_in = 0;
								BI_Y_Motion_in = 0;
								Dir_in = Halted;
							end
							else
							begin
								BI_Y_Motion_in = 0;
								BI_X_Motion_in = -BI_X_Step;
								Dir_in = left;
								Dir_delayed_in = left;	
							end
						end
					
					else if(((keycode & 16'h00ff) == 16'd22) || ((keycode & 16'hff00) == 16'h1600)) //S
						begin
							if (down_wall) 
							begin
								BI_Y_Motion_in = 0;
								BI_X_Motion_in = 0;
							Dir_in = Halted;
							end
							else
							begin
								BI_Y_Motion_in = BI_Y_Step;
								BI_X_Motion_in = 0;
								Dir_in = down;
								Dir_delayed_in = down;	
							end
						end
					
					else if (((keycode & 16'h00ff) == 16'd7) || ((keycode & 16'hff00) == 16'h0700)) //D
						begin
							if(right_wall) 
							begin
							BI_X_Motion_in = 0;
							BI_Y_Motion_in = 0;
							Dir_in = Halted;
							end
							else
							begin
								BI_Y_Motion_in = 0;
								BI_X_Motion_in = BI_X_Step;
								Dir_in = right;	
								Dir_delayed_in = right;
							end
						end

					else
						begin             //nothing is pointed


							//Dir_in = Halted;
						end
				end
				else // now, we get that BI is stopped
				begin
					if((BI_X_Pos_in!=BI_X_Pos) || (BI_Y_Pos_in!=BI_Y_Pos))
					begin
						Dir_in = Halted;
						BI_Y_Motion_in = 0;
						BI_X_Motion_in = 0;
					end
				end

            // Update the Pac's position with its motion in 60 Hz game frame
            BI_X_Pos_in = BI_X_Pos + BI_X_Motion;
            BI_Y_Pos_in = BI_Y_Pos + BI_Y_Motion;

			end
        end
        

    end
    
    // Compute whether the pixel corresponds to Pac or background
    /* Since the multiplicants are required to be signed, we have to first cast them
       from logic to int (signed by default) before they are multiplied. */
    int DistX, DistY, Size;
    assign DistX = DrawX - BI_X_Pos;
    assign DistY = DrawY - BI_Y_Pos;
    always_comb begin
//        if ( ( DistX*DistX + DistY*DistY) <= (Size*Size) ) 
		   if (DistX < BI_sizeX && DistX >= 0 && DistY<=0 && -DistY < BI_sizeY)
		  begin
        is_BI = 1'b1;
				BI_X = DrawX - BI_X_Pos;
				BI_Y = DrawY - BI_Y_Pos+BI_sizeY-1;
		  end
        else
		  begin
        is_BI = 1'b0;
				BI_X = 0;
				BI_Y = 0;
        end
		  /* The Pac's (pixelated) circle is generated using the standard circle formula.  Note that while 
           the single line is quite powerful descriptively, it causes the synthesis tool to use up three
           of the 12 available multipliers on the chip! */
    end
	 
endmodule
