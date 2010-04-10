#define TIMER_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <timer.inc>


#define TIMER_CONFIG_PRESCALER      .8
#define TIMER_HARD_PRESCALLER       .4
#define TIMER_BASE_FREQ             .8000000
#define TIMER_NB_MS_IN_SEC          .1000

#define TIMER_VAL       (TIMER_PERIOD_MS*TIMER_BASE_FREQ)/(TIMER_NB_MS_IN_SEC*TIMER_CONFIG_PRESCALER*TIMER_HARD_PRESCALLER)

#define TIMER_VAL_HI    ((TIMER_VAL & 0xFF00) >> 8)
#define TIMER_VAL_LO    (TIMER_VAL & 0x00FF)


COMMON_VAR UDATA


; relocatable code
COMMON CODE

;;; Initialize a 10 ms tick using a hardware timer
;;; param1: addrl of function to be called at each tick
;;; param2: addrh of function to be called at each tick
timer_init:
    global timer_init

    ;; Prescaller 1:8
    banksel T1CON
    bsf T1CON, T1CKPS0
    bsf T1CON, T1CKPS1
    ;; compare mode, trigger special event
    banksel CCP1CON
    bsf CCP1CON, CCP1M0
    bsf CCP1CON, CCP1M1
    bcf CCP1CON, CCP1M2
    bsf CCP1CON, CCP1M3
    ;; Set compare value
    banksel CCPR1H
    movlw TIMER_VAL_HI
    movwf CCPR1H
    movlw TIMER_VAL_LO
    movwf CCPR1L
    ;; Enable it for ccp1
    banksel PIE1
    bsf PIE1, CCP1IE
    banksel INTCON
    bsf INTCON, PEIE
    ;; Timer1 ON
    banksel T1CON
    bsf T1CON, TMR1ON

    return
END
