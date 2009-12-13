; Driver for encoder

#define SPI_M

#include <cpu.inc>
#include <global.inc>
#include <io.inc>
#include <delay.inc>

#define ENCODER_DEFAULT_VALUE 0x9
#define ENCODER_DEFAULT_MIN_VALUE 0x00
#define ENCODER_DEFAULT_MAX_VALUE 0x15

    UDATA
encoder_min_value RES 1 ; encoder minimum value
    global encoder_min_value
encoder_max_value RES 1 ; encoder maximum value
    global encoder_max_value

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


END
