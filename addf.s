	.text
	.global addf
addf:
	stmfd sp!,{r4-r8,lr}

	@@ Extract fraction parts from r0 and r1
	ldr r7,=0xFF800000
	bic r3,r1,r7
	bic r2,r0,r7
	orr r2,r2,#(1<<23)
	orr r3,r3,#(1<<23)
	lsl r2,r2,#6
	lsl r3,r3,#6

	@@ Extract exponent parts from r0 and r1
	ldr r4,=0x807FFFFF
	bic r5,r1,r4
	lsr r5,r5,#23
	bic r4,r0,r4
	lsr r4,r4,#23

	@@ Get difference of exponents
	sub r6,r4,r5
	cmp r6,#0
	rsblt r6,r6,#0

	@@ If negative, swap r0,r1 and r2,r3 and r4,r5
	movlt r8,r0
	movlt r0,r1
	movlt r1,r8
	movlt r8,r2
	movlt r2,r3
	movlt r3,r8
	movlt r8,r4
	movlt r4,r5
	movlt r5,r8

	@@ Shift r3 right by the difference of exponents
	lsr r3,r3,r6
	mov r6,#0

	@@ Make r3 negative if the signs of r0 and r1 differ
	eors r8,r0,r1
	lsr r8,r8,#29
	bic r8,r8,#3
	rsbmi r3,r3,#0
	bicmi r3,r3,#(1<<31)

	@@ Add r2 and r3
	adds r2,r2,r3

	@@ If sum is negative, take 2's complement
	lsr r5,r2,#30
	orr r8,r5,r8
	teq r8,#5
	rsbeq r2,r2,#0

	@@ If r0 and r1 were of the same sign and there was carry out
	@@ right shift the carry back in
	teq r8,#1
	addeq r6,r6,#1
	lsreq r2,r2,#1

	@@ Else find leading one and shift left until it's the MSB
	bicne r2,r2,#(3<<30)
	blne get_left_shifts
	teq r8,#1
	lslne r2,r2,r6
	rsbne r6,r6,#0

	@@ Adjust exponent
	add r4,r4,r6
	lsl r4,r4,#23

	@@ Adjust fraction
	lsr r2,r2,#6
	bic r2,r2,r7

	@@ Assemble answer
	and r0,r0,#(1<<31)
	orr r0,r0,r2
	orr r0,r0,r4

	@@ Return r0
	ldmfd sp!,{r4-r8,pc}

@@ Takes value in r2, returns number of left shifts required to shift
@@ leading 1 into bit 30
get_left_shifts:
	stmfd sp!,{r0,r1,r3,lr}
	mov r1,#16
	mov r0,#16
loop:
	mov r3,#1
	lsl r3,r3,r1
	sub r3,r3,#1
	lsl r3,r3,r0

	tst r2,r3
	lsr r1,r1,#1
	subeq r0,r0,r1
	addne r0,r0,r1

	cmp r1,#0
	bne loop
	tst r2,r3
	addne r0,r0,#1
	rsb r6,r0,#30
	ldmfd sp!,{r0,r1,r3,pc}