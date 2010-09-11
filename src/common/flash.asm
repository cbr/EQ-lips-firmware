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

#define FLASH_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <flash.inc>



; relocatable code
COMMON CODE

;;; Get flash data from an address and an offset
;;; Read data is put in W.
;;; param1: addrl of base address
;;; param2: addrh of base address
;;; param3: offset
;;; changed registers: EEADR, EEADRH, EECON1
flash_get_data:
    global flash_get_data
    ;;  set base_addr to read
    banksel EEADR
    movf param1, W
    movwf EEADR
    movf param2, W
    movwf EEADRH

    ;; add offset
    movf param3, W
    addwf EEADR, F
    btfsc STATUS, C
    incf EEADRH, F

    ;;  read  flash
    banksel EECON1
    bsf EECON1, EEPGD
    bsf EECON1, RD
    nop
    nop

    ;; get data
    banksel EEDAT
    movf EEDAT, W
    banksel 0
    return
END
