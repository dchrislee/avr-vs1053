.include "m32U4def.inc"
.include "define.inc"

.dseg
	_ptr:		.byte 2
	card_type:	.byte 1

.cseg
.org 	0x0000
rjmp 	reset
.org	INT_VECTORS_SIZE

; ====================================================================================================================
; RESET
; ====================================================================================================================
reset:
	.include "init.asm"
	rcall uart_init
	rcall spi_init
	rcall sd_raw_init
	rjmp main

main:
	rjmp main

;===============================================================
; Delay utilities
; Registers used: r18:r19, r30:r31, XL:XH
;===============================================================
_wait_us:
	sbiw   XL, 1
	brne   _wait_us
	ret

_wait_ms:
	push XL
	push XH
_wait_ms_sub:
	ldi XH, high(DVUS(500))
	ldi XL, low(DVUS(500))
	rcall  _wait_us ; wait 500 us

	ldi XH, high(DVUS(500))
	ldi XL, low(DVUS(500))
	rcall  _wait_us ; wait 500 us

	sbiw 	r30, 1
	brne   _wait_ms_sub
	pop XH
	pop XL
	ret

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
select_sd_card:
	cbi PORTB, PB4
	ret

unselect_sd_card:
	sbi PORTB, PB4
	ret

set_card_type:
	push XL
	push XH
	ldi XL, low(card_type)
	ldi XH, high(card_type)
	st X, mp
	pop XH
	pop XL
	ret

get_card_type:
	push XL
	push XH
	ldi XL, low(card_type)
	ldi XH, high(card_type)
	ld mp, X
	pop XH
	pop XL
	ret

sd_raw_init:
	;DEBUG_MSG Initialization
	ldi mp, 0x00
	rcall set_card_type
	rcall unselect_sd_card
	ldi mp, 10
_sd_raw_core_init:	
	rcall spi_recv
	dec mp
	brne _sd_raw_core_init
	rcall select_sd_card
_sd_cmd0:
	ldi mp1, CMD_GO_IDLE_STATE
	ldi mp2, 0x00
	ldi mp3, 0x00
	ldi mp4, 0x00
	ldi mp5, 0x00
	ldi mp6,  0x95
	rcall sd_raw_send_command 	; CMD_GO_IDLE_STATE
	cpi spi_mp, 0x01
	breq _sd_cmd8
	rjmp _sd_cmd0
_sd_cmd8:
	ldi mp1, CMD_SEND_IF_COND
	ldi mp2, 0x00
	ldi mp3, 0x00
	ldi mp4, 0x01
	ldi mp5, 0xAA
	ldi mp6,  0xFF
	rcall sd_raw_send_command 	; CMD_SEND_IF_COND
	sbrs spi_mp, R1_ERASE_RESET
	rjmp _sd_cmd8_response_check
	sbrs spi_mp, R1_ILL_COMMAND
	rjmp _sd_cmd8_response_check
_sd_cmd8_ok:
	rcall get_card_type
	ori mp, SD_RAW_SPEC_1
	rcall set_card_type
_sd_cmd8_response_check:
	ldi mp, 0x04
_sd_cmd8_check:
	rcall spi_recv
	dec mp
	brne _sd_cmd8_check
_sd_cmd8_result:
	cpi spi_mp, 0xAA
	breq _sd_cmd8_card_result
	cpi spi_mp, 0xFF
	brne _sd_acmd_op_cond	
_sd_cmd8_card_result:
	rcall get_card_type
	ori mp, SD_RAW_SPEC_2
	rcall set_card_type
_sd_acmd_op_cond:
	rcall uart_send
	mov spi_mp, mp
	ldi mp1, CMD_SD_SEND_OP_COND
	ldi mp2, 0x00
	ldi mp3, 0x00
	ldi mp4, 0x00
	ldi mp5, 0x40
	ldi mp6, 0xFF
	sbrs spi_mp, SD_RAW_SPEC_2
	rjmp _sd_acmd_op_cond_repeat
	ldi mp2, 0x40
_sd_acmd_op_cond_repeat:
	rcall sd_raw_send_acommand
	cpi spi_mp, R1_IDLE_STATE
	brne _sd_acmd_op_cond_repeat
	sbrs spi_mp, SD_RAW_SPEC_2
	rjmp _sd_check_wont_check_ocr
_sd_check_ocr:
	ldi mp1, CMD_READ_OCR
	ldi mp2, 0x00
	ldi mp3, 0x00
	ldi mp4, 0x00
	ldi mp5, 0x00
	ldi mp6, 0xFF
	rcall sd_raw_send_command
_sd_check_wont_check_ocr:
;	if (sd_raw_card_type & (1 << SD_RAW_SPEC_2)) {
;		if (sd_raw_send_command(CMD_READ_OCR, 0)) {
;			return 0;
;		}
;		if ((spiRecByte() & 0XC0) == 0XC0)
;			sd_raw_card_type |= (1 << SD_RAW_SPEC_SDHC);
;		for (uint8_t i = 0; i < 3; i++) spiRecByte();
;	}

	ret

sd_raw_send_command:
	rcall select_sd_card
	nop
	nop
	mov spi_mp, mp1
	ori spi_mp, 0x40
	rcall spi_send
	mov spi_mp, mp2
	rcall spi_send
	mov spi_mp, mp3
	rcall spi_send
	mov spi_mp, mp4
	rcall spi_send
	mov spi_mp, mp5
	rcall spi_send
	mov spi_mp, mp6
	rcall spi_send
	ldi mp6, 10
_sd_raw_send_command_check:
	rcall spi_recv
	cpi spi_mp, 0xFF
	brne _sd_raw_send_command_checked
	dec mp6
	brne _sd_raw_send_command_check
_sd_raw_send_command_checked:
	ret

sd_raw_send_acommand:
	push mp1
	push mp2
	push mp3
	push mp4
	push mp5
	push mp6
	ldi mp1, CMD_APP
	ldi mp2, 0x00
	ldi mp3, 0x00
	ldi mp4, 0x00
	ldi mp5, 0x00
	ldi mp6, 0xFF
	rcall sd_raw_send_command
	pop mp6
	pop mp5
	pop mp4
	pop mp3
	pop mp2
	pop mp1
	rcall sd_raw_send_command
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
	sts _ptr, ZL
	sts _ptr + 1, ZH 
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
__uart_send:
	lds R17, UCSR1A
	sbrs R17, UDRE1		; wait for empty TX
	rjmp __uart_send
	ret

ErrorInitSD:
.db "Error init SD card", 0x0D, 0x0A, 0x00, 0x00

CardInIDleState:
.db "SD Card in idle state", 0x0D, 0x0A, 0x00

WaitForIdle:
.db "+", 0x0D, 0x0A, 0x00

SPIInit:
.db "SPI init done.", 0x0D, 0x0A, 0x00, 0x00

Initialization:
.db "Initialization in process...", 0x0D, 0x0A, 0x00, 0x00
