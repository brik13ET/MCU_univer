.dseg
dat_loop: .byte 1
.cseg
; RESET VECTOR
.org $00 rjmp Start
.org $01 rjmp int0_handle
.org $0A rjmp spi_rx
.org $13 rjmp cnt0_match

.equ ex_addr=$10
.def sign=	r10
.def exp=	r9
.def mh=	r8
.def ml=	r7

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

.org $30

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

spi_rx:
	cli
	push r16
	in r16,	sreg
	push r16

	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck
	nop ;fuck

	fuck: rjmp fuck
	pop r16
	out sreg, r16
	pop r16
	sei
	reti

int0_handle:
	cli
	push r16
	in r16,	sreg
	push r16

	

	pop r16
	out sreg, r16
	pop r16
	sei
	reti

cnt0_match:
	cli
	push r16
	in r16, sreg
	push r16

	
	; setup spi-slave 
	ldi r16, (1 << 6) | (1 << 5) | 0
	out SPCR, r16


	SPI_SlaveReceive_exp:
	sbis SPSR,SPIF
	rjmp SPI_SlaveReceive_exp
	in exp,SPDR
	SPI_SlaveReceive_mh:
	sbis SPSR,SPIF
	rjmp SPI_SlaveReceive_mh
	in mh,SPDR
	SPI_SlaveReceive_ml:
	sbis SPSR,SPIF
	rjmp SPI_SlaveReceive_ml
	in ml,SPDR
	
	pop r16
	out sreg, r16
	pop r16
	sei
	reti


Start:
	; stack
	ldi r16,	HIGH(RAMEND)
	out sph,	r16
	ldi r16,	LOW(RAMEND)
	out spl,	r16

	; gpio
	ser r16
	out DDRA,	r16
	out DDRC,	r16
	out PORTA,	r16
	out PORTC,	r16
	ldi r16,	0 | (1 << 3 )
	out DDRB,	r16
	out portB,	r16
	
	; counter-match
	ldi r16,	100
	out OCR0,	r16
	; counter-interrupt
	ldi R16,	0 | ( 1 << 6) | (0 << 5) | ( 1 << 4 ) | (1 << 2) | ( 1 << 1 ) | ( 1<< 0 )
	out TCCR0,	r16
	ldi r16,	1 << 1
	out TIMSK,	r16
	out TIFR,	r16
	
	sei
Loop:
	rjmp  Loop