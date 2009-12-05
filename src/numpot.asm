; Manages SPI-chained MPC420XX numeric potentiometers

#define LCD_M

#include <cpu.inc>
#include <global.inc>
#include <io.inc>
#include <spi.inc>
#include <delay.inc>


#define NUMPOT_NB_CHIP        0x05
#define NUMPOT_NB_POT_BY_CHIP

    UDATA
potvalues       RES 2*NUMPOT_NB_CHIP

; relocatable code
PROG CODE

numpot_send_chained_values macro command, num_pot_in_chip, nb_chip
    ;; send cmd
    movlw command
    spi_send_w_and_wait

    ;; send data
    banksel potvalues
    movf (potvalues + ((nb_chip - 1) * NUMPOT_NB_POT_BY_CHIP) + num_pot_in_chip), W
    spi_send_w_and_wait

    if (nb_chip > 0)
        numpot_send_chained_values command, num_pot_in_chip, nb_chip-1
    endif
    endm

;;; send all values to all chips
;;; used variables: var1
numpot_send_all:
    global numpot_send_all

    movf potvalues, W

    ; set CS
    banksel SPI_CS_PORT
    bcf SPI_CS_PORT, SPI_CS_BIT

    numpot_send_chained_values 0x13, 0, NUMPOT_NB_CHIP
    numpot_send_chained_values 0x13, 1, NUMPOT_NB_CHIP

    ;; unset CS
    banksel SPI_CS_PORT
    bsf SPI_CS_PORT, SPI_CS_BIT

    banksel 0

    return

END
