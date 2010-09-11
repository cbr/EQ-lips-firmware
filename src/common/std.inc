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


#define UNUSED_PARAM        "0"

lshift_f macro reg, value
    if (value != 0)
        bcf STATUS, C
        rlf reg, F
        lshift_f reg, (value-1)
    endif
    endm

rshift_f macro reg, value
    if (value != 0)
        bcf STATUS, C
        rrf reg, F
        rshift_f reg, (value-1)
    endif
    endm

goto_other_page macro label
    pagesel label
    goto label
    endm

call_other_page macro label
    pagesel label
    call label
    pagesel $
    endm

call_indirect macro reg_lo, reg_hi
    local call_indirect_push
    local call_indirect_end

    call call_indirect_push
    pagesel $
    goto call_indirect_end
call_indirect_push:
    banksel reg_hi
    movf reg_hi, W
    movwf PCLATH
    banksel reg_lo
    movf reg_lo, W
    movwf PCL

call_indirect_end:
    endm

mem_clear macro base_addr, length
    if (length > 0)
        clrf base_addr
        mem_clear (base_addr+1), (length-1)
    endif
    endm

mem_set macro base_addr, length, value
    if (length > 0)
        movlw value
        movwf base_addr
        mem_set (base_addr+1), (length-1), value
    endif
    endm

#ifndef STD_M
    extern std_strlen
#endif
