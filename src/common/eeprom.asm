; Driver for EEPROM controller of PIC16F690

#define EEPROM_M

#include <cpu.inc>
#include <global.inc>
#include <delay.inc>
#include <eeprom.inc>



COMMON CODE



; write byte into eeprom
;   param1: addr in eeprom
;   param2: byte to write
eeprom_write:
    global eeprom_write
    ; Set addr
    movf param1, W
    banksel EEADR
    movwf EEADR
    movlw 0
    movwf EEADRH
    ; Put data in register
    banksel param2
    movf param2, W
    banksel EEADR
    movwf EEDAT
    ; configure write
    banksel EECON1
    bcf EECON1, EEPGD
    bsf EECON1, WREN
    ;Disable IT.
eeprom_write_disable_it:
    bcf INTCON, GIE
    btfsc INTCON, GIE    ;SEE AN576
    goto eeprom_write_disable_it
    ; realize write operations cycle
    movlw 0x55
    movwf EECON2
    movlw 0xAA
    movwf EECON2
    ; Set WR bit to begin write
    bsf EECON1, WR
    ; Enable IT
    bsf INTCON, GIE

    ; Bank 0
    banksel 0x00

    ; wait end of write
eeprom_write_wait_end:
    btfss PIR2, EEIF
    goto eeprom_write_wait_end

    bcf PIR2, EEIF

    ; Disable writes
    bcf EECON1, WREN

    return

; read byte from eeprom
;   param1: addr in eeprom
; return read byte in W
eeprom_read:
    global eeprom_read

    ; Set addr
    movf param1, W;
    banksel EEADR
    movwf EEADR
    movlw 0
    movwf EEADRH
    ; Select read eeprom
    banksel EECON1
    bcf EECON1, EEPGD
    bsf EECON1, RD
    ; Get data
    banksel EEDAT
    movf EEDAT, W
    ; bank 0
    banksel 0x00

    return

END
