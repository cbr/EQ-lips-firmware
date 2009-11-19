; Driver for encoder

#define SPI_M

#include <cpu.inc>
#include <global.inc>
#include <io.inc>
#include <delay.inc>

#define ENCODER_DEFAULT_VALUE 0x9
#define ENCODER_DEFAULT_MIN_VALUE 0x00
#define ENCODER_DEFAULT_MAX_VALUE 0x15

PROG CODE

; init encoder
;   no param
encoder_init
    global encoder_init

    ; configure ENC_A and ENC_B
    ; Activate interrupt for ENC_A
    banksel IOCB
    bsf IOCB, ENC_A_BIT
    ; Activate interrupt for PORTA/PORTB change
    banksel 0
#ifdef RABIE
    bsf INTCON, RABIE
#else
    bsf INTCON, RBIE
#endif
    ; Set default encoder values
    movlw ENCODER_DEFAULT_VALUE
    movwf encoder_value
    movlw ENCODER_DEFAULT_MIN_VALUE
    movwf encoder_min_value
    movlw ENCODER_DEFAULT_MAX_VALUE
    movwf encoder_max_value

    return


END
