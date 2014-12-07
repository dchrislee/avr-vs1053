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
; ram flush
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

; The Brown-out Detector should be turned off => “Brown-out Detection” on page 40
;	in mp, MCUSR				; MCU Control and Status Register
;	andi mp, ~(1 << BORF)		; Switch off Brown Out Reset Flag
;	out MCUSR, mp

; The Watchdog Timer should be turned off => “Watchdog Timer” on page 43
;	in mp, MCUSR				; MCU Control and Status Register
;	andi mp, ~(1 << WDRF)		; Switch off WatchDog Reset Flag
;	out MCUSR, mp
;
; Ext 0 interrupt
;
	;ldi mp, (1 << INT0)
	;sts EIFR, mp

;	EIMSK |= _BV(INT0);  //Enable INT0
;  e4:	e8 9a       	sbi	0x1d, 0	; 29
;    EICRA |= _BV(ISC01); //Trigger on falling edge of INT0
;  e6:	80 91 69 00 	lds	r24, 0x0069
;  ea:	82 60       	ori	r24, 0x02	; 2
;  ec:	80 93 69 00 	sts	0x0069, r24
;  f0:	ff cf       	rjmp	.-2      	; 0xf0 <main+0xc>

	ldi	mp, 0xFE
	out DDRD, mp
	sbi PORTD, PD0
	cbi PORTD, PD6
	
	ldi mp, (1 << ISC10)
	sts EICRA, mp

	ldi mp, (1 << INT0)
	out EIMSK, mp

	ldi mp, 0
	out EIFR, mp
