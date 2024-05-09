/*
 * test_eeprom.asm
 *
 *  Created: 08/05/2024 03:56:18
 *   Author: eliot
 */ 

.include "macros.asm"		
.include "definitions.asm"

.include "printf.asm"
.include "lcd.asm"

 ; === definitions ===
.equ  KPDD = DDRE
.equ  KPDO = PORTE
.equ  KPDI = PINE

.equ  KPD_DELAY = 30   ; msec, debouncing keys of keypad


reset:  LDSP  RAMEND    ; Load Stack Pointer (SP)
	rcall  LCD_init    ; initialize UART

	OUTI  KPDD,0x0f    ; bit0-3 pull-up and bits4-7 driven low
	OUTI  KPDO,0xf0    ;>(needs the two lines)
	OUTI  DDRB,0xff    ; turn on LEDs
	OUTI  EIMSK,0xf0    ; enable INT4-INT7
	OUTI  EICRB,0b00    ;>at low level

	PRINTF LCD
.db	CR,CR,"Sprinkler Sys"

	_LDI    b0, 0x23
	_LDI    b1, 0x23
	_LDI    b2, 0x23
	_LDI    b3, 0x23

	sei
	;jmp  main        ; not useful in this case, kept for modularity

main:
	PRINTF LCD
	.db CR, LF, "Code in: ",FSTR, b
	.db  0
	WAIT_MS 1000
    rjmp	main

