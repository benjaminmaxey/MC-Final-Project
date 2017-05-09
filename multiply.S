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
ldr r2, =#0x80000000
BIC r3, r0, r2
CMP r3, #0
moveq r0, #0
BEQ done
BIC r3, r1, r2
CMP r3, #0
moveq r0, #0
BEQ done

@@Read MSB(bit 32) of both values
ldr r4, =#0x80000000
AND r2, r0, r4	@clear everything except the MSB
AND r3, r1, r4	@1&&1 = 1, 0&&1 = 0
	@@XOR the MSB and store into Sr
	EOR r2, r2, r3 @r2 = Sr @0&&0 = 0, 1&&1 = 0, 1&&0 = 1; 0 = pos, 1 = neg

@@Read the next 8 bits[31:24] after the MSB for e – b for both
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
	@@Shift right such that the bottom 15 bits hold the leading 1 and the fraction (don't really care about precision)
    LSR r4, r4, #9
    LSR r5, r5, #9

	@@Multiply Ma and Mb and store in Mr
	mul r4, r4, r5 @Ma*Mb = r4 = Mr

    @@Check 30th bit (because n*m number results in n+m bits; if 30th bit has a 1, then increment exponent by 1)
	ldr r5, =#0x20000000
	AND r7, r4, r5
    @if r7 = 1 @30th bit, then +1 to Er, else do nothing
    CMP r7, #0x20000000
    ADDEQ r3, r3, #0x00800000

		@add 127 to Er
	ldr r5, =#0x3f800000
	ADD r3, r3, r5 @e+127; r3 = Er

    @@Shift Mr such that the leading 1 sits at the 24th bit
lsrMr: AND r5, r4, r6 @clear all bits except for 24th bit and higher
    CMP r5, #0x00800000 @is leading 1 > 24th bit?
    LSRGT r4, r4, #1 @shift right by 1 bit
    BGT lsrMr

    @@Clear leading 1
    BIC r4, r4, r5 @clear leading 1 of Mr

@@Combine sign Sr, the exponent Er, and significand Mr using OR
ORR r0, r2, r3 @include Sr and Er
ORR r0, r0, r4 @include Sr, Er, and Mr

done:

ldmfd sp!, {r4-r8, pc}
