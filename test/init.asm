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

	ldi	mp, 0xFE
	out DDRD, mp
	sbi PORTD, PD0
	cbi PORTD, PD6
	
;	ldi mp, (1 << ISC10)
;	sts EICRA, mp

;	ldi mp, (1 << INT0)
;	out EIMSK, mp

;	EICRA = (EICRA & ~((1<<ISC00) | (1<<ISC01))) | (mode << ISC00);
;  e4:	e9 e6       	ldi	r30, 0x69	; 105
;  e6:	f0 e0       	ldi	r31, 0x00	; 0
;  e8:	80 81       	ld	r24, Z
;  ea:	8c 7f       	andi	r24, 0xFC	; 252
;  ec:	81 60       	ori	r24, 0x01	; 1
;  ee:	80 83       	st	Z, r24
;	EIMSK |= (1<<INT0);
;  f0:	e8 9a       	sbi	0x1d, 0	; 29

	ldi mp, EICRA
	andi mp, ~(1 << ISC00) | (1 << ISC01)
	ori mp, CHANGING
	sts EICRA, mp

	ldi mp, (1 << INT0)
	out EIMSK, mp
;	sbi EIMSK, 0;	fastest

    sei
	