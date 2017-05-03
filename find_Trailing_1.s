	.text
	.global find_Trailing_1

@@ Finds the trailing 1 of the value in r0
@@ Returns the bit number of trailing 1 in r0
@@ Returns 0 if the value in r0 is 0
find_Trailing_1:
	stmfd sp!,{lr}
	mov r1,#16			@ Width of bit mask
	mov r2,#0			@ Shift of bit mask 
loop:
	mov r3,#1			@ Create bit mask
	lsl r3,r3,r1		@ Example: r1 = 8, r2 = 16,
	sub r3,r3,#1		@          r3 = 0x00FF0000
	lsl r3,r3,r2

	tst r0,r3			@ If 1 is in range...
	addeq r2,r2,r1		@ Update shift
	cmp r0,r3			@ If 1 is on range when width = 1...
	addeq r2,r2,r1		@ Update shift
	lsr r1,r1,#1		@ Divide width in half

	cmp r1,#0			@ If width is 0, return
	bne loop
	mov r0,r2
	ldmfd sp!,{pc}