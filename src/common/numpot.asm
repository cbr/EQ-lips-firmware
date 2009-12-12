; Manages SPI-chained MPC420XX numeric potentiometers

#define NUMPOT_M

#include <cpu.inc>
#include <global.inc>
#include <io.inc>
#include <spi.inc>
#include <delay.inc>
#include <std.inc>
#include <numpot.inc>

;;; Number of chained chips.
#define NUMPOT_NB_CHIP              0x06

;;; Number of left shift to obtain NUMPOT_NB_POT_BY_CHIP
#define NUMPOT_NB_POT_BY_CHIP_SHT   0x01

;;; Number of potentiometer in one chip
;;; This value has to be a power of two
#define NUMPOT_NB_POT_BY_CHIP       (0x01 << NUMPOT_NB_POT_BY_CHIP_SHT)

;;; Command spi value of MPC420XX
#define NUMPOT_SPI_COMMAND          0x10

    UDATA
potvalues           RES NUMPOT_NB_POT_BY_CHIP*NUMPOT_NB_CHIP
    global potvalues
remaining_chip      RES 1
num_pot             RES 1
num_pot_in_cmd      RES 1
tmp                 RES 1

; relocatable code
COMMON CODE

numpot_send_chained_values macro command, num_pot_in_chip, nb_chip
    ;; send cmd
    movlw command
    spi_send_w_and_wait

    ;; send data
    banksel potvalues
    movf (potvalues + ((nb_chip - 1) * NUMPOT_NB_POT_BY_CHIP) + num_pot_in_chip), W
    spi_send_w_and_wait

    if (nb_chip > 1)
        numpot_send_chained_values command, num_pot_in_chip, nb_chip-1
    endif
    endm

;;; send all values to all chips
;;; Changed registers: none
numpot_send_all_old:
    global numpot_send_all_old

    ; set CS
    banksel SPI_CS_PORT
    bcf SPI_CS_PORT, SPI_CS_BIT

    numpot_send_chained_values 0x11, 0, NUMPOT_NB_CHIP

    ;; unset CS
    banksel SPI_CS_PORT
    bsf SPI_CS_PORT, SPI_CS_BIT

    ; set CS
    banksel SPI_CS_PORT
    bcf SPI_CS_PORT, SPI_CS_BIT

    numpot_send_chained_values 0x12, 1, NUMPOT_NB_CHIP

    ;; unset CS
    banksel SPI_CS_PORT
    bsf SPI_CS_PORT, SPI_CS_BIT

    banksel 0

    return


    ;;; send all values to all chips
    ;;; used variables: var1
numpot_send_all:
    global numpot_send_all

    banksel num_pot
    movlw 0
    movwf num_pot
    banksel num_pot_in_cmd
    movlw 1
    movwf num_pot_in_cmd

numpot_send_all_next_pot_series:
    banksel remaining_chip
    movlw NUMPOT_NB_CHIP
    movwf remaining_chip

    ;; set CS
    banksel SPI_CS_PORT
    bcf SPI_CS_PORT, SPI_CS_BIT
numpot_send_all_next_chip:
    ;; Send command
    movlw NUMPOT_SPI_COMMAND
    iorwf num_pot_in_cmd, W
    spi_send_w_and_wait

    ;; Calculate pot value address:
    ;; address = &potvalues + ((remaining_chip - 1) * NUMPOT_NB_POT_BY_CHIP) + num_pot)
    ;; w = remaining_chip-1
    decf remaining_chip, W
    ;; tmp = w
    movwf tmp
    ;; tmp = tmp << NUMPOT_NB_POT_BY_CHIP_SHT
    lshift_f tmp, NUMPOT_NB_POT_BY_CHIP_SHT
    ;; W = tmp + &potvalues
    movlw potvalues
    addwf tmp, W
    ;; W = W + num_pot
    addwf num_pot, W

    ;; Get pot value (in W)
    movwf FSR
    movf INDF, W

    ;; Send pot value
    spi_send_w_and_wait

    ;; next chip
    decfsz remaining_chip, F
    goto numpot_send_all_next_chip

    ;; unset CS
    banksel SPI_CS_PORT
    bsf SPI_CS_PORT, SPI_CS_BIT

    ;; next pot in chips
    banksel num_pot_in_cmd
    rlf num_pot_in_cmd, F
    banksel num_pot
    incf num_pot, F
    movlw NUMPOT_NB_POT_BY_CHIP
    subwf num_pot, W
    btfss STATUS, Z
    goto numpot_send_all_next_pot_series

    banksel 0

    return

;;; Set internal value of a potentiometer.
;;; The value is stored but transmitted to tye real potentiometer
;;; param1: potentiometer number
;;; param2: value
;;; Changed registers: none
numpot_set_one_value:
    global numpot_set_one_value
    movlw potvalues
    addwf param1, W
    ;; INDF and FSR are mapped on all pages, so non banksel is needed
    movwf FSR
    movf param2, W
    movwf INDF
    return
END
