@ Code for Lab-HW8 for ENSC 254
@ Copyright (C) 2022 Craig Scratchley

;@ Student Name 1: Aleksandr Kopylov
;@ Student 1 301384850
;@ Student 1 userid (email): akopylov (stu1@sfu.ca)
;@
;@ Student Name 2: Nicholas Chu
;@ Student 2 #: 301440034
;@ Student 2 userid (email): nmc10 (stu2@sfu.ca)

@Declare the labels of the interrupt handler and the main routine as globals
//.global FIQHandler

#include "asm_include.h"
#include "macros.i"

.equ E254_TC_CSR_NEEDED_MASKS, XTC_CSR_ENABLE_TMR_MASK | XTC_CSR_ENABLE_INT_MASK | XTC_CSR_DOWN_COUNT_MASK | XTC_CSR_INT_OCCURED_MASK
.equ Reload_timer_without_enable, XTC_CSR_LOAD_MASK | XTC_CSR_ENABLE_INT_MASK | XTC_CSR_DOWN_COUNT_MASK | XTC_CSR_INT_OCCURED_MASK

.text

FUNC	asm_main
	PUSH	{R4-R11, LR}
	BL	OLED_clear
	BL	OLED_welcome
	LDR	R0, =0 @ total_events

	@Switch to FIQ mode
	LDR	R1, =XREG_CPSR_FIQ_MODE
	MSR	CPSR_c, R1

	@Initialize FIQ registers for the purposes
	@of the FIQ being able to use them
	LDR	R9, =XPAR_AXI_GPIO_BTNS_BASEADDR  
	LDR	R10, =XPAR_AXI_GPIO_LEDS_BASEADDR
	LDR	R11, =XPAR_AXI_TIMER_0_BASEADDR

	@configure timer
	@Count goes here -- 1s
	@LDR	R8, =XPAR_AXI_TIMER_0_CLOCK_FREQ_HZ
	//LDR	R8, =5000000
	LDR	R8, =2000000
 	@Now load the load register.
	STR 	R8, [R11, #XTC_TLR_OFFSET]
	@Load the counter register.
	LDR 	R8, =XTC_CSR_LOAD_MASK
	STR 	R8, [R11, #XTC_TCSR_OFFSET]


	@Button interrupt on.
	LDR 	R8, =XGPIO_GIE_GINTR_ENABLE_MASK
	STR 	R8, [R9, #XGPIO_GIE_OFFSET]
	LDR 	R8, =XGPIO_IR_CH1_MASK
	STR 	R8, [R9, #XGPIO_IER_OFFSET]
	mov	r12, #1

  	str 	r0, [r10, #XGPIO_DATA_OFFSET]	;@ write 0 to LEDs to turn them off

	;@ The connections to the LEDs and switches are initially configured as inputs. This works well
	;@ for the switches but not so helpful for the LEDs.  Connections can be changed to outputs by
	;@ clearing their corresponding bits in the GPIO 'Tristate Register'. The
	;@ Tristate register is at an offset from the base address for GPIO ports.
	ldr 	R8, [R10, #XGPIO_TRI_OFFSET] 	;@ Read the tristate register for the LEDs
	bic 	R8, #0xFF   			;@ Clear the first 8 tristate bits to enable the 8 LEDs as outputs
	str 	R8, [R10, #XGPIO_TRI_OFFSET]	;@ Write new value to LED tristate register to enable as outputs

	MOV 	R8, R0 @ total_events

	@Switch back to system mode
	LDR 	R1, =XREG_CPSR_SYSTEM_MODE
	MSR 	CPSR_c, R1

	@Print initial count of events on the OLED
	MOV 	R1, #3
	BL 	OLED_print_R0_on_row_R1
	
	@Enable fast interrupts
	CPSIE 	f

	;@ Load base addresses for ... and Slider Switch GPIO
	ldr 	r4, =XPAR_AXI_GPIO_SWS_BASEADDR		;@ load base address of Switches into r4

.poll:
	ldr 	r6, =4000  @ first argument for below subroutine and function
	@ ldr 	r6, =32
	@ ldr 	r6, [r4, #XGPIO_DATA_OFFSET]	;@ read slider switches
	@ mov	r6, r6, lsl #9			;@ scale value up
	mov 	r0, r6
	mov 	r1, #1
	BL 	OLED_print_R0_on_row_R1
	mov 	r0, r6
	BL 	fib_main
	mov 	r7, r0
	ldr 	r5, =184375  @ return value from fib_main should be 184375
	teq 	r5, r0
	beq	cont
  	MOV 	R1, #2
  	BL 	OLED_print_R0_on_row_R1
err_loop:
	mov 	r0, r7 		@ put erroneous fib_main return value in r0
	bl 	_exit		@ exit program hitting default breakpoint
	@ nop
	@ b 	err_loop	@ alternative error handling

cont:
  	MOV 	R1, #2
  	BL 	OLED_print_R0_on_row_R1
  	B 	.poll

	@ we should never get here
  	POP 	{R4-R11, PC}
ENDFUNC asm_main

;@ FIQHandler stuff below
@ offsets from stack pointer for automatic variables
.equ 	bigN0, 0
.equ 	bigN1, 4 + bigN0

.equ 	autoSize, 4 + bigN1 @ total space for automatic variables

FUNC	FIQHandler

	PUSH 	{r0-r4, lr}
	sub	sp, sp, #autoSize @ make space for automatic variables

	//check here if r12 is == 0 and timer interrupt == 0 if it is we can simply exit the FIQ. r12 == 1 initially, and only becomes 0 after pressed label, and back to 1 due to timer
	//if r12 == 0, want to set ISR == 0
	//LDR	r0, [R9, #XGPIO_IER_OFFSET]

	tst	r12, #XGPIO_IR_CH1_MASK	//R12 functions as our ISR

	mov	r3, #0
	STREQ	r3, [R9, #XGPIO_ISR_OFFSET]
	LDR	r3, [R9, #XGPIO_ISR_OFFSET]

	LDR 	R1, [R11, #XTC_TCSR_OFFSET]

	AND	r1, r1, #XTC_CSR_INT_OCCURED_MASK	//Get only the Int occured bit
	ORRS	r1, r1, r3		//if this result has any bit set to 1, we should continue, else exit FIQ

	//teq	r1, #0		//bitwise XOR, if result is 0, we should exit (false button press)
	beq	Exit1		//else continue


	mov 	r2, #0
  	str	r2, [sp, #bigN0] @ bigN0 is the value 0
  	str	r2, [sp, #bigN1] @ bigN1 is the value 0
  	add 	r0, sp, #bigN0	@ put address in r0
  	add 	r1, sp, #bigN1  @ put other address in r1
	BL 	bigAdd		@ commented out for now


  	LDR 	R4, [R9, #XGPIO_ISR_OFFSET]
  	TST 	R4, #XGPIO_IR_CH1_MASK		@ see if button interrupt occured.
  	BNE 	pressed

	//else it must have been a timer interrupt
	//LDR 	R12, [R11, #XTC_TCSR_OFFSET]   					@dont need this
	//TST 	R12, #XTC_CSR_INT_OCCURED_MASK @ see if timer interrupt occured.

	ldr r3, =XPAR_AXI_GPIO_BTNS_BASEADDR		;@ load base address of Switches into r3
	ldr r4, [r3, #XGPIO_DATA_OFFSET]

	cmp r4, #0

	ADDNE	R8, R8, #1				@increment only after we verify the button press
	BEQ	skipWrite

	str 	r8, [r10, #XGPIO_DATA_OFFSET]	;@ write count value to LED
	MOV 	R0, R8
	MOV 	R1, #3
	BL 	OLED_print_R0_on_row_R1		;@write count to OLED

skipWrite:
  	LDR  	R0, =XGPIO_IR_CH1_MASK	@enable button interrupts
	mov 	R12, r0

  	@clear the timer interrupt here.
  	LDR	R4, =Reload_timer_without_enable @ E254_TC_CSR_NEEDED_MASKS equated above in this file.	this shouldn't happen, i think we need a seperate mask. This mask restarts the timer I think
  	STR 	R4, [R11, #XTC_TCSR_OFFSET]

Exit1:
  	add	sp, sp, #autoSize	@ remove space for automatic variables
  	POP 	{r0-r4, lr}
	SUBS	PC, LR, #4
ENDFUNC	FIQHandler

pressed:
		STR 	R4, [R9, #XGPIO_ISR_OFFSET]	@ Clear the button interrupt here -- TOGGLES on write

  		MOV   	R12, #0      @disable button interrupts

  		@enable the countdown timer with an interrupt
		LDR 	R0, =E254_TC_CSR_NEEDED_MASKS @ E254_TC_CSR_NEEDED_MASKS equated above in this file.
		STR 	R0, [R11, #XTC_TCSR_OFFSET]


		add	sp, sp, #autoSize	@ remove space for automatic variables
  		POP 	{r0-r4, lr}
		SUBS	PC, LR, #4
