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
