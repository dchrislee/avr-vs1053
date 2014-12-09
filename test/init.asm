; ============================
; core init
; ============================
	clr mp

; ============================
; initialize a stack pointer
; ============================
	ldi	mp, low(RAMEND)
	out SPL, mp

	ldi	mp, high(RAMEND)
	out SPH, mp

	clr	ZL
	clr	ZH

; ============================
; RAM flush
; ============================
	ldi	ZL, low(SRAM_START)
	ldi	ZH, high(SRAM_START)

;
; Turn off AC
;
	ldi mp, ADCSRA				; ADC Control and Status Register A
	andi mp, ~(1 << ADEN)		; Switch off 'AD Enable' bit
	sts ADCSRA, mp				; Rewrite Register Bits
; The Analog Comparator should be disabled => “Analog Comparator” on page 186
	ldi mp, 1 << ACD			; Analog Comarator Disable bit
	out ACSR, mp				; Analog Comparator Control and Status Register


; TODO: Turn off WDT

;
; UART pins init + LED
;
; PD0 - INT0, input
; PD2 - TXD, input
;
	ldi mp, 0xFF
	andi mp, ~((1 << PD0) | (1 << PD2))
	out DDRD, mp

;
; PD2 - RXD,  high
; PD0 - INT0, high
; PD6 - LED,  low
;
	ldi mp, ((1 << PD2) | (1 << PD0))
	out PORTD, mp

;
; SPI pins init
;
	ldi mp, 0xFF
	out DDRB, mp

;	sbi DDRB, PB0				; Prevent high rise times on PB.0 (/SS) from forcing a change to SPI slave mode !!!
	sbi PORTB, PB0

	ldi mp, DDRB
	ori mp, ((1 << PB0) | (1 << PB1) | (1 << PB2))
	andi mp, ~(1 << PB3)
	out DDRB, mp

	sbi PORTB, PB3

;
; Ext 0 interrupt
;
	ldi mp, EICRA
	andi mp, ~(1 << ISC00) | (1 << ISC01)
	ori mp, CHANGING
	sts EICRA, mp

	sbi EIMSK, 0				; Enable INT0

    sei
