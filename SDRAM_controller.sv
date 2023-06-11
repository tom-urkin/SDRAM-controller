//SDRAM Controller for ISSI IS42S16320f-7 IC. Timings are calculated for 100MHz input clock.
//This controller program the IC upon initialization or upon dedicated request (XXX signal XXX), please refer to the datasheet for configuration specifications. 

//[ADD reconfiguration madoe from IDLE state] X

module SDRAM_controller(i_rst,i_clk,i_initial,i_addr,i_ba,i_data,i_rw,i_mode_register,A,BA,DQ,CKE,CS_N,RAS_N,CAS_N,WE_N,DQML,DQMH,o_data,o_busy);

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
localparam ACTIVATE=4'b1001;                                  //ACTIVATE state initiates row activation- at the end of this operation all values are stored in the latches of the sense amplifiers. 
localparam PRECHARGE=4'b1010;                                 //PRECHARGE state initiates precharge command of an active row in a specific/all banks
localparam WRITE = 4'b1011;                                   //WRITE state 
localparam READ = 4'b1100;                                    //Read state
localparam READ_DOUT = 4'b1101;                               //READ_DOUT state is entered after the READ state and it's duration corresponds to the latency and burst length

//SDRAM Commands [CS_N,RAS_N,CAS_N,WE_N]
localparam DESL = 4'b1000;                                    //Device deselect
localparam NOP = 4'b0111;                                     //No operation
localparam BST = 4'b0110;                                     //Burst stop
localparam RD = 4'b0101;                                      //For read with auto precharge A10 is '1' else '0'
localparam WRT = 4'b0100;                                     //For write with auto precharge A10 is '1' else '0'
localparam ACT = 4'b0011;                                     //Activate
localparam PRE = 4'b0010;                                     //Precharge. To precharge all banks A10 is '1' else '0'
localparam REF = 4'b0001;                                     //CBR auto-refrsh. For self-refresh toggle CKE along with CS_N
localparam MRS = 4'b0000;                                     //Mode register set

//Inputs
input logic i_rst;                                            //Trigerrs the initialization sequence
input logic i_clk;                                            //System clock input - 100MHz (generated by a PLL)
input logic i_rw;                                             //'1' for write and '0' for read 
input logic i_initial;                                        //Rises to logic high to perform read/write for one clock cycle
input logic [A_ROW_WIDTH+A_COL_WIDTH-1:0] i_addr;             //2^13 rows and 2^10 columns [13 row bits; 10 column bits]
input logic [BA_WIDTH-1:0] i_ba;                              //Banks select address
input logic [D_WIDTH-1:0] i_data;                             //Data to be written
input logic [A_WIDTH-1:0] i_mode_register;                    //Mode register settings (please refer to the datasheet for detailed explanation on the various modes of operation)

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
logic [D_WIDTH-1:0] DQ_tx;
logic [D_WIDTH-1:0 ]DQ_rx;
logic DQ_enable;                                              //When logic high DQ bus is driven by DQ_tx (for 'write' commands)
logic [5:0] counter_rd;                                       //Used to determine the duration of the READ_OUT state - counts until 'latency'+'burst length'
logic [1:0] latency;                                          //The latency is registered upon entering the MODE_REGISTER_SET state. It is re-sampled on every modification to the configuration settings
logic [3:0] burst;                                            //The lateburst lengthncy is registered upon entering the MODE_REGISTER_SET state. It is re-sampled on every modification to the configuration settings
logic [5:0] rd_duration;                                      //Dictates the duration of the read operation. rd_duration=latecny+burst-1.

//HDL code : For start up: apply clock, take rst to '1'. To turn off take rst down and clock cycle later you can disable the input clock

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
    MODE_REGISTER_SET : next_state = WAIT;
    IDLE : next_state = (refresh_flag==1'b1) ? AUTO_REFRESH : (i_initial==1'b1) ? ACTIVATE : IDLE;
    AUTO_REFRESH : next_state = WAIT;
    ACTIVATE : next_state = WAIT;
    WRITE: next_state = WAIT;
    READ: next_state = READ_DOUT;
    READ_DOUT : next_state = (counter_rd<rd_duration) ? READ_DOUT : WAIT;
 endcase

//Generate corresponding command signals to the SDRAM IC and internal controller signals 
always @(posedge i_clk)
  case (state)

    POWER_DOWN : begin
      CKE<=1'b0;
      DQML<=1'b1;
      DQMH<=1'b1;
      cmd<=DESL;                                                //Deselects device to minimize power dissipation when memory is not required
      o_busy<=1'b0;                                             //Read/write commands cannot be issued until initialization phase is complete
      DQ_enable<=1'b0;
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

   MODE_REGISTER_SET: begin                                     //The comments refer to default mode of: {0001000100000}
     cmd<=MRS;                                                  //Mode register set command
     next_state_after_wait<=IDLE;                               
     counter_wait<=$bits(counter_wait)'(2);                     //TRC period is 60ns (REF to REF)
     A[2:0]<=i_mode_register[2:0];                              //Burst legnth is 1. Determines the maximum number of column locations that can be accessed for a given READ or WRITE command
     A[3]<=i_mode_register[3];                                  //Sequencial burst
     A[6:4]<=i_mode_register[6:4];                              //Latency mode - CAS is set to 2. The delay, in clock cycles, between a READ command and the availability of the first piece of output data
     A[8:7]<= i_mode_register[8:7];                             //Stnadard operation 
     A[9]<=i_mode_register[9];                                  //Write burst mode. '1' for single-location write accesses and '0' for burst length as for read accesses 
     A[12:10]<=i_mode_register[12:10];                          //To ensure compatability with futre devices set to '0'
     BA[1:0]<=2'b00;                                            //To ensure compatability with futre devices set to '0'

     latency<=(i_mode_register[6:4]) ? 2'b10 : 2'b11;           //setting the value of 'latency' used to calculate the duration of 'read' operations
     burst<=(i_mode_register[2:0]==3'b000) ? 4'd1 : (i_mode_register[2:0]==3'b001) ? 4'd2 : (i_mode_register[2:0]==3'b010) ? 3'd4 : (i_mode_register[2:0]==3'b011) ? 4'd8 : 4'd1;  //setting the value of 'burst' used to calculate the duration of 'read' operation
   end

   IDLE: begin    //ADD here an option for reconfiguration of the mode register!!!@#!@#!@#$!@$!@$!@!@$[!!!!!!!!!!]
      cmd<=NOP;
      o_busy<=1'b0;                                             //Logic low value allows new read/write operations to be issued
      DQ_enable<=1'b0;                                          //Controller's DQ bus is at high-z
      DQML<=1'b1;                                               //Logic high deactivates SDRAM IC input and output buffers
      DQMH<=1'b1;                                               //Logic high deactivates SDRAM IC input and output buffers
   end

   AUTO_REFRESH: begin
     cmd<=REF;
     counter_wait<=$bits(counter_wait)'(6);                    //TRC period is 60ns (REF to REF)
     next_state_after_wait<=IDLE;
     o_busy<=1'b1;                                             //Read/write command cannot be issued during auto refresh phase
   end

   ACTIVATE: begin
     cmd<=ACT;
     counter_wait<=$bits(counter_wait)'(2);                    //TRCD period is 15ns (Active command to read/write command delay time)
     next_state_after_wait<= (i_rw==1'b1) ? WRITE : READ;      //i_rw determines the operation: '1'for write and '0' for read
     A[12:0]<=i_addr[22:10];                                   //Row is registered upon issueing the ACT command
     BA[1:0]<=i_ba;                                            //Memory bank is registered upon issueing the ACT command
     o_busy<=1'b1;                                             //Rises to logic high so that no additional read/write requests will not be issued                                      	 
   end

   WRITE: begin
     cmd<=WRT;
     A[9:0]<=i_addr[9:0];                                      //Column address
     A[10]<=1'b1;                                              //Write command with auto precharge enabled
     DQ_enable<=1'b1;                                          //Set DQ_enable to logic high to allow the controller to set the DQ bus according to the data needed to be written to memory
     DQ_tx<=i_data;                                            //Data to be written is latched from i_data input                                          
     DQML<=1'b0;                                               //In write mode, DQML and DQMH control the input buffer. When DQML or DQMH is LOW, the corresponding buffer byte is enabled and data can be written to the device
     DQMH<=1'b0;                                               //In write mode, DQML and DQMH control the input buffer. When DQML or DQMH is LOW, the corresponding buffer byte is enabled and data can be written to the device
     counter_wait<=$bits(counter_wait)'(2);                    //TRP period is 15ns. NOP command must be issueed while the SDRAM performs auto precharge operation
     next_state_after_wait<=IDLE;
   end
      
   READ: begin
     cmd<=RD;
     A[9:0]<=i_addr[9:0];                                      //Column adrress
     A[10]<=1'b1;                                              //Read command with auto precharge enabled
     DQML<=1'b0;                                               //In read mode, DQML and DQMH control the output buffer. When DQML or DQMH is LOW, thecorresponding buffer byte is enabled, and when HIGH, disabled. The outputs go to the HIGH impedance state when DQML/DQMH is HIGH.
     DQMH<=1'b0;                                               //In read mode, DQML and DQMH control the output buffer. When DQML or DQMH is LOW, thecorresponding buffer byte is enabled, and when HIGH, disabled. The outputs go to the HIGH impedance state when DQML/DQMH is HIGH.
     counter_rd<=$bits(counter_rd)'(0);                        //Initialize the counter_rd which monitors the duration of the following NOP command with respect to the latency and burst length
   end
   
   READ_DOUT: begin
     cmd<=NOP;
     counter_wait<=$bits(counter_wait)'(2);                    //TRP period is 15ns. NOP command must be issueed while the SDRAM performs auto precharge operation
     next_state_after_wait<=IDLE;

     counter_rd<=counter_rd+$bits(counter_rd)'(1);             //WAIT state is terminated once the internal counter reaches 0
     if (counter_rd>$bits(counter_rd)'(2-1))                   //FIX THIS!!! sample after the latency but no more than burst !!!! [FIXXXXXXXXX] 
       o_data<=DQ;
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
  else if (refresh_en==1'b1) begin
     refresh_flag<=1'b1;
     if (o_busy==1'b0)                                         //If auto refresh is due but the device is currently in active mode the refresh_flag is maintained logic high until IDLE state is reached
       counter_rst<=$bits(counter_rst)'(0);
  end
  else if ((state==IDLE)&&(refresh_en==1'b0))
    refresh_en<=1'b1;

//Assign commands
assign rd_duration = $bits(rd_duration)'(latency+burst-1);     //Duration of 'read' operatoins is a function of both the programmed latency and burst length
assign {CS_N,RAS_N,CAS_N,WE_N}=cmd;                            //cmd is synchronized to the positive edge of i_clk (this assignement does not carry any logical calculations)
assign DQ = (DQ_enable) ? DQ_tx : 'z;                          //When DQ_enable is logic high allow the controller to set the value of DQ bus, otherwise set to high-z
assign DQ_rx = DQ;                                             //Value of the shared DQ bus between the SDRAM IC and the controller
endmodule 