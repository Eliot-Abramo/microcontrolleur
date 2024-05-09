; file	eeprom1.asm   target ATmega128L-4MHz-STK300
; purpose internal EEPROM, demo

.include "macros.asm"		; macro definitions
.include "definitions.asm"	; register/constant definitions
.include "lcd.asm"      ; include UART routines
.include "printf.asm"    ; include formatted printing routines

reset:
	LDSP	RAMEND			; set up stack pointer (SP)
	rcall  LCD_init    ; initialize UART

	OUTI	DDRB,0xff		; configure portB to output
	OUTI  EIMSK,0xf0    ; enable INT4-INT7
	OUTI  EICRB,0b00    ;>at low level
	sei
	rjmp	main			; jump ahead to the main program

.include "eeprom.asm"		; eeprom access routines

main:
	_LDI	a0,0x0f				; read buttons
	ldi	xl, low(123)		; load EEPROM address
	ldi	xh,high(123)
	rcall	eeprom_store	; store byte to EEPROM
	
	clr	a0					; clear a0
	rcall	eeprom_load		; relaod a0 from EEPROM
;	out	PORTB,a0			; output to LEDs

	PRINTF LCD
	.db	CR,CR,"a0: ", a, FHEX

	WAIT_MS	100				; wait 100 msec
	rjmp	main			; jump back to main