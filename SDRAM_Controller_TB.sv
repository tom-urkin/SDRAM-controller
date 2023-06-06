`timescale 1ns/100ps

module SDRAM_Controller_TB ();

//Parameters
parameter A_WIDTH=13;                         //SDRAM address bus length
parameter BA_WIDTH=2;                         //2^2 memory banks in the SDRAM IC
parameter D_WIDTH=16;                         //Word length
parameter A_ROW_WIDTH = 13;                   //Number of rows in each bank
parameter A_COL_WIDTH = 10;                   //Number of columns in each bank

//Internal signals declarations
logic i_rst;                                               //Trigerrs the initialization sequence
logic CLK;                              //SDRAM clock input - 100MHz.

logic i_rw;                                                       //'1' for write and '0' for read 
logic i_initial;                                                  //Rises to logic high to perform read/write
logic [A_ROW_WIDTH+A_COL_WIDTH-1:0] i_addr;                       //2^13 rows and 2^10 columns
logic [BA_WIDTH-1:0] i_ba;                                        //Banks select address
logic [D_WIDTH-1:0] i_data;                                       //Data to be written - [?] [This is a single word -what happens in bursts?] [?]

logic [A_WIDTH-1:0] A;                  //SDRAM address bus
logic [BA_WIDTH-1:0] BA;                //Banks select address
logic CKE;                              //Clock enable
logic CS_N;                             //Chip select
logic RAS_N;                            //Row address strobe command
logic CAS_N;                            //Column address strobe command
logic WE_N;                             //Write enable
logic DQML;                             //Lower byte, input/output mask
logic DQMH;                             //Upper byte, input/ouptut mask

//Fix hold violations
logic [A_WIDTH-1:0] A_tmp;                  //SDRAM address bus
logic [BA_WIDTH-1:0] BA_tmp;                //Banks select address
logic CLK_tmp;                              //SDRAM clock input - 100MHz.
logic CKE_tmp;                              //Clock enable
logic CS_N_tmp;                             //Chip select
logic RAS_N_tmp;                            //Row address strobe command
logic CAS_N_tmp;                            //Column address strobe command
logic WE_N_tmp;                             //Write enable
logic DQM_tmpL;                             //Lower byte, input/output mask
logic DQMH_tmp;                             //Upper byte, input/ouptut mask

logic [D_WIDTH-1:0] o_data;             //Word read from memoy. [?] What happens here in bursts? [?]
logic o_busy;                           //Read/Write operations can be initiated only when not busy, i.e. busy==1'b0
tri1 [D_WIDTH-1:0] DQ;

//SDRAM IC instantiation
IS42S16320f m1(.Dq(DQ),
               .Addr(A),
			   .Ba(BA),
			   .Clk(CLK),
			   .Cke(CKE),
			   .Cs_n(CS_N),
			   .Ras_n(RAS_N),
		       .Cas_n(CAS_N),
		       .We_n(WE_N),
		       .Dqm({DQMH,DQML})
          );


//SDRAM instantiation
SDRAM_controller m0(.i_rst(i_rst),
                    .i_clk(CLK),
			        .i_initial(i_initial),
				    .i_addr(i_addr),
				    .i_ba(i_ba),
				    .i_rw(i_rw),
				    .A(A_tmp),
				    .BA(BA_tmp),
				    .DQ(DQ),
				    .CKE(CKE_tmp),
					.CS_N(CS_N_tmp),
                    .RAS_N(RAS_N_tmp),
                    .CAS_N(CAS_N_tmp),
                    .WE_N(WE_N_tmp),
                    .DQML(DQML_tmp),
                    .DQMH(DQMH_tmp),
					.o_busy(o_busy),
			      	.o_data(o_data)
                    );




//Hold violations fix by adding delay of 0.8ns
assign #0.9 A=A_tmp;
assign #0.9 BA = BA_tmp;
assign #0.9 CKE = CKE_tmp;
assign #0.9 CS_N = CS_N_tmp;
assign #0.9 RAS_N = RAS_N_tmp;
assign #0.9 CAS_N = CAS_N_tmp;
assign #0.9 WE_N = WE_N_tmp;
assign #0.9 DQMH = DQMH_tmp;
assign #0.9 DQML = DQML_tmp;

//Initial blocks
initial 
begin
	i_rst<=1'b0;	
	CLK<=1'b0;
	#1000
	i_rst<=1'b1;
end

//25MHz clock generation
always	
begin
#10; 
CLK=~CLK;
end		

endmodule


