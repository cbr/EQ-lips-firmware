


interrupt_enable macro
    bsf INTCON, GIE
    endm

interrupt_disable macro
    local interrupt_disable_loop
interrupt_disable_loop:
    bcf INTCON, GIE
    btfsc INTCON, GIE    ;SEE AN576
    goto interrupt_disable_loop
    endm
