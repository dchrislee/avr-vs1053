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
