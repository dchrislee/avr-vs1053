#ifndef F_CPU
  #error "F_CPU must be defined!"
#endif

#define CYCLES_PER_US	(F_CPU / 1000000)
#define C4PUS			(CYCLES_PER_US / 8)
#define DVUS(x)			(C4PUS * x)

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

; usage: InReg reg, addr
.macro InReg
    .if @1 < 0x40
        in @0, @1
    .elif ((@1 >= 0x60) && (@1 < SRAM_START))
        lds @0,@1
    .else
       .error "InReg: Invalid I/O register address"
    .endif
.endm

; usage: OutReg addr, reg
.macro OutReg
    .if @0 < 0x40
        out @0, @1
    .elif ((@0 >= 0x60) && (@0 < SRAM_START))
        sts @0,@1
    .else
       .error "OutReg: Invalid I/O register address"
    .endif
.endm
