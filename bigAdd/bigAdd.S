;@============================================================================
;@
;@ Student Name 1: Aleksandr Kopylov
;@ Student 1 301384850
;@ Student 1 userid (email): akopylov (stu1@sfu.ca)
;@
;@ Student Name 2: Nicholas Chu
;@ Student 2 #: 301440034
;@ Student 2 userid (email): nmc10 (stu2@sfu.ca)
;@
;@ Below, edit to list any people who helped you with the code in this file,
;@      or put ‘none’ if nobody helped (the two of) you.
;@
;@ Helpers: none
;@
;@ Also, reference resources beyond the course textbooks and the course pages on Canvas
;@ that you used in making your submission.
;@
;@ Resources:  none
;@
;@% Instructions:
;@ * Put your name(s), student number(s), userid(s) in the above section.
;@ * Edit the "Helpers" line and "Resources" line.
;@ * Your group name should be "HW4_<userid1>_<userid2>" (eg. HW4_stu1_stu2)
;@ * Form groups as described at:  https://courses.cs.sfu.ca/docs/students
;@ * Submit your file to courses.cs.sfu.ca
;@
;@ Name        : bigAdd.S
;@ Description : bigAdd subroutine for Assignment -- 2022
;@============================================================================

;@ Tabs set for 8 characters in Edit > Configuration

	.text				;@ Store in ROM
	.global	bigAdd


bigAdd:				;@r0-r3 may be arguments, and can be overwritten. r0 and r1 may be return values								change this to r2 and move down
	push	{r4-r8, lr}	;@push lr since bigAdd calls a subroutine

	ldr	r3, [r0],#4	;@load first word of r0 into r3, shows how many more valid words in r0 array
	ldr	r4, [r1],#4	;@load first word of r1 into r4, shows how many more valid words in r1 array

	cmp 	r2,r3		;@r2-r3	- if valid words in r0 array > maxn0size (N flag set), return -1
	bmi	invalidInput

	cmp	r2,r4		;@r2-r4	- if valid words in r1 array > maxn0size (N flag set), return -1
	bmi	invalidInput

	mov	r12, #0x000000D3		;@ r12 = 0xD3, when moved into CPSR, this sets the status flags to 0
								;@ ^ used for init to init branching
	cmp 	r3,r4		;@compare sizes of valid words
	beq	eqLengthInit	;@branches if Z flag set, so sizes are equal
	bpl	r0LargerInit	;@branches if r0 array is longer
                        ;@ else continue to r1Larger
	.global	rndLoc

r1LargerInit:
	mov		r7,r4 		;@r7 holds larger size of r1 array, since its larger
	cmp 	r3,#0		;@if r1 is longer, check if r0 is empty
	beq		r0Zero
r1Larger:
    msr	CPSR,r12	

	ldr		r8, [r0]		;@Load r5 with next word in r0 array
	ldr		r6, [r1], #4		;@Load r6 with next word in r1 array

	adcs	r8, r8, r6
	str	r8, [r0],#4

	mrs	r12,CPSR
	sub	r4, r4, #1	;@r4 larger than r3, therefore r3 is the limit
	subs	r3, r3, #1	;@while r3 is positive, continue loop
	bgt	r1Larger	;@else continue to r0ZeroInit


r0Zero:
    msr	CPSR,r12

	ldr	r6, [r1], #4	;@Load r6 with next word in r1 array
	
	adcs	r8, r6, #0
	str	r8, [r0],#4	;@store r5 into r0 location and increment pointer to store next word in r0 array
	
	mrs	r12,CPSR
	subs	r4, r4, #1	;@Now r4 is the limit
	beq	return

	
	b	r0Zero

eqLengthInit:
	mov	r7,r3		;@ r7 holds larger size of r0 and r1 arrays, arbitrarily choose r3 since r3==r4
	cmp	r3,#0		;@if r0 and r1 have equal length, check if r0 is empty	
	moveq	r0,#0		;@if empty, put 0 in r0
	popeq	{r4-r8, pc}	;@return from bigAdd if empty
eqLength:	
    msr	CPSR, r12	;@r12 holds status flags or 0xd3

	ldr	r8, [r0]		;@Load r5 with next word in r0 array
	ldr	r6, [r1], #4		;@Load r6 with next word in r1 array

	adcs	r8, r8, r6
	str	r8, [r0],#4
	

	mrs  	r12, CPSR	;@r12 holds status flags from previous loop
	subs	r3, r3, #1	;@decrement r3 by 1, could also use r4 since r3==r4
	beq	return		;@if result is 0, we are done, return from counter

	b	eqLength

r0LargerInit:
	mov	r7,r3
	cmp	r4,#0		;@if r0 is longer, check if r1 is empty
	beq	r1Zero
r0Larger:		
	msr	CPSR,r12

	ldr	r8, [r0]		;@Load r5 with next word in r0 array
	ldr	r6, [r1], #4		;@Load r6 with next word in r1 array

	adcs	r8, r8, r6
	str	r8, [r0],#4

	mrs	r12,CPSR
	sub	r3, r3, #1	;@r3 larger than r4, therefore r4 is the limit
	subs	r4, r4, #1	;@when r4 is 0, branch again
	bgt	r0Larger

	
r1Zero:
    msr	CPSR,r12    ;@r12 may hold 0xD3 if branched from r0LargerInit, otherwise it will hold status flags from r0Larger
	ldr	r8, [r0]	;@Load r5 with next word in r0 array

	adcs	r8, r8, #0
	str	r8, [r0], #4	;@store r5 into r0 location and increment pointer
	
	mrs	r12,CPSR
	subs 	r3, r3, #1	;@Now r3 is the limit
	bgt     r1Zero

return:
	mov	r3, #1
	cmp 	r2,r7		;@r2 holds maxnosize, r7 holds largest input memory array size
	beq	returnEqual	;@if positive, r2 is atleast 1 larger, and overflow isn't possible, therefore r0=0 and maybe add 1 to end if carry bit set

returnLarger:
	msr	CPSR, r12
	addcs	r7,r7,#1	;@if there was carry set, then size = max size of either array + 1
	str	r7,[r5]		;@move r7 to element 0 of r0 array
	strcs	r3, [r0]	;@if there was carry set, then add r3=#1 to the last element in the r0 array
	mov	r0, #0
	pop	{r4-r8,pc}

returnEqual:
	msr	CPSR, r12
	str	r7,[r5]		;@move r7 to element 0 of r0 array
	
	movcc	r0, #0
	movcs	r0, #1
	pop	{r4-r8, pc}
	
	
invalidInput:
	mvn	r0,#0		;@if invalid entry, put -1 in r0
	cmp	r3,r4		;@check determine which is larger between r3 and r4, put that value in element 0 of r0 [r8]
	strmi	r4, [r5]	;@if r4 is larger, N flag is set, and store r4 into [r8]
	strpl	r3, [r5]	;@if r3 is larger, N flag not set, and store r3 into [r8]
	pop	{r4-r8, pc}	;@return from bigAdd if invalid

rndLoc:		;@ use location after program as so