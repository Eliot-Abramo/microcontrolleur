; file	i2cx_4.asm	   target ATmega128L-4MHz-STK300
; purpose I2C EEPROM address testing
; module: M5, output port: PORTB
.include "macros.asm"
.include "definitions.asm"

reset:	LDSP	RAMEND		; load stack pointer SP
	rcall	i2c_init	; initialize DDRx and PORTx
	rjmp	main
	
.include "i2cx.asm"

main:
	CA	i2c_start, 0b10100000	
	rcall	i2c_stop
	WAIT_US	10
		
	;CA	i2c_start, 0b10110000	
	;rcall	i2c_stop
	WAIT_MS	100
	rjmp	main