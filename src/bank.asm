;;; Manage bank data: update, loading and saving

#define BANK_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <eeprom.inc>
#include <numpot.inc>
#include <bank.inc>

#define BANK_EESIZE_SHT     0x04


PROG_VAR_1 UDATA
    ;; GLOBAL
    ;; Sources data
bank_numpot_values_a RES BANK_NB_NUMPOT_VALUES
    global bank_numpot_values_a
bank_numpot_values_b RES BANK_NB_NUMPOT_VALUES
    global bank_numpot_values_b
bank_trem_type       RES 1
    global bank_trem_type
;;; amplitude of simple tremolo (in %)
bank_trem_rate       RES 1
    global bank_trem_rate
;;; number of inc value in a half period of tremolo (=speed of tremolo)
bank_nb_inc     RES 1
    global bank_nb_inc

    ;; LOCAL
bank_tmp     RES 1


; relocatable code
EQ_PROG CODE
;;; Save current eq values in eeprom
;;; param1: bank number
bank_save:
    global bank_save

    ;; set param1 to the start of bank in eeprom
    lshift_f param1, BANK_EESIZE_SHT
    ;; Prepare current value counter
    clrf bank_tmp

bank_save_loop:
    ;; Calculate value addr
    movlw potvalues
    addwf bank_tmp, W
    ;; Derefenrence value
    bankisel potvalues
    movwf FSR
    movf INDF, W
    ;; Put value in param2
    movwf param2
    ;; Store in eeprom
    call_other_page eeprom_write
    ;; next value
    incf param1, F
    incf bank_tmp, F
    ;; loop in order to store all values
    movf bank_tmp, W
    sublw (NUMPOT_NB_CHIP * NUMPOT_NB_POT_BY_CHIP)
    btfss STATUS, Z
    goto bank_save_loop

    return

;;; Load a memorized bank from eeprom to numpot
;;; param1: bank number
bank_load:
    global bank_load

    ;; set param1 to the start of bank in eeprom
    lshift_f param1, BANK_EESIZE_SHT
    ;; Prepare current value counter
    clrf bank_tmp

bank_load_loop:
    ;; Calculate value addr
    movlw potvalues
    addwf bank_tmp, W
    ;; Prepare pointer
    movwf FSR
    ;; Get value from eeprom
    call_other_page eeprom_read
    ;; Store in numpot memory
    banksel potvalues
    movwf INDF

    ;; next value
    incf param1, F
    incf bank_tmp, F
    ;; loop in order to store all values
    movf bank_tmp, W
    sublw (NUMPOT_NB_CHIP * NUMPOT_NB_POT_BY_CHIP)
    btfss STATUS, Z
    goto bank_load_loop

    return


END
