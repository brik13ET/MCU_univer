;
; studio_project.asm
;
; Created: 22.04.2023 15:49:53
; Author : user0
;


.org $30
int0:


reti


start:
	
loop:
    rjmp loop

.dseg																			
ram_arr: .byte 42	