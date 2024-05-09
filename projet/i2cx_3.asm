; file	i2cx_3.asm 	  target ATmega128L-4MHz-STK300
; purpose I2C start condition test
; module: M5, output port: PORTB, PORTC
; misc: flexible cable from LEDs to PORTC
.include "macros.asm"
.include "definitions.asm"

reset:	LDSP	RAMEND		; load stack pointer SP
	rcall	i2c_init	; initialize DDRx and PORTx
	sbi	DDRC,0x07	; activate LED PB7
	rjmp	main
	
.include "i2cx.asm"

main:	ldi	a0,0x5a		; load the parameter
	rcall	i2c_start	; send byte
	WAIT_MS	1
	
	bld	r0,7
	tst	r0
	brne	PC+2
	sbi	PORTC,0x07
	rjmp	main