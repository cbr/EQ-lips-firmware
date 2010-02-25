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

#define EDIT_EQ_BANK_EESIZE_SHT     0x04

#define TREM_TYPE_NONE              0x00
#define TREM_TYPE_SIMPLE            0x01
#define TREM_TYPE_EQ                0x02

PROG_VAR_1 UDATA
edit_eq_tmp     RES 1
gain16          RES 2
inc             RES 2
trem_nb_val     RES 1
    ;; Sources data
numpot_values_a RES 11
numpot_values_b RES 11
trem_type       RES 1
    ;; Data update info
update_info     RES 1

    ;; Temporary activation data
PROG_VAR_2 UDATA
all_numpot_16   RES (2*11)
all_inc_16      RES (2*11)


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

    call prepare_trem

    movlw 1
    movwf current_bank
    menu_start trem_manage
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
    call trem_manage
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
#if 1
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
#endif
trem_manage_end:
    banksel 0
    return
END
