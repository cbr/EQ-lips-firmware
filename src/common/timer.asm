#define TIMER_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <timer.inc>
#include <io.inc>


    UDATA_SHR
timer_cpt       RES 1
    global timer_cpt;

    COMMON_VAR UDATA
var1    RES 1

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
#warning timer without ECCP not tested !
    ;; Prescaller 1:8
    banksel T1CON
    bsf T1CON, T1CKPS0
    bsf T1CON, T1CKPS1
    ;; Choose low power oscillator
    banksel T1CON
    bsf T1CON, T1OSCEN

    bsf TMR1CS, T1CON
    bsf NOT_T1SYNC, T1CON
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

;;; Enable timer 1
timer_enable:
    global timer_enable
#if 1
    banksel T1CON
    bsf T1CON, T1OSCEN
    ;; Set timer value
    banksel TMR1H
    movlw TIMER_VAL_HI
    movwf TMR1H
    banksel TMR1L
    movlw TIMER_VAL_LO
    movwf TMR1L
#else
    ;; Set timer value
    banksel TMR1H
    movlw TIMER_VAL_HI
    movwf TMR1H
    banksel TMR1L
    movlw TIMER_VAL_LO
    movwf TMR1L

    ;; Save PORTC value
    ;; banksel PORTC
    ;; movf PORTC, W
    ;; banksel var1
    ;; movwf var1

#if 1
    banksel T1CON
    bsf T1CON, T1OSCEN
#endif

    ;; Timer1 ON
    banksel T1CON
    bsf T1CON, TMR1ON
#endif
    return

;;; Disable timer 1
timer_disable:
    global timer_disable
#if 1
    banksel T1CON
    bcf T1CON, T1OSCEN
    banksel LCD_E1_TRIS
    bcf LCD_E1_TRIS, LCD_E1_BIT
    bcf LCD_E2_TRIS, LCD_E2_BIT
    banksel LCD_E1_PORT
    bcf LCD_E1_PORT, LCD_E1_BIT
    bcf LCD_E2_PORT, LCD_E2_BIT
#else
    ;; Timer1 Off
    banksel T1CON
    bcf T1CON, TMR1ON

    ;; Restore PORTC value
    ;; banksel var1
    ;; movf var1, W
    ;; banksel PORTC
    ;; movwf PORTC
    ;; Restore TRISC config
    banksel TRISC
    bcf TRISC, 0
    bcf TRISC, 1
#endif
    return
END
