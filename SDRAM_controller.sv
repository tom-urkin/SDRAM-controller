//SDRAM Controller XXX version - operate with 100MHz clock

module SDRAM_controller(i_rst,i_clk,i_initial,i_addr,i_ba,i_data,i_rw,A,BA,DQ,CKE,CS_N,RAS_N,CAS_N,WE_N,DQML,DQMH,o_data,o_busy);

//Parameter declerations
parameter A_WIDTH=13;                                         //SDRAM address bus length
parameter BA_WIDTH=2;                                         //2^2 memory banks in the SDRAM IC
parameter D_WIDTH=16;                                         //Word length
parameter A_ROW_WIDTH = 13;                                   //Number of rows in each bank
parameter A_COL_WIDTH = 10;                                   //Number of columns in each bank

//States
localparam POWER_DOWN=4'b0000;                                //During POWER_DOWN the CKE is logic low and NOP command is issued which prevents registration of new commands
localparam INITIALIZATION=4'b0001;                            //INITIALIZATION state is a 1 clock cycle frame which is entered upon i_rst transition to logic high
localparam WAIT=4'b0010;                                      //WAIT state initiates a NOP command for an adjustable number of cycles and continiues to next_state_after_wait upon completion
localparam PRECHARGE_INIT=4'b0011;                            //PRECHARGE_INIT is the required prechrage operation during device initialization (all banks are precharged)
localparam AUTO_REFRESH_INIT_1=4'b0100;                       //AUTO_REFRESH_INIT_1 is the first auto refresh operation required during device initiatlization
localparam AUTO_REFRESH_INIT_2=4'b0101;                       //AUTO_REFRESH_INIT_2 is the second auto refresh operation required during device initiatlization
localparam MODE_REGISTER_SET=4'b0110;                         //MODE_REGISTER_SET is a 1 clock cycle frame in which the device attributes are set (burst length,burst type,...)
localparam IDLE=4'b0111;                                      //During IDLE mode the controller issues a NOP command
localparam AUTO_REFRESH=4'b1000;                              //AUTO_REFRESH command is issued 8192 time every 64ms (divided equally)
localparam ACTIVATE=4'b1001;                                  //ACTIVATE state initiates row activation- at the end of this operation all values are stored in the latches of the sense amplifiers
localparam PRECHARGE=4'b1010;                                 //PRECHARGE state initiates precharge command of an active row in a specific/all banks


//SDRAM Commands [CS_N,RAS_N,CAS_N,WE_N]
localparam DESL = 4'b1000;                                    //Device deselect
localparam NOP = 4'b0111;                                     //No operation
localparam BST = 4'b0110;                                     //Burst stop
localparam READ = 4'b0101;                                    //For read with auto precharge A10 is '1' else '0'
localparam WRITE = 4'b0100;                                   //For write with auto precharge A10 is '1' else '0'
localparam ACT = 4'b0011;                                     //Activate
localparam PRE = 4'b0010;                                     //Precharge. To precharge all banks A10 is '1' else '0'
localparam REF = 4'b0001;                                     //CBR auto-refrsh. For self-refresh toggle CKE along with CS_N
localparam MRS = 4'b0000;                                     //Mode register set

//Inputs
input logic i_rst;                                            //Trigerrs the initialization sequence
input logic i_clk;                                            //System clock input - 100MHz (generated by a PLL)
input logic i_rw;                                             //'1' for write and '0' for read 
input logic i_initial;                                        //Rises to logic high to perform read/write
input logic [A_ROW_WIDTH+A_COL_WIDTH-1:0] i_addr;             //2^13 rows and 2^10 columns
input logic [BA_WIDTH-1:0] i_ba;                              //Banks select address
input logic [D_WIDTH-1:0] i_data;                             //Data to be written - [?] [This is a single word -what happens in bursts?] [?]


//Outputs
output logic [A_WIDTH-1:0] A;                                 //SDRAM address bus
output logic [BA_WIDTH-1:0] BA;                               //Banks select address
output logic CKE;                                             //Clock enable
output logic CS_N;                                            //Chip select
output logic RAS_N;                                           //Row address strobe command
output logic CAS_N;                                           //Column address strobe command
output logic WE_N;                                            //Write enable
output logic DQML;                                            //Lower byte, input/output mask
output logic DQMH;                                            //Upper byte, input/ouptut mask

output logic [15:0] o_data;                                   //Word read from memoy. [?] What happens here in bursts? [?] XXXXXXXXXXXXXX
output logic o_busy;                                          //Read/Write operations can be initiated only when not busy, i.e. busy==1'b0

//Inouts
inout logic [D_WIDTH-1:0] DQ;                                 //Data on the Data Bus is latched on DQ pins during Write commands, and buffered for output after Read commands

//Internal signals
logic [15:0] counter_wait;                                    //counter used to determine the duration of NOP command issued while in WAIT state
logic [9:0] counter_rst;                                      //Auto-refresh at 100MHz occurs every 782 clock cycles (8192 time every 64ms)
logic [3:0] state;                                            //Current state
logic [3:0] next_state;                                       //Next state
logic [3:0] next_state_after_wait;                            //State after WAIT state
logic [3:0] cmd;                                              //Command sent to the SDRAM IC. Concatination of: {CS_N,RAS_N,CAS_N,WE_N
logic refresh_en;                                             //Prevents auto refresh during device initialization phase
logic refresh_flag;                                           //Rises to logic high for one clock cycle when auto refresh is due

//HDL code : For start up: apply clock, take rst to '1'. To turn off take rst down and clock cycle later you can close the clock [!] 

//Next state latching
always @(posedge i_clk)                                       //POWER_DOWN mode may be entered only in synch with i_clk
  if (!i_rst)
    state<=POWER_DOWN;
  else 
    state<=next_state; 

//Next state calculation
always @(*)
  case (state)
    POWER_DOWN : next_state = INITIALIZATION;
    INITIALIZATION : next_state = WAIT;
    WAIT : next_state = (counter_wait>$bits(counter_wait)'(1)) ? WAIT: next_state_after_wait;
    PRECHARGE_INIT : next_state = WAIT;
    AUTO_REFRESH_INIT_1 : next_state = WAIT;
    AUTO_REFRESH_INIT_2 : next_state = WAIT;
    MODE_REGISTER_SET : next_state = IDLE;
    IDLE : next_state = (refresh_flag==1'b1) ? AUTO_REFRESH : IDLE;
    AUTO_REFRESH : next_state = WAIT;
 endcase

//
always @(posedge i_clk)
  case (state)

    POWER_DOWN : begin
      CKE<=1'b0;
      DQML<=1'b1;
      DQMH<=1'b1;
      cmd<=DESL;                                                //Deselects device to minimize power dissipation when memory is not required
      o_busy<=1'b0;                                             //Read/write commands cannot be issued until initialization phase is complete
    end

    INITIALIZATION: begin
      CKE<=1'b1;
      DQML<=1'b1;
      DQMH<=1'b1;
      counter_wait<=$bits(counter_wait)'(10000);                //Initialization requires 100us, i.e. 10000 cycles in 100MHz clock
      next_state_after_wait<=PRECHARGE_INIT;
    end

    WAIT: begin
      cmd<=NOP;
      counter_wait<=counter_wait-$bits(counter_wait)'(1);       //WAIT state is terminated once the internal counter reaches 0
    end

    PRECHARGE_INIT: begin
      cmd<=PRE;
      A[10]<=1'b1;                                              //Setting A[10] to logic high precharges all banks
      counter_wait<=$bits(counter_wait)'(2);                    //Precharge requires 2 clock cycles (PRE to ACT)
      next_state_after_wait<=AUTO_REFRESH_INIT_1;
    end

    AUTO_REFRESH_INIT_1: begin
      cmd<=REF;
      counter_wait<=$bits(counter_wait)'(6);                    //TRC period is 60ns (REF to REF)
      next_state_after_wait<=AUTO_REFRESH_INIT_2;               //Two auto refresh commands are required during initialization
    end

    AUTO_REFRESH_INIT_2: begin
      cmd<=REF;
      counter_wait<=$bits(counter_wait)'(6);                    //TRC period is 60ns (REF to REF)
      next_state_after_wait<=MODE_REGISTER_SET;                 //Two auto refresh commands are required during initialization
    end

   MODE_REGISTER_SET: begin  //Parameterize later [X]
     cmd<=MRS;                                                  //Mode register set command
     A[2:0]<=3'b000;                                            //Burst legnth is 1. Determines the maximum number of column locations that can be accessed for a given READ or WRITE command
     A[3]<=1'b0;                                                //Sequencial burst
     A[6:4]<=3'b010;                                            //Latency mode - CAS is set to 2.The delay, in clock cycles, between a READ command and the availability of the first piece of output data
     A[8:7]<=2'b00;                                             //Stnadard operation 
     A[9]<=1'b1;                                                //Write burst mode. '1' for single-location write accesses and '0' for burst length as for wrtie accesses 
     A[12:10]<=3'b000;                                          //To ensure compatability with futre devices set to '0'
     BA[1:0]<=2'b00;                                            //To ensure compatability with futre devices set to '0'
   end

   IDLE: begin
      cmd<=NOP;
      o_busy<=1'b0;
   end

   AUTO_REFRESH: begin
     cmd<=REF;
     counter_wait<=$bits(counter_wait)'(6);                    //TRC period is 60ns (REF to REF)
     next_state_after_wait<=IDLE;
     o_busy<=1'b1;                                             //Read/write command cannot be issued during auto refresh phase
   end

  endcase

//Auto-refresh counter
always @(posedge i_clk or negedge i_rst)
  if (!i_rst) begin
    counter_rst<=$bits(counter_rst)'(0);
	refresh_en<=1'b0;                                           //Auto-refresh counter is enabled after initiation is complete
	refresh_flag<=1'b0;
  end
  else if ((counter_rst<$bits(counter_rst)'(782))&&(refresh_en==1'b1)) begin
    refresh_flag<=1'b0;
    counter_rst<=counter_rst+$bits(counter_rst)'(1);
  end
  else if (refresh_en==1'b1)begin
     refresh_flag<=1'b1;
     if (o_busy==1'b0)                                        //If auto refresh is due but the device is currently in active mode the refresh_flag is maintained logic high until IDLE state is reached
       counter_rst<=$bits(counter_rst)'(0);
  end
  else if ((state==IDLE)&&(refresh_en==1'b0))
    refresh_en<=1'b1;

//Assign the commands
assign {CS_N,RAS_N,CAS_N,WE_N}=cmd;                            //cmd is synchronized to the positive edge of i_clk (this assignement does not carry any logical calculations)
assign DQ='z;                                                  //
endmodule 