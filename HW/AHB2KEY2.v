/******************************************************************************
*
*    File Name:  AHB2KEY2.v
*    Version:  2.0
*    Start Date:  Nov. 15, 2017
*    End   Date:  
*    Description:  main body of AHB2KEY2.v
*    Dependencies:  
*    Company:  School of EEE, Dankook University
*    Designer: HyunJin Kim
*    Feature: AHB Lite interface for KEY, 
*             One action (interrupt) for one falling edge
*
******************************************************************************/


module AHB2KEY2(
  input wire HCLK,
  input wire HRESETn,
  input wire [31:0] HADDR,
  input wire [31:0] HWDATA,
  input wire HWRITE,
  input wire [1:0] HTRANS,
  input wire HREADY,
  input wire HSEL,
  
  output wire HREADYOUT,
  output wire [31:0] HRDATA,
  output reg KEY_IRQ,
  
  input wire [4:0] KEY
    );
    
  reg last_HSEL;
  reg last_HWRITE;
  reg [1:0] last_HTRANS;
  
  always @(posedge HCLK)
  if(HREADY)
    begin
      last_HSEL <= HSEL;
      last_HWRITE <= HWRITE;
      last_HTRANS <= HTRANS;
    end
  
  wire       rd;             //read
  reg  [4:0] keyout;        //key output
  reg        key_pushed;    //key output
  
  // sequential part
  always @(posedge HCLK or negedge HRESETn)
  begin
	 if(!HRESETn)
   begin
     keyout <= 5'b0;
     key_pushed <= 1'b0;
   end
   else if ((key_pushed == 1'b0) && (KEY != 5'b0))
   begin
     keyout <= KEY;
     key_pushed <= 1'b1; 
   end
   else if (KEY == 5'b0) 
   begin
     keyout <= 5'b0;
     key_pushed <= 1'b0; 
   end
  end

  // sequential part
  always @(posedge HCLK or negedge HRESETn)
  begin
	 if(!HRESETn)
     KEY_IRQ <= 1'b0;
   else if ((key_pushed == 1'b0) && (KEY != 5'b0))
     KEY_IRQ <= 1'b1;
   else if (rd)
     KEY_IRQ <= 1'b0;
  end


  //Only read if not empty
  assign rd = ~last_HWRITE & last_HTRANS[1] & last_HSEL & key_pushed;  

  //If not pushed wait for pushed
  assign HREADYOUT = key_pushed;

  //assign output
  assign HRDATA[7:0] = keyout;
  
endmodule
