//  --========================================================================--
//  Version and Release Control Information:
//
//  File Name           : block_ram.v
//  File Revision       : 1.00
//
//  ----------------------------------------------------------------------------
//  Purpose             : Memory in Block RAM
//                        
//  --========================================================================--
module block_ram
#(
  parameter MEMWIDTH = 10,
  parameter BITWIDTH = 32
  )
  (
  input wire [MEMWIDTH:2] awrite,
  input wire [MEMWIDTH:2] aread,
  input wire clk,
  input wire [BITWIDTH-1:0] din,
  input wire we,
  output wire [BITWIDTH-1:0] dout
  );
  
  (* ram_style = "block" *)
  reg [BITWIDTH-1:0] ram [(2**(MEMWIDTH-2)-1):0];
  reg [MEMWIDTH-1:0] read_a;
	
  initial
  begin
	$readmemh("code.hex", ram);
  end
    
  always @(posedge clk) begin
    if (we) begin
      ram [awrite] <= din;
    end
    read_a <= aread;
  end
	
  assign dout = ram [read_a];
    
endmodule
