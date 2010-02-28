;;; Manage bank data: update, loading and saving

#define BANK_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <eeprom.inc>
#include <bank.inc>

#define BANK_EESIZE_SHT     0x04


PROG_VAR_1 UDATA
    ;; GLOBAL
    ;; Sources data
bank_numpot_values RES BANK_NB_NUMPOT_VALUES
    global bank_numpot_values
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
;;; Save current parameters into bank
;;; param1: bank number
bank_save:
    global bank_save

    ;; save numpot values
    movlw bank_numpot_values
    movwf param2
    bankisel bank_numpot_values
    call bank_save_eq_gain
    ;; param1 have been set to the next eeprom position
    ;; in the previous function -> don't need to prepare it

    ;; save trem type
    banksel bank_trem_type
    movf bank_trem_type, W
    movwf param2
    call_other_page eeprom_write
    incf param1, F

    ;; save trem rate
    banksel bank_trem_rate
    movf bank_trem_rate, W
    movwf param2
    call_other_page eeprom_write
    incf param1, F

    ;; save nb inc
    banksel bank_nb_inc
    movf bank_nb_inc, W
    movwf param2
    call_other_page eeprom_write

    return

;;; Load parameters from bank
;;; param1: bank number
bank_load:
    global bank_load

    ;; load numpot values
    movlw bank_numpot_values
    movwf param2
    bankisel bank_numpot_values
    call bank_load_eq_gain
    ;; param1 have been set to the next eeprom position
    ;; in the previous function -> don't need to prepare it

    ;; save trem type
    call_other_page eeprom_read
    banksel bank_trem_type
    movwf bank_trem_type
    incf param1, F

    ;; save trem rate
    call_other_page eeprom_read
    banksel bank_trem_rate
    movwf bank_trem_rate
    incf param1, F

#if 0
    ;; save nb inc
    call_other_page eeprom_write
    banksel bank_nb_inc
    movwf bank_nb_inc
#endif
    return

;;; Save current eq and gain values into a bank
;;; param1: bank number
;;; param2: address of buffer from which equalizer and gain config are read.
;;;         IRP bit of STATUS register must be correctly set before calling
;;;         this function in order to read the value with the help of FSR/INDF.
;;; Changed registers: param3
bank_save_eq_gain:
    global bank_save

    ;; set param1 to the start of bank in eeprom
    lshift_f param1, BANK_EESIZE_SHT
    ;; Prepare current value counter
    banksel bank_tmp
    clrf bank_tmp
    ;; Save param2 into param3
    movf param2, W
    movwf param3
bank_save_loop:
    ;; Calculate value addr
    movf param3, W
    banksel bank_tmp
    addwf bank_tmp, W
    ;; Derefenrence value
    movwf FSR
    movf INDF, W
    ;; Put value in param2
    movwf param2
    ;; Store in eeprom
    call_other_page eeprom_write
    ;; next value
    incf param1, F
    banksel bank_tmp
    incf bank_tmp, F
    ;; loop in order to store all values
    movf bank_tmp, W
    sublw BANK_NB_NUMPOT_VALUES
    btfss STATUS, Z
    goto bank_save_loop

    return

;;; Load the eq and gain values from a memorized bank to numpot
;;; param1: bank number
;;; param2: address of buffer which will receive equalizer and gain config.
;;;         IRP bit of STATUS register must be correctly set before calling
;;;         this function in order to read the value with the help of FSR/INDF.
bank_load_eq_gain:
    global bank_load

    ;; set param1 to the start of bank in eeprom
    lshift_f param1, BANK_EESIZE_SHT
    ;; Prepare current value counter
    banksel bank_tmp
    clrf bank_tmp

bank_load_loop:
    ;; Calculate value addr
    movf param2, W
    banksel bank_tmp
    addwf bank_tmp, W
    ;; Prepare pointer
    movwf FSR
    ;; Get value from eeprom
    call_other_page eeprom_read
    ;; Store in numpot memory
    movwf INDF

    ;; next value
    incf param1, F
    banksel bank_tmp
    incf bank_tmp, F
    ;; loop in order to store all values
    movf bank_tmp, W
    sublw BANK_NB_NUMPOT_VALUES
    btfss STATUS, Z
    goto bank_load_loop

    return


END
