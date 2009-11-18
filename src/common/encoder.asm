; Driver for encoder

#define SPI_M

#include <cpu.inc>
#include <global.inc>
#include <io.inc>
#include <delay.inc>

#define ENCODER_DEFAULT_VALUE 0x9

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
    bsf INTCON, GIE
    ; Set default encoder value
    movlw ENCODER_DEFAULT_VALUE
    movwf encoder_value

    return


END
