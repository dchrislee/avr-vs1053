.include "m32U4def.inc"
.include "define.inc"

.dseg
	_ptr:	.byte 2

.include "vectors.inc"
.include "delay.asm"

; ====
; UART initialization
; ====
uart_init:
	ldi mp, low(UART_DIVIDER)
	sts UBRR1L, mp
	ldi mp, high(UART_DIVIDER)
	sts UBRR1H, mp
	ldi mp, 0
	sts UCSR1A, mp

	ldi mp, (1 << RXEN1) | (1 << TXEN1)
	sts UCSR1B, mp

	; 8 bit
	ldi mp, (1 << UCSZ10) | (1 << UCSZ11)
	sts UCSR1C, mp
	ret

; ====
; UART send from pointer
; ====
uart_send_z:
	push ZL
	push ZH
	lds ZL, _ptr
	lds ZH, _ptr + 1
_uart_send_z:
	lpm mp, Z+
	cpi mp, 0		; check for 0
	breq stop_send_z; if not equal send it to UART
	rcall uart_send
	rjmp _uart_send_z
stop_send_z:
	pop ZH
	pop ZL
	ret

; ====
; UART send single character
; ====
uart_send:
	push R17
_uart_send:
	lds R17, UCSR1A
	sbrs R17, UDRE1		; wait for empty TX
	rjmp _uart_send
	pop R17
	sts UDR1, mp		; send the char in mp
	ret

reset:
	.include "init.asm"
	rcall uart_init
	DEBUG_MSG HelloWorld
	sei

main:
;	sbi PORTD, PD6
;	DELAY_MS 1000
;	cbi PORTD, PD6
;	DELAY_MS 1000
	rjmp main

_sd_card_insert:
;	cli
	cbi EIMSK, 0	; turn off INT0
	push mp
	in mp, SREG
	push mp
	sbic PIND, PD6
	cbi  PORTD, PD6
	sbis PIND, PD6
	sbi  PORTD, PD6
	DEBUG_MSG T
	pop mp
	out SREG, mp
	pop mp
	sbi EIMSK, 0	; turn on INT0
;	sei
reti

T: .db "MSG", 0x0d, 0x0a, 0x00


HelloWorld:
.db "Please insert a card into a slot", 0x0D, 0x0A, 0x00, 0x00
