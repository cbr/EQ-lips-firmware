#define TIMER_PERIOD_MS             .50

;;; Uncomment the following define in order to manage timer1 with
;;; ECCP (Enhanced Capture/Compare/PWM). This kind of timer is more
;;; precise, however it is stopped in sleep mode.
;; #define TIMER_WITH_ECCP

#define TIMER_CONFIG_PRESCALER      .8
#define TIMER_HARD_PRESCALLER       .4
#define TIMER_BASE_FREQ             .8000000
#define TIMER_NB_MS_IN_SEC          .1000
;; #define TIMER_LP_OSC                .8000000
#define TIMER_LP_OSC                .32768
#define TIMER_OVERFLOW_VALUE        0xFFFF

#ifdef TIMER_WITH_ECCP
#define TIMER_VAL       (TIMER_PERIOD_MS*TIMER_BASE_FREQ)/(TIMER_NB_MS_IN_SEC*TIMER_CONFIG_PRESCALER*TIMER_HARD_PRESCALLER)
#else
#define TIMER_VAL       (TIMER_OVERFLOW_VALUE - ((TIMER_PERIOD_MS*TIMER_LP_OSC)/(TIMER_NB_MS_IN_SEC*TIMER_CONFIG_PRESCALER*TIMER_HARD_PRESCALLER)))
#endif

#define TIMER_VAL_HI    ((TIMER_VAL & 0xFF00) >> 8)
#define TIMER_VAL_LO    (TIMER_VAL & 0x00FF)

timer_it macro
    local timer_it_end

#ifdef TIMER_WITH_ECCP
    ;; Check if timer interrupt flag is set
    banksel PIR1
    btfss PIR1, CCP1IF
    ;; -> Not set
    goto timer_it_end
    ;; -> Set
    incf timer_cpt, F
    ;; ack it
    bcf PIR1, CCP1IF
#else

    ;; Check if timer interrupt flag is set
    banksel PIR1
    btfss PIR1, TMR1IF
    ;; -> Not set
    goto timer_it_end
    ;; -> Set
    incf timer_cpt, F

    ;; Timer1 OFF
    ;; banksel T1CON
    ;; bcf T1CON, TMR1ON

    ;; Set timer value
    banksel TMR1H
    movlw TIMER_VAL_HI
    movwf TMR1H
    banksel TMR1L
    movlw TIMER_VAL_LO
    movwf TMR1L

    ;; Timer1 ON
    ;; banksel T1CON
    ;; bsf T1CON, TMR1ON

    ;; ack it
    banksel PIR1
    bcf PIR1, TMR1IF
#endif
timer_it_end:
    endm

#ifndef TIMER_M
    extern timer_cpt

    extern timer_init
    extern timer_enable
    extern timer_disable
#endif
