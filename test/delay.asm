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
