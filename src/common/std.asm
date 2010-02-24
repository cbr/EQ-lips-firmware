#define STD_M


#include <cpu.inc>
#include <global.inc>
#include <io.inc>
#include <flash.inc>

    UDATA

;;; relocatable code
COMMON CODE

;;; Return in W the length of the string given in parameter
;;; param1: addrl of null terminated string
;;; param2: addrh of null terminated string
;;; changed registers: param3
std_strlen:
    global std_strlen
    clrf param3
    ;; Loop until char '0' is found
std_strlen_loop:
    call flash_get_data
    sublw 0
    btfsc STATUS, Z
    goto std_strlen_end
    incf param3, F
    goto std_strlen_loop

std_strlen_end:
    ;; The number of char is in param3.
    ;; Put it in W
    movf param3, W

    return

END
