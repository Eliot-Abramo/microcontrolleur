 /*
    EPFL - EE-208: Microcontroleurs et Systemes Numeriques
    Semester Project - Spring Semester 2024

    Groupe 014:
    Eliot Abramo - SCIPER 355665
    Mathias Rainaldi - SCIPER 364154

	Custom written math library to calculate the coefficient of Arrhenius 
	on a 2-byte floating decimal system.

	k = exp(E/(R*temp)) = exp(x)
*/

start_math:
	; save current state of system in order to restore it after
	in		_sreg, SREG
	push	_sreg
	push	zh
	push	zl
	push	yh
	push	yl
	push	xh
	push	xl
	push	_w
	push	w
	push	d3
	push	d2
	push	d1
	push	d0
	push	c3
	push	c2
	push	c1
	push	c0
	push	b3
	push	b2
	push	b1
	push	b0
	push	a3
	push	a2
	push	a1
	push	a0

calculation_speed:
	lds		xl, high(exp_result)			; load value of exponential from memory into x pointer
	lds		xh, low(exp_result)
	lds		zl, temp_LSB					; load threshold temperature from memory into z pointer
	lds		zh, temp_MSB
    ; Calculate k = exp(E/(R*temp)) = exp(x)

	;x = x/temperature
	;initial division
	ldi		a0, 0x10
	ldi		a1, 0x27
	mov		b0, zl
    mov		b1, zh
	call	div22
	mov		r17, c0
	
	;scale remainder to adapt floating decimal
	mov		a0, d0
	mov		a1, d1
	ldi		b0, 0x64
	call	mul21

	;second division to calculate decimal part
	mov		a0, c0
	mov		a1, c1
	mov		a2, c2
	mov		b0, zl
	mov		b1, zh
	call	div32
	mov		r16, c0

	;update pointer
	mov		zl, r16
	mov		zh, r17
	clr		r16
	clr		r17

;result = exp(x)
exp_cal:
	; initialize all of the counters and placeholder values needed 
    ldi		r17, 0x01
	ldi		r26, 0x02
	ldi		r27, 0x02
	ADD2	r17, r16,	zh,zl

    ; Calculate e^x using Taylor series
	; 1 + x + x^2/2 + x^3/6
exp_loop:
    ; Calculate x^i
    clr		r11
	inc		r11
	push	r17
	push	r16
	rcall	pow_loop

    ; Calculate x/i! = r28/r27
	pop		r16
	pop		r17

	;initial division
	mov		a0, r29
	mov		b0, r27
	call	div11
	add		r17, c0

	;second devision to adapt data in order to find decimal part
	add		r28, d0
	mov		a0, r28
	mov		b0, r27
	call	div11
	add		r16, c0

    ;Update i and factorial
    inc		r26

	mov		a0, r27
	mov		b0, r26
	call	mul44
	mov		r27, c0

    ; Repeat for 3 terms (3 because max value is ff = 256 and worst case 5^3 < 256 but not 5^4)
    cpi		r26, 4
    brne	exp_loop
	sts		high(exp_result), r17		; write results to memory to ensure accessible later
	sts		low(exp_result), r16

end_math:
	; restore system state
	pop		a0
	pop		a1
	pop		a2
	pop		a3
	pop		b0
	pop		b1
	pop		b2
	pop		b3
	pop		c0
	pop		c1
	pop		c2
	pop		c3
	pop		d0
	pop		d1
	pop		d2
	pop		d3
	pop		w
	pop		_w
	pop		xl
	pop		xh
	pop		yl
	pop		yh
	pop		zl
	pop		zh
	pop		_sreg
	out		SREG, _sreg
	ret		; return to where math functions called in main program
	
;=======================
; ==== sub-routines ====
;=======================

pow_loop:
	; calculate x^i
	mov		a0, zl
	mov		b0, zl
	call	mul11

	mov		a0, c0
	mov		a1, c1
	ldi		b0, 0x64
	call	div21
	add		r28, c0
	
	mov		a0, zh
	mov		b0, zh
	call	mul11
	add		r29, c0

    inc		r11
	cp		r11, r26 ; compare i and r11
    brlt	pow_loop ; if i != interm2, repeat loop
	ret
