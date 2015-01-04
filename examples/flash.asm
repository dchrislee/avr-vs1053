.equ TABLE_SIZE = 12

.dseg
MyTable:
   .byte TABLE_SIZE   ; Declare storage space to hold the 
                      ; coefficient table

.cseg
.org 0
   rjmp Reset

Reset:
   ldi r16, high(ramend)
   out SPH, r16
   ldi r16, low(ramend)
   out SPL, r16
   rcall Initialize_RAM
   rjmp Main

Main:
   ; Insert application here.
   ; Always access the coefficient table stored in RAM.

Flash_Table_Initializer:
; This table contains the initial value that should always be
; used for the coefficient table on start-up.  The RAM copy
; of the table will be initialized based on this table.
   .db 12, 56, 28, 93, 72, 103, 82, 213, 48, 85, 157, 68

Initialize_RAM:
   ; Copy the initial values for the coefficient table from Flash into RAM.
   ldi ZH, high(Flash_Table_Initializer << 1)
   ldi ZL, low(Flash_Table_Initializer << 1)
   ldi XH, high(MyTable)
   ldi XL, low(MyTable)
   ldi r16, TABLE_SIZE
Initialize_RAM_Loop:
   lpm r17, Z+
   st X+, r17
   dec r16
   brne Initialize_RAM_Loop
   ret
