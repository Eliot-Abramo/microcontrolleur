.include "definitions.asm"
.include "macros.asm"

.equ initial_temp = 0x17 ; replace with actual value
.equ base_speed = 0x64 ; replace with actual value
.equ E = 0x64 ; replace with actual value

.dseg
temp: .byte 2
res: .byte 2
; high = msb = int
; low = lsb = decimal

; Variables
.def i = r26
.def factorial = r27
.def interm = r28
.def interm2 = r29
.def interm3 = r11


;speed=base_speed + (temp - initial_temp)k
;k = exp(-E/(R*temp)) = exp(-x)

; === initialization and configuration ===
.cseg
reset:  LDSP  RAMEND    ; Load Stack Pointer (SP)
	ldi r17, 0xb
	ldi r16, 0xc7
	; temp = 2851
	sts high(temp), r17
	sts low(temp), r16

	clr r16
	clr r17

	rjmp calculation_speed

.include "math.asm"


calculation_speed:
	lds zl, low(temp)
	lds zh, high(temp)

    ; Calculate k = exp(E/(R*temp)) = exp(x)

	;x = x/temperature
	;initial division
	ldi a0, 0x10
	ldi a1, 0x27 ;=10 000
	mov b0, zl
    mov b1, zh
	call div22
	mov r17, c0
	
	;scale remainder
	mov a0, d0
	mov a1, d1
	ldi b0, 0x64
	call mul21

	;second devision to find decimal part
	mov a0, c0
	mov a1, c1
	mov a2, c2
	mov b0, zl
	mov b1, zh
	call div32
	mov r16, c0

	;x = -x
	;neg r16
	;neg r17

	;update pointer
	mov zl, r16
	mov zh, r17
	clr r16
	clr r17

    ;result = exp(x)
	nop
	rcall exp_cal

    ; Calculate speed = base_speed + (temp - initial_temp)*k
	lds zl, low(temp)
	lds zh, high(temp)
	lds xl, low(res)
	lds xh, high(res)

	SUB2 zh,zl, xh,xl
    ;interm = initial_temp
	;ldi interm, initial_temp
	;ldi interm2, base_speed
    ;temperature = temperature - initial_temp
	;sub temperature, interm
	;temperature = temperature*k
	;mov a0, temperature
	;mov b0, result
	;call mul44
	;mov temperature, c0
	;temperature = temperature + base_speed
    ;add temperature, interm2

exp_cal:
    ldi r17, 0x01
	ldi i, 0x02
	ldi factorial, 0x02
	ADD2 r17, r16,	zh,zl
    ; Calculate e^x using Taylor series
	; 1 + x + x^2/2 + x^3/6
exp_loop:
    ; Calculate x^i
    clr interm3
	inc interm3
	push r17
	push r16
	rcall pow_loop

    ; Calculate interm = interm / factorial!
	pop r16
	pop r17
	;initial division
	mov a0, interm2
	mov b0, factorial
	call div11
	add r17, c0

	;second devision to find decimal part
	add interm, d0
	mov a0, interm
	mov b0, factorial
	call div11
	add r16, c0

	/*
	; Variables
.def i = r26
.def factorial = r27
.def interm = r28
.def interm2 = r29
.def interm3 = r11
	*/

    ;Update i and factorial
    inc i

	mov a0, factorial
	mov b0, i
	call mul44
	mov factorial, c0

    ; Repeat for 3 terms (3 because max value is ff = 256 and worst case 5^3 < 256 but not 5^4)
    cpi i, 4
    brne exp_loop
	sts high(res), r17
	sts low(res), r16
	ret

pow_loop:
	;mov interm, interm3
	mov a0, zl
	mov b0, zl
	call mul11

	mov a0, c0
	mov a1, c1
	ldi b0, 0x64
	call div21
	add interm, c0
	
	mov a0, zh
	mov b0, zh
	call mul11
	add interm2, c0

    inc interm3
	cp interm3, i ; compare i and interm3
    brlt pow_loop ; if i != interm2, repeat loop
	ret