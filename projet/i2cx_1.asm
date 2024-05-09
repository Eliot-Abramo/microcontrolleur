; file	i2cx_1.asm 	   target ATmega128L-4MHz-STK300
; purpose observe I2C signals using oscilloscope
; module: M5, output port: PORTB
.include "macros.asm"
.include "definitions.asm"

reset:	rjmp	main	
.include "i2cx.asm"

main:	SCL0		; serial clock = 0
	SDA0		; serial data  = 0
	SCL1		; serial clock = 1
	SDA1		; serial data  = 1
	rjmp	main