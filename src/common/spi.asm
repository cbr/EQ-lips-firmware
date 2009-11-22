; Driver for SPI controller of PIC16F690

#define SPI_M

#include <cpu.inc>
#include <global.inc>
#include <io.inc>
#include <delay.inc>
#include <spi.inc>

spi_send_w_and_wait macro
        ; send cmd
        movwf SSPBUF
        banksel SSPSTAT
        ; wait end of transmission
        btfss SSPSTAT, BF
        goto $ - 1
        banksel 0
    endm




PROG CODE

; init spi
;   no param
spi_init:
    global spi_init
    ; unset CS
    bsf SPI_CS_PORT, SPI_CS_BIT

    ; Configure spi
    banksel SSPSTAT
    movlw (1 << SMP) | (1 << CKE)
    movwf SSPSTAT

    bcf TRISC, 7
    bcf TRISB, 6


    ; Activate spi
    banksel 0
    movlw (1 << SSPEN)
    movwf SSPCON
    return




; send spi
;   param1: data to send
;   param2: cmd to send
spi_send:
    global spi_send
    ; set CS
    bcf SPI_CS_PORT, SPI_CS_BIT

    ; send cmd
    movf param1, W
    spi_send_w_and_wait

    ; send data
    movf param2, W
    spi_send_w_and_wait

    movlw 0
    spi_send_w_and_wait
    movlw 0
    spi_send_w_and_wait

    ; unset CS
    bsf SPI_CS_PORT, SPI_CS_BIT

    return

END
