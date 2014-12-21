.include "m32U4def.inc"
.include "define.inc"

.dseg
	_ptr:				.byte 2
	card_type:			.byte 1
	raw_block_address:	.byte 2
	raw_block:			.byte 512

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

spi_full_speed:
	in spi_mp, SPCR
	andi spi_mp, 0xFC
	ori spi_mp, 0

	in spi_mp, SPSR
	andi spi_mp, 0xFE
	ori spi_mp, 0x01
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

set_block_address:
	push XL
	push XH
	ldi XL, low(raw_block_address)
	ldi XH, high(raw_block_address)
	st X+, 	mp1
	st X, 	mp2
	pop XH
	pop XL
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
	rcall sd_raw_send_command 	; CMD 0
	cpi spi_mp, 0x01
	breq _sd_cmd8
	rjmp _sd_cmd0
_sd_cmd8:
	ldi mp1, CMD_SEND_IF_COND
	ldi mp2, 0x00
	ldi mp3, 0x00
	ldi mp4, 0x01
	ldi mp5, 0xAA
	ldi mp6,  0x87
	rcall sd_raw_send_command 	; CMD 8
	sbrs spi_mp, R1_ILL_COMMAND
	rjmp _sd_cmd8_response_check
_sd_cmd8_ver1:
	rcall get_card_type
	ori mp, (1 << SD_RAW_SPEC_1)
	rcall set_card_type
	rjmp _sd_card_init_failed	; TODO: SD Ver. 1 Not supported

_sd_cmd8_response_check:
	rcall get_card_type
	ori mp, (1 << SD_RAW_SPEC_2)
	rcall set_card_type
	ldi mp, 0x04
_sd_cmd8_check:
	rcall spi_recv
	dec mp
	brne _sd_cmd8_check
; result = 0xFF
_sd_cmd8_result:
	cpi spi_mp, 0xAA
	breq _sd_acmd_41_cond
	cpi spi_mp, 0xFF
	brne _sd_acmd_41_cond

_sd_acmd_41_cond:
	ldi mp1, CMD_SD_SEND_OP_COND
	ldi mp2, 0x00
	ldi mp3, 0x00
	ldi mp4, 0x00
	ldi mp5, 0x00
	rcall get_card_type
	sbrc mp, SD_RAW_SPEC_2
	ldi mp5, 0x40
	ldi mp6, 0xFF

_sd_acmd_41_cond_repeat:
	rcall sd_raw_send_acommand
	cpi spi_mp, 0x01
	brne _sd_acmd_41_cond_repeat

	sbrs mp, SD_RAW_SPEC_2
	rjmp _sd_card_init_failed		; TODO: SD Ver. 1 Not supported

_sd_cmd_58_ocr:
	ldi mp1, CMD_READ_OCR
	ldi mp2, 0x00
	ldi mp3, 0x00
	ldi mp4, 0x00
	ldi mp5, 0x00
	ldi mp6, 0xFF
	rcall sd_raw_send_command
	cpi spi_mp, 0x01
	breq _sd_cmd_58_ocr

	rcall spi_recv
	andi spi_mp, 0xC0
	cpi  spi_mp, 0xC0
	brne _sd_cmd58_result
sdhc_card:
	rcall get_card_type
	ori mp, (1 << SD_RAW_SPEC_SDHC)
	rcall set_card_type
_sd_cmd58_result:
	ldi mp, 3
_sd_cmd58_result_skip:
	rcall spi_recv
	dec mp
	brne _sd_cmd58_result_skip
_sd_card_init_done:
	ldi mp, 0xFF
	rcall spi_send
	ldi mp, 0xFF
	rcall spi_send
	rcall unselect_sd_card
	ldi mp, 0xFF
	rcall spi_send
; SPI switch to high speed
	rcall spi_full_speed
	ldi mp1, 0
	ldi mp2, 0
	ldi mp3, low(512)
	ldi mp4, high(512)
	rcall sd_raw_read
	DEBUG_MSG CardReady

_sd_card_init_failed:
	ret

sd_raw_buffer_clean:
	push ZL
	push ZH
	push XL
	push XH
	push mp1

	ldi mp1, 0
	ldi ZL, low(512)
	ldi ZH, high(512)
	ldi XL, low(raw_block)
	ldi XH, high(raw_block)
_clean_buffer:
	st X+, mp1
	sbiw ZL, 1
	brne _clean_buffer

	pop mp1
	pop XH
	pop XL
	pop ZH
	pop ZL
	ret
;
; SD card read routine
; in: mp1-L:mp2-H - offset
; in: mp3:mp4 - length to read
;
sd_raw_read:
	push mp7
	push mp8
	; clean buffer first
	rcall sd_raw_buffer_clean
	;ldi XL, low(512)
	;ldi XH, high(512)
_sd_raw_read:
; block_offset = offset & 0x01ff;
; mp6 - block_offset * HIGH
; mp5 - block_offset * LOW
	movw mp6:mp5, mp2:mp1
	andi mp6, high(0x01FF)
	andi mp5, low(0x01FF)
; block_address = offset - block_offset;
; mp8 - block_address * HIGH
; mp7 - block_address * LOW
	movw mp8:mp7, mp2:mp1
	sub mp7, mp5
	sbc mp8, mp6
;        read_length = 512 - block_offset; /* read up to block border */
;        if(read_length > length)
;            read_length = length;
	push mp1
	push mp2
; mp1 - read_length * LOW
; mp2 - read_length * HIGH
	ldi mp1, low(512)
	ldi mp2, high(512)
	sub mp1, mp5
	sbc mp2, mp6
	cp mp1, mp3
	cpc mp2, mp4
	brsh _sd_raw_read_1
	movw mp2:mp1, mp4:mp3
_sd_raw_read_1:
	push mp3
	push mp4
	ldi XL, low(raw_block_address)
	ldi XH, high(raw_block_address)
	ld mp3, X+
	ld mp4, X
	cp mp7, mp3
	cpc mp8, mp4
	pop mp4
	pop mp3
	breq _sd_read_done
_sd_raw_read_2:
	rcall select_sd_card
;            /* send single block request */
;            if(sd_raw_send_command(CMD_READ_SINGLE_BLOCK, (sd_raw_card_type & (1 << SD_RAW_SPEC_SDHC) ? block_address / 512 : block_address)))
;            {
;                unselect_card();
;                return 0;
;            }
;            while(sd_raw_rec_byte() != 0xfe);
;#if SD_RAW_SAVE_RAM
;            /* read byte block */
;            uint16_t read_to = block_offset + read_length;
;            for(uint16_t i = 0; i < 512; ++i)
;            {
;                uint8_t b = sd_raw_rec_byte();
;                if(i >= block_offset && i < read_to)
;                    *buffer++ = b;
;            }
;#else
;            /* read byte block */
;            uint8_t* cache = raw_block;
;            for(uint16_t i = 0; i < 512; ++i)
;                *cache++ = sd_raw_rec_byte();
;            raw_block_address = block_address;
;            memcpy(buffer, raw_block + block_offset, read_length);
;            buffer += read_length;
;#endif
;            /* read crc16 */
;            sd_raw_rec_byte();
;            sd_raw_rec_byte();
;            /* deaddress card */
;            unselect_card();
;            /* let card some time to finish */
;            sd_raw_rec_byte();
	; read crc16
	rcall spi_recv
	rcall spi_recv
	rcall unselect_sd_card
	; let's card take some time to finish
	rcall spi_recv
	;sbiw XL, 1
	;brne _sd_raw_read
_sd_read_done:
	pop mp2
	pop mp1

	pop mp8
	pop mp7
	ret

sd_raw_send_command:
	rcall select_sd_card
	ldi spi_mp, 0xFF
	rcall spi_send
	mov spi_mp, mp1
	ori spi_mp, 0x40
	rcall spi_send
; data
	mov spi_mp, mp2
	rcall spi_send
	mov spi_mp, mp3
	rcall spi_send
	mov spi_mp, mp4
	rcall spi_send
	mov spi_mp, mp5
	rcall spi_send
; checksum
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

CardReady:
.db "SD Card ready", 0x0D, 0x0A, 0x00
