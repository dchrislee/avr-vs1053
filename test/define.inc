#ifndef F_CPU
  #error "F_CPU must be defined!"
#endif

#define SPI_USE_DOUBLESPEED            (1 << SPE)
;
; SPI Prescaler Configuration Masks
;
; SPI prescaler mask. Divides the system clock by a factor of 2.
#define SPI_SPEED_FCPU_DIV_2           SPI_USE_DOUBLESPEED

; SPI prescaler mask. Divides the system clock by a factor of 4.
#define SPI_SPEED_FCPU_DIV_4           0

; SPI prescaler mask. Divides the system clock by a factor of 8.
#define SPI_SPEED_FCPU_DIV_8           (SPI_USE_DOUBLESPEED | (1 << SPR0))

; SPI prescaler mask. Divides the system clock by a factor of 16.
#define SPI_SPEED_FCPU_DIV_16          (1 << SPR0)

; SPI prescaler mask. Divides the system clock by a factor of 32.
#define SPI_SPEED_FCPU_DIV_32          (SPI_USE_DOUBLESPEED | (1 << SPR1))

; SPI prescaler mask. Divides the system clock by a factor of 64.
#define SPI_SPEED_FCPU_DIV_64          (SPI_USE_DOUBLESPEED | (1 << SPR1) | (1 << SPR0))

; SPI prescaler mask. Divides the system clock by a factor of 128.
#define SPI_SPEED_FCPU_DIV_128         ((1 << SPR1) | (1 << SPR0))

;
; SPI SCK Polarity Configuration Masks
;

; SPI clock polarity mask. Indicates that the SCK should lead on the rising edge.
#define SPI_SCK_LEAD_RISING            (0 << CPOL)

; SPI clock polarity mask. Indicates that the SCK should lead on the falling edge.
#define SPI_SCK_LEAD_FALLING           (1 << CPOL)

;
; SPI Sample Edge Configuration Masks
;
; SPI data sample mode mask. Indicates that the data should sampled on the leading edge.
#define SPI_SAMPLE_LEADING             (0 << CPHA)

; SPI data sample mode mask. Indicates that the data should be sampled on the trailing edge.
#define SPI_SAMPLE_TRAILING            (1 << CPHA)

;
; SPI Data Ordering Configuration Masks
;
; SPI data order mask. Indicates that data should be shifted out MSB first.
#define SPI_ORDER_MSB_FIRST            (0 << DORD)

; SPI data order mask. Indicates that data should be shifted out LSB first.
#define SPI_ORDER_LSB_FIRST            (1 << DORD)

;
; SPI Mode Configuration Masks
;
; SPI mode mask. Indicates that the SPI interface should be initialized into slave mode.
#define SPI_MODE_SLAVE                 (0 << MSTR)

; SPI mode mask. Indicates that the SPI interface should be initialized into master mode.
#define SPI_MODE_MASTER                (1 << MSTR)

/* CMD0: response R1 */
#define CMD_GO_IDLE_STATE 0x00
/* CMD1: response R1 */
#define CMD_SEND_OP_COND 0x01
/* CMD8: response R7 */
#define CMD_SEND_IF_COND 0x08
/* CMD9: response R1 */
#define CMD_SEND_CSD 0x09
/* CMD10: response R1 */
#define CMD_SEND_CID 0x0a
/* CMD12: response R1 */
#define CMD_STOP_TRANSMISSION 0x0c
/* CMD13: response R2 */
#define CMD_SEND_STATUS 0x0d
/* CMD16: arg0[31:0]: block length, response R1 */
#define CMD_SET_BLOCKLEN 0x10
/* CMD17: arg0[31:0]: data address, response R1 */
#define CMD_READ_SINGLE_BLOCK 0x11
/* CMD18: arg0[31:0]: data address, response R1 */
#define CMD_READ_MULTIPLE_BLOCK 0x12
/* CMD24: arg0[31:0]: data address, response R1 */
#define CMD_WRITE_SINGLE_BLOCK 0x18
/* CMD25: arg0[31:0]: data address, response R1 */
#define CMD_WRITE_MULTIPLE_BLOCK 0x19
/* CMD27: response R1 */
#define CMD_PROGRAM_CSD 0x1b
/* CMD28: arg0[31:0]: data address, response R1b */
#define CMD_SET_WRITE_PROT 0x1c
/* CMD29: arg0[31:0]: data address, response R1b */
#define CMD_CLR_WRITE_PROT 0x1d
/* CMD30: arg0[31:0]: write protect data address, response R1 */
#define CMD_SEND_WRITE_PROT 0x1e
/* CMD32: arg0[31:0]: data address, response R1 */
#define CMD_TAG_SECTOR_START 0x20
/* CMD33: arg0[31:0]: data address, response R1 */
#define CMD_TAG_SECTOR_END 0x21
/* CMD34: arg0[31:0]: data address, response R1 */
#define CMD_UNTAG_SECTOR 0x22
/* CMD35: arg0[31:0]: data address, response R1 */
#define CMD_TAG_ERASE_GROUP_START 0x23
/* CMD36: arg0[31:0]: data address, response R1 */
#define CMD_TAG_ERASE_GROUP_END 0x24
/* CMD37: arg0[31:0]: data address, response R1 */
#define CMD_UNTAG_ERASE_GROUP 0x25
/* CMD38: arg0[31:0]: stuff bits, response R1b */
#define CMD_ERASE 0x26
/* ACMD41: arg0[31:0]: OCR contents, response R1 */
#define CMD_SD_SEND_OP_COND 0x29
/* CMD42: arg0[31:0]: stuff bits, response R1b */
#define CMD_LOCK_UNLOCK 0x2a
/* CMD55: arg0[31:0]: stuff bits, response R1 */
#define CMD_APP 0x37
/* CMD58: arg0[31:0]: stuff bits, response R3 */
#define CMD_READ_OCR 0x3a
/* CMD59: arg0[31:1]: stuff bits, arg0[0:0]: crc option, response R1 */
#define CMD_CRC_ON_OFF 0x3b


#define CYCLES_PER_US					(F_CPU / 1000000)
#define C4PUS							(CYCLES_PER_US / 8)
#define DVUS(x)							(C4PUS * x)

.macro UOUT
.if @0<0x40
	OUT @0, @1
.else
	STS @0, @1
.endif
.endm

.macro DELAY_MS
	push r18
	push r19
	push r30
	push r31
	ldi r18, low(DVUS(@0))
	ldi r19, high(DVUS(@0))
	movw r30, r18
	rcall  _wait_ms
	pop r31
	pop r30
	pop r19
	pop r18
.endm

.def mp		 = r16			;	Maintain register
.def spi_mp  = r17
.def int_mp  = r18
.def mp1	 = r19
.def mp2	 = r20
.def mp3 	 = r21
.def mp4 	 = r22

.equ CHANGING = 1
.equ RISING = 3
.equ FALLING = 2

.equ UART_BAUDRATE = 9600
.equ UART_DIVIDER = F_CPU / (16 * UART_BAUDRATE) - 1;

.macro DEBUG_MSG
	push mp
    ldi mp, low(@0 * 2)
	sts _ptr, mp
    ldi mp, high(@0 * 2)
	sts _ptr + 1, mp
	rcall uart_send_z
	pop mp
.endm
