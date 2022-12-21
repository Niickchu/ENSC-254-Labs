@ Code for OLED display for ZedBoard for ENSC 254
@ For OLED controller designed for ENSC 254 at SFU
@ Copyright (C) 2022 School of Engineering Science, SFU

;@ Student Name 1: Aleksandr Kopylov
;@ Student 1 301384850
;@ Student 1 userid (email): akopylov (stu1@sfu.ca)
;@
;@ Student Name 2: Nicholas Chu
;@ Student 2 #: 301440034
;@ Student 2 userid (email): nmc10 (stu2@sfu.ca)


#include "asm_include.h"
#include "definitions.i"
#include "macros.i"

.section .rodata
r0Message: .asciz "ENSC 254 LAB 7"
r1Message: .asciz "maxSize: "
r2Message: .asciz "return: "
r3Message: .asciz "intr's: "

.section .data
.align
@Reserving space to use for the OLED
counter_str:
	 .space 16

.section .text

.equ 	OLED_char, XPAR_AXI_OLED_CONTROLLER_0_S_AXI_BASEADDR + OLED_CHAR_OFFSET @ 0x41240400

FUNC	OLED_clear
	LDR 	R0, =OLED_char
	MOV 	R2, #64
	MOV 	R3, #' '
loop_clear:
	STRB 	R3, [r0], #1
	SUB 	R2, #1
	CMP 	r2, #0
	BNE 	loop_clear

	mov	PC, LR
ENDFUNC OLED_clear

FUNC	OLED_setup
	ldr	r0, =OLED_char
	ldr	r1, =r0Message
OLED_print_r0_loop:
	ldrb	r2, [r1], #1
	cmp	r2, #0
	beq	OLED_print_r1_loop_init
	strb 	r2, [r0], #1		;@ store the character on OLED display buffer
	b 	OLED_print_r0_loop

OLED_print_r1_loop_init:
	ldr	r0, =OLED_char
	ldr	r1, =r1Message
	add	r0, r0, #16
OLED_print_r1_loop:
	ldrb	r2, [r1], #1
	cmp	r2, #0
	beq	OLED_print_r2_loop_init
	strb 	r2, [r0], #1		;@ store the character on OLED display buffer
	b 	OLED_print_r1_loop

OLED_print_r2_loop_init:
	ldr	r0, =OLED_char
	ldr	r1, =r2Message
	add	r0, r0, #32
OLED_print_r2_loop:
	ldrb	r2, [r1], #1
	cmp	r2, #0
	beq	OLED_print_r3_loop_init
	strb 	r2, [r0], #1		;@ store the character on OLED display buffer
	b 	OLED_print_r2_loop

OLED_print_r3_loop_init:
	ldr	r0, =OLED_char
	ldr	r1, =r3Message
	add	r0, r0, #48
OLED_print_r3_loop:
	ldrb	r2, [r1], #1
	cmp	r2, #0
	beq 	OLED_print_loop_stop
	strb 	r2, [r0], #1		;@ store the character on OLED display buffer
	b 	OLED_print_r3_loop
OLED_print_loop_stop:
	mov	PC, LR

ENDFUNC	OLED_setup


;@ subroutine to divide number in r0 by 10
FUNC 	div10
	;@ r0 should contain the dividend
	ldr	r1, =0xCCCCCCCD		;@ fix point binary representation of 1/10
	umull	r2, r1, r0, r1		;@ try umull r0, r1, r0, r1 to avoid using r2
	mov	r0, r1, LSR #3		;@ shifting the result of the multiplication by 32+3 bits
						;@ will give the division result
	mov	pc, lr
ENDFUNC	div10

;@ Sub routine to display an integer number on a specific row of the OLED screen
;@ the number displayed will be considered unsigned
;@ argument: 	r0 should contain the number to be display upon entering the sub routine
;@ 		r1 holds the row number on the OLED screen to be displayed

FUNC 	OLED_print_R0_on_row_R1
	push 	{r4-r10, lr}

	mov 	r5, r0			;@ use r5 to store the value to display
	mov 	r12, r1			;@ store specified row number in r12

	ldr 	r8, =counter_str	;@ use r8 as pointer to counter string
	mov 	r6, #0			;@ pad a NULL at the beginning
	strb 	r6, [r8], #1
div10_get_remainder_loop:
	mov 	r0, r5
	bl 	div10			;@ divide by 10
	mov 	r10, r0			;@ move division result from r0 to r10
	mov 	r6, #10
	umull 	r7, r6, r10, r6
	sub 	r9, r5, r7		;@ and get the remainder (this will be the least significant digit)
	add 	r9, r9, #'0'		;@ add the value to ascii equivalent of number 0 (0x30)
	strb 	r9, [r8], #1		;@ store the byte to counter string
	mov	r5, r10			;@ store division result back to r5
	cmp 	r10, #0			;@ if division result is not 0, repeat
	bne	div10_get_remainder_loop

	;@ display the counter string on OLED:
	ldr 	r4, =OLED_char
	add 	r6, r4, r12, LSL #4	;@ point r6 to the beginning of the specified row on OLED

find_empty_space:
	ldrb	r1, [r6], #1
	cmp	r1, #32		;@ check for space
	bne	find_empty_space

	sub 	r8, r8, #1
	;@ at this point r8 should point at the end of the string and also the most significant digit of the counter
print_counter_OLED_loop:
	ldrb 	r5, [r8], #-1		;@ load character from the string in backward direction
	cmp 	r5, #0			;@ stop when reaching NULL at the beginning of the counter string
	beq	print_counter_OLED_loop_stop
	strb 	r5, [r6], #1		;@ store character on OLED display buffer
	b 	print_counter_OLED_loop

print_counter_OLED_loop_stop:
	;@ clean up the remaining of the line with white space
	add 	r12, r12, #1		;@ Specify the end of the specified row (beginning of next row)
print_counter_OLED_clean:
	mov 	r5, #' '
	strb 	r5, [r6], #1
	sub 	r7, r6, r4		;@ get current position of r6 pointer on OLED buffer (r7 represent offset from base addr)

					;@ compare position on OLED buffer with
	cmp 	r7, r12, LSL #4		;@ the first character of the specified row + 1
					;@ (make sure its past the last character of the row)
	blt	print_counter_OLED_clean

	pop 	{r4-r10, pc}
ENDFUNC	OLED_print_R0_on_row_R1
