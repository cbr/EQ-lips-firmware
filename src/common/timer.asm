#define TIMER_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <timer.inc>



COMMON_VAR UDATA


; relocatable code
COMMON CODE

;;; Initialize a 10 ms tick using a hardware timer
;;; param1: addrl of function to be called at each tick
;;; param2: addrh of function to be called at each tick
timer_init:
    global timer_init

#ifdef TIMER_WITH_ECCP
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
#else
    ;; Prescaller 1:8
    banksel T1CON
    bsf T1CON, T1CKPS0
    bsf T1CON, T1CKPS1
    ;; Choose low power oscillator
#if 0
    banksel T1CON
    bsf T1CON, T1OSCEN
#endif
    ;; Enable IT for timer1
    banksel PIE1
    bsf PIE1, TMR1IE
    bsf INTCON, PEIE
    ;; Set timer value
    banksel TMR1H
    movlw TIMER_VAL_HI
    movwf TMR1H
    banksel TMR1L
    movlw TIMER_VAL_LO
    movwf TMR1L
#endif

    ;; Timer1 ON
    banksel T1CON
    bsf T1CON, TMR1ON

    return
END
