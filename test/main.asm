.include "m32U4def.inc"
.include "define.inc"

.dseg
	_ptr:		.byte 2
	card_type:	.byte 1

.include "vectors.inc"
.include "delay.asm"

; ====================================================================================================================
; SPI routines
; ====================================================================================================================
spi_init:
	push spi_mp
_spi_init:
	sbi DDRB, PB0				; Prevent high rise times on PB0 (/SS) from forcing a change to SPI slave mode !!!
	sbi PORTB, PB0

_configure_spi_pins:
	in spi_mp, DDRB
	ori spi_mp, ((1 << PB1) | (1 << PB2))	; SCK | MOSI
	andi spi_mp, ~(1 << PB3)				; MISO
	out DDRB, spi_mp
	sbi PORTB, PB3
_configure_spi_opts:
	in spi_mp, SPCR
	andi spi_mp, ~((1 << DORD) | (1 << SPIE) | (1 << CPOL) | (1 << CPHA))	; SPI MSBFIRST, NO SPI Interrupt, Clock Polarity: SCK low when idle, Clock Phase: sample on rising SCK edge
	ori spi_mp, ((1 << SPE) | (1 << MSTR) | (1 << SPR1) | (1 << SPR0))		; Master, SPI Enable, Clock Frequency: f_OSC / 128			
	out SPCR, spi_mp

    in spi_mp, SPSR
    andi spi_mp, ~(1 << SPI2X)				; SPI: No double clock freq
    out SPSR, spi_mp

	pop spi_mp
	ret

_spi_wait_ready:
	rcall uart_send
	in spi_mp, SPSR
	sbrs spi_mp, SPIF
	rcall _spi_wait_ready
	ret

spi_recv:
	ldi spi_mp, 0xFF
	out SPDR, spi_mp
	rcall _spi_wait_ready
	in spi_mp, SPDR
	ret

spi_send:
	out SPDR, spi_mp
	rcall _spi_wait_ready
	in spi_mp, SPDR
	ret
; ====================================================================================================================
; SD card routines
; ====================================================================================================================
.macro SEND_SD_CMD
	push mp
	ldi mp, @0
	ldi mp1, 0;low(@1)
	ldi mp2, 0;byte2(@1)
	ldi mp3, 0;byte3(@1)
	ldi mp4, 0;byte4(@1)
	rcall sd_raw_send_command
	pop mp
.endm

select_sd_card:
	cbi PORTB, PB4
	ret

unselect_sd_card:
	sbi PORTB, PB4
	ret

set_card_type:
	sts card_type, mp
	ret

_get_card_type:
	lds mp, card_type
	ret

sd_raw_init:
	rcall unselect_sd_card
	ldi mp, 74;	74 cycles to initialize
_sd_raw_ready_check:
	rcall spi_recv
	dec mp
	brne _sd_raw_ready_check
    ldi mp, 0
	rjmp set_card_type
	rjmp select_sd_card
	ldi mp, 0xFF
_go_idle_state:
	SEND_SD_CMD CMD_GO_IDLE_STATE, 0
	sbrs spi_mp, R1_IDLE_STATE
	rjmp sd_card_init_after_idle
	dec mp
	brne _go_idle_state
	rjmp sd_card_state_failed
sd_card_init_after_idle:
	DEBUG_MSG CardInIDleState
	ret

sd_raw_send_command:
	rcall spi_recv
	DEBUG_MSG WaitForIdle
	;sd_raw_send_byte(0x40 | command);
    ldi spi_mp, 0x40
    or spi_mp, mp
    rcall spi_send
    DEBUG_MSG WaitForIdle

;   sd_raw_send_byte((arg >> 24) & 0xff);
	mov spi_mp, mp4
	andi spi_mp, 0xff
	rcall spi_send
	DEBUG_MSG WaitForIdle
;   sd_raw_send_byte((arg >> 16) & 0xff);
	mov spi_mp, mp3
	andi spi_mp, 0xff
	rcall spi_send
	DEBUG_MSG WaitForIdle
;   sd_raw_send_byte((arg >> 8) & 0xff);
	mov spi_mp, mp2
	andi spi_mp, 0xff
	rcall spi_send
	DEBUG_MSG WaitForIdle
;   sd_raw_send_byte((arg >> 0) & 0xff);
	mov spi_mp, mp1
	andi spi_mp, 0xff
	rcall spi_send
	DEBUG_MSG WaitForIdle
;	sd_raw_send_byte(command == CMD_GO_IDLE_STATE ? 0x95 : 0xFF);
;#if mp == CMD_GO_IDLE_STATE
	ldi spi_mp, 0x95
;#else
;	ldi spi_mp, 0xFF
;#endif
	rcall spi_send
	DEBUG_MSG WaitForIdle
;   for(uint8_t i = 0; i < 10; ++i)
;   {
;        response = sd_raw_rec_byte();
;        if(response != 0xff)
;            break;
;    }
;    return response;
	ldi mp, 10
_cmd_response:
	dec mp
	breq _cmd_response_handle
	rcall spi_recv
	cpi spi_mp, 0xFF
	breq _cmd_response
_cmd_response_handle:
	mov mp, spi_mp
	ret

sd_raw_send_acommand:
	ret

sd_raw_read:
	ret

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
	rcall spi_init
	DEBUG_MSG SPIInit
	rcall sd_raw_init
	;sei

main:
	rjmp main

sd_card_state_failed:
	DEBUG_MSG ErrorInitSD
	rjmp main

ErrorInitSD:
.db "Error init SD card", 0x0D, 0x0A, 0x00, 0x00

CardInIDleState:
.db "SD Card in idle state", 0x0D, 0x0A, 0x00

WaitForIdle:
.db "W", 0x0D, 0x0A, 0x00

SPIInit:
.db "SPI init done.", 0x0D, 0x0A, 0x00, 0x00
