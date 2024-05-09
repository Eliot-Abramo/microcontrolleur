/*
    EPFL - EE-208: Microcontrôleurs et Systèmes Numériques
    Semester Project - Spring Semester 2024

    Groupe 014:
    Eliot Abramo - SCIPER 355665
    Mathias Rainaldi - SCIPER 364154

    Project description:
	!!!! A l'aide !!!!
*/

.include "macros.asm"    ; include macro definitions
.include "definitions.asm"  ; include register/constant definitions

; ====== macros ======
.macro VERIFY_ENTER
	_CPI @1,0x03
	brne PC+6
	INVP DDRD, 0x02
	_CPI @0,0x00
	brne PC+3
	INVP DDRD, 0x03
	rjmp verify_code
	rjmp display_code
	_CPI @0,0x03
	brne PC+4
	_CPI @1,0x01
	breq PC+2
	rjmp display_code
	INVP DDRD, 0x04
	nop
.endmacro

.macro CHECK_AND_SET
    cpi		count, 0x00		; compare a3 with 0x23
    breq	set_a0			; if equal, branch to set_a3
    cpi		count, 0x01		; compare a2 with 0x23
    breq	set_a1			; if equal, branch to set_a2
    cpi		count, 0x02		; compare a1 with 0x23
    breq	set_a2			; if equal, branch to set_a1
    cpi		count, 0x03		; compare a0 with 0x23
    breq	set_a3			; if equal, branch to set_a0
    rjmp	set_a0     		; jump to end

	set_a0:
		ldi count,0x01
		mov		@0, interm		; set a3 to interm
		rjmp	end				; jump to end

	set_a1:
		ldi count,0x02
		mov		@1, interm		; set a2 to interm
		rjmp	end				; jump to end

	set_a2:
		ldi count,0x03
		mov		@2, interm		; set a1 to interm
		rjmp	end				; jump to end

	set_a3:
		ldi count,0x00
		mov		@3, interm		; set a0 to interm

	end:
		nop
.endmacro

.macro DECODE_ASCII
	; @1 = wr1 = r1 = column = high bit
	; @0 = wr0 = r2 = row = low bit
	clr    Zl
	clr    ZH
	;clr    @2

	;add    interm, @1
	;add    interm, @0

	ldi    ZL, low(2*(KeySet01))
	ldi    ZH, high(2*(KeySet01))
	add    ZL, wr0
	add    ZL, wr0
	add    ZL, wr0
	add    ZL, wr0
	add    ZL, wr1
	;lpm    @2, Z
	lpm interm,Z

.endmacro

.macro SET_BIT_1;reg,bit		;Change selected bit to 1
	push a0
	mov a0,@0
	FB1 a0,@1		
	mov @0,a0
	pop a0
	.endmacro


 ; === definitions ===
.equ  KPDD = DDRE
.equ  KPDO = PORTE
.equ  KPDI = PINE

.equ  KPD_DELAY = 30   ; msec, debouncing keys of keypad

.def  wr0 = r2         ; detected row in hex
.def  wr1 = r1         ; detected column in hex
.def  mask = r14       ; row mask indicating which row has been detected in bin
.def  wr2 = r15        ; semaphore: must enter LCD display routine, unary: 0 or other
.def interm = r16      ; intermediate register used in calculations
.def state = r6
.def temp0 = r8        ;temperature0
.def temp1= r9		   ;temperature1
.def chg= r26		   ;relaod temperature
.def count=r27		   ;for know at which character
; === interrupt vector table ===
.org 0
	jmp reset
.org 10
	jmp isr_ext_int0   ; external interrupt INT4
	jmp isr_ext_int1   ; external interrupt INT5
	jmp isr_ext_int2   ; external interrupt INT6
	jmp isr_ext_int3   ; external interrupt INT7
.org	OVF0addr
	INVP	PORTA,7				; timer check temp			
	rjmp read_temp



; === interrupt service routines ===
retour:		;if note mode put code
	WAIT_MS 300
	_LDI state,0x01
	reti
isr_ext_int0:
	_CPI state,0x00
	breq retour
	INVP  PORTA,0x00     ;;debug
	_LDI  wr0, 0x00    ; detect row 1
	_LDI  mask, 0b00010000
	rjmp  column_detect

isr_ext_int1:
	_CPI state,0x00
	breq retour
	INVP  PORTA,0x01
	_LDI  wr0, 0x01    ; detect row 2
	_LDI  mask, 0b00100000
	rjmp  column_detect

isr_ext_int2:
	_CPI state,0x00
	breq retour
	INVP  PORTA,0x02
	_LDI  wr0, 0x02    ; detect row 3
	_LDI  mask, 0b01000000
	rjmp  column_detect

isr_ext_int3:
	_CPI state,0x00
	breq retour
	INVP  PORTA,0x03
	_LDI  wr0, 0x03    ; detect row 4
	_LDI  mask, 0b10000000
	rjmp  column_detect

column_detect:
	OUTI  KPDO,0xff    ; bit4-7 driven high

col7:
	WAIT_MS  KPD_DELAY
	OUTI  KPDO,0xf7    ; check column 7
	WAIT_MS  KPD_DELAY
	in    w,KPDI
	and    w,mask
	tst    w
	brne  col6
	_LDI  wr1,0x03
	INVP  PORTA,7       ;;debug
	rjmp  isr_return
  
col6:
	WAIT_MS  KPD_DELAY
	OUTI  KPDO,0xfb     ; check column 6
	WAIT_MS  KPD_DELAY
	in    w,KPDI
	and    w,mask
	tst    w
	brne  col5
	_LDI  wr1,0x02
	INVP  PORTA,6       ;;debug
	rjmp  isr_return

col5:
	WAIT_MS  KPD_DELAY
	OUTI  KPDO,0xfd     ; check column 5
	WAIT_MS  KPD_DELAY
	in    w,KPDI
	and    w,mask
	tst    w
	brne  col4
	_LDI  wr1,0x01
	INVP  PORTA,5       ;;debug
	rjmp  isr_return

col4:
	WAIT_MS  KPD_DELAY
	OUTI  KPDO,0xfe     ; check column 4
	WAIT_MS  KPD_DELAY
	in    w,KPDI
	and    w,mask
	tst    w
	brne  err_row0
	_LDI  wr1,0x00
	INVP  PORTA,4       ;;debug
	rjmp  isr_return
  
  err_row0:      ; debug purpose and filter residual glitches    
  ;INVP  PORTB,0
  rjmp  isr_return

isr_return:
	;INVP  PORTB,0    ; visual feedback of key pressed acknowledge
	ldi    _w,10    ; sound feedback of key pressed acknowledge

beep01:   
	; TO BE COMPLETED AT THIS LOCATION
	OUTI KPDO, 0xf0
	_LDI  wr2,0xff
	reti

read_temp :
	push a0
	rcall	wire1_reset			; send a reset pulse
	CA	wire1_write, skipROM	; skip ROM identification
	CA	wire1_write, convertT	; initiate temp conversion
	WAIT_MS	750					; wait 750 msec
	
	rcall	lcd_home			; place cursor to home position
	rcall	wire1_reset			; send a reset pulse
	CA	wire1_write, skipROM
	CA	wire1_write, readScratchpad	
	rcall	wire1_read			; read temperature LSB
	mov	c0,a0
	rcall	wire1_read			; read temperature MSB
	mov	temp1,a0
	mov	temp0,c0
	ldi chg,0xff
	pop a0

	reti
 
.include "lcd.asm"      ; include UART routines
.include "printf.asm"    ; include formatted printing routines
.include "eeprom.asm"			;include internal EEPROM routines
.include "wire1.asm"
; === initialization and configuration ===
.org 0x400

reset:  LDSP  RAMEND    ; Load Stack Pointer (SP)
	rcall  LCD_init    ; initialize UART
	rcall	wire1_init			; initialize 1-wire(R) interface
	rcall	lcd_init			; initialize LCD
	OUTI  KPDD,0x0f    ; bit0-3 pull-up and bits4-7 driven low
	OUTI  KPDO,0xf0    ;>(needs the two lines)
	OUTI  DDRA,0xff    ; turn on LEDs
	OUTI  EIMSK,0xf0    ; enable INT4-INT7
	OUTI  EICRB,0b00    ;>at low level
	OUTI  TIMSK,(1<<TOIE0)	; timer0 overflow interrupt enable
	OUTI  ASSR, (1<<AS0)		; clock from TOSC1 (external)
	OUTI  TCCR0,6	; CS0=1 CK
	OUTI  DDRD,0xff			;led second visualiton
	PRINTF LCD
	.db	FF,CR,"Sprinkler Sys",0

	_LDI    a0, 0x23
	_LDI    a1, 0x23
	_LDI    a2, 0x23
	_LDI    a3, 0x23
	clr    count
	clr    wr0
	clr    wr1
	clr    wr2
	clr	chg
	clr    b1
	clr    b2
	clr    b3
	_LDI state,0x00
	sei
	jmp  main        ; not useful in this case, kept for modularity

  ; === main program ===
main:
	out DDRD,state
	_CPI state,0x00
	breq display_temp
	_CPI state,0x01
	breq temp
	rjmp main


 
 ; === sous routine ===
 display_temp:
 	tst    chg        ; check flag/semaphore
	breq   main
	clr    chg
	mov a0,temp0
	mov a1,temp1
	PRINTF	LCD
	.db	LF,"Curr Temp=",FFRAC2+FSIGN,a,4,$22,"C ",0
	rjmp main

temp:
	rcall LCD_clear
	PRINTF	LCD
	.db FF,CR, "ENTER: ",0
	_LDI    a0, 0x23
	_LDI    a1, 0x23
	_LDI    a2, 0x23
	_LDI    a3, 0x23
display_code:
	INVP DDRD, 0

	tst    wr2        ; check flag/semaphore
	breq   display_code
	clr    wr2
	VERIFY_ENTER wr0,wr1  ;check if BCD*# dont count,if A,verify code,otherwise ok
		
	DECODE_ASCII wr0, wr1, interm
	CHECK_AND_SET a0, a1, a2, a3

	PRINTF LCD
	.db CR, LF, "Code in: ",FSTR, a
	.db  0

	rjmp display_code
	
verify_code:
	nop
	_LDI state,0x00
	rjmp main

 ; === look up table ===
KeySet01:
	.db 0x31, 0x32, 0x33, 0x41 ; 1, 2, 3, A
	.db 0x34, 0x35, 0x36, 0x42 ; 4, 5, 6, B
	.db 0x37, 0x38, 0x39, 0x43 ; 7, 8, 9, C
	.db 0x2A, 0x30, 0x23, 0x44 ; *, 0, #, D
/*
 * AsmFile3.asm
 *
 *  Created: 08.05.2024 11:49:15
 *   Author: mathi
 */ 
