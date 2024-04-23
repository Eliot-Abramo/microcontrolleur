/*
    EPFL - EE-208: Microcontrôleurs et Systèmes Numériques
    Semester Project - Spring Semester 2023

    Groupe 022:
    Alexandre Moy - SCIPER 345712
    Loriane Schafer - SCIPER 346561

    Project description:
    Security IR system with passcode
*/

.include "definitions.asm"
.include "macros.asm"

.macro SET_BIT_1;reg,bit		;Change selected bit to 1
	push a0
	mov a0,@0
	FB1 a0,@1		
	mov @0,a0
	pop a0
	.endmacro

.macro SET_BIT_0;reg,bit		;Change selected bit to 0
	push a0
	mov a0,@0
	FB0 a0,@1
	mov @0,a0
	pop a0
	.endmacro

.macro PULSE_TEST				;Impulse test to debug IR command
	push a0
	ldi a0, 0xff
	WAIT_US @0
	ldi a0, 0x00
	WAIT_US @0
	pop a0
	WAIT_US 30000
	.endmacro

;=== Interrupt table ===
.org 0
	jmp reset
.org INT0addr					;interrup INT0
    jmp ext_int0
.org INT7addr					;interrup INT7
	jmp ext_int7
.org OVF0addr
	jmp overflow_0

;=== Interrupt service routines ===
ext_int0:						;subroutine for IR sensor
	JB0		r6,1,exit_inter
	SET_BIT_1 r6,0	
	reti

exit_inter:						;exit interruption
	reti

ext_int7:						;subroutine for IR command
read_IR_input:
	CLR2		b1,b0			; clear 2-byte register
	ldi			b2,14			; load bit-counter
	WP1			PINE,IR			; Wait if Pin=1 	
	WAIT_US		(T1/4)			; wait a quarter period
	
loop_ir:	P2C		PINE,IR		; move Pin to Carry (P2C)
	ROL2		b1,b0			; roll carry into 2-byte reg
	WAIT_US		(T1-4)			; wait bit period (- compensation)	
	DJNZ		b2,loop_ir		; Decrement and Jump if Not Zero
	com		b0					; complement b0

	brtc	PC+4				;branch if T=0
	sbrc	b1,3				;skip if T=1 and toggle=0
	reti						;out of interrupt if T=1 and toggle=1
	rjmp	PC+3				;continue program if T=1 and toggle=0
	sbrs	b1,3				;continue program if T=0 and toggle=1
	reti						;out of interrupt if T=0 and toggle=0

	bst		b1,3				;store toggle bit in T 

	;PULSE_TEST 10000

	JB1		r6,7,change_code	;branch to the change passcode routine if bit 7 of r6 is 1

	JB1		r6,1,PC+3			;check if the AV button is pressed when the system is inactive
	cpi		b0,0xc7
	breq	change_code_activation

	JB1		r6,2,check_code		;skip actions buttons for passcode validation

	cpi		b0,0xef				;check if "system on" button pressed
	breq	activate_system

	cpi		b0,0xf3				;check if "code unlock" button pressed
	breq	code_unlock

	reti
overflow_0:
	JB0		r6,0,exit_inter
    com		r7		;make sound if system is active and a motion is detected

	reti
;=== Buttons actions ===
put_alarm_off:
	SET_BIT_0	r6,0			;set the alarm bit to 0
	reti
desactivate_system:
	SET_BIT_0	r6,1			;set the system bit to 0
	reti
activate_system:
	SET_BIT_1	r6,1			;set the system bit to 1
	reti
code_unlock:
	SET_BIT_1	r6,2			;set the code unlock bit to 1
	reti
change_code_activation:
	SET_BIT_1	r6,7			;set the change passcode bit to 1
	reti

;=== Passcode verification ===
check_code:
	JB0		r6,6,code1_check	;jump to subroutine for first digit test
	JB0		r6,5,code2_check	;jump to subroutine for second digit test
	JB0		r6,4,code3_check	;jump to subroutine for third digit test
	reti
code1_check:
	SET_BIT_1	r6,6
	push a0						;search in EEPROM the first passcode digit
	ldi xl, low(code1_adress)
	ldi xh, high(code1_adress)
	rcall eeprom_load
	cp			b0, a0			;check good code 
	pop a0
	brne		wrong_code
	reti
code2_check:
	SET_BIT_1	r6,5
	push a0						;search in EEPROM the second passcode digit
	ldi xl, low(code2_adress)
	ldi xh, high(code2_adress)
	rcall eeprom_load
	cp			b0, a0			;check good code 
	pop a0
	brne		wrong_code
	reti
code3_check:
	SET_BIT_1	r6,4
	push a0						;search in EEPROM the third passcode digit
	ldi xl, low(code3_adress)
	ldi xh, high(code3_adress)
	rcall eeprom_load
	cp			b0, a0			;check good code 
	pop a0
	brne		wrong_code
	reti
wrong_code:
	SET_BIT_1	r6,3			;set the wrong code bit to 1 if wrong passcode detected
	reti

;=== Change the passcode in the EEPROM ===
change_code:
	JB0			r6,6,code1_change;jump to the subroutine for store first digit in EEPROM
	JB0			r6,5,code2_change;jump to the subroutine for store second digit in EEPROM
	JB0			r6,4,code3_change;jump to the subroutine for store third digit in EEPROM
	reti
code1_change:
	SET_BIT_1	r6,6
	cli
	push		a0				;store selected value in the selected adress in the EEPROM
	mov			a0,b0
	ldi			xl, low(code1_adress)
	ldi			xh, high(code1_adress)
	rcall		eeprom_store
	pop			a0
	sei
	reti
code2_change:
	SET_BIT_1	r6,5
	cli
	push		a0				;store selected value in the selected adress in the EEPROM
	mov			a0,b0
	ldi			xl, low(code2_adress)
	ldi			xh, high(code2_adress)
	rcall		eeprom_store
	pop			a0
	sei
	reti
code3_change:
	SET_BIT_1	r6,4
	cli
	push		a0				;store selected value in the selected adress in the EEPROM
	mov			a0,b0
	ldi			xl, low(code3_adress)
	ldi			xh, high(code3_adress)
	rcall		eeprom_store
	pop			a0
	sei

	WAIT_MS 500

	SET_BIT_0 r6,7				;reset all leds indicators when passcode changed
	SET_BIT_0 r6,6
	SET_BIT_0 r6,5
	SET_BIT_0 r6,4

	reti

;=== Set global constants ===
.equ T1 = 1778
.equ code1 = 0xfe				;first code digit
.equ code2 = 0xfd				;second code digit
.equ code3 = 0xfc				;third code digit

.equ code1_adress = 123			;first EEPROM adress for passcode
.equ code2_adress = 124			;second EEPROM adress for passcode
.equ code3_adress = 125			;third EEPROM adress for passcode

;=== Reset ===
reset :
	LDSP	RAMEND				;load stack pointer

	cbi		DDRE,IR				;set IR input
    
    sbi		DDRE,SPEAKER		;set speaker output
    
    rcall	LCD_init			;initialize LCD 
	rcall	LCD_clear
	rcall	LCD_home 

	OUTI	TIMSK,1<<TOIE0	; Timer0 Overflow Interrupt Enable
	OUTI	TCCR0,4
	OUTI	ASSR,1<<AS0

    OUTI EIMSK, 0b10000001		;enable INT0
    OUTEI EICRA, 0b00000011		;3<<ISC00 ;
	sei							;set global interrupt

	clr r6						;clear working registers
	clr r7

    rjmp main

.include "lcd.asm"				;include LCD routines
.include "printf.asm"			;include PRINTF library
.include "eeprom.asm"			;include internal EEPROM routines

;==== Main code ===
main:
	JB1		r6,7,display_ask_new_code;ask to set the new passcode on LCD
	JB1		r6,4,exit_code_verification;test if we have to check the code
	JB1		r6,2,display_ask_code;ask to the user to enter passcode
	JB0		r6,1,system_inactive;check if the system needs to be active
	JB1		r6,1,system_active	;check if the system needs to be active
	rjmp main

wrong_code_test:
	SET_BIT_0	r6,3			;reset bool bits 
	SET_bit_0	r6,6
	SET_BIT_0	r6,5
	SET_BIT_0	r6,4

	rcall		LCD_home		;write "Code FALSE" on the LCD
	PRINTF		LCD 
	.db "Code FALSE      ",LF,0
	PRINTF		LCD
	.db "                ",LF,0
	WAIT_MS		2000
	rjmp		main

exit_code_verification:			;exit the passcode verification test
	SET_BIT_0	r6,2
	JB0			r6,3,desactivate_sound
	rjmp		wrong_code_test

display_ask_code:				;ask the user to enter the passcode
	rcall		LCD_home
	PRINTF		LCD
	.db "Enter the code  ",LF,0
	PRINTF		LCD
	.db "                ",LF,0
	JB1			r6,0,different_sound;check if we need to play a sound when passcode required
	rjmp main

different_sound:
	JB1 r7,0,main
	sbi		PORTE,SPEAKER		
    WAIT_US 550
    cbi		PORTE,SPEAKER
    WAIT_US 550
	rjmp	main

display_ask_new_code:			;display "Set the new code" on the LCD 
	rcall		LCD_home
	PRINTF		LCD
	.db "Set the new code",LF,0
	PRINTF		LCD
	.db "                ",LF,0
	rjmp main

desactivate_sound:
	SET_BIT_0	r6,0			;reset bool bits
	SET_BIT_0	r6,1
	SET_bit_0	r6,6
	SET_BIT_0	r6,5
	SET_BIT_0	r6,4

	rcall		LCD_home		;print "Code OK" on the LCD 
	PRINTF		LCD 
	.db "Code OK         ",LF,0
	PRINTF		LCD
	.db "                ",LF,0
	WAIT_MS		2000
	rjmp		main

system_inactive:				;print "System inactive" on the LCD
	rcall		LCD_home
	PRINTF		LCD 
	.db "System inactive ",LF,0
	PRINTF		LCD
	.db "                ",LF,0
	rjmp		main

system_active:					;branch to subroutine when system is active
	JB1		r6,0,speaker_alarm
	JB0		r6,0,speaker_off
	ret

speaker_alarm:
	rcall	LCD_home			;print "System active" on the LCD
	PRINTF	LCD 
	.db "System active  ",LF,0
	PRINTF	LCD
	.db "Sound : ON     ",LF,0

    rjmp	different_sound

speaker_off:					;turn off the speaker
	rcall	LCD_home
	PRINTF	LCD 
	.db "System active   ",LF,0
	PRINTF	LCD
	.db "Sound : OFF     ",LF,0
	rjmp	main