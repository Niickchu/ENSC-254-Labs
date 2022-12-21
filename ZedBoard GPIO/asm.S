;@ Copyright (C) 2022 School of Engineering Science, SFU

#include "asm_include.h"
#include "../src/macros.i"
#include "../src/definitions.i"

;@ Student Name 1: Aleksandr Kopylov
;@ Student 1 301384850
;@ Student 1 userid (email): akopylov (stu1@sfu.ca)
;@
;@ Student Name 2: Nicholas Chu
;@ Student 2 #: 301440034
;@ Student 2 userid (email): nmc10 (stu2@sfu.ca)

;@  ;@ you can put any variables below these lines (once you uncomment next 2 lines)

.data
.align
Counter:
	.space 1

.text
.align		;@align the code to 4 bytes word boundary

;@ int main()
FUNCTION main	;@ macro FUNCTION defines a label for a subroutine and makes it global.
				;@	Use this macro for all subroutines in this environment.
	;@ Use r3 to hold the base address of the Switch GPIO ports
	;@ Use r1 to hold the base address of LED GPIO ports
	;@ Use r2 as scratch

	;@ Load base addresses for LED GPIO and Switch GPIO
	ldr r3, =XPAR_AXI_GPIO_BTNS_BASEADDR		;@ load base address of Switches into r0 -- ldr r0, [PC, #offset]
	ldr r1, =XPAR_AXI_GPIO_LEDS_BASEADDR	;@ load base address of LEDs into r1

	;@ The connections to the LEDs and switches are initially configured as inputs. This works well
	;@ for the switches but not so helpful for the LEDs.  Connections can be changed to outputs by
	;@ clearing their corresponding bits in the GPIO 'Tristate Register'. The
	;@ Tristate register is at an offset from the base address for GPIO ports.
	ldr r2, [r1, #XGPIO_TRI_OFFSET] ;@ Read the tristate register for the LEDs
	mvn r10, #255
	and r2,r2, r10	;@ Clear the first 8 tristate bits to enable the 8 LEDs as outputs
	str r2, [r1, #XGPIO_TRI_OFFSET]	;@ Write new value to LED tristate register to enable as outputs

	;@ *** Follow the lab document and complete the main program to read from
	;@ 		pushbutton switches and update a counter variable and LEDs ***

	;@ The Data Register is located directly at the base address of the GPIO ports
	;@ so by reading and writing the base address we can read from and write to the data register.
	;@ Still a (zero) offset has been defined for the Data Register.

	mov r4, #0
	ldr r5, =Counter

poll:	ldr r2, [r3, #XGPIO_DATA_OFFSET]	;@read switches

	;@and r2,r2,r6
	bic r2, #0x0C
	cmp r2, #0
	blne pressed


	str r4, [r1, #XGPIO_DATA_OFFSET]	;@write value to LED
	strb r4, [r5]

	b poll ;@ Loop endlessly polling buttons and setting LEDs

	mov r0, #0
	mov pc, lr  ;@ Return from function call

pressed:
	ldr r10, [r3, #XGPIO_DATA_OFFSET]
	;@and r10,r10,r6
	bic r10, #0x0C
	cmp r10, #0
	beq released

	bne pressed

released:
	cmp r2, #16	;@ Up
	addeq r4, r4, #1

	cmp r2, #2	;@ Down
	subeq r4,r4, #1

	cmp r2, #1	;@ Center
	moveq r4, #0

	mov pc, lr


ENDFUNC main	;@ macro ENDFUNC does some housekeeping for the end of a subroutine.
				;@	Use this macro at the end of all subroutines in this environment
