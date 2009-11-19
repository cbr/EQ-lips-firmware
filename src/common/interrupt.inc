


interrupt_enable macro
    bsf INTCON, GIE
    endm

interrupt_disable macro
    bcf INTCON, GIE
    endm
