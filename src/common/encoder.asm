; Driver for encoder

#define SPI_M

#include <cpu.inc>
#include <global.inc>
#include <io.inc>
#include <delay.inc>
#include <interrupt.inc>

#define ENCODER_DEFAULT_VALUE 0x9
#define ENCODER_DEFAULT_MIN_VALUE 0x00
#define ENCODER_DEFAULT_MAX_VALUE 0x15

    UDATA
encoder_min_value RES 1 ; encoder minimum value
    global encoder_min_value
encoder_max_value RES 1 ; encoder maximum value
    global encoder_max_value
encoder_reg_last_value RES 1 ; register B last value
    global encoder_reg_last_value
encoder_reg_current_value RES 1 ; register B current value
    global encoder_reg_current_value

COMMON CODE

; init encoder
;   no param
encoder_init:
    global encoder_init

    ; configure ENC_A and ENC_B
    ; Activate interrupt for ENC_A
    banksel IOCB
    bsf IOCB, ENC_A_BIT
    ; Activate interrupt for ENC_SW
    bsf IOCB, ENC_SW_BIT
    ; Activate interrupt for PORTA/PORTB change
    banksel 0
#ifdef RABIE
    bsf INTCON, RABIE
#else
    bsf INTCON, RBIE
#endif
    ;; init encoder_sw counter
    clrf encoder_sw
    ; Set default encoder values
    movlw ENCODER_DEFAULT_VALUE
    movwf encoder_value
    movlw ENCODER_DEFAULT_MIN_VALUE
    banksel encoder_min_value
    movwf encoder_min_value
    movlw ENCODER_DEFAULT_MAX_VALUE
    banksel encoder_max_value
    movwf encoder_max_value
    banksel 0

    return


;;;
;;; param1: current_value
;;; param2: value_min
;;; param3: value_max
encoder_set_value:
    global encoder_set_value
    interrupt_disable
    movf param1, W
    movwf encoder_value
    movf param2, W
    banksel encoder_min_value
    movwf encoder_min_value
    movf param3, W
    banksel encoder_max_value
    movwf encoder_max_value
    interrupt_enable
    banksel 0
    return

END
