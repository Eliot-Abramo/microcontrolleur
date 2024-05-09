/*
 * test_eeprom.asm
 *
 *  Created: 08/05/2024 16:14:09
 *   Author: eliot
 */ 
.include "macros.asm"		
.include "definitions.asm"

.include "printf.asm"
.include "lcd.asm"

.def	address = r18
.def	i = r19

reset:
	LDSP	RAMEND				; set up stack pointer (SP)
	OUTI	DDRB,0xff			; configure portB to output
	OUTI	PORTB,0xff			; turn off LEDs
	
	in	r16, SFIOR				; disable internal pull-up devices
	ori	r16, (1<<PUD)
	out	SFIOR, r16
	rcall	i2c_init			; initialize I2C	
	
	rcall  LCD_init    ; initialize UART
	PRINTF LCD
	.db	CR,CR,"Sprinkler Sys"

    rjmp    main

.include "i2cx.asm"

 main:
    ; Write the values of the registers to the EEPROM
    ldi		address, 0x00		; Start at address 0x00
    ldi		i, 0

write_loop:
    ; Load the value of the next register
    mov		a0, b0
    call	write_value
    mov		a0, b1
    call	write_value
    mov		a0, b2
    call	write_value
    mov		a0, b3
    call	write_value

write_value:
    call	i2c_start			; Start the I2C communication
    call	i2c_write			; Write the value to the EEPROM
    call	i2c_stop			; Stop the I2C communication
    inc		address				; Increment the address
    ret

read_loop:
    ldi     address, 0x00
    ; Prepare the address to read from
    mov		a0, address
    call	read_value
    mov		b0, a0
    call	read_value
    mov		b1, a0
    call	read_value
    mov		b2, a0
    call	read_value
    mov		b3, a0

read_value:
    ; Start the I2C communication
    call	i2c_start
    call	i2c_write
    ; Read the value from the EEPROM
    call	i2c_read
    ; Stop the I2C communication
    call	i2c_stop
    ; Increment the address
    inc		address
    ret

print:
    PRINTF LCD
	.db CR, LF, "Code in: ",b, FSTR
	.db  0

	rjmp main