/*
 * test_eeprom3.asm
 *
 *  Created: 08/05/2024 18:35:39
 *   Author: eliot
 */ 
.include "macros.asm"		
.include "definitions.asm"

.include "printf.asm"
.include "lcd.asm"

.def	address = r18
.def	i = r19

reset:
    ; Set up the stack pointer
    LDSP	RAMEND	

    rcall  LCD_init    ; initialize UART

    PRINTF LCD
    .db	CR,CR,"Sprinkler Sys"

    ; Initialize the I2C
    call    i2c_init

    clr     b0
    clr     b1
    clr     b2
    clr     b3

	clr zl
	clr zh

    rjmp    main

.include "i2cx.asm"

main:
    ; Write the values of the registers to the EEPROM
    ldi		address, 0x00		; Start at address 0x00
    ldi		i, 0

    ; Lookup table for register values
	ldi    ZL, low(2*(table))
	ldi    ZH, high(2*(table))

table:
    .dw     b0, b1, b2, b3

write_loop:
    ; Load the value of the next register
    lpm     a0, Z+
    call    write_value
    inc     i
    cpi     i, 4
    brne    write_loop

write_value:
    call	i2c_start			; Start the I2C communication
    call	i2c_write			; Write the value to the EEPROM
    call	i2c_stop			; Stop the I2C communication
    inc		address				; Increment the address
    ret

    ; Read the values of the registers from the EEPROM
    ldi		address, 0x00		; Start at address 0x00
    ldi		i, 0

read_loop:
    ; Load the address of the next register
    lpm     a0, Z+
    call    read_value
    inc     i
    cpi     i, 4
    brne    read_loop

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

	PRINTF LCD
	.db CR, LF, "Code in: ",b, FSTR
	.db  0

    rjmp	main
