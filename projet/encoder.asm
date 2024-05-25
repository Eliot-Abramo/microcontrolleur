; file	encoder.asm   target ATmega128L-4MHz-STK300
; purpose library angular encoder operation

; === definitions ===
.equ	ENCOD	= PORTD

.dseg
enc_old:.byte	1
.cseg

; === macro ===
.macro add_volker2			;if button down, macro to increment the		
	add @0,a2				;fourth bit of the first byte while 
	brcc end2				;checking and avoid errors du to 
	inc @1					;overflow/carry
	ldi a3,0x01
end2 :
	nop
.endmacro

.macro add_volker			;if button up, macro to incrment on 
	inc @0					;two bytes while checking and avoid  
	cpi @0,0x00				;errors due to overflow/carry
	brne end1
	inc @1
	ldi a3,0x01
end1 :
	nop
.endmacro

.macro sub_volker2			;if button down, macro to decrement the
	push @0					;fourth bit of the first byte while
	push a2					;checking and avoid errors du to
	ldi a2,0xf0				;overflow/carry
	and @0,a2
	pop a2
	cpi @0,0x00
	pop @0
	breq mala
	subi @0,0x10
	jmp end3
mala:
	subi @1,0x01
	subi @0,0x10
end3 :
	nop
.endmacro


.macro sub_volker			;if button up, macro to decrement on 
	cpi @0,0x00				;two bytes while checking and avoid
	breq mala				;errors due to overflow/carry
	subi @0,1
	jmp end
mala:
	subi @1,1
	subi @0,1
end :
	nop
.endmacro 
; === routines ===

encoder_init:
	in	w,ENCOD-1		; make 3 lines input
	andi	w,0b10001111
	out	ENCOD-1,w
	in	w,ENCOD			; enable 3 internal pull-ups
	ori	w,0b01110000
	out	ENCOD,w
	ret

encoder:
; a0,b0	if button=up   then increment/decrement a0	 
; a0,b0	if button=down then incremnt/decrement b0 
; T 	T=1 button press (transition up-down)
; Z	Z=1 button down change
	clr a3
	ldi a2,0x10
	clt						; preclear T
	in	_w,ENCOD-2			; read encoder port (_w=new)
	
	andi	_w,0b01110000	; mask encoder lines (A,B,I)
	lds	_u,enc_old			; load prevous value (_u=old)
	cp	_w,_u				; compare new<>old ?
	brne	PC+3
	clz
	ret						; if new=old then return (Z=0)
	sts	enc_old,_w			; store encoder value for next time

	eor	_u,_w				; exclusive or detects transitions
	clz						; clear Z flag
	sbrc	_u,ENCOD_I
	rjmp	encoder_button	; transition on I (button)
	sbrs	_u,ENCOD_A
	ret						; return (no transition on I or A)	

	sbrs	_w,ENCOD_I		; is the button up or down ?
	rjmp	i_down
i_up:	
	sbrc	_w,ENCOD_A
	rjmp	a_rise
a_fall:
	add_volker a0,a1					; if B=1 then increment
	sbrc	_w,ENCOD_B
	rjmp i_up_done
	subi	a0,1
	sub_volker a0,a1			; if B=0 then decrement
	cpi a3,0x00
	breq PC+2
	subi a1,1
	rjmp	i_up_done
a_rise:
	add_volker a0,a1					; if B=0 then increment
	sbrs	_w,ENCOD_B
	rjmp i_up_done
	subi	a0,1
	sub_volker a0,a1	
	cpi a3,0x00
	breq PC+2
	subi a1,1		; if B=1 then decrement
i_up_done:
	clz						; clear Z
	ret

i_down:	
	sbrc	_w,ENCOD_A
	rjmp	a_rise2
a_fall2:
	add_volker2 a0,a1					; if B=1 then increment
	sbrc	_w,ENCOD_B
	rjmp i_up_done
	subi	a0,0x10
	sub_volker2 a0,a1			; if B=0 then decrement
	cpi a3,0x00
	breq PC+2
	subi a1,0x01
	rjmp	i_up_done
a_rise2:
	add_volker2 a0,a1					; if B=0 then increment
	sbrs	_w,ENCOD_B
	rjmp i_up_done
	subi	a0,0x10
	sub_volker2 a0,a1	
	cpi a3,0x00
	breq PC+2
	subi a1,0x01
i_down_done:
	sez						; set Z
	ret

encoder_button:
	sbrc	_w,ENCOD_I
	rjmp	i_rise
i_fall:
	set						; set T=1 to indicate button press
	ret
i_rise:
	ret

.macro	CYCLIC	;reg,lo,hi
	cpi	@0,@1-1
	brne	PC+2
	ldi	@0,@2
	cpi	@0,@2+1
	brne	PC+2
	ldi	@0,@1
.endmacro
	