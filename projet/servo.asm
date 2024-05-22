; file	servo1.asm   target ATmega128L-4MHz-STK300
; purpose servo motor control from potentiometer
; module: M3, output port: PORTF
; module: M4, P7 servo Futaba S3003, output port: PORTB
.include "macros.asm"		; macro definitions
.include "definitions.asm"	; register/constant definitions

reset:
	LDSP	RAMEND			; set up stack pointer (SP)
	OUTI	DDRC,0xff		; configure portB to output
	rcall	LCD_init		; initialize the LCD
	

;	OUTI	ADCSR,(1<<ADEN)+6; AD Enable, PS=CK/64	
;	OUTI	ADMUX,POT		; select channel with potentiometer POT	
	jmp	main			; jump ahead to the main program
	
.include "lcd.asm"			; include the LCD routines
.include "printf.asm"		; include formatted print routines

/*
temp actuelle = temp0
Slow:
	wait 2000000, a0 = 0f, a1=e0

Medium
	wait 200, a0 = ff, a1=ef

Fast
	wat 200, a0=ff, a1=ff
*/

main:	
	WAIT_US	200
	ldi	a0,0xff				; read low byte first
	ldi	a1,0xff				; read high byte second
	ADDI2	a1,a0,100		; add an offset of 1000
	
	PRINTF	LCD				; print formatted
.db	"pulse=",FDEC2,a,"usec    ",CR,0
	
loop:
	SUBI2	a1,a0,0x1
	brne	loop
	rjmp	main			
