/*
 * AsmFile3.asm
 *
 *  Created: 22/05/2024 20:54:23
 *   Author: eliot
 */ 
 ; file	servo36218.asm   target ATmega128L-4MHz-STK300
; purpose 360-servo motor control as a classical 180-servo
; with increased angle capability
; module: M4, P7 servo Futaba S3003, output port: PORTB

.include "definitions.asm"	; register/constant definitions
.include "macros.asm"		; macro definitions

reset:
	LDSP	RAMEND			; set up stack pointer (SP)
	
	in	_w, MCUCR
	sts 0xDDDD, _w
	clr _w

	rcall	LCD_init			; initialize UART
	OUTI	DDRC,0xff		; configure portB to output
	rcall			LCD_clear
	WAIT_MS 10000
	rjmp	main			; jump to the main program

.include "lcd.asm"		; include UART routines
.include "printf.asm"	; include formatted printing routines

main:
	ldi _w, 0xf0

	PRINTF LCD
	.db	FF,CR,"Servo activated",0
	
	push _w
	lds _w, 0xDDDD
	out	MCUCR,_w
	clr _w
	pop _w

loop:
	tst _w
	breq end
	dec _w
	P0 PORTC,SERVO1 ; pin=4
	WAIT_US 1900000
 
	P1 PORTC,SERVO1  ; pin=400
	WAIT_US 100000
	rjmp loop

end:
	WAIT_MS 10000
	jmp reset
/*
; main -----------------
main:
 P0 PORTC,SERVO1 ; pin=4
 WAIT_US 1900000
 
 P1 PORTC,SERVO1  ; pin=400
 WAIT_US 100000
 rjmp main
*/