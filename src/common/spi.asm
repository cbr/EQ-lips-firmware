; Driver for SPI controller of PIC16F690

#define SPI_M

#include <cpu.inc>
#include <global.inc>
#include <io.inc>
#include <delay.inc>
#include <spi.inc>

COMMON CODE

; init spi
;   no param
spi_init:
    global spi_init
    ;; unset CS
    banksel SPI_CS_PORT
    bsf SPI_CS_PORT, SPI_CS_BIT

    ;; Configure spi
    banksel SSPSTAT
    movlw (1 << SMP) | (1 << CKE)
    movwf SSPSTAT

    ;;  Configure SPI pins
    banksel SPI_SDO_TRIS
    bcf SPI_SDO_TRIS, SPI_SDO_BIT
    banksel SPI_SCL_TRIS
    bcf SPI_SCL_TRIS, SPI_SCL_BIT


    ;; Activate SPI
    banksel SSPCON
    movlw (1 << SSPEN)
    movwf SSPCON
    banksel 0
    return




END
