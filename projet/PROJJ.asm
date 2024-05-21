/*
    EPFL - EE-208: Microcontrôleurs et Systèmes Numériques
    Semester Project - Spring Semester 2024

    Groupe 014:
    Eliot Abramo - SCIPER 355665
    Mathias Rainaldi - SCIPER 364154

    Project description:
	Sprinkler System
*/

.include "macros.asm"		; include macro definitions
.include "definitions.asm"  ; include register/constant definitions

; ====== macros ======
;	VERIFY_ENTER wr0,wr1,interm  ;check if BCD*# dont count,if A,verify code,otherwise ok
									;interm=0 ok, interm=1 verify code, interm=2 dont count

.macro VERIFY_ENTER
	; @2 = interm = intermediate register used to temporary store values
	; @1 = wr1 = column counter
	; @0 = wr0 = row counter

	;check if value entered not in column 3 (not letter)
	_CPI @1,0x03
	brne not_letter

	;check if 
	_CPI @0,0x01
	breq verif

	ldi @2,0x02
	rjmp fin

verif:	
	ldi @2,0x01
	rjmp fin
	
not_letter:
	;check if not last ligne
	_CPI @0,0x03
	brne okay

	;check if 0
	_CPI @1,0x01
	breq okay
	
	;
	ldi @2,0x02
	rjmp fin

okay:
	ldi @2,0x00

fin:
	nop
.endmacro

.macro CHECK_AND_SET
	; @5 = count = bit of code you want to change
	; @4 = interm = intermediate register used to temporary store values
	; @3 = a3 = fourth bit of code
	; @2 = a2 = third bit of code
	; @1 = a1 = second bit of code
	; @0 = a0 = first bit of code

    cpi		@5, 0x00				; compare a3 with 0x23 ('#' ASCII code)
    breq	set_a0					; if equal, branch to set_a0
    cpi		@5, 0x01				; compare a2 with 0x23
    breq	set_a1					; if equal, branch to set_a1
    cpi		@5, 0x02				; compare a1 with 0x23
    breq	set_a2					; if equal, branch to set_a2
    cpi		@5, 0x03				; compare a0 with 0x23
    breq	set_a3					; if equal, branch to set_a3

	set_a0:
		ldi		@5, 0x01
		mov		@0, @4				; set a3 to interm
		rjmp	end					; jump to end

	set_a1:
		ldi		@5, 0x02
		mov		@1, @4				; set a2 to interm
		rjmp	end					; jump to end

	set_a2:
		ldi		@5, 0x03
		mov		@2, @4			; set a1 to interm
		rjmp	end					; jump to end

	set_a3:
		ldi		@5, 0x00
		mov		@3, @4			; set a0 to interm

	end:
		nop
.endmacro

.macro DECODE_ASCII
	; @2 = interm = intermediate 'temporary' register used in calculations
	; @1 = wr1 = r1 = column = high bit
	; @0 = wr0 = r2 = row = low bit

	;point Z to ASCII table
	ldi    ZL, low(2*(KeySet01))
	ldi    ZH, high(2*(KeySet01))
	;move pointer to value pressed on keypad
	add    ZL, @0
	add    ZL, @0
	add    ZL, @0
	add    ZL, @0
	add    ZL, @1
	;load ASCII value to temporary register to be used later
	lpm		@2,Z

.endmacro

.macro ROW_MACRO
	; @4 = state = current state of system
	; @3 = mask for the row
	; @2 = wr0 = row counter
	; @1 = mask to extract correct row
	; @0 = row number on keypad (0->3)

	; check if in state_0, if not update the position on keypad
	_CPI		@4, 0x00
	brne		not_state_0
	WAIT_MS		500
	_LDI		@4, 0x01
	reti
	
not_state_0:
	_LDI		@2, @0
	_LDI		@3, @1

.endmacro

 .macro COLUMN_MACRO
	; @2 = column number (0->3)
	; @1 = next column subroutine address
	; @0 = column identification

 	WAIT_MS		KPD_DELAY
	OUTI		KPDO, @0
	WAIT_MS		KPD_DELAY
	in			w,KPDI
	and			w,mask
	tst			w
	brne		@1
	_LDI		wr1,@2

 .endmacro


; === definitions ===
.equ  KPDD = DDRE
.equ  KPDO = PORTE
.equ  KPDI = PINE

.equ  KPD_DELAY = 30				; msec, debouncing keys of keypad

.def	wr0 = r2					; detected row in hex
.def	wr1 = r1					; detected column in hex
.def	mask = r14					; row mask indicating which row has been detected in bin
.def	wr2 = r15					; semaphore: must enter LCD display routine, unary: 0 or other
.def	interm = r16				; intermediate register used in calculations
.def	state = r6					; store state of system, three states total
.def	temp0 = r8					; temperature0 (LSB)
.def	temp1 = r9					; temperature1 (MSB)
.def	chg = r26					; reload temperature
.def	count = r27					; to know at which character of code to change

.dseg
.org 0x0100
	temp_seuil: .byte 2
	code:		.byte 4

; === interrupt vector table ===
.cseg
.org 0
	jmp reset

.org 10
	jmp isr_ext_int0				; external interrupt INT4
	jmp isr_ext_int1				; external interrupt INT5
	jmp isr_ext_int2				; external interrupt INT6
	jmp isr_ext_int3				; external interrupt INT7

.org OVF0addr						; external interrupt for temperature sensor
	rjmp read_temp

.org OVF2addr						; timer overflow 2 interrupt vector
	rjmp overflow2

; === interrupt service routines ===
.org	0x30
isr_ext_int0: ; detect row 0
	ROW_MACRO		0x00, 0b00010000, wr0, mask, state
	rjmp			column_detect

isr_ext_int1: ; detect row 1
	ROW_MACRO		0x01, 0b00100000, wr0, mask, state
	rjmp			column_detect

isr_ext_int2: ; detect row 2
	ROW_MACRO		0x02, 0b01000000, wr0, mask, state
	rjmp			column_detect

isr_ext_int3: ; detect row 3
	ROW_MACRO		0x03, 0b10000000, wr0, mask, state
	rjmp			column_detect

column_detect:
	OUTI			KPDO,0xff	; bit4-7 driven high

col7: ; check column 7
	COLUMN_MACRO	0xf7, col6, 0x03
	rjmp			isr_return

col6: ; check column 6
	COLUMN_MACRO	0xfb, col5, 0x02
	rjmp			isr_return

col5: ; check column 5
	COLUMN_MACRO	0xfd, col4, 0x01
	rjmp			isr_return

col4: ; check column 4
	COLUMN_MACRO	0xfe, isr_return, 0x00
	rjmp			isr_return
  
isr_return:
	ldi				_w,10  ; sound feedback of key pressed acknowledge

beep01:   
	OUTI KPDO,		0xf0
	_LDI			wr2,0xff
	reti

read_temp: ; temperature sensor interrupt routine
	_CPI				state,0x00					; check if in first state
	breq				PC+2
	reti

	push				a0							; a0 might change, save on stack in case
	push				a1

	rcall				wire1_reset					; send a reset pulse
	CA					wire1_write, skipROM		; skip ROM identification
	CA					wire1_write, convertT		; initiate temp conversion
	WAIT_MS				750							; wait 750 msec

	rcall				lcd_home					; place cursor to home position
	rcall				wire1_reset					; send a reset pulse
	CA					wire1_write, skipROM	
	CA					wire1_write, readScratchpad	; send address to read value from sensor
	
	rcall				wire1_read					; read temperature LSB
	mov					temp0, a0					; save temperature LSB
	rcall				wire1_read					; read temperature MSB
	mov					temp1, a0					; save temperature MSB
	ldi					chg, 0xff					; indicate temperature has changed
	
	; now we compare with the temperature seuil
	ldi					xl, low(temp_seuil)
	ldi					xh, high(temp_seuil)
	ld					a0, x+
	ld					a1, x
	CP2					temp1,temp0,a1,a0

	pop					a1							; restore a1
	pop					a0							; restore a0
	brlo				PC+2
	_LDI				state, 0x02

	reti

overflow2 :
	INVP DDRD,SPEAKER
	reti	

; === include necessary libraries === 
.include "lcd.asm"		; include UART routines
.include "printf.asm"	; include formatted printing routines
.include "eeprom.asm"	; include internal EEPROM routines
.include "wire1.asm"	; include one-wire protocol routines
.include "encoder.asm"	; include encoder routines

; === initialization and configuration ===
.org 0x400

reset:  
	LDSP	RAMEND				; Load Stack Pointer (SP)

	;=== initialize the protocols ===
	rcall	LCD_init			; initialize UART
	rcall	wire1_init			; initialize 1-wire(R) interface
	rcall	encoder_init		; initialize encoder interface

	;=== configure output pins ===
	OUTI	DDRA,0xff			; configure portA to output
	OUTI	DDRD,0xff			; configure portD to output
	sbi		DDRD,SPEAKER		; set bit speaker is connected to 1

	;=== configure keypad pins ===
	OUTI	KPDD,0x0f			; bit0-3 pull-up and bits4-7 driven low
	OUTI	KPDO,0xf0			; >(needs the two lines)

	;=== configure interrupts ===
	OUTI	EIMSK,0xf0			; enable INT4-INT7
	OUTI	EICRB,0b00			; >at low level

	;=== configure timer ===
	OUTI	TIMSK,(1<<TOIE0)	; timer0 overflow interrupt enable
	OUTI	ASSR, (1<<AS0)		; clock from TOSC1 (external)
	OUTI	TCCR0,6				; CS0=1 CK
	OUTI	TCCR2,2				; prescaler for the buzzer
	
	;=== clear registers ===
	CLR8 count, wr0, wr1, wr2, chg, b1, b2, b3

	;=== set temperature limit ===
	_LDI a0,0xe0				; corresponds to 30 degree celcius
	_LDI a1,0x01
	ldi xl,low(temp_seuil)
	ldi xh,high(temp_seuil)
	st x,a0
	inc xl
	st x,a1

	;=== set initial code ===
	_LDI    a0, 0x31			
	_LDI    a1, 0x32
	_LDI    a2, 0x33
	_LDI    a3, 0x34
	ldi     xl,low(code)
	ldi     xh,high(code)
	st      x+,a0
	st      x+,a1
	st      x+,a2
	st      x,a3

	;=== set initial values ===
	PRINTF LCD					; display initial LCD message
	.db	FF,CR,"Sprinkler Sys",0

	_LDI    a0, 0x23			; sets the a registers to #
	_LDI    a1, 0x23			; for display purposes
	_LDI    a2, 0x23
	_LDI    a3, 0x23
	_LDI	state, 0x00			; set initial state to 0
	sei							; enable interrupt

; === main program ===
main:
	_CPI	state,0x00	; check if in state 0
	breq	state_0

	_CPI	state,0x01	; check if in state 1
	brne	PC+2
	rjmp	state_1

	_CPI	state,0x02	; check if in state 2
	brne	PC+2
	rjmp	alarm

	rjmp	main

; === sub-routines ===
state_0:
 	tst		chg			; check flag/semaphore
	breq	main		; if no change, back to main
	clr		chg
	mov		a0, temp0	; update temperature values
	mov		a1,	temp1
	
	PRINTF	LCD			; Update LCD display
	.db	LF,"Curr Temp=",FFRAC2+FSIGN,a,4,$22,"C ",0
	rjmp main

state_1:
	rcall			LCD_clear		; clear LCD
	clr				count
	PRINTF			LCD				; update LCD
	.db				FF,CR, "ENTER: ",0

	_LDI			a0, 0x23		; reset a values to # for display
	_LDI			a1, 0x23		; purposes
	_LDI			a2, 0x23
	_LDI			a3, 0x23

display_code:
	tst				wr2				; check flag/semaphore
	breq			display_code	; loop back till not 0
	clr				wr2

	VERIFY_ENTER	wr0,wr1,interm  ; check if BCD*# dont count,if A,verify code,otherwise ok
									; interm=0 ok, interm=1 verify code, interm=2 dont count
	cpi				interm, 0x01	
	brne			PC+2
	jmp				verify_code
	cpi				interm,0x02
	breq			display_code

	DECODE_ASCII	wr0, wr1, interm
	CHECK_AND_SET	a0, a1, a2, a3, interm, count

	PRINTF LCD
	.db LF, "Code in: ",FSTR, a,0
	

	rjmp display_code

alarm : 
	OUTI  TIMSK,(1<<TOIE2)
	rjmp state_1

stop_alarm :
	WAIT_MS 1000
	rcall LCD_clear
	PRINTF LCD
	.db	FF,CR,"Sprinkler Sys",0
	OUTI  TIMSK,(1<<TOIE0)
	_LDI state,0x00
	rjmp main

	
verify_code:
	rcall LCD_clear
	PRINTF LCD
	.db CR, CR, "verification...",0
	WAIT_MS 1000
	INVP DDRD,0x05

	push c0
	push c1
	push c2
	push c3
	ldi xl,low(code)
	ldi xh,high(code)
	ld c0,x+
	ld c1,x+
	ld c2,x+
	ld c3,x

	cp a0,c0
	breq PC+2
	rjmp wrong_code
	cp a1,c1
	breq PC+2
	rjmp wrong_code
	cp a2,c2
	breq PC+2
	rjmp wrong_code
	cp a3,c3
	breq PC+2
	rjmp wrong_code
	nop
	pop c3
	pop c2
	pop c1
	pop c0


correct_code:
	nop
	PRINTF LCD
	.db CR, LF, "Correct Code"
	.db  0
	_CPI state,0x02
	brne PC+2
	rjmp stop_alarm

	rjmp menu


wrong_code:
	pop c3
	pop c2
	pop c1
	pop c0
	PRINTF LCD
	.db LF, "Wrong code PD",0
	WAIT_MS 1000
	_CPI state,0x02
	brne PC+2
	rjmp state_1
	_LDI state,0x00
	rcall  LCD_clear
	PRINTF LCD
	.db	FF,CR,"Sprinkler Sys",0
	rjmp main

menu:
	WAIT_MS 1000
	rcall  LCD_clear
menu1:
	WAIT_MS 100
	PRINTF LCD
	.db	FF,CR,"A=CHANGE CODE",0
	nop
	PRINTF LCD
	.db	LF,"B=CHANGE TEMP   ",0
	tst    wr2        ; check flag/semaphore
	breq   menu1
	clr    wr2
	DECODE_ASCII wr0, wr1, interm
	cpi interm,0x41
	brne PC+2
	rjmp change_code
	cpi interm,0x42
	breq change_temp
	rjmp menu1

change_temp:
	ldi xl,low(temp_seuil)
	ldi xh,high(temp_seuil)
	ld a0,x+
	ld a1,x
	rcall	LCD_clear
	PRINTF	LCD
	.db	FF,CR,"Change temp:",0
change_temp1:					
	WAIT_MS	1
	rcall	encoder				; poll encoder
	PRINTF LCD
	.db	LF,"Temp=",FFRAC2+FSIGN,a,4,$32,"C ",0
	tst    wr2        ; check flag/semaphore
	breq   change_temp1
	clr    wr2
	DECODE_ASCII wr0, wr1, interm
	cpi interm,0x41
	breq set_new_temp
	rjmp	change_temp1

set_new_temp :
	ldi xl,low(temp_seuil)
	ldi xh,high(temp_seuil)
	st x+,a0
	st x,a1
	rcall  LCD_clear
	PRINTF LCD
	.db LF, "NEW TEMP SET",0
	_LDI state,0x00

	WAIT_MS 1000
	rcall  LCD_clear
	PRINTF LCD
	.db	FF,CR,"Sprinkler Sys",0
	rjmp main

change_code :
	rcall LCD_clear
	PRINTF	LCD
	.db	FF,CR,"WRITE NEW CODE:",0
	clr count
	ldi xl,low(code)
	ldi xh,high(code)
	ld a0,x+
	ld a1,x+
	ld a2,x+
	ld a3,x
change_code_1:
	WAIT_MS	1
	PRINTF LCD 
	.db LF, "NEW CODE:   ",FSTR, a,0
	tst    wr2        ; check flag/semaphore
	breq   change_code_1
	clr    wr2
	VERIFY_ENTER wr0,wr1,interm  ;check if BCD*# dont count,if A,verify code,otherwise ok
							;interm=0 ok, interm=1 set code, interm=2 dont count
	cpi interm,0x01	
	brne PC+2
	jmp set_new_code
	cpi interm,0x02
	brne PC+2
	rjmp change_code_1
	DECODE_ASCII wr0, wr1, interm
	CHECK_AND_SET a0, a1, a2, a3, interm, count
	rjmp change_code_1




set_new_code :
	ldi xl,low(code)
	ldi xh,high(code)
	st x+,a0
	st x+,a1
	st x+,a2
	st x,a3
	rcall  LCD_clear
	PRINTF LCD
	.db LF, "NEW CODE SET",0
	_LDI state,0x00

	WAIT_MS 1000
	rcall  LCD_clear
	PRINTF LCD
	.db	FF,CR,"Sprinkler Sys",0
	rjmp main


	



 ; === look up table ===
KeySet01:
	.db 0x31, 0x32, 0x33, 0x41 ; 1, 2, 3, A
	.db 0x34, 0x35, 0x36, 0x42 ; 4, 5, 6, B
	.db 0x37, 0x38, 0x39, 0x43 ; 7, 8, 9, C
	.db 0x2A, 0x30, 0x23, 0x44 ; *, 0, #, D