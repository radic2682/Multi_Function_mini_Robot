//  --========================================================================--
//  Version and Release Control Information:
//
//  File Name           : AHB2BRAM.v
//  File Revision       : 1.50
//
//  ----------------------------------------------------------------------------
//  Purpose             : Basic AHBLITE Internal Memory Default Size = 64KB
//                        
//  --========================================================================--
module AHB2MEM
#(parameter MEMWIDTH = 16)					// SIZE = 64KB = 16K Words
  (
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
  output wire HREADYOUT,
  output wire [31:0] HRDATA
  );

  assign HREADYOUT = 1'b1; // Always ready

  // Registers to store Adress Phase Signals
 
  reg APhase_HSEL;
  reg APhase_HWRITE;
  reg [1:0] APhase_HTRANS;
  reg [31:0] APhase_HADDR;
  reg [2:0] APhase_HSIZE;

  // Sample the Address Phase   
  always @(posedge HCLK or negedge HRESETn)
  begin
    if(!HRESETn)
    begin
      APhase_HSEL <= 1'b0;
      APhase_HWRITE <= 1'b0;
      APhase_HTRANS <= 2'b00;
      APhase_HADDR <= 32'h0;
      APhase_HSIZE <= 3'b000;
    end
    else if(HREADY)
    begin
      APhase_HSEL <= HSEL;
      APhase_HWRITE <= HWRITE;
      APhase_HTRANS <= HTRANS;
      APhase_HADDR <= HADDR;
      APhase_HSIZE <= HSIZE;
    end
  end

  // Decode the bytes lanes depending on HSIZE & HADDR[1:0]

  wire tx_byte = ~APhase_HSIZE[1] & ~APhase_HSIZE[0];
  wire tx_half = ~APhase_HSIZE[1] &  APhase_HSIZE[0];
  wire tx_word =  APhase_HSIZE[1];
  
  wire byte_at_00 = tx_byte & ~APhase_HADDR[1] & ~APhase_HADDR[0];
  wire byte_at_01 = tx_byte & ~APhase_HADDR[1] &  APhase_HADDR[0];
  wire byte_at_10 = tx_byte &  APhase_HADDR[1] & ~APhase_HADDR[0];
  wire byte_at_11 = tx_byte &  APhase_HADDR[1] &  APhase_HADDR[0];
  
  wire half_at_00 = tx_half & ~APhase_HADDR[1];
  wire half_at_10 = tx_half &  APhase_HADDR[1];
  
  wire word_at_00 = tx_word;
  
  wire byte0 = word_at_00 | half_at_00 | byte_at_00;
  wire byte1 = word_at_00 | half_at_00 | byte_at_01;
  wire byte2 = word_at_00 | half_at_10 | byte_at_10;
  wire byte3 = word_at_00 | half_at_10 | byte_at_11;
  
  wire [31:0] data_to_write = {byte3 ? HWDATA[31:24] : HRDATA[31:24],
                               byte2 ? HWDATA[23:16] : HRDATA[23:16],
                               byte1 ? HWDATA[15: 8] : HRDATA[15: 8],
                               byte0 ? HWDATA[ 7: 0] : HRDATA[ 7: 0]};

  // Student Assignment: Write a testbench & simulate to spot bugs in this Memory module

  block_ram
  #(.MEMWIDTH(MEMWIDTH), .BITWIDTH(32))
  u_block_ram (
    .awrite(APhase_HADDR[MEMWIDTH:2]),
    .aread(HADDR[MEMWIDTH:2]),
    .clk(HCLK),
    .din(data_to_write),
    .we(APhase_HSEL & APhase_HWRITE & APhase_HTRANS[1]),
    .dout(HRDATA)
  );
  
endmodule
