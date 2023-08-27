//////////////////////////////////////////////////////////////////////////////////
//END USER LICENCE AGREEMENT                                                    //
//                                                                              //
//Copyright (c) 2012, ARM All rights reserved.                                  //
//                                                                              //
//THIS END USER LICENCE AGREEMENT (“LICENCE?) IS A LEGAL AGREEMENT BETWEEN      //
//YOU AND ARM LIMITED ("ARM") FOR THE USE OF THE SOFTWARE EXAMPLE ACCOMPANYING  //
//THIS LICENCE. ARM IS ONLY WILLING TO LICENSE THE SOFTWARE EXAMPLE TO YOU ON   //
//CONDITION THAT YOU ACCEPT ALL OF THE TERMS IN THIS LICENCE. BY INSTALLING OR  //
//OTHERWISE USING OR COPYING THE SOFTWARE EXAMPLE YOU INDICATE THAT YOU AGREE   //
//TO BE BOUND BY ALL OF THE TERMS OF THIS LICENCE. IF YOU DO NOT AGREE TO THE   //
//TERMS OF THIS LICENCE, ARM IS UNWILLING TO LICENSE THE SOFTWARE EXAMPLE TO    //
//YOU AND YOU MAY NOT INSTALL, USE OR COPY THE SOFTWARE EXAMPLE.                //
//                                                                              //
//ARM hereby grants to you, subject to the terms and conditions of this Licence,//
//a non-exclusive, worldwide, non-transferable, copyright licence only to       //
//redistribute and use in source and binary forms, with or without modification,//
//for academic purposes provided the following conditions are met:              //
//a) Redistributions of source code must retain the above copyright notice, this//
//list of conditions and the following disclaimer.                              //
//b) Redistributions in binary form must reproduce the above copyright notice,  //
//this list of conditions and the following disclaimer in the documentation     //
//and/or other materials provided with the distribution.                        //
//                                                                              //
//THIS SOFTWARE EXAMPLE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ARM     //
//EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING     //
//WITHOUT LIMITATION WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR //
//PURPOSE, WITH RESPECT TO THIS SOFTWARE EXAMPLE. IN NO EVENT SHALL ARM BE LIABLE/
//FOR ANY DIRECT, INDIRECT, INCIDENTAL, PUNITIVE, OR CONSEQUENTIAL DAMAGES OF ANY/
//KIND WHATSOEVER WITH RESPECT TO THE SOFTWARE EXAMPLE. ARM SHALL NOT BE LIABLE //
//FOR ANY CLAIMS, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, //
//TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE    //
//EXAMPLE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE EXAMPLE. FOR THE AVOIDANCE/
// OF DOUBT, NO PATENT LICENSES ARE BEING LICENSED UNDER THIS LICENSE AGREEMENT.//
//////////////////////////////////////////////////////////////////////////////////


module AHBLITE_SYS(    
    //CLOCKS & RESET
    input		wire				 CLK,
    input		wire				 RESET,
    
    //TO BOARD LEDs
    output 	wire	[15:0] LED,
    
    // SW
    input   wire    [14:0]  sw,
    
    // KEY
    input   wire  [4:0]  KEY,
    
    // SEG
    output  wire  [6:0]  seg,
    output  wire  [3:0]  an,
    output  wire         dp,
    
    // UART
    input wire           JARx,
    output wire          JATx,

    // GPIO JB
    input wire  [3:0]   JBI,
    output wire  [3:0]   JBO
);
 
//AHB-LITE SIGNALS 
//Gloal Signals
wire  			HCLK;
wire  			HRESETn;
//Address, Control & Write Data Signals
wire [31:0]		HADDR;
wire [31:0]		HWDATA;
wire 			HWRITE;
wire [1:0] 		HTRANS;
wire [2:0] 		HBURST;
wire 			HMASTLOCK;
wire [3:0] 		HPROT;
wire [2:0] 		HSIZE;
//Transfer Response & Read Data Signals
wire [31:0] 	HRDATA;
wire 			HRESP;
wire 			HREADY;

//SELECT SIGNALS
wire [3:0] 		MUX_SEL;

wire 				  HSEL_MEM;
wire 				  HSEL_GPIO;
wire 				  HSEL_KEY;
wire 				  HSEL_SEG;
wire 				  HSEL_TIMER;
wire 				  HSEL_UART;
wire 				  HSEL_GPIO_JB;

//SLAVE READ DATA
wire [31:0] 	HRDATA_MEM;
wire [31:0] 	HRDATA_GPIO;
wire [31:0] 	HRDATA_KEY;
wire [31:0] 	HRDATA_SEG;
wire [31:0] 	HRDATA_TIMER;
wire [31:0] 	HRDATA_UART;
wire [31:0] 	HRDATA_GPIO_JB;

//SLAVE HREADYOUT
wire 				  HREADYOUT_MEM;
wire 				  HREADYOUT_GPIO;
wire 				  HREADYOUT_KEY;
wire 				  HREADYOUT_SEG;
wire 				  HREADYOUT_TIMER;
wire 				  HREADYOUT_UART;
wire 				  HREADYOUT_GPIO_JB;

//CM0-DS Sideband signals
wire 				  LOCKUP;
wire 				  TXEV;
wire 				  SLEEPING;
wire [15:0]		IRQ;
  
//SYSTEM GENERATES NO ERROR RESPONSE
assign 			  HRESP = 1'b0;

wire          KEY_IRQ;
wire          TIMER_IRQ;
wire          UART_IRQ;

//CM0-DS INTERRUPT SIGNALS  
assign 			  IRQ = {13'b0000_0000_0000_000, KEY_IRQ, UART_IRQ, TIMER_IRQ};
assign 			  LED[15] = LOCKUP;

assign 	      HRESETn = ~RESET;    

// Clock divider, divide the frequency by two, hence less time constraint 
reg clk_div;

  always @(posedge CLK or negedge HRESETn)
  begin
    if (!HRESETn)
      clk_div = 0;
    else 
      clk_div=~clk_div;
  end

// A global clock buffer
  BUFG BUFG_CLK( 
      .O(HCLK), 		// 1-bit output: Clock buffer outpu
      .I(clk_div)  	// 1-bit input: Clock buffer inpu
  );

//AHBLite MASTER --> CM0-DS

CORTEXM0DS u_cortexm0ds (
	//Global Signals
	.HCLK        (HCLK),
	.HRESETn     (HRESETn),
	//Address, Control & Write Data	
	.HADDR       (HADDR[31:0]),
	.HBURST      (HBURST[2:0]),
	.HMASTLOCK   (HMASTLOCK),
	.HPROT       (HPROT[3:0]),
	.HSIZE       (HSIZE[2:0]),
	.HTRANS      (HTRANS[1:0]),
	.HWDATA      (HWDATA[31:0]),
	.HWRITE      (HWRITE),
	//Transfer Response & Read Data	
	.HRDATA      (HRDATA[31:0]),			
	.HREADY      (HREADY),					
	.HRESP       (HRESP),					

	//CM0 Sideband Signals
	.NMI         (1'b0),
	.IRQ         (IRQ[15:0]),
	.TXEV        (),
	.RXEV        (1'b0),
	.LOCKUP      (LOCKUP),
	.SYSRESETREQ (),
	.SLEEPING    ()
);

//Address Decoder 

AHBDCD uAHBDCD ( 
	.HADDR(HADDR[31:0]), 
	 
	.HSEL_S0(HSEL_MEM),   // 0x0000_0000
	.HSEL_S1(HSEL_GPIO_JB),   // 0x5000_0000
	.HSEL_S2(HSEL_UART),  // 0x5100_0000
	.HSEL_S3(HSEL_TIMER), // 0x5200_0000
	.HSEL_S4(HSEL_GPIO),  // 0x5300_0000
	.HSEL_S5(HSEL_SEG),   // 0x5400_0000
	.HSEL_S6(HSEL_KEY),   // 0x5500_0000
	.HSEL_S7(),   // 0x5600_0000
	.HSEL_S8(),
	.HSEL_S9(),
	.HSEL_NOMAP(HSEL_NOMAP),
	 
	.MUX_SEL(MUX_SEL[3:0])  
);

//Slave to Master Mulitplexor

AHBMUX uAHBMUX (
	.HCLK(HCLK),
	.HRESETn(HRESETn),
	.MUX_SEL(MUX_SEL[3:0]),

	.HRDATA_S0(HRDATA_MEM),
	.HRDATA_S1(HRDATA_GPIO_JB),
	.HRDATA_S2(HRDATA_UART),
	.HRDATA_S3(HRDATA_TIMER),
	.HRDATA_S4(HRDATA_GPIO),
	.HRDATA_S5(HRDATA_SEG),
	.HRDATA_S6(HRDATA_KEY),
	.HRDATA_S7(),
	.HRDATA_S8(),
	.HRDATA_S9(), 
	.HRDATA_NOMAP(32'hDEADBEEF),
	 
	.HREADYOUT_S0(HREADYOUT_MEM),
	.HREADYOUT_S1(HREADYOUT_GPIO_JB),
	.HREADYOUT_S2(HREADYOUT_UART),
	.HREADYOUT_S3(HREADYOUT_TIMER),
	.HREADYOUT_S4(HREADYOUT_GPIO),
	.HREADYOUT_S5(HREADYOUT_SEG),
	.HREADYOUT_S6(HREADYOUT_KEY),
	.HREADYOUT_S7(1'b1),
	.HREADYOUT_S8(1'b1),
	.HREADYOUT_S9(1'b1),
	.HREADYOUT_NOMAP(1'b1),
    
	.HRDATA(HRDATA[31:0]),
	.HREADY(HREADY)
);

// AHBLite Peripherals


//AHBLite Slave 
AHB2MEM uAHB2MEM (
	//AHBLITE Signals
	.HSEL(HSEL_MEM),
	.HCLK(HCLK), 
	.HRESETn(HRESETn), 
	.HREADY(HREADY),     
	.HADDR(HADDR),
	.HTRANS(HTRANS[1:0]), 
	.HWRITE(HWRITE),
	.HSIZE(HSIZE),
	.HWDATA(HWDATA[31:0]), 
	
	.HRDATA(HRDATA_MEM), 
	.HREADYOUT(HREADYOUT_MEM)
	//Sideband Signals
	
);


//AHBLite Slave
AHBGPIO uAHBGPIO(
	//AHBLITE Signals
	.HSEL(HSEL_GPIO),
	.HCLK(HCLK), 
	.HRESETn(HRESETn), 
	.HREADY(HREADY),     
	.HADDR(HADDR),
	.HTRANS(HTRANS[1:0]), 
	.HWRITE(HWRITE),
	.HWDATA(HWDATA[31:0]), 
	
	.HRDATA(HRDATA_GPIO), 
	.HREADYOUT(HREADYOUT_GPIO),
	
    .GPIOIN({1'b0, sw[14:0]}),
    .GPIOOUT(LED[14:0])

);

//AHBLite Slave
AHBGPIO uAHBGPIOJB(
	//AHBLITE Signals
	.HSEL(HSEL_GPIO_JB),
	.HCLK(HCLK), 
	.HRESETn(HRESETn), 
	.HREADY(HREADY),     
	.HADDR(HADDR),
	.HTRANS(HTRANS[1:0]), 
	.HWRITE(HWRITE),
	.HWDATA(HWDATA[31:0]), 
	
	.HRDATA(HRDATA_GPIO_JB), 
	.HREADYOUT(HREADYOUT_GPIO_JB),
	
    .GPIOIN({12'b0, JBI[3:0]}),
    .GPIOOUT(JBO[3:0])
);

//AHBLite Slave 
AHB2KEY2 uAHB2KEY2 (
	//AHBLITE Signals
	.HSEL(HSEL_KEY),
	.HCLK(HCLK), 
	.HRESETn(HRESETn), 
	.HREADY(HREADY),     
	.HADDR(HADDR),
	.HTRANS(HTRANS[1:0]), 
	.HWRITE(HWRITE),
	.HWDATA(HWDATA[31:0]), 
	
	.HRDATA(HRDATA_KEY),   
	.HREADYOUT(HREADYOUT_KEY),
	//Sideband Signals
	.KEY_IRQ(KEY_IRQ),
	.KEY(KEY)
);


//AHBLite Slave 
AHB7SEGDEC uAHB7SEGDEC (
	//AHBLITE Signals
	.HSEL(HSEL_SEG),
	.HCLK(HCLK), 
	.HRESETn(HRESETn), 
	.HREADY(HREADY),     
	.HADDR(HADDR),
	.HTRANS(HTRANS[1:0]), 
	.HWRITE(HWRITE),
	.HWDATA(HWDATA[31:0]), 
	
	.HRDATA(HRDATA_SEG),   
	.HREADYOUT(HREADYOUT_SEG),
	
  //Sideband Signals
  .seg(seg),
  .an(an),
  .dp(dp)
);

//AHBLite Slave 
AHBTIMER uAHBTIMER (
	//AHBLITE Signals
	.HSEL(HSEL_TIMER),
	.HCLK(HCLK), 
	.HRESETn(HRESETn), 
	.HREADY(HREADY),     
	.HADDR(HADDR),
	.HTRANS(HTRANS[1:0]), 
	.HWRITE(HWRITE),
	.HWDATA(HWDATA[31:0]), 
	
	.HRDATA(HRDATA_TIMER),   
	.HREADYOUT(HREADYOUT_TIMER),
	//Sideband Signals
	.timer_irq(TIMER_IRQ)
);

//AHBLite Slave 
AHBUART uAHBUART (
	//AHBLITE Signals
	.HSEL(HSEL_UART),
	.HCLK(HCLK), 
	.HRESETn(HRESETn), 
	.HREADY(HREADY),     
	.HADDR(HADDR),
	.HTRANS(HTRANS[1:0]), 
	.HWRITE(HWRITE),
	.HWDATA(HWDATA[31:0]), 
	
	.HRDATA(HRDATA_UART),   
	.HREADYOUT(HREADYOUT_UART),
	//Sideband Signals
	.JARx(JARx),
	.JATx(JATx),
	.uart_irq(UART_IRQ)
);


endmodule
