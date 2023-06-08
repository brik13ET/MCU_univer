
.def sign=	r10
.def exp=	r9
.def mh=	r8
.def ml=	r7

.equ num_len=3

.macro lldi
	ldi @0, @2
	mov @1, @0
.endmacro

.macro andli
	ldi @0, @2
	and @1, @0
.endmacro

.macro lldiw
	lldi @0, @1, high(@3)
	lldi @0, @2, low(@3)
.endmacro


.dseg
num: .byte num_len

.cseg
; RESET VECTOR
.org $00		rjmp Start
.org INT0addr	rjmp int0_handle
.org OC0addr	rjmp cnt0_match

.org $30

; in : sign, exp, mh, ml
; out: -
bit_iter: 
	push r16
	in r16, sreg
	push r16
	push r17
	bit_it:

		mov r17,	mh
		andi r17,	$80
		cp r17,	sign
		brne bit_it_end 

		inc exp
		mov r17,	exp
		cpi r17,	$7F
		breq bit_it_end
		lsl mh
		
		sbrc ml,	7
		inc mh

		lsl ml

		sbrc sign,	7
		inc ml 

		rjmp bit_it
	bit_it_end:
	pop r17
	pop r16
	out sreg,	r16
	pop r16
	ret

int0_handle:
	cli
	push r16
	in r16,	sreg
	push r16
	push r17
	
	in r16, TCCR0
	andi r16, (1 << 2) | ( 1 << 1 ) | ( 1<< 0 )
	brne int0_exit
	

	rcall ExRam_Write
	int0_exit:

	pop r17
	pop r16
	out sreg, r16
	pop r16
	sei
	reti


; in : void
; out: void
SPI_Init:
	push r16
	in r16, sreg
	push r16
	
	clr r16
	out portb, r16

	;ldi r16, ( 1 << 6 ) ;(0 << 4) | ( 0 << 5) | ( 0 << 7 ) | 
	;out ddrb, r16
	sbi ddrb, pb6
	ldi r16, ( 1 << spe ) | ( 0 << spie ) | (0 << Dord ) | ( 0 << mstr ) | ( 0 << cpol ) | ( 1 << cpha )
	out spcr, r16
	
	pop r16
	out sreg, r16
	pop r16
	ret

; in : r5:r4 DM addr for arr; r6 - arr len
; out: void
SPI_pool:
	push r16
	in r16, sreg
	push r16
	push zh
	push zl
		
	movw zh:zl, r5:r4
	
	array_pool:

		SPI_wait:
		sbic PORTD, pind2
		rjmp SPI_recv_end
		in r16, spsr
		sbrs r16, SPIF
		rjmp SPI_wait
		sbrc r16, WCOL
		rjmp SPI_wait

	in r16, spdr
	st Z+, r16

	dec r6
	brne array_pool
	
	SPI_recv_end:
	cbi PORTB, pb3
	
	pop zl
	pop zh
	pop r16
	out sreg, r16
	pop r16
	ret

cnt0_Init:
	; counter-interrupt
	ldi R16,	0 | (0 << foc0) | (1 << wgm01 ) | ( 0 << wgm00 ) | (1 << cs02 ) | ( 1  << cs01 ) | ( 0 << cs00) | ( 0 << com01)
	;ldi R16,	0 | ( 1 << 6) | (0 << 5) | ( 1 << 4 ) | (1 << 2) | ( 1 << 1 ) | ( 1<< 0 )
	out TCCR0,	r16
	ldi r16,	1 << 1
	out TIMSK,	r16
	out TIFR,	r16
	ret

cnt0_match:
	cli
	push r16
	in r16, sreg
	push r16
	sbi portb, pb3


	; disable interrupt
	ldi R16,	0 | ( 1 << WGM01) | (0 << WGM00) | (0 << COM01) | ( 0 << COM00 ) | (0 << CS02) | ( 0 << CS01 ) | ( 0 << CS00 )
	out TCCR0,	r16
	
	ldi r16,	0 << 1
	out TIMSK,	r16
	out TIFR,	r16
	cBI PORTD, PD3
	sbi PORTB, pb3

	; in : r5:r4 DM addr for arr, r6 - arr len
	; out: void
	lldi r16, r6, num_len
	lldi r16, r5, high(num)
	lldi r16, r4, low(num)
	rcall SPI_pool
	
	lds exp, num+0
	lds mh, num+1
	lds ml, num+2
	
	mov r16, exp
	andi r16, $80
	mov sign, r16
	rcall bit_iter

	pop r16
	out sreg, r16
	pop r16
	sei
	reti

ExRam_Init:
	push r16
	in r16, sreg
	push r16

	ser r16
	OUT DDRA, r16
	out ddrb, r16
	out ddrc, r16

	pop r16
	out sreg, r16
	pop r16
	ret

ExRam_Write:
	push r16
	in r16, sreg
	push r16
	
	ldi r17, 0 | ( 1 << pa7 )
	out porta, r17
	cbi Porta, pa7
	out portc, exp
	sbi porta, pa7
	ser r17
	out porta, r17
	
	ldi r17, 1 | ( 1 << pa7 )
	out porta, r17
	cbi Porta, pa7
	out portc, mh
	sbi porta, pa7
	ser r17
	out porta, r17
	
	ldi r17, 2 | ( 1 << pa7 )
	out porta, r17
	cbi Porta, pa7
	out portc, ml
	sbi porta, pa7
	ser r17
	out porta, r17
	
	rjmp speed_test_end
	speed_test:
	
	ldi r17, $32 | ( 1 << pa7 )
	out porta, r17
	cbi Porta, pa7
	out portc, r17
	sbi porta, pa7
	ser r17
	out porta, r17
	nop
	nop
	nop
	//rjmp speed_test
	speed_test_end:
	
	pop r16
	out sreg, r16
	pop r16
	ret

GPIO_Init:
	push r16
	in r16, sreg
	push r16
	
	ser r16
	out DDRA,	r16
	sbi ddrb, pb3
	ldi r16, $2f
	out DDRC,	r16
	sbi ddrd,	pd3
	
	pop r16
	out sreg, r16
	pop r16
	ret
	
Start:
	; stack
	ldi r16,	HIGH(RAMEND)
	out sph,	r16
	ldi r16,	LOW(RAMEND)
	out spl,	r16

	; gpio
	rcall GPIO_Init
	cBI PORTD, PD3
	; SPI init
	rcall SPI_Init
	; counter-match
	ldi r16,	100
	out OCR0,	r16
	rcall cnt0_Init
	;ExRam
	rcall ExRam_Init
	;Interrupts
	ldi r16, (1 << 0) | (1 << 1) 
	out mcucr, r16
	ldi r16, (1 << 6)
	out gicr, r16
	
	sei
	sBI PORTD,	PD3


Loop:
	rjmp  Loop