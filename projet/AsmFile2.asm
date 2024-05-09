/*
 * AsmFile2.asm
 *
 *  Created: 09.05.2024 09:29:34
 *   Author: mathi
 */ 

 /*
 * AsmFile1.asm
 *
 *  Created: 06.05.2024 21:23:13
 *   Author: mathi
 */ 
.include "macros.asm"    ; include macro definitions
.include "definitions.asm"

reset :
	clr r16
	clr r17
	ldi r16,0x03

main :
	cpi r17,0x01
	brne caca


caca:
	cpi r16,0x03
	breq main
	subi r17,0x01
	ret





