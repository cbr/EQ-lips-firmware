; Manages SPI-chained MPC420XX numeric potentiometers

#define NUMPOT_M

#include <cpu.inc>
#include <global.inc>
#include <io.inc>
#include <spi.inc>
#include <delay.inc>
#include <std.inc>
#include <numpot.inc>
#include <flash.inc>
#define NUMPOT_MAPPING

#define NUMPOT_INVERT_VALUES

;;; Command spi value of MPC420XX
#define NUMPOT_SPI_COMMAND          0x10

;;; Max value
#define NUMPOT_MAX_VALUE            0xFF

COMMON_VAR UDATA
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

;;;
;;; send all values to all chips
;;; used variables: var1
;;;
numpot_send_all:
    global numpot_send_all

    banksel num_pot
    clrf num_pot
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
    bankisel potvalues
    movwf FSR
    movf INDF, W
#ifdef NUMPOT_MAPPING
    flash_get_data_w numpot_mapping
#endif
#ifdef NUMPOT_INVERT_VALUES
    ;; Values are inverted
    sublw NUMPOT_MAX_VALUE
#endif
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
    bcf STATUS, C
    rlf num_pot_in_cmd, F
    banksel num_pot
    incf num_pot, F
    movlw NUMPOT_NB_POT_BY_CHIP
    subwf num_pot, W
    btfss STATUS, Z
    goto numpot_send_all_next_pot_series

    banksel 0

    return

;;;
;;; Set internal value of a potentiometer.
;;; The value is stored but transmitted to tye real potentiometer
;;; param1: potentiometer number
;;; param2: value
;;; Changed registers: none
;;;
numpot_set_one_value:
    global numpot_set_one_value
    movlw potvalues
    addwf param1, W
    movwf FSR
    bankisel potvalues
    movf param2, W
    movwf INDF
    return

#ifdef NUMPOT_MAPPING
numpot_mapping:
#include <numpot_mapping.inc>
#endif

    END
