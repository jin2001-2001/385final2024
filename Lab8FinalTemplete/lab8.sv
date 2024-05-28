//-------------------------------------------------------------------------
//      lab8.sv                                                          --
//      Christine Chen                                                   --
//      Fall 2014                                                        --
//                                                                       --
//      Modified by Po-Han Huang                                         --
//      10/06/2017                                                       --
//                                                                       --
//      Fall 2017 Distribution                                           --
//                                                                       --
//      For use with ECE 385 Lab 8                                       --
//      UIUC ECE Department                                              --
//-------------------------------------------------------------------------


module lab8( input               CLOCK_50,
             input        [3:0]  KEY,          //bit 0 is set up as Reset
             output logic [6:0]  HEX0, HEX1,//HEX2,HEX3,HEX4,HEX5, HEX6, HEX7,
             // VGA Interface 
             output logic [7:0]  VGA_R,        //VGA Red
                                 VGA_G,        //VGA Green
                                 VGA_B,        //VGA Blue
             output logic        VGA_CLK,      //VGA Clock
                                 VGA_SYNC_N,   //VGA Sync signal
                                 VGA_BLANK_N,  //VGA Blank signal
                                 VGA_VS,       //VGA virtical sync signal
                                 VGA_HS,       //VGA horizontal sync signal
             // CY7C67200 Interface
             inout  wire  [15:0] OTG_DATA,     //CY7C67200 Data bus 16 Bits
             output logic [1:0]  OTG_ADDR,     //CY7C67200 Address 2 Bits
             output logic        OTG_CS_N,     //CY7C67200 Chip Select
                                 OTG_RD_N,     //CY7C67200 Write
                                 OTG_WR_N,     //CY7C67200 Read
                                 OTG_RST_N,    //CY7C67200 Reset
             input               OTG_INT,      //CY7C67200 Interrupt
             // SDRAM Interface for Nios II Software
             output logic [12:0] DRAM_ADDR,    //SDRAM Address 13 Bits
             inout  wire  [31:0] DRAM_DQ,      //SDRAM Data 32 Bits
             output logic [1:0]  DRAM_BA,      //SDRAM Bank Address 2 Bits
             output logic [3:0]  DRAM_DQM,     //SDRAM Data Mast 4 Bits
             output logic        DRAM_RAS_N,   //SDRAM Row Address Strobe
                                 DRAM_CAS_N,   //SDRAM Column Address Strobe
                                 DRAM_CKE,     //SDRAM Clock Enable
                                 DRAM_WE_N,    //SDRAM Write Enable
                                 DRAM_CS_N,    //SDRAM Chip Select
                                 DRAM_CLK      //SDRAM Clock
                    );


    parameter  Num_BI = 1;
	parameter  Num_Monster = -1;
	parameter  Num_Fruita = 6;
	parameter  Num_tiles_Pow = 3;
	parameter  Maze_BlkX = 18;
	parameter  Maze_BlkY = 13;

    logic Reset_h, Clk;
    logic [15:0] keycode, monkeycode;
	logic is_BI,is_Fruit, is_Mon, is_Map;
	logic[10:0] DrawX,DrawY,judgeBIx,judgeBIy,judgeMonx,judgeMony;
	logic [9:0] BI_X;
	logic [9:0] BI_Y;
	logic [5:0] Blk_addressX, Blk_addressY;
	logic [3:0] score;

	logic [Num_tiles_Pow - 1:0] Tile_Out;   // should be Num_tiles_Pow - 1
	logic [Num_BI-1:0] BI_up_wall, BI_down_wall,  BI_left_wall, BI_right_wall;
	
//global Block xy location of BI and Monster...
	logic [Num_BI-1:0][4:0] BI_BlkX_Pos;
	logic [Num_BI-1:0][4:0] BI_BlkY_Pos;	

//arrays fpr Monster....
	logic [Num_Monster+1:0] mup_walls, mdown_walls,  mleft_walls, mright_walls;
	logic [Num_Monster+1:0][4:0] Mon_BlkX_Poss;
	logic [Num_Monster+1:0][4:0] Mon_BlkY_Poss;	
	logic [Num_Monster+1:0] is_Mons, Mon_num;
	logic [Num_Monster+1:0][9:0] Mon_Xs;
	logic [Num_Monster+1:0][9:0] Mon_Ys;

	logic [5:0] eata_6;
	logic [5:0] alivea_6;
	logic [10:0] is_Fruit_a;
	logic [5:0][10:0] Fa_Xs;
	logic [5:0][10:0] Fa_Ys;


	initial 
	begin
		keycode <= 0;
		DrawX <=0;
		DrawY <=0;
	end

    assign Clk = CLOCK_50;
    always_ff @ (posedge Clk) begin
        Reset_h <= ~(KEY[0]);        // The push buttons are active low
    end
    
    logic [1:0] hpi_addr;
    logic [15:0] hpi_data_in, hpi_data_out;
    logic hpi_r, hpi_w, hpi_cs, hpi_reset;
	 logic [2:0] DIR,DIR_IN; 
	 logic [9:0] kill_10, alive_10,is_dot;
	 
	maze_RAM #(.Num_Monster(Num_Monster),
			   .Num_BI(Num_BI),
			   .Maze_BlkX(Maze_BlkX),
			   .Maze_BlkY(Maze_BlkY),
			   .Num_tiles_Pow(Num_tiles_Pow)
			   ) maze_instance(		.Blk_addressX(Blk_addressX), 
								.Blk_addressY(Blk_addressY),
								.DrawX(DrawX),
								.DrawY(DrawY),
								.BI_BlkX_Pos(BI_BlkX_Pos),
								.BI_BlkY_Pos(BI_BlkY_Pos),
								.Mon_BlkX_Poss(Mon_BlkX_Poss),
								.Mon_BlkY_Poss(Mon_BlkY_Poss),
								.Tile_Out(Tile_Out),
								.is_Map(is_Map),
								.BI_up_wall(BI_up_wall), .BI_down_wall(BI_down_wall), .BI_left_wall(BI_left_wall), .BI_right_wall(BI_right_wall),
								.mup_walls(mup_walls), .mdown_walls(mdown_walls), .mleft_walls(mleft_walls), .mright_walls(mright_walls)
								);

	 
	 lab8_soc m_lab8_soc(
											 .clk_clk(CLOCK_50),
											 .reset_reset_n(1'b1), 
										    //.key_2_wire_export(KEY[2]), 
											 //.key_3_wire_export(KEY[3]), 
											 .sdram_wire_addr(DRAM_ADDR),    //  sdram_wire.addr
											 .sdram_wire_ba(DRAM_BA),      	//  .ba
											 .sdram_wire_cas_n(DRAM_CAS_N),    //  .cas_n
											 .sdram_wire_cke(DRAM_CKE),     	//  .cke
											 .sdram_wire_cs_n(DRAM_CS_N),      //  .cs_n
											 .sdram_wire_dq(DRAM_DQ),      	//  .dq
											 .sdram_wire_dqm(DRAM_DQM),     	//  .dqm
											 .sdram_wire_ras_n(DRAM_RAS_N),    //  .ras_n
											 .sdram_wire_we_n(DRAM_WE_N),      //  .we_n
											 .sdram_clk_clk(DRAM_CLK),			//  clock out to SDRAM from other PLL port
											 .keycode_export(keycode),
											 .otg_hpi_address_export(hpi_addr),
											 .otg_hpi_cs_export(hpi_cs),     
	                               .otg_hpi_data_in_port(hpi_data_in),  
	                               .otg_hpi_data_out_port(hpi_data_out), 
	                               .otg_hpi_r_export(hpi_r),      
											 .otg_hpi_reset_export(hpi_reset),  
                                  .otg_hpi_w_export(hpi_w)
	);
    // Interface between NIOS II and EZ-OTG chip
    hpi_io_intf hpi_io_inst(
                            .Clk(Clk),
                            .Reset(Reset_h),//Do we need to reset OTG Chip?
                            // signals connected to NIOS II
                            .from_sw_address(hpi_addr),
                            .from_sw_data_in(hpi_data_in),
                            .from_sw_data_out(hpi_data_out),
                            .from_sw_r(hpi_r),
                            .from_sw_w(hpi_w),
                            .from_sw_cs(hpi_cs),
                            .from_sw_reset(hpi_reset),
                            // signals connected to EZ-OTG chip
                            .OTG_DATA(OTG_DATA),    
                            .OTG_ADDR(OTG_ADDR),    
                            .OTG_RD_N(OTG_RD_N),    
                            .OTG_WR_N(OTG_WR_N),    
                            .OTG_CS_N(OTG_CS_N),
                            .OTG_RST_N(OTG_RST_N)
    );
     
   // Use PLL to generate the 25MHZ VGA_CLK.
    // You will have to generate it on your own in simulation.
    vga_clk vga_clk_instance(.inclk0(Clk), .c0(VGA_CLK));
    
    // TODO: Fill in the connections for the rest of the modules 
    VGA_controller vga_controller_instance(
			.Clk(Clk),
			.Reset(Reset_h),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_CLK(VGA_CLK),
			.VGA_BLANK_N(VGA_BLANK_N),
			.VGA_SYNC_N(VGA_SYNC_N),
			.DrawX(DrawX),
			.DrawY(DrawY)
	);
    
//    // Which signal should be frame_clk?
    badicecream BI_instance1(
			.Clk(Clk),
			.Reset(Reset_h), 
			.frame_clk(VGA_VS), 
			.DrawX(DrawX),
			.DrawY(DrawY),
			.BI_X(BI_X),
			.BI_Y(BI_Y),
			.up_wall(BI_up_wall[0]),
			.down_wall(BI_down_wall[0]),
			.left_wall(BI_left_wall[0]),
			.right_wall(BI_right_wall[0]),
			.keycode(keycode),
			.is_BI(is_BI),
			.BI_BlkX_Pos(BI_BlkX_Pos[0]),
			.BI_BlkY_Pos(BI_BlkY_Pos[0]),
			.BI_X_Pos(judgeBIx),
			.BI_Y_Pos(judgeBIy)
	);

    idenmon Mon_instance1(
			.Clk(Clk),
			.Reset(Reset_h), 
			.frame_clk(VGA_VS), 
			.DrawX(DrawX),
			.DrawY(DrawY),
			.BI_X(Mon_Xs),
			.BI_Y(Mon_Ys),
			.up_wall(mup_walls[0]),
			.down_wall(mdown_walls[0]),
			.left_wall(mleft_walls[0]),
			.right_wall(mright_walls[0]),
			.keycode(monkeycode),
			.is_BI(is_Mon),
			.BI_BlkX_Pos(Mon_BlkX_Poss[0]),
			.BI_BlkY_Pos(Mon_BlkY_Poss[0]),
			.BI_X_Pos(judgeMonx),
			.BI_Y_Pos(judgeMony)
	);

 	fruitas fas_instance(
			.Clk(Clk),
			.Reset(Reset_h),   
			.eata_6(eata_6),// if some eat happen... tell this set...
	.DrawX(DrawX), .DrawY(DrawY),//xxx
	.BIBx(BI_BlkX_Pos[0]),.BIBy(BI_BlkY_Pos[0]),
	.alivea_6(alivea_6),   //check if eaten, or no need to draw...
	.is_Fruit_as(is_Fruit_as),      // if fruit a needed? 
	.fruita_num(fruita_num), //index helpful to extarct target x,y
	.is_Fruit_a(is_Fruit_a), //indicate which fruit to be drawn...
	.Fa_Xs(Fa_Xs),
	.Fa_Ys(Fa_Ys) // For drawing... each time only use one pair...
);

 Montrace tracer(
	//bydefault, we design 6 fruit a
	 .Clk(Clk), .Reset(Reset), .frame_clk(frame_clk),    
	//input  logic [5:0] eata_6,// if some eat happen... tell this set...
	.judgeMonx(judgeMonx),.judgeMony(judgeMony),.judgeBIx(judgeBIx),.judgeBIy(judgeBIy),//xxx
	.mup_walls(mup_walls[0]), .mdown_walls(mdown_walls[0]), .mleft_walls(mleft_walls[0]), .mright_walls(mright_walls[0]),
	//output logic [5:0] alivea_6,   //check if eaten, or no need to draw...
	//output logic ,      // if fruit a needed? 
	//output logic [4:0] Mon_num, //Here, we prefer to draw first monster...
	//output logic is_Mon,
	//output logic [4:0] is_Mons, //indicate which fruit to be drawn...
	//output logic [4:0][10:0] Mon_Xs,
	//output logic [4:0][10:0] Mon_Ys, // For drawing... each time only use one pair...
	//output logic [4:0][5:0] Mon_BlkX_Poss, Mon_BlkY_Poss
    .monkeycode(monkeycode)
);

   	Mcolor_mapper color_instance(
			.Clk(Clk),
			.Reset(Reset_h), 
			.BIBlkx(judgeBIx),
			.BIBlky(judgeBIy),
			.MonBlkx(judgeMonx),
			.MonBlky(judgeMony),
			.is_BI(is_BI),
			.is_Mon(is_Mon),//
			.is_Fruita(is_Fruita),
			.is_Fruit_a(is_Fruit_a),
			.is_Map(is_Map),
			.DrawX(DrawX),
			.DrawY(DrawY),
			.BI_X(BI_X),
			.BI_Y(BI_Y),
			.Mon_Xs(Mon_Xs),//
			.Mon_Ys(Mon_Ys),//
			.Mon_X(),
			.Mon_Y(),
			.is_Mons(is_Mons),
			.Tile_Out(Tile_Out),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.kill_6(kill_6),
			.alivea_6(alivea_6),
			.score(score),
			.fruita_num(fruita_num),
			.Fa_Xs(Fa_Xs),
			.Fa_Ys(Fa_Ys)

	);

    
    // Display keycode on hex display
    //HexDriver hex_inst_0 (keycode[3:0], HEX0);
    //HexDriver hex_inst_1 (keycode[7:4], HEX1);
//	 HexDriver hex_inst_0 (alive_10[3:0], HEX0);
//	 HexDriver hex_inst_1 (alive_10[7:4], HEX1);
//	 HexDriver hex_inst_2 (alive_10[9:8], HEX2);

logic[3:0] first;
logic[3:0] second;
 HexDriver hex_inst_0 (first, HEX0);
 HexDriver hex_inst_1 (second, HEX1);
always_comb begin
	Blk_addressX = (({1'b0, DrawX})>>5) -1;
	Blk_addressY = (({1'b0, DrawY})>>5) -1;//debug stage1...
	// if(score == 10)
	// begin
	// 	first = 0;
	// 	second = 1;
	// end
	// else
	// begin
	// 	first = score;
	// 	second = 0;
	// end 
end
//	 HexDriver hex_inst_2 (is_dot[9:8], HEX2);
//	 
//	 HexDriver hex_inst_3 (kill_10[3:0], HEX3);
//	 HexDriver hex_inst_4 (kill_10[7:4], HEX4);
//	 HexDriver hex_inst_5 (kill_10[9:8], HEX5);
endmodule
