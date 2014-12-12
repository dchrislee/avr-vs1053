MCU          = atmega32u4
MCU_AVR_CORE = __AVR_ATmega32u4__
ARCH         = AVR8
BOARD        = NONE
F_CPU        = 16000000
F_USB        = $(F_CPU)


CC=avrasm2
HEADERS=
OBJ=main
HEX=$(OBJ).hex
FLAGS=-fI -I. -l $(OBJDIR)/$(OBJ).lst -m $(OBJDIR)/$(OBJ).map -d $(OBJDIR)/$(OBJ).obj -O w -D F_CPU=$(F_CPU) -W+ie

OBJDIR=build
LUFA_PATH    = ../Build
TARGET       = $(OBJDIR)/$(OBJ)

AVRDUDE_PROGRAMMER = avr109
AVRDUDE_PORT = COM7


default: $(OBJDIR)/$(OBJ).hex
all: default

$(OBJDIR)/%.hex: %.asm
	rm -rf $(OBJDIR)
	mkdir $(OBJDIR)
	$(CC) $(FLAGS) $< -o $@
    
clean:
	rm -rf $(OBJDIR)

include $(LUFA_PATH)/lufa_avrdude.mk
