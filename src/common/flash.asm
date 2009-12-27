#define FLASH_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <flash.inc>



    UDATA
var1       RES 1


; relocatable code
COMMON CODE

;;; Get flash data from an address and an offset
;;; Read data is put in W.
;;; param1: addrl of null terminated string
;;; param2: addrh of null terminated string
;;; param3: offset
flash_get_data:
    global flash_get_data
    ;;  set base_addr to read
    banksel EEADR
    movf param1, W
    movwf EEADRH
    movf param2, W
    movwf EEADR

    ;; add offset
    ;; bcf STATUS, C
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
