`timescale 1ns/100ps

module SDRAM_Controller_TB ();

//Parameters
parameter A_WIDTH=13;                              //SDRAM address bus length
parameter BA_WIDTH=2;                              //2^2 memory banks in the SDRAM IC
parameter D_WIDTH=16;                              //Word length
parameter A_ROW_WIDTH = 13;                        //Number of rows in each bank
parameter A_COL_WIDTH = 10;                        //Number of columns in each bank

//Internal signals declarations
logic i_rst;                                       //Trigerrs the initialization sequence
logic CLK;                                         //SDRAM clock input - 100MHz.

logic i_rw;                                        //'1' for write and '0' for read 
logic [A_WIDTH-1:0] mode_register;                 //
logic i_initial;                                   //Rises to logic high to perform read/write
logic [A_ROW_WIDTH+A_COL_WIDTH-1:0] i_addr;        //2^13 rows and 2^10 columns
logic [BA_WIDTH-1:0] i_ba;                         //Banks select address
logic [D_WIDTH-1:0] i_data;                        //Data to be written

logic [A_WIDTH-1:0] A;                             //SDRAM address bus
logic [BA_WIDTH-1:0] BA;                           //Banks select address
logic CKE;                                         //Clock enable
logic CS_N;                                        //Chip select
logic RAS_N;                                       //Row address strobe command
logic CAS_N;                                       //Column address strobe command
logic WE_N;                                        //Write enable
logic DQML;                                        //Lower byte, input/output mask
logic DQMH;                                        //Upper byte, input/ouptut mask

integer i;                                         //Used in the TB 'for' loops
integer SEED_a=1;                                  //Used to generate random addresses
integer SEED_b=10;                                 //Used to generate random bank 
integer SEED_d=15;                                 //Used to generate random data values to be written into the memory
logic [A_ROW_WIDTH+A_COL_WIDTH-1:0] addr_tst;      //Address value
logic [BA_WIDTH-1:0] bank_tst;                     //Bank number
logic [D_WIDTH-1:0] data_tst;                      //Data to be written into the memory

//Fix hold violations - there is a hold time requirement of 800ps so I have added this delay manually
logic [A_WIDTH-1:0] A_tmp;                         //SDRAM address bus
logic [BA_WIDTH-1:0] BA_tmp;                       //Banks select address
logic CLK_tmp;                                     //SDRAM clock input - 100MHz.
logic CKE_tmp;                                     //Clock enable
logic CS_N_tmp;                                    //Chip select
logic RAS_N_tmp;                                   //Row address strobe command
logic CAS_N_tmp;                                   //Column address strobe command
logic WE_N_tmp;                                    //Write enable
logic DQM_tmpL;                                    //Lower byte, input/output mask
logic DQMH_tmp;                                    //Upper byte, input/ouptut mask

logic [D_WIDTH-1:0] o_data;                        //Word read from memoy
logic o_busy;                                      //Read/Write operations can be initiated only when not busy, i.e. busy==1'b0
tri [D_WIDTH-1:0] DQ;                              //DQ bus is of type 'tri' since both the controller and the SDRAM might operate with high-z value

//Modules instantiations

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


//SDRAM controller instantiation
SDRAM_controller m0(.i_rst(i_rst),
                    .i_clk(CLK),
					.i_mode_register(mode_register),
			        .i_initial(i_initial),
				    .i_addr(i_addr),
				    .i_ba(i_ba),
					.i_data(i_data),
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


//Hold violations fix by adding delay of 900ps
assign #0.9 A=A_tmp;
assign #0.9 BA = BA_tmp;
assign #0.9 CKE = CKE_tmp;
assign #0.9 CS_N = CS_N_tmp;
assign #0.9 RAS_N = RAS_N_tmp;
assign #0.9 CAS_N = CAS_N_tmp;
assign #0.9 WE_N = WE_N_tmp;
assign #0.9 DQMH = DQMH_tmp;
assign #0.9 DQML = DQML_tmp;


//Tasks
//write task recieves address, bank number and data and initiates a 'write' command
task write(input [A_ROW_WIDTH+A_COL_WIDTH-1:0] address, [BA_WIDTH-1:0] bank, [D_WIDTH-1:0] wr_data);
  if (o_busy==1'b1) begin
    $display("\n------------------------------");
    $display("\nThe controller is busy. Write operration cannot be initiated");   
	end
  else begin
    $display("\n------------------------------");
    $display("\nInitiating a write command to row number %d, column address %d, bank number %d. The written data is %4h", address[22:10], address[9:0], bank, wr_data);
    @(posedge CLK)
    i_initial=1'b1;
    i_rw=1'b1;
    i_addr=address;
    i_ba=bank;
    i_data=wr_data;
    @(posedge CLK)
    i_initial=1'b0;
	@(negedge o_busy);                                   //Wait until negedge of o_busy which indicates the termination of the write operation
    compare(addr_tst,bank_tst,data_tst);                 //Verify the correctness of the 'write' operation by executing the 'compare' task	
  end
endtask

//'compare' task performs comparison between the data actually written to memory and the data that was inteded to be written
task compare(input [A_ROW_WIDTH+A_COL_WIDTH-1:0] address, [BA_WIDTH-1:0] bank, [D_WIDTH-1:0] wr_data);
  case (bank)
    2'b00: if (m1.Bank0[address]==wr_data) begin
	  $display("\nData written to row %d and column %d in bank %d matches the stored data in the memory array",address[22:10],address[9:0],bank);	
	  $display("\nComparison task was succefull!");
	end
	else begin
	  $display("\nComaprison task unfortunately failed. Data stored in memory is: %4h which does not match the written data of %d" , m1.Bank0[address],wr_data);
	  $finish;	
	end
	
    2'b01: if (m1.Bank1[address]==wr_data) begin
	  $display("\nData written to row %d and column %d in bank %d matches the stored data in the memory array",address[22:10],address[9:0],bank);	
	  $display("\nComparison task was succefull!");
	end
	else begin
	  $display("\nComaprison task unfortunately failed. Data stored in memory is: %4h which does not match the written data of %d" , m1.Bank1[address],wr_data);
	  $finish;	
	end
	
    2'b10: if (m1.Bank2[address]==wr_data) begin
	  $display("\nData written to row %d and column %d in bank %d matches the stored data in the memory array",address[22:10],address[9:0],bank);	
	  $display("\nComparison task was succefull!");	
	end
	else begin
	  $display("\nComaprison task unfortunately failed. Data stored in memory is: %4h which does not match the written data of %d" , m1.Bank2[address],wr_data);
	  $finish;	
	end
	
    2'b11: if (m1.Bank3[address]==wr_data) begin
	  $display("\nData written to row %d and column %d in bank %d matches the stored data in the memory array",address[22:10],address[9:0],bank);	
	  $display("\nComparison task was succefull!");	  
    end	  
	else begin
	  $display("\nComaprison task unfortunately failed. Data stored in memory is: %4h which does not match the written data of %d" , m1.Bank3[address],wr_data);
	  $finish;	
	end
  endcase
endtask

//'read' task...
task read(input [A_ROW_WIDTH+A_COL_WIDTH-1:0] address, [BA_WIDTH-1:0] bank);
  if (o_busy==1'b1)
    $display("\nThe controller is busy. Read operration cannot be initiated");   
  else begin
    $display("\nInitiating a read command to row number %d, column address %d, bank number %d", address[22:10], address[9:0], bank);
    @(posedge CLK)
    i_initial=1'b1;
    i_rw=1'b0;
    i_addr=address;
    i_ba=bank;
    @(posedge CLK)
    i_initial=1'b0;  
  end
endtask

//'combined_wr_rd_verification' task...
task combined_wr_rd_verification(input [A_ROW_WIDTH+A_COL_WIDTH-1:0] address, [BA_WIDTH-1:0] bank, [D_WIDTH-1:0] wr_data);
	write(addr_tst,bank_tst,data_tst);                            //
    read(addr_tst,bank_tst);
endtask
//Initial blocks
initial 
begin
	i_rst<=1'b0;                                                  //When i_rst is logic low the SDRAM is in 'power down' mode and the IC is deselected	
	CLK<=1'b0;                                             
	i_initial<=1'b0;                                              //Positive edge of i_initial trigerres a read/write operation      
    mode_register<=13'b0001000100001;	                          //change LSB back to 0 for burst ==1 
	#1000
	i_rst<=1'b1;                                                  //Logic high for i_rst triggers SDRAM initialization sequence
	repeat(10050)                                                 //SDRAM initialization sequence requires ~1030 clock cycles.
	  @(posedge CLK);
/*
    for (i=0; i<1; i++) begin
      addr_tst= $dist_uniform(SEED_a,0,8388607);                  //Generate a random address 
      bank_tst= $dist_uniform(SEED_b,0,3);                        //Generate a random bank number
      data_tst= $dist_uniform(SEED_d,0,65535);                    //Generate random word to be written into memory
      	
      combined_wr_rd_verification(addr_tst,bank_tst,data_tst);    //Initiate a 'write' command 

      repeat(2)                                                  //Minimum of 2 CLK cycles is required
	      @(posedge CLK);	    
    end 
*/

    $display("\nKAKA");   
     write(23'd0,2'b00,16'habcd);              //Initiate a 'write' command 
     //@(negedge o_busy);                                   //Wait until negedge of o_busy which indicates the termination of the write operation
 	 write(23'd1,2'b00,16'h1234);              //Initiate a 'write' command 
     //@(negedge o_busy);                                   //Wait until negedge of o_busy which indicates the termination of the write operation
     read(23'd0,2'b00);
	 
end

//100MHz clock generation
always	
begin
#5; 
CLK=~CLK;
end		

endmodule


