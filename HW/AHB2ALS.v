/******************************************************************************
*
*    File Name:  AHB2ALS.v
*    Version:  1.0
*    Start Date:  Oct. 24, 2017
*    End   Date:  
*    Description:  main body of AHB2ALS.v
*    Dependencies:  
*    Company:  School of EEE, Dankook University
*    Designer: HyunJin Kim
*    Feature: AHB Lite interface for Pmod Ambient Light Sensor
*             SCK is (50/128)MHz for 50MHz bus clock speed. (1MHz < x < 4MHz)
*             16 sclk clock cycles for reading value
*               1 sclk clock cycles for no information
*               3 sclk clock cycles for leading zeros
*               8 sclk clock cycles for eight values
*               4 sclk clock cycles for trailing values
*
******************************************************************************/

`define READ    1'b1
`define WRITE   1'b0
`define ST_IDLE 4'd0
//`define ST_NI   4'd1 // no information
`define ST_LZ   4'd2 // leading zeros
`define ST_D1   4'd3
`define ST_D2   4'd4
`define ST_D3   4'd5
`define ST_D4   4'd6
`define ST_D5   4'd7
`define ST_D6   4'd8
`define ST_D7   4'd9
`define ST_D8   4'd10
`define ST_TZ   4'd11 // trailing zeros


module AHB2ALS(
  //AHBLITE INTERFACE
  //Slave Select Signals
  input wire HSEL,
  //Global Signal
  input wire HCLK,
  input wire HRESETn,
  //Address, Control & Write Data
  input wire HREADY,
  input wire [31:0] HADDR,
  input wire [1:0] HTRANS,
  input wire HWRITE,
  input wire [2:0] HSIZE,
  			
  input wire [31:0] HWDATA,
  // Transfer Response & Read Data
  output reg  HREADYOUT,
  output wire [31:0] HRDATA,

  input  wire  MISO,
  output reg   CS,
  output reg   SCLK

);

  reg [10:0]  cnt_hclk_clocks;
  reg        cnt_done;
  
  always @(posedge HCLK or negedge HRESETn)
  begin
    if (!HRESETn)
    begin
      cnt_done <= 1'b0;
      cnt_hclk_clocks <= 11'd0;
      CS <= 1'b1;
    end
    // start read operation
    else if ((HSEL && !HWRITE && HTRANS[1] && HREADY) && (cnt_hclk_clocks == 11'd0))
    begin
      cnt_done   <= 1'b1;
      cnt_hclk_clocks <= cnt_hclk_clocks + 1'b1;
      CS <= 1'b0;
    end
    else if (cnt_done == 1'b1) 
    begin
      if (cnt_hclk_clocks == 128*16-1) 
		  begin
        cnt_done <= 1'b0;
        cnt_hclk_clocks <= 11'd0;
        CS <= 1'b1;
		  end  
      else 
      begin  
        cnt_hclk_clocks <= cnt_hclk_clocks + 1'b1;
      end
    end
  end

  // generate HREADYOUT considering cnt_done, cnt_hclk_clocks
  always @(posedge HCLK or negedge HRESETn)
  begin
    if (!HRESETn)
      HREADYOUT <= 1'b1;
    else if ((HSEL && !HWRITE && HTRANS[1] && HREADY) && (cnt_hclk_clocks == 11'd0)) 
      HREADYOUT <= 1'b0;
    else if ((cnt_done == 1'b1) && (cnt_hclk_clocks != 128*16-1) && (cnt_hclk_clocks != 11'd0)) 
      HREADYOUT <= 1'b0;
    else 
      HREADYOUT <= 1'b1;
  end

  // generate SCLK
  always @(posedge HCLK or negedge HRESETn)
    if (!HRESETn)
      SCLK <= 1'b1;
    else if (cnt_hclk_clocks[6:0] < 7'd64)
      SCLK <= 1'b1;
    else
      SCLK <= 1'b0;

  reg [3:0] state, next_state; 

  // sequential part
  always @(posedge HCLK or negedge HRESETn)
  begin
	 if(!HRESETn)
     state <= `ST_IDLE;
   else
     state <= next_state;
  end

  // combinational part
  always @(cnt_hclk_clocks or cnt_done or state)
  begin
    next_state = state;
    case(state) 
      `ST_IDLE: begin
        if ((cnt_done == 1'b1) && (cnt_hclk_clocks == (128-1))) // 127  
          next_state = `ST_LZ;
      end
       `ST_LZ: begin
        if ((cnt_done == 1'b1) && (cnt_hclk_clocks == 128*4-1))  
          next_state = `ST_D1;
      end
       `ST_D1: begin
        if ((cnt_done == 1'b1) && (cnt_hclk_clocks == 128*5-1))  
          next_state = `ST_D2;
      end
       `ST_D2: begin
        if ((cnt_done == 1'b1) && (cnt_hclk_clocks == 128*6-1))  
          next_state = `ST_D3;
      end
       `ST_D3: begin
        if ((cnt_done == 1'b1) && (cnt_hclk_clocks == 128*7-1))  
          next_state = `ST_D4;
      end
       `ST_D4: begin
        if ((cnt_done == 1'b1) && (cnt_hclk_clocks == 128*8-1))  
          next_state = `ST_D5;
      end
       `ST_D5: begin
        if ((cnt_done == 1'b1) && (cnt_hclk_clocks == 128*9-1))  
          next_state = `ST_D6;
      end
       `ST_D6: begin
        if ((cnt_done == 1'b1) && (cnt_hclk_clocks == 128*10-1))  
          next_state = `ST_D7;
      end
       `ST_D7: begin
        if ((cnt_done == 1'b1) && (cnt_hclk_clocks == 128*11-1))  
          next_state = `ST_D8;
      end
       `ST_D8: begin
        if ((cnt_done == 1'b1) && (cnt_hclk_clocks == 128*12-1))  
          next_state = `ST_TZ;
      end
       `ST_TZ: begin
        if ((cnt_done == 1'b1) && (cnt_hclk_clocks == 128*16-1))  
          next_state = `ST_IDLE;
      end
        default:  
          next_state = `ST_IDLE;
    endcase
  end  

  reg [7:0] data, next_data;
 
  always @(posedge HCLK or negedge HRESETn)
  begin
	 if(!HRESETn)
   begin
     data  <= 32'h0; 
   end
   else
   begin
     data  <= next_data; 
   end
  end
 
  // output part
  always @(state or MISO or cnt_hclk_clocks[6:0] or data)
  begin
    next_data = data;
    if (cnt_hclk_clocks[6:0] == 0)  
      case(state)  
        `ST_LZ: next_data    = 8'b0;
        `ST_D1: next_data[7] = MISO;
        `ST_D2: next_data[6] = MISO;
        `ST_D3: next_data[5] = MISO;
        `ST_D4: next_data[4] = MISO;
        `ST_D5: next_data[3] = MISO;
        `ST_D6: next_data[2] = MISO;
        `ST_D7: next_data[1] = MISO;
        `ST_D8: next_data[0] = MISO;
      endcase
  end  

  assign HRDATA = {24'b0, data};

endmodule
