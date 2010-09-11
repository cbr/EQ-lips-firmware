;;;
;;; Copyright 2010 Cedric Bregardis.
;;;
;;; This file is part of EQ-lips firmware.
;;;
;;; EQ-lips firmware is free software: you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundation, version 3 of the
;;; License.
;;;
;;; EQ-lips firmware is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with EQ-lips firmware.  If not, see <http://www.gnu.org/licenses/>.
;;;

; Driver for EEPROM controller of PIC16F690

#define EEPROM_M

#include <cpu.inc>
#include <global.inc>
#include <delay.inc>
#include <eeprom.inc>
#include <interrupt.inc>


COMMON CODE



;;; write byte into eeprom
;;;   param1: addr in eeprom
;;;   param2: byte to write
eeprom_write:
    global eeprom_write
    ;; Set addr
    movf param1, W
    banksel EEADR
    movwf EEADR
    clrf EEADRH
    ;; Put data in register
    banksel param2
    movf param2, W
    banksel EEADR
    movwf EEDAT
    ;; configure write
    banksel EECON1
    bcf EECON1, EEPGD
    bsf EECON1, WREN
    ;;Disable IT.
    interrupt_disable
    ;; realize write operations cycle
    movlw 0x55
    movwf EECON2
    movlw 0xAA
    movwf EECON2
    ;; Set WR bit to begin write
    bsf EECON1, WR
    ;; Enable IT
    interrupt_enable

    ;; Bank 0
    banksel 0x00

    ;; wait end of write
eeprom_write_wait_end:
    btfss PIR2, EEIF
    goto eeprom_write_wait_end

    bcf PIR2, EEIF

    ;; Disable writes
    bcf EECON1, WREN

    return

; read byte from eeprom
;   param1: addr in eeprom
; return read byte in W
eeprom_read:
    global eeprom_read

    ;; Set addr
    movf param1, W;
    banksel EEADR
    movwf EEADR
    clrf EEADRH
    ;; Select read eeprom
    banksel EECON1
    bcf EECON1, EEPGD
    bsf EECON1, RD
    ;; Get data
    banksel EEDAT
    movf EEDAT, W
    ;; bank 0
    banksel 0x00

    return

END
