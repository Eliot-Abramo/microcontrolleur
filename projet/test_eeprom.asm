/*
 * test_eeprom.asm
 *
 *  Created: 08/05/2024 03:46:15
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

	;in	r16, SFIOR				; disable internal pull-up devices
	;ori	r16, (1<<PUD)
	;out	SFIOR, r16

	PRINTF LCD
	.db	CR,CR,"Sprinkler Sys"

    ; Initialize the I2C
    call    i2c_init

    clr     b0
    clr     b1
    clr     b2
    clr     b3

    rjmp    main

.include "i2cx.asm"

main:
    ; Write the values of the registers to the EEPROM
    ldi		address, 0x00		; Start at address 0x00
    ldi		i, 0

	ldi b0, 0x31
	ldi b1, 0x32
	ldi b2, 0x33
	ldi b3, 0x34

write_loop:
    ; Load the value of the next register
    cpi		i, 0
    breq	load_b0
    cpi		i, 1
    breq	load_b1
    cpi		i, 2
    breq	load_b2
    cpi		i, 3
    breq	load_b3

load_b0:
    mov		a0, b0
    rjmp	write_value
load_b1:
    mov		a0, b1
    rjmp	write_value
load_b2:
    mov		a0, b2
    rjmp	write_value
load_b3:
    mov		a0, b3

write_value:
    call	i2c_start			; Start the I2C communication
    call	i2c_write			; Write the value to the EEPROM
    call	i2c_stop			; Stop the I2C communication
    inc		address				; Increment the address
    inc		i					; Increment the counter
    cpi		i, 4				; Check if all values have been written
    brne	write_loop			; If not, continue the loop
    
    nop

read_loop:
    ldi     address, 0x00
    ; Prepare the address to read from
    mov		a0, address
    ; Start the I2C communication
    call	i2c_start
    /*
    The i2c_write call at line 203 is not used to write data to the EEPROM, but to set the address from which 
    the data will be read. In I2C communication, to read data from a specific memory address of an EEPROM, you 
    first need to write the address to the EEPROM. After that, you can read the data stored at that address.
    */
    call	i2c_write
    ; Read the value from the EEPROM
    call	i2c_read
    ; Store the value in the corresponding register
    cpi		i, 0
    breq	store_b0
    cpi		i, 1
    breq	store_b1
    cpi		i, 2
    breq	store_b2
    cpi		i, 3
    breq	store_b3

store_b0:
    mov		b0, a0
    rjmp	increment
store_b1:
    mov		b1, a0
    rjmp	increment
store_b2:
    mov		b2, a0
    rjmp	increment
store_b3:
    mov		b3, a0

increment:
    ; Stop the I2C communication
    call	i2c_stop
    ; Increment the address and counter
    inc		address
    inc		i
    ; Check if all values have been read
    cpi		i, 4
    brne	read_loop


    PRINTF LCD
	.db CR, LF, "Code in: ",b, FSTR
	.db  0

;     ; Compare the values with the other registers
;     cp		b0, c0
;     brne	main jump to main if wrong
;     cp		b1, c1
;     brne	main
;     cp		b2, c2
;     brne	main
;     cp		b3, c3
;     brne	main

;     ; If all values are the same, jump to the menu system
;     rjmp	menu_system

; menu_system:

    rjmp	main

