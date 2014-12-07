.cseg

.org 	0x0000
rjmp 	reset

.org	INT0addr
rjmp	_sd_card_insert

.org	INT1addr;	= 0x0004	; External Interrupt Rorgest 1
reti
.org	INT2addr;	= 0x0006	; External Interrupt Rorgest 2
reti
.org	INT3addr;	= 0x0008	; External Interrupt Rorgest 3
reti
.org	INT6addr;	= 0x000e	; External Interrupt Rorgest 6
reti
.org	PCI0addr;	= 0x0012	; Pin Change Interrupt Rorgest 0
reti
.org	USB_GENaddr;	= 0x0014	; USB General Interrupt Rorgest
reti
.org	USB_COMaddr;	= 0x0016	; USB Endpoint/Pipe Interrupt Communication Rorgest
reti
.org	WDTaddr;	= 0x0018	; Watchdog Time-out Interrupt
reti
.org	ICP1addr;	= 0x0020	; Timer/Counter1 Capture Event
reti
.org	OC1Aaddr;	= 0x0022	; Timer/Counter1 Compare Match A
reti
.org	OC1Baddr;	= 0x0024	; Timer/Counter1 Compare Match B
reti
.org	OC1Caddr;	= 0x0026	; Timer/Counter1 Compare Match C
reti
.org	OVF1addr;	= 0x0028	; Timer/Counter1 Overflow
reti
.org	OC0Aaddr;	= 0x002a	; Timer/Counter0 Compare Match A
reti
.org	OC0Baddr;	= 0x002c	; Timer/Counter0 Compare Match B
reti
.org	OVF0addr;	= 0x002e	; Timer/Counter0 Overflow
reti
.org	SPIaddr;	= 0x0030	; SPI Serial Transfer Complete
reti
.org	URXC1addr;	= 0x0032	; USART1, Rx Complete
reti
.org	UDRE1addr;	= 0x0034	; USART1 Data register Empty
reti
.org	UTXC1addr;	= 0x0036	; USART1, Tx Complete
reti
.org	ACIaddr;	= 0x0038	; Analog Comparator
reti
.org	ADCCaddr;	= 0x003a	; ADC Conversion Complete
reti
.org	ERDYaddr;	= 0x003c	; EEPROM Ready
reti
.org	ICP3addr;	= 0x003e	; Timer/Counter3 Capture Event
reti
.org	OC3Aaddr;	= 0x0040	; Timer/Counter3 Compare Match A
reti
.org	OC3Baddr;	= 0x0042	; Timer/Counter3 Compare Match B
reti
.org	OC3Caddr;	= 0x0044	; Timer/Counter3 Compare Match C
reti
.org	OVF3addr;	= 0x0046	; Timer/Counter3 Overflow
reti
.org	TWIaddr;	= 0x0048	; 2-wire Serial Interface
reti
.org	SPMRaddr;	= 0x004a	; Store Program Memory Read
reti
.org	OC4Aaddr;	= 0x004c	; Timer/Counter4 Compare Match A
reti
.org	OC4Baddr;	= 0x004e	; Timer/Counter4 Compare Match B
reti
.org	OC4Daddr;	= 0x0050	; Timer/Counter4 Compare Match D
reti
.org	OVF4addr;	= 0x0052	; Timer/Counter4 Overflow
reti
.org	TIMER4_FPFaddr;	= 0x0054	; Timer/Counter4 Fault Protection Interrupt
reti

.org	INT_VECTORS_SIZE
