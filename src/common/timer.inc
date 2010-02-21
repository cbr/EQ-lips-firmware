
timer_it macro
    local timer_it_end

    ;; Check if timer interrupt flag is set
    banksel PIR1
    btfss PIR1, CCP1IF
    ;; -> Not set
    goto timer_it_end
    ;; -> Set
    ;; Call tick hook
    call_indirect timer_tick_hook_lo, timer_tick_hook_hi
    ;; ack it
    bcf PIR1, CCP1IF
timer_it_end:
    endm

#ifndef TIMER_M
    extern timer_tick_hook_lo
    extern timer_tick_hook_hi

    extern timer_init
#endif
