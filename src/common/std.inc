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
