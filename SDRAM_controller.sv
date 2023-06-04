//SDRAM Controller XXX version - operate with 100MHz clock

module SDRAM_controller(rst,A,BA,DQ,CLK,CKE,CS_N,RAS_N,CAS_N,WE_N,DQML,DQMH);

//Parameter declerations
parameter A_WIDTH=13;                         //SDRAM address bus length
parameter BA_WIDTH=2;                         //2^2 memory banks in the SDRAM IC
parameter D_WIDTH=16;                         //Word length

parameter A_ROW_WIDTH = 13;                   //Number of rows in each bank
parameter A_COL_WIDTH = 10;                   //Number of columns in each bank

//States
localparam POWER_DOWN=4'b0000;                //
localparam INITIALIZATION=4'b0001;            //
localparam WAIT=4'b0010;                      //

//SDRAM Commands [CS_N,RAS_N,CAS_N,WE_N]
localparam DESL = 4'b1000;                    //Device deselect
localparam NOP = 4'b0111;                     //No operation
localparam BST = 4'b0110;                     //Burst stop
localparam READ = 4'b0101;                    //For read with auto precharge A10 is '1' else '0'
localparam WRITE = 4'b0100;                   //For write with auto precharge A10 is '1' else '0'
localparam ACT = 4'b0011;                     //Activate
localparam PRE = 4'b0010;                     //Precharge. To precharge all banks A10 is '1' else '0'
localparam REF = 4'b0001;                     //CBR auto-refrsh. For self-refresh toggle CKE along with CS_N
localparam MRS = 4'b0000;                     //Mode register set

//Inputs
input logic i_rst;                                                      //Trigerrs the initialization sequence
input logic i_clk;                                                      //System clock input - 100MHz.
input logic i_rw;                                                       //'1' for write and '0' for read 
input logic i_initial;                                                  //Rises to logic high to perform read/write
input logic [A_ROW_WIDTH+A_COL_WIDTH-1:0] i_addr;                       //2^13 rows and 2^10 columns
input logic [BA_WIDTH-1:0] i_ba;                                        //Banks select address
input logic [D_WIDTH-1:0] i_data;                                       //Data to be written - [?] [This is a single word -what happens in bursts?] [?]


//Outputs
output logic [A_WIDTH-1:0] A;                  //SDRAM address bus
output logic [BA_WIDTH-1:0] BA;                //Banks select address
output logic CLK;                              //SDRAM clock input - 100MHz.
output logic CKE;                              //Clock enable
output logic CS_N;                             //Chip select
output logic RAS_N;                            //Row address strobe command
output logic CAS_N;                            //Column address strobe command
output logic WE_N;                             //Write enable
output logic DQML;                             //Lower byte, input/output mask
output logic DQMH;                             //Upper byte, input/ouptut mask

output logic [15:0] o_data;                    //Word read from memoy. [?] What happens here in bursts? [?]

//Inouts
inout logic [D_WIDTH-1:0] DQ;                  //

//Internal signals
logic [15:0] counter_wait;                     //

//HDL code

//Next state latching
always @(posedge CLK or negedge rst)
  if (!rst)
    state<=POWER_DOWN;
  else 
    state<=next_state; 

//Next state calculation
always @(*)
  case (state)
    POWER_DOWN : next_state = (~rst) ? POWER_DOWN : INITIALIZATION;
    INITIALIZATION : next_state = WAIT;
    WAIT :
 endcase

//
always @(posedge CLK or negedge rst)
  if (!rst) begin
    cmd<=DESL;                                                    //Deselects device to minimize power dissipation when memory is not required

  end
  else begin
    case (state)

      POWER_DOWN : begin
        cmd<=DESL;                                                    //Deselects device to minimize power dissipation when memory is not required
      end

      INITIALIZATION: begin
        CKE<=1'b1;
        DQML<=1'b1;
        DQMH<=1'b1;
        cmd<=NOP;
        counter_wait<=$bits(counter_wait)'(XXX);                  //Initialization requires 100us, i.e. X cycles in 100MHz clock
      end

      Wait: begin
        counter_wait<=counter_wait-$bits(counter_wait)'(1);       //WAIT state is terminated once the internal counter reaches 0
      end

    endcase
  end


//Assign the commands
assign {CS_N,RAS_N,CAS_N,WE_N}=cmd;                               //cmd is synchronized to the positive edge of i_clk
endmodule 