#define TIMER_PERIOD_MS             .5

timer_it macro
    local timer_it_end

    ;; Check if timer interrupt flag is set
    banksel PIR1
    btfss PIR1, CCP1IF
    ;; -> Not set
    goto timer_it_end
    ;; -> Set
    incf timer_cpt, F
    ;; ack it
    bcf PIR1, CCP1IF
timer_it_end:
    endm

#ifndef TIMER_M
    extern timer_init
#endif
