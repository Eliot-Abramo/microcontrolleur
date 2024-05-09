.include "definitions.asm"
.include "macros.asm"

.equ initial_temp = 0x17 ; replace with actual value
.equ base_speed = 0x64 ; replace with actual value
.equ E = 0x64 ; replace with actual value

; Variables
.def temperature = r12
.def result = r19
.def i = r20
.def factorial = r21
.def interm = r23
.def interm2 = r24
.def interm3 = r25
.def x_val = r4
;speed=base_speed + (temp - initial_temp)k
;k = exp(-E/(R*temp)) = exp(-x)

; === initialization and configuration ===
reset:  LDSP  RAMEND    ; Load Stack Pointer (SP)
	clr interm
	clr interm2
	clr interm3
	rjmp calculation_speed

.include "math.asm"

calculation_speed:
    _LDI temperature, 0x1E ; replace with actual temperature

    ; Calculate k = exp(E/(R*temp)) = exp(x)
    _LDI x_val, E
	;temperature = R*temperature
;	ldi interm, R
;	mov a0, temperature
;	mov b0, interm
;	call mul44
;	mov temperature, c0
;	mul temperature, interm
	;x = x/temperature
	mov a0, x_val
    mov b0, temperature
    call div11
    mov x_val, c0	
	;x = -x
;    neg x_val
    ;result = exp(x)
	nop
	nop
	rcall exp_cal

	clr interm
	clr interm2
	clr interm3

    ; Calculate speed = base_speed + (temp - initial_temp)*k
    ;interm = initial_temp
	ldi interm, initial_temp
	ldi interm2, base_speed
    ;temperature = temperature - initial_temp
	sub temperature, interm
	;temperature = temperature*k
	mov a0, temperature
	mov b0, result
	call mul44
	mov temperature, c0
	;temperature = temperature + base_speed
    add temperature, interm2

exp_cal:
    ldi result, 0x01
	ldi i, 0x02
	ldi factorial, 0x02

	add result, x_val
    ; Calculate e^x using Taylor series
	; 1 + x + x^2/2 + x^3/6 + x^4/24
exp_loop:
    ; Calculate x^i
	mov interm, x_val
	mov interm2, x_val
    clr interm3
	rcall pow_loop

    ; Calculate interm = interm / factorial!
	mov a0, interm
	mov b0, factorial
	call div11
    ;mov interm3, c0
    ; result = result + interm3
    add result, c0
    ; Update i and factorial
    inc i

	mov a0, factorial
	mov b0, i
	call mul44
	mov factorial, c0
;    mul factorial, i
    ; Repeat for 4 terms
    cpi i, 4
    brne exp_loop
	ret

pow_loop:
	;mov interm, interm3

	mov a0, interm
	mov b0, interm2
	call mul44
	mov interm, c0
;	mul interm3, interm

    inc interm3
	inc interm3
    cp interm3, i ; compare i and interm2
    brlt pow_loop ; if i != interm2, repeat loop
	ret