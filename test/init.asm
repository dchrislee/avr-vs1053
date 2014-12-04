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
; ============================
; ram flush
; ============================
	ldi	ZL, low(SRAM_START)
	ldi	ZH, high(SRAM_START)

; configure ports
; ============================
	ldi	mp, 0xFF
	out DDRD, mp
; ============================
; UART init
; ============================
;	rjmp uart_init

	clr	ZL
	clr	ZH