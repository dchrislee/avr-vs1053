.include "m32U4def.inc"
.include "define.inc"

.dseg
	_ptr:	.byte 2

.include "vectors.inc"
.include "delay.asm"

; ====================================================================================================================
; SPI routines
; ====================================================================================================================
spi_init:
	push mp
_spi_init:
	sbi DDRB, PB0				; Prevent high rise times on PB0 (/SS) from forcing a change to SPI slave mode !!!
	sbi PORTB, PB0

_configure_spi_pins:
	in mp, DDRB
	ori mp, ((1 << PB1) | (1 << PB2))	; SCK | MOSI
	andi mp, ~(1 << PB3)				; MISO
	out DDRB, mp
	sbi PORTB, PB3
_configure_spi_opts:
	in mp, SPCR
	andi mp, ~((1 << DORD) | (1 << SPIE) | (1 << CPOL) | (1 << CPHA))	; SPI MSBFIRST, NO SPI Interrupt, Clock Polarity: SCK low when idle, Clock Phase: sample on rising SCK edge
	ori mp, ((1 << SPE) | (1 << MSTR) | (1 << SPR1) | (1 << SPR0))		; Master, SPI Enable, Clock Frequency: f_OSC / 128			
	out SPCR, mp

    in mp, SPSR
    andi mp, ~(1 << SPI2X)				; SPI: No double clock freq
    out SPSR, mp

	pop mp
	ret

_spi_wait_ready:
	in mp, SPSR
	sbrs mp, SPIF
	rjmp _spi_wait_ready
	ret

spi_recv:
	ldi mp, 0xFF
	out SPDR, mp
	rjmp _spi_wait_ready
	in mp, SPDR
	ret

spi_send:
	out SPDR, mp
	rjmp _spi_wait_ready
	in mp, SPDR
	ret
; ====================================================================================================================
; SD card routines
; ====================================================================================================================



; ====================================================================================================================
; UART routines
; ====================================================================================================================
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

uart_send_z:
	push ZL
	push ZH
	lds ZL, _ptr
	lds ZH, _ptr + 1
_uart_send_z:
	lpm mp, Z+		;
	cpi mp, 0		; check for 0
	breq stop_send_z; if not equal send it to UART
	rcall uart_send
	rjmp _uart_send_z
stop_send_z:
	pop ZH
	pop ZL
	ret

uart_send:
	push R17
_uart_send:
	lds R17, UCSR1A
	sbrs R17, UDRE1		; wait for empty TX
	rjmp _uart_send
	pop R17
	sts UDR1, mp		; send the char in mp
	ret

; ====================================================================================================================
; RESET
; ====================================================================================================================
reset:
	.include "init.asm"
	rcall uart_init
	DEBUG_MSG HelloWorld
	rcall spi_init
	sei

main:
	rjmp main

; ====================================================================================================================
; EXT 0 interrupt handler
; ====================================================================================================================
_sd_card_insert:
	cbi EIMSK, 0	; turn off INT0
	push mp
	in mp, SREG
	push mp

	sbic PIND, PD6
	cbi  PORTD, PD6
	sbis PIND, PD6
	sbi  PORTD, PD6

	pop mp
	out SREG, mp
	pop mp
	sbi EIMSK, 0	; turn on INT0
reti

HelloWorld:
.db "Please insert a card into a slot", 0x0D, 0x0A, 0x00, 0x00
