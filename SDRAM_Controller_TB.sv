`timescale 1ns/100ps

module UART_TB_TX ();
//For the TX TB the UART model instantiates only the UART_TX module.
//The relevant TB should be chosen in the project settings in Quartus environment along with the relevant .do file.

//Internal signals declarations
logic UART_line;						//Wire connecting the TX and RX
logic clk_TX;							//TX clock - 25MHz
logic rst_TX;							//Active high module

logic [7:0] data_rand;					//Radom data to be transmitted
logic start_TX;							//Transmission initiation signal

integer k;

parameter TX_bit_period = 17360;		//TX operates at 25MHz, baud rate of 57600 --> 434 TX clock cycles --> time-per-bit equals 434*40 

//UART modules instantiation
UART UART(
				.rst_TX(rst_TX),
				.clk_TX(clk_TX),
				.UART_line(UART_line),
				.data_TX(data_rand),
				.start_TX(start_TX)
				);
			
//Initial blocks
initial 
begin
	rst_TX<=1'b0;	
	clk_TX<=1'b0;
	start_TX<=1'b0;
	data_rand<=8'd0;
	#(TX_bit_period)
	rst_TX<=1'b1;
	#(TX_bit_period)
	
	for(k=0; k<10; k++)
		begin
		#(20*TX_bit_period)			//20 'bit intervals' ensures previous previous data transmission has ended
		data_rand= $random%8;		//Generate 8-bit random data to be sent
		start_TX<=1'b1;
		#(TX_bit_period)
		start_TX<=1'b0;
		end
end

//25MHz clock generation
always	
begin
#20; 
clk_TX=~clk_TX;
end		

endmodule


