#include "EDK_CM0.h" 
#include "core_cm0.h"
#include "edk_driver.h"
#include <stdlib.h>
#include <time.h>

#define Timer_Interrput_Frequency 			1
#define System_Tick_Frequency 					50000000
#define Timer_Prescaler 								1							//Timer Prescaler, options are: 256, 16, 1 
#define Timer_Load_Value 								(System_Tick_Frequency/Timer_Interrput_Frequency/Timer_Prescaler)

// MODE (SW)
#define MODE_UPCOUNTER					0x01
#define MODE_STOPWATCH					0x02
#define MODE_RANDOM_MULTIPLIER	0x04
#define MODE_ADDER_SUB					0x08
#define MODE_ROBOT							0x10

// Function
void delay(unsigned int);
unsigned int knowBit (unsigned int, unsigned int);
unsigned int checkMoreThanTwoSW (unsigned int);
unsigned int cut0to4(unsigned int);
unsigned int cut5to9(unsigned int);
unsigned int cut10to15(unsigned int);
void eachSegmentDivider(unsigned int, unsigned int);
void eachSegmentDivider_all(unsigned int);
void digReset(void);
void diggReset(void);
void inverseBit(unsigned int*);
void increase_dig_4bit(void);
void decrease_dig_4bit(void);
void increase_dig_3bit(void);
void decrease_dig_3bit(void);

// value
static char dig1,dig2,dig3,dig4;
static char digg1,digg2,digg3,digg4;
static char seven1000, seven100, seven10, seven1;
static unsigned int result;
static unsigned int stopwatchStart;
static unsigned int add_sub_select; // 0: add mode, 1: sub mode
static unsigned int stop_multi_select; // 0: stopwatch mode, 1: multiplier mode

// ---------------------------------------------------------------------------
// Interrupt Functions
// ---------------------------------------------------------------------------
void UART_ISR(void){
	*(unsigned char*) AHB_UART_BASE = knowBit(GPIO_read(),4);
}

void Timer_ISR(void){
	increase_dig_4bit();
	
	// MODE_UPCOUNTER
	if(cut0to4(GPIO_read()) == MODE_UPCOUNTER){ 
		seven_seg_write(dig1, dig2, dig3, dig4);
	}
	
	// MODE_STOPWATCH
	if(cut0to4(GPIO_read()) == MODE_STOPWATCH){
		decrease_dig_4bit();
		seven_seg_write(digg1, digg2, digg3, digg4);
	}
	
	// clear JB when not digg:0000
	if(((digg4==0) & (digg3==0) & (digg2==0) & (digg1==0)) != 1){ // 1 is digg all 0000
		GPIO_JB_write(0x00);
	}
	
	timer_irq_clear();
}	

void Key_ISR(){
  unsigned int temp;
  temp = *(unsigned int*) AHB_KEY_BASE;

  if (temp == 0x1){ // top key:  up-counter reset, stopwatch reset
		digReset();
		diggReset();
    seven_seg_write(0,0,0,0);
		stopwatchStart = 0;
  }
  else if (temp == 0x2){ // left key
		increase_dig_3bit();
		seven_seg_write(digg1, digg2, digg3, digg4);
  }
  else if (temp == 0x4){ // right key
		decrease_dig_3bit();
		seven_seg_write(digg1, digg2, digg3, digg4);
  }
  else if (temp == 0x8){ // bottom key
		inverseBit(&stopwatchStart);
  }
  else if (temp == 0x10){ // middle key
		inverseBit(&add_sub_select);
		inverseBit(&stop_multi_select);
  }
}

// ---------------------------------------------------------------------------
// Main Functions
// ---------------------------------------------------------------------------
int main(void){

	//Initialise timer (load value, prescaler value, mode value)
	timer_init(Timer_Load_Value,Timer_Prescaler,1);
	timer_enable();
	seven_seg_write(0,0,0,0);
	GPIO_JB_write(0x00); //Initialise GPIO_JB
	stopwatchStart = 0;
	add_sub_select=0;
	stop_multi_select=0;
	
	NVIC_SetPriority (Timer_IRQn, 0x00);
	NVIC_SetPriority (UART_IRQn, 0x80);
	NVIC_SetPriority (KEY_IRQn, 0xC0);
	NVIC_EnableIRQ(Timer_IRQn);			//enable timer interrupt
	NVIC_EnableIRQ(UART_IRQn);			//enable UART interrupt
	NVIC_EnableIRQ(KEY_IRQn);				//enable UART interrupt
	
	while(1){
		GPIO_write(GPIO_read());
		
		if (checkMoreThanTwoSW(GPIO_read()) == 0)
			goto nothingHappen;
		

		// MODE_RANDOM_MULTIPLIER	
		if (cut0to4(GPIO_read()) == MODE_RANDOM_MULTIPLIER	){
			if(stop_multi_select==0){ // RANDOM MODE
				result = rand() % 10000;
				eachSegmentDivider_all(result);
				seven_seg_write(seven1000, seven100, seven10, seven1);
			}
			else{ // MULTIPLIER MODE
				result = cut5to9(GPIO_read()) * cut10to15(GPIO_read());
				eachSegmentDivider(result, 0x00);
				seven_seg_write(seven1000, seven100, seven10, seven1);
			}
		}

		// MODE_ADDER_SUB
		else if (cut0to4(GPIO_read()) == MODE_ADDER_SUB){
			if(add_sub_select==0){ // ADDER MODE
				result = cut5to9(GPIO_read()) + cut10to15(GPIO_read());
				eachSegmentDivider(result, 0x00);
				seven_seg_write(seven1000, seven100, seven10, seven1);
			}
			else{ // SUB MODE
				if(cut10to15(GPIO_read())> cut5to9(GPIO_read())){
					result = cut10to15(GPIO_read()) - cut5to9(GPIO_read());
					eachSegmentDivider(result, 0x00);
					seven_seg_write(seven1000, seven100, seven10, seven1);
				}
				else if(cut10to15(GPIO_read())< cut5to9(GPIO_read())){
					result = cut5to9(GPIO_read()) - cut10to15(GPIO_read());
					eachSegmentDivider(result, 0x11); // 0x11 is -
					seven_seg_write(seven1000, seven100, seven10, seven1);
				}
				else{
					seven_seg_write(0,0,0,0);
				}
			}
		}
		
		// MODE_ROBOT
		else if (cut0to4(GPIO_read()) == MODE_ROBOT){
			seven_seg_write(0x11,0x11,0x11,0x11);
		}
		

		nothingHappen:
		delay(1000000); // ******
	}
}

// ---------------------------------------------------------------------------
// Functions
// ---------------------------------------------------------------------------
void delay(unsigned int period){
	unsigned int counter=0;
	unsigned int i=0;
  for (i=0;i<period;i++){
		counter++;
	}
}

// A function that extracts a specific bit
unsigned int knowBit (unsigned int temp, unsigned int where){
	return (temp & (1 << where)) >> where;
}

// A function that sets a specific bit
unsigned int SetBit (unsigned int temp, unsigned int where){
	return (temp | (1 << where));
}

// Check if more than two mode SW on => 1: only one, 0: 0 or more than two
unsigned int checkMoreThanTwoSW (unsigned int temp){
	unsigned int i = 0;
	unsigned int check_v = 0;
	
	while (i < 5){
		if (knowBit(temp, i) == 1)
			check_v ++;
		i ++;
	}
	
	if (check_v == 1)
		return check_v;
	else
		return 0;
}

unsigned int cut0to4(unsigned int temp){
	temp = 0x001F & temp; // 0x001F: 0000 0000 0001 1111
	return temp;
}

unsigned int cut5to9(unsigned int temp){
	temp = 0x03E0 & temp; // 0x03E0: 0000 0011 1110 0000
	return temp >> 5;
}

unsigned int cut10to15(unsigned int temp){
	temp = 0x7C00 & temp; // 0x7C00: 0111 1100 0000 0000
	return temp >> 10;
}

// SegmentDivider -> 3bit + special sign
void eachSegmentDivider(unsigned int result, unsigned int thousand){
	seven1		=	(result) % 10;
	seven10		= (result % 100) /10 ;    
	seven100 	= (result %1000) / 100;
	seven1000 =	thousand;
}

// SegmentDivider -> 3bit + special sign
void eachSegmentDivider_all(unsigned int result){
	seven1		=	(result) % 10;
	seven10		= (result % 100) /10 ;    
	seven100 	= (result %1000) / 100;
	seven1000 =	(result) / 1000;
}

void inverseBit(unsigned int* temp){
	if(*temp==0)
		*temp = 1;
	else
		*temp = 0;
}


// ---------------------------------------------------------------------------
// dig, digg Functions
// ---------------------------------------------------------------------------
void digReset(){
	dig1 = 0;
	dig2 = 0;
	dig3 = 0;
	dig4 = 0;
}

void diggReset(){
	digg1 = 0;
	digg2 = 0;
	digg3 = 0;
	digg4 = 0;
}

void increase_dig_4bit(){
	dig4++;
	if(dig4==10){
		dig4=0;
		dig3++;
		if (dig3==10){
			dig3=0;
			dig2++;
			if (dig2==10){
				dig2=0;
				dig1++;
			}
		}
	}
}

void decrease_dig_4bit(){
	if(stopwatchStart==1){
			if(digg4==0){
				if(digg3==0){
					if(digg2==0){
						if(digg1==0){
							GPIO_JB_write(0x01);
						}
						else{
							digg1--;
							digg2 = 9;
						}
					}
					else{
						digg2--;
						digg3 = 9;
					}
				}
				else{
					digg3--;
					digg4 = 9;
				}
			}
			else
				digg4--;
		}
}

void increase_dig_3bit(){
	digg3++;
	if (digg3==10){
		digg3=0;
		digg2++;
		if (digg2==10){
			digg2=0;
			digg1++;
		}
	}
}

void decrease_dig_3bit(){
	if(digg3==0){
		if(digg2==0){
			if(digg1==0){
				// digg: 0000
			}
			else{
				digg1--;
				digg2 = 9;
			}
		}
		else{
			digg2--;
			digg3 = 9;
		}
	}
	else{
		digg3--;
	}
}

