@Code for MC final project - floating point multiplication

	.text
.global multiply

@@Multiplies two numbers in single precision format
@@param(r0 = 1st number, r1 = 2nd number)
@@return(r0 = product in single precision format)

multiply:
stmfd sp!, {r4-r8, lr}

@@Check 0 case; if either of them are 0, then the result of the multiplication is 0
@clear out sign bit cause we don't care if it's pos 0 or neg 0
ldr r2, =#80000000
AND r3, r0, r2
CMP r3, #0
moveq r0, #0
BEQ done
AND r3, r1, r2
CMP r3, #0
moveq r0, #0
BEQ done

@@Read MSB(bit 32) of both values
ldr r4, =#0x80000000
AND r2, r0, r4	@clear everything except the MSB
AND r3, r1, r4	@1&&1 = 1, 0&&1 = 0
	@@XOR the MSB and store into Sr
	EOR r2, r2, r3 @r2 = Sr @0&&0 = 0, 1&&1 = 0, 1&&0 = 1; 0 = pos, 1 = neg

@@Read the next 8 bits[31:24] after the MSB for e – b for both; check for 0
ldr r5, =#0x807fffff
BIC r3, r0, r5	@bit clear everything except for e-b bits
BIC r4, r1, r5	@r3 = Ea, r4 = Eb

	@@SUB 127 from both for Ea and Eb
	ldr r5, =#0x3f800000
	SUB r3, r3, r5	@r3 = Ea
	SUB r4, r4, r5	@r4 = Eb
	@@ADD Ea and Eb and however many more places it takes to get to the leading 1, +127, then store into Er
	ADD r3, r3, r4 @r3 = Ea + Eb

@@Read the last 23 bits[23:0] of each (using BIC and then OR with a 1 in the 24th bit slot for the leading 1)
ldr r6, =#0xff800000 @f
ldr r7, =#0x00800000 @1.f
BIC r4, r0, r6 @clear [31:24] @r4 = Ma
ORR r4, r4, r7 @or with 1 @ [24]
BIC r5, r1, r6 @clear [31:24] @r5 = Mb
ORR r5, r5, r7 @or with 1 @ [24]
	@@Rotate right until the first 1 bit is at the bottom
	ldr r6, =#0x1 @get the first bit
rorMa:	AND r7, r4, r6 @get rid of everything in Ma besides the first bit
	CMP r7, r6 @is the first bit = 1?
	RORNE r4, r4, #1 @rotate right once
	BNE rorMa

rorMb:	AND r7, r5, r6 @get the first bit of Mb
	CMP r7, r6 @LSB = 1?
	RORNE r5, r5, #1 @rotate right once
	BNE rorMb

	@@Multiply Ma and Mb and store in Mr
	mul r4, r4, r5 @Ma*Mb = r4 = Mr

	@Shift Mr back to its place [24:0] (with hidden 1) b/c after the multiplication it's not in the single precision format'
	ldr r6, =#0x00800000 
lslMr:  AND r7, r4, r6 @is the hidden 1 in the 24th bit slot?
	CMP r7, r6 @are the bits equal
	LSLNE r4, r4, #1 @if not, shift left by 1
	BNE lslMr @keep shifting

mov r6, r1 @preserve second number m
stmfd sp!, {r2, r3} @preserve Sr and Er
	@@Find where the radix ends up after multiplication
		@find bit length of both numbers n and m (from leading 1 - trailing 1)
			@leading 1 @ bit 24
			@find trailing 1 of n using binary search(@param(r0 = number) @return(r0 = bit # of trailing 1))
			bl find_Trailing_1 @find trailing 1 of n; result: r0 holds bit # of trailing 1
			mov r7, #24
			SUB r7, r7, r0 @24-bit# = bit length of n

			mov r0, r6 @second number m
			bl find_Trailing_1 @find trailing 1 of m; result: r0 holds bit # of trailing 1
			mov r8, #24
			SUB r8, r8, r0 @24-bit# = bit length of m

		@add n+m-2 = r5 = new decimal place of Mr
		ADD r5, r7, r8 @n+m
		SUB r5, r5, #2 @n+m-2

	@@Calculate new Er
		@find trailing 1 of Mr using binary search(@param(r0 = number) @return(r0 = index of trailing 1)) and shift right (n+m-2)
		mov r0, r4
		bl find_Trailing_1  @find bit# of trailing 1

ldmfd sp!, {r2, r3} 
		@check if there's bit 2 bits away = 1 b/c 1.xxx*1.xxx will never be greater than 4(=2*2)
			@add bit# of trailing 1 and decimal place#
			ADD r5, r5, r0 @n+m-2 + bit#

			@shift right whole result up to that point
			LSR r6, r4, r5 @shift result by value held in r5 up to the "hidden 1" and put it into r6
			@shift right again to check if there's another value
			LSR r6, r6, #1 @/2
				@if = 1, then +1 to Er, else do nothing
				CMP r6, #1 
				ADDEQ r3, r3, #1 


		@add 127 to Er
	ldr r5, =#0x3f800000
	ADD r3, r3, r5 @e+127; r3 = Er

@@Combine sign Sr, the exponent Er, and significand Mr using OR
ldr r7, =#0x00800000 @1.f
BIC r4, r4, r7 @clear leading 1 of Mr
ORR r2, r2, r3 @include Sr and Er
ORR r2, r2, r4 @include Sr, Er, and Mr

done:

ldmfd sp!, {r4-r8, pc}
stop:	B stop
