;;; Manage dialog screen for eqalizer editing

#define EDIT_EQ_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <lcd.inc>
#include <menu.inc>
#include <menu_button.inc>
#include <menu_eq.inc>
#include <menu_edit.inc>
#include <encoder.inc>
#include <interrupt.inc>
#include <numpot.inc>
#include <eeprom.inc>
#include <math.inc>
;; #include <menu_label.inc>

#define NB_NUMPOT_VALUES            0xB

#define EDIT_EQ_BANK_EESIZE_SHT     0x04

#define TREM_TYPE_NONE              0x00
#define TREM_TYPE_SIMPLE            0x01
#define TREM_TYPE_EQ                0x02

#define UPDATE_ONE_TIME             0x01
#define UPDATE_EVERY_TIME           0x02

#define SHIFT_NUMPOT_VAL_TO_HIGH_ORDER  0x03

PROG_VAR_1 UDATA
edit_eq_tmp     RES 1
gain16          RES 2
inc             RES 2
trem_nb_val     RES 1
    ;; Sources data
numpot_values_a RES NB_NUMPOT_VALUES
numpot_values_b RES NB_NUMPOT_VALUES
trem_type       RES 1
;;; amplitude of simple tremolo (in %)
trem_rate       RES 1
;;; number of inc value in a half period of tremolo (=speed of tremolo)
trem_nb_inc     RES 1
trem_inc_cpt    RES 1
;;; Data update info. Tell if numpot have to be updated or not.
;;; If this value is not 0, then data have to be updated.
;;; Bit UPDATE_ONE_TIME tell to only update data one time, and bit
;;; UPDATE_EVERY_TIME tell to update data at every tick.
update_info     RES 1
;;; Loop index used to update numpot next values
index           RES 1

    ;; Temporary activation data
PROG_VAR_2 UDATA
all_numpot_16   RES (2*NB_NUMPOT_VALUES)
all_inc_16      RES (2*NB_NUMPOT_VALUES)


; relocatable code
EQ_PROG CODE
st_bank:
    dt "BANK: ", 0
st_load:
    dt "LOAD", 0
st_save:
    dt "SAVE", 0

edit_eq_save:
    global edit_eq_save
    movf current_bank, W
    movwf param1
    decf param1, F
    call edit_eq_save_bank
    return

edit_eq_load:
    global edit_eq_save
    movf current_bank, W
    movwf param1
    decf param1, F
    call edit_eq_load_bank
    call_other_page numpot_send_all
    menu_ask_refresh
    return

edit_eq_show:
    global edit_eq_show

    ;; call prepare_trem

    movlw 1
    movwf current_bank
    menu_start data_update
    ;; menu_label_int 0, current_bank
    menu_edit st_bank, 1, 1, 0x10, current_bank, edit_eq_load, 0
    menu_edit_no_show st_save, 2, 1, 0x10, current_bank, edit_eq_refreh, edit_eq_save
    menu_eq (0x5*0 + 0x3D), potvalues, numpot_send_all
    menu_eq (0x5*1 + 0x3D), potvalues+1, numpot_send_all
    menu_eq (0x5*2 + 0x3D), potvalues+2, numpot_send_all
    menu_eq (0x5*3 + 0x3D), potvalues+3, numpot_send_all
    menu_eq (0x5*4 + 0x3D), potvalues+4, numpot_send_all
    menu_eq (0x5*5 + 0x3D), potvalues+5, numpot_send_all
    menu_eq (0x5*6 + 0x3D), potvalues+6, numpot_send_all
    menu_eq (0x5*7 + 0x3D), potvalues+7, numpot_send_all
    menu_eq (0x5*8 + 0x3D), potvalues+8, numpot_send_all
    menu_eq (0x5*9 + 0x3D), potvalues+9, numpot_send_all
    menu_eq (0x5*0xB + 0x3D), potvalues+0xA, numpot_send_all
    menu_end


;;; Save current eq values in eeprom
;;; param1: bank number
edit_eq_save_bank:
    ;; set param1 to the start of bank in eeprom
    lshift_f param1, EDIT_EQ_BANK_EESIZE_SHT
    ;; Prepare current value counter
    clrf edit_eq_tmp

edit_eq_save_bank_loop:
    ;; Calculate value addr
    movlw potvalues
    addwf edit_eq_tmp, W
    ;; Derefenrence value
    movwf FSR
    movf INDF, W
    ;; Put value in param2
    movwf param2
    ;; Store in eeprom
    call_other_page eeprom_write
    ;; next value
    incf param1, F
    incf edit_eq_tmp, F
    ;; loop in order to store all values
    movf edit_eq_tmp, W
    sublw (NUMPOT_NB_CHIP * NUMPOT_NB_POT_BY_CHIP)
    btfss STATUS, Z
    goto edit_eq_save_bank_loop

    return

;;; Load a memorized bank from eeprom to numpot
;;; param1: bank number
edit_eq_load_bank:
    ;; set param1 to the start of bank in eeprom
    lshift_f param1, EDIT_EQ_BANK_EESIZE_SHT
    ;; Prepare current value counter
    clrf edit_eq_tmp

edit_eq_load_bank_loop:
    ;; Calculate value addr
    movlw potvalues
    addwf edit_eq_tmp, W
    ;; Prepare pointer
    movwf FSR
    ;; Get value from eeprom
    call_other_page eeprom_read
    ;; Store in numpot memory
    movwf INDF

    ;; next value
    incf param1, F
    incf edit_eq_tmp, F
    ;; loop in order to store all values
    movf edit_eq_tmp, W
    sublw (NUMPOT_NB_CHIP * NUMPOT_NB_POT_BY_CHIP)
    btfss STATUS, Z
    goto edit_eq_load_bank_loop

    return

edit_eq_refreh:
    menu_ask_refresh
    return

;;; function called when bank have to be changed
edit_eq_bank_change:
    ;; nothing to do
    return


#if 0
prepare_trem
    ;; init gain16
    banksel gain16
    movlw .16
    movwf gain16+1
    lshift_f gain16+1, 3
    clrf gain16

    ;; init inc
    ;; inc = amplitude / nb_val
    ;; inc = 16 (shifted) / nb_val
    ;; inc = 0x4000 / 50 = 0x147
    banksel inc
    movlw 0x47
    movwf inc
    movlw 0x01
    movwf inc+1

    ;; init nb val
    banksel trem_nb_val
    movlw 0x32
    movwf trem_nb_val
    return

trem_manage:
    ;; increment gain value
    ;; gain16 = gain16 + inc
    math_copy_16 gain16, number_a
    math_copy_16 inc, number_b
    math_banksel
    call_other_page math_add_1616s
    math_copy_16 number_b, gain16

    ;; Set gain value (keep only 5 high order bits)
    banksel gain16
    movf gain16+1, W
    movwf param2
    rshift_f param2, 3
    ;; gain is pot 9
    movlw 0xA
    movwf param1
    call_other_page numpot_set_one_value
    ;; incf tst_timer, F

    ;; send values
    call_other_page numpot_send_all

    ;; prepare next val
    banksel trem_nb_val
    decfsz trem_nb_val, F
    goto trem_manage_end
    ;; reinit nb_val
    movlw 0x32
    movwf trem_nb_val
    ;; inverse inc
    math_copy_16 inc, number_a
    math_banksel
    call_other_page math_neg_number_a_16s
    math_copy_16 number_a, inc
trem_manage_end:
    banksel 0
    return
#endif

;;;
;;; Function called when input data have been changed
;;; (because of gui data change or bank load)
;;;
data_change:
    ;; Reset all_inc_16 and all_numpot_16

    ;; clear all_inc_16
    mem_clear all_inc_16, (2*11)

    ;; Manage simple tremolo

    ;; inc = amplitude / trem_nb_inc
    ;; inc = (numpot_values_a - (numpot_values_a * trem_rate / 100)) / trem_nb_inc
    ;; inc = 16 (shifted) / trem_nb_inc
    ;; inc = 0x4000 / trem_nb_inc = 0x147

    ;; Calculate numpot_values_a * trem_rate / 100
#if 1
    ;; For testing
    banksel all_numpot_16
    movlw .16
    movwf all_numpot_16+(0xA*2)+1
    lshift_f all_inc_16+(0xA*2)+1, 3
    clrf all_numpot_16+(0xA*2)

    banksel trem_nb_inc
    movlw 0x32
    movwf trem_nb_inc

    banksel trem_inc_cpt
    clrf trem_inc_cpt

    banksel all_inc_16
    movlw 0x47
    movwf all_inc_16+(0xA*2)
    movlw 0x01
    movwf all_inc_16+(0xA*2)+1
#endif
    return



;;;
;;; Function called at each tick to update numpot
;;; Variable changes: number_a, nuùber_b, FSR,
;;; all_numpot_16, all_inc_16, index, update_info
;;;
data_update:
    ;; Check if numpot have to be changed
    banksel update_info
    movf update_info, W
    btfsc STATUS, Z
    goto data_update_end

    ;; Send previously prepared numpot values
    call_other_page numpot_send_all

    ;; Prepare next values

    ;; Prepate loop
    banksel index
    movlw NB_NUMPOT_VALUES
    movwf index
data_update_loop_update_gain:
    ;; Put address of 16 bit increment (all_inc_16) value in FSR
    banksel index
    movf index, W
    movwf FSR
    lshift_f FSR, 1
    movlw all_inc_16
    addwf FSR, F
    ;; take care of bank
    bankisel all_inc_16
    ;; Extract 16 bit value into number_a
    math_banksel
    movf INDF, W
    movwf number_a_lo
    incf FSR, F
    movf INDF, W
    movwf number_a_hi

    ;; Put address of indexed 16 bit numpot (all_numpot_16) value in FSR
    banksel index
    movf index, W
    movwf FSR
    lshift_f FSR, 1
    movlw all_numpot_16
    addwf FSR, F
    ;; take care of bank
    bankisel all_numpot_16
    ;; Extract 16 bit value into number_b
    math_banksel
    movf INDF, W
    movwf number_b_lo
    incf FSR, F
    movf INDF, W
    movwf number_b_hi

    ;; add number_a and number_b
    call_other_page math_add_1616s

    ;; store back result (number_b) into all_numpot_16
    movf number_b_hi, W
    movwf INDF
    decf FSR, F
    movf number_b_lo, W
    movwf INDF

    ;; store value in numpot
    ;; Set gain value (keep only the high order bits corresponding to real value)
    movf number_b_hi, W
    movwf param2
    rshift_f param2, SHIFT_NUMPOT_VAL_TO_HIGH_ORDER
    ;; set numpot index in param 1
    banksel index
    movf index, W
    movwf param1
    call_other_page numpot_set_one_value

    ;; Next index, and loop
    banksel index
    decfsz index, F
    goto data_update_loop_update_gain

    ;; Check if inc values have to be negated
    banksel trem_inc_cpt
    decfsz data_update_end, F
    goto data_update_end

    ;; End of half period
    ;; -> trem_inc_cpt need to be reset and all_inc_16 have to be negated
    ;; Reinit trem_inc_cpt
    movf trem_nb_inc, W
    movwf trem_inc_cpt
    ;; Prepare loop
    banksel index
    movlw NB_NUMPOT_VALUES
    movwf index
data_update_loop_negate_inc:
    ;; inverse inc
    ;; Put address of 16 bit increment (all_inc_16) value in FSR
    banksel index
    movf index, W
    movwf FSR
    lshift_f FSR, 1
    movlw all_inc_16
    addwf FSR, F
    ;; take care of bank
    bankisel all_inc_16
    ;; Extract 16 bit value into number_a
    math_banksel
    movf INDF, W
    movwf number_a_lo
    incf FSR, F
    movf INDF, W
    movwf number_a_hi

    call_other_page math_neg_number_a_16s

    ;; store back value in all_inc_16
    movf number_a_hi, W
    movwf INDF
    decf FSR, F
    movf number_a_lo, W
    movwf INDF

    ;; Next index, and loop
    banksel index
    decfsz index, F
    goto data_update_loop_negate_inc


    ;; Remove UPDATE_ONE_TIME bit from update_info,
    ;; in order to not update data next time if not needed (eg if
    ;; UPDATE_EVERY_TIME bit is not set)
    banksel update_info
    bcf update_info, UPDATE_ONE_TIME

    ;; Numpot have to be changed
data_update_end:
    return
END
