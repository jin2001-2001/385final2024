module badicecream(input         Clk,                // 50 MHz clock
                             Reset,              // Active-high reset signal
                             frame_clk,          // The clock indicating a new frame (~60Hz)
                input [10:0]   DrawX, DrawY ,   // Current pixel coordinates
				input [15:0]   keycode,				 // keycodes for handling presses
               	output logic is_BI	,			// Whether current pixel belongs to ball or background
				output logic [10:0] BI_X, BI_Y,
				input logic up_wall, down_wall , left_wall, right_wall,
				output logic [10:0] BI_X_Pos, BI_Y_Pos,
//for convenience, discard...
				output logic [5:0] BI_BlkX_Pos, BI_BlkY_Pos
              );
				  
				  
   
	enum logic[2:0] { 
					 right=3'b000, 
					 left=3'b001,
					 up=3'b010,
					 down=3'b011,
					 Halted=3'b100} Dir, Dir_in, Dir_delayed, Dir_delayed_in;

    parameter [10:0] BI_X_Corner = 11'd64;  // Center position on the X axis
    parameter [10:0] BI_Y_Corner = 11'd95;  // Center position on the Y axis
    parameter [5:0] BI_Blk_X_Corner = 6'd1;  // Center position on the X axis
    parameter [5:0] BI_Blk_Y_Corner = 6'd1;  // Center position on the Y axis	
//    parameter [9:0] Pac_X_Min = 10'd0;       // Leftmost point on the X axis
//    parameter [9:0] Pac_X_Max = 10'd639;     // Rightmost point on the X axis
//    parameter [9:0] Pac_Y_Min = 10'd0;       // Topmost point on the Y axis
//    parameter [9:0] Pac_Y_Max = 10'd479;     // Bottommost point on the Y axis
    parameter [10:0] BI_X_Step = 10'd1;      // Step size on the X axis
    parameter [10:0] BI_Y_Step = 10'd1;      // Step size on the Y axis
    parameter  BI_sizeX = 6'd32;        // Pac size
	parameter  BI_sizeY = 6'd48;

	logic [5:0] frame_counter, per_frame_counter;   
	logic [5:0] frame_counter_in, per_frame_counter_in;

	logic [5:0] pace_counter, pace_counter_in;


    logic [10:0] BI_X_Motion, BI_Y_Motion;
    logic [10:0] BI_X_Pos_in, BI_X_Motion_in, BI_Y_Pos_in, BI_Y_Motion_in;
	logic [5:0] BI_BlkX_Pos_in, BI_BlkY_Pos_in;
	logic [2:0] health;
	

	initial 
	begin
			BI_X_Pos <= BI_X_Corner;
            BI_Y_Pos <= BI_Y_Corner;
			BI_BlkX_Pos <= BI_Blk_X_Corner;
			BI_BlkY_Pos <= BI_Blk_Y_Corner;
            BI_X_Motion <= 10'b0;
            BI_Y_Motion <= 10'b0;

			health <=3'd1;

			frame_counter <=6'b0;
			per_frame_counter <=6'b0;
			frame_counter_in <=6'b0;
			per_frame_counter_in <=6'b0;
			Dir <= Halted;
			Dir_delayed <= down;
			pace_counter = 0;
			pace_counter_in = 0;
	end
	     //////// Do not modify the always_ff blocks. ////////
    // Detect rising edge of frame_cslk
    logic frame_clk_delayed, frame_clk_rising_edge;


   always_ff @ (posedge Clk) 
	begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
		frame_counter <= frame_counter_in;
		per_frame_counter <=  per_frame_counter_in;
    end

	always_comb
	begin
		frame_counter_in = frame_counter;
		per_frame_counter_in = per_frame_counter;

		if (frame_clk_rising_edge)   //meet the requiremet
		begin
		//frame_counter_in = frame_counter;
		per_frame_counter_in = per_frame_counter+6'b1;
		if((per_frame_counter) == 6'b000111) //equal to 9
			begin
				per_frame_counter_in=6'b0;
				frame_counter_in = frame_counter+6'b1;
			

				if((frame_counter ) == 6'b100) //equal to 4
				begin
					frame_counter_in=6'b0;
				end
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
			pace_counter <= 6'd0;
				Dir <= Halted;
				Dir_delayed <= down;
        end
        else
        begin
			pace_counter <= pace_counter_in;
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
		pace_counter_in = pace_counter;
        BI_X_Pos_in = BI_X_Pos;
        BI_Y_Pos_in = BI_Y_Pos;
		BI_X_Motion_in = BI_X_Motion;
		BI_Y_Motion_in = BI_Y_Motion;
        BI_BlkX_Pos_in = BI_BlkX_Pos;   //divid by 32, 
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

				//first, get future things...
            	// Update the Pac's position with its motion in 60 Hz game frame
            	BI_X_Pos_in = BI_X_Pos + BI_X_Motion_in;
            	BI_Y_Pos_in = BI_Y_Pos + BI_Y_Motion_in;
//				BI_BlkX_Pos_in = {1'b0, (BI_X_Pos_in+1-32)}>>5;   //divid by 32, 
//        		BI_BlkY_Pos_in = ({1'b0, (BI_Y_Pos_in+1-32)}>>5)-1;

				if (Dir == Halted) //only stop can we do futher operation
				begin
					if ((keycode[7:0] == 8'd26) || ((keycode[15:8] == 8'd26 ))) //W
					begin
						Dir_delayed_in = up;
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
						end
					end
					else if (((keycode[7:0] == 8'd4) || keycode[15:8] == 8'd4 )) //A
						begin
							Dir_delayed_in = left;
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
									
							end
						end
					
					else if((keycode[7:0] == 8'd22) || ((keycode[15:8] == 8'd22 ))) //S
						begin
							Dir_delayed_in = down;
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
									
							end
						end
					
					else if (((keycode[7:0]) == 8'd7) || ((keycode[15:8]) == 8'd7)) //D
						begin
							Dir_delayed_in = right;
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
							
							end
						end

					else
						begin             //nothing is pointed


							//Dir_in = Halted;
						end
				end
				else // now, Dir_in is not Halted, maining we are walking....
				begin
					pace_counter_in = pace_counter + 6'd1;
					if(pace_counter == 6'd31)
					begin
						pace_counter_in = 6'd0;
						case(Dir)
							left:
							begin
								BI_BlkX_Pos_in = BI_BlkX_Pos -1;
							end
							right:
							begin
								BI_BlkX_Pos_in = BI_BlkX_Pos +1;
							end
							up:
							begin
								BI_BlkY_Pos_in = BI_BlkY_Pos -1;
							end
							down:
							begin
								BI_BlkY_Pos_in = BI_BlkY_Pos +1;
							end
							default:
							begin
								BI_BlkY_Pos_in = 0; //never happend.....
							end

						endcase
						Dir_in = Halted;
						BI_Y_Motion_in = 0;
						BI_X_Motion_in = 0;						
					end
					// if((BI_X_Pos_in[4:0] == 5'b0) && ((BI_Y_Pos_in[4:0] + 1) == 5'b0 )) //arrive a totally new block...
					// begin
					// 	Dir_in = Halted;
					// 	BI_BlkX_Pos_in = ({1'b0, (BI_X_Pos_in)}>>5)-1;   //divid by 32, 
		        	// 	BI_BlkY_Pos_in = ({1'b0, (BI_Y_Pos_in+1-32)}>>5)-1;						
					// end
				end

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
				BI_X = DrawX - BI_X_Pos+({5'b0, frame_counter}*32);
				BI_Y = DrawY - BI_Y_Pos+BI_sizeY-1+ Dir_delayed_in*48;
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
