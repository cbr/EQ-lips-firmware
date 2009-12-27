;;; Manage dialog screen for eqalizer editing

#define EDIT_EQ_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <lcd.inc>
#include <menu.inc>
#include <menu_button.inc>
#include <menu_eq.inc>
#include <encoder.inc>
#include <interrupt.inc>
#include <numpot.inc>
#include <eeprom.inc>

#define EDIT_EQ_BANK_EESIZE_SHT     0x05

    UDATA
edit_eq_tmp      RES 1
edit_eq_refresh  RES 1


; relocatable code
EQ_PROG CODE
st_load:
    dt "LOAD", 0
st_save:
    dt "SAVE", 0

edit_eq_save:
    global edit_eq_save
    movlw 0
    movwf param1
    call edit_eq_save_bank
    return

edit_eq_load:
    global edit_eq_save
    movlw 0
    movwf param1
    call edit_eq_load_bank
    call_other_page numpot_send_all
    movlw 1
    banksel edit_eq_refresh
    movwf edit_eq_refresh
    return

edit_eq_need_refresh:
    global edit_eq_need_refresh
    banksel edit_eq_refresh
    movf edit_eq_refresh, W
    return

edit_eq_need_refresh_last:
    global edit_eq_need_refresh_last
    banksel edit_eq_refresh
    movf edit_eq_refresh, W
    clrf edit_eq_refresh
    return

edit_eq_show:
    global edit_eq_show
#if 0
    movlw high st_load
    movwf param1
    movlw low st_load
    movwf param2
    call_other_page std_strlen
#endif
    menu_start
    menu_button st_load, 0, edit_eq_load
    menu_button st_save, 1, edit_eq_save
    menu_eq (0x5*0 + 0x3D), potvalues, numpot_send_all, edit_eq_need_refresh
    menu_eq (0x5*1 + 0x3D), potvalues+1, numpot_send_all, edit_eq_need_refresh
    menu_eq (0x5*2 + 0x3D), potvalues+2, numpot_send_all, edit_eq_need_refresh
    menu_eq (0x5*3 + 0x3D), potvalues+3, numpot_send_all, edit_eq_need_refresh
    menu_eq (0x5*4 + 0x3D), potvalues+4, numpot_send_all, edit_eq_need_refresh
    menu_eq (0x5*5 + 0x3D), potvalues+5, numpot_send_all, edit_eq_need_refresh
    menu_eq (0x5*6 + 0x3D), potvalues+6, numpot_send_all, edit_eq_need_refresh
    menu_eq (0x5*7 + 0x3D), potvalues+7, numpot_send_all, edit_eq_need_refresh
    menu_eq (0x5*8 + 0x3D), potvalues+8, numpot_send_all, edit_eq_need_refresh
    menu_eq (0x5*9 + 0x3D), potvalues+9, numpot_send_all, edit_eq_need_refresh
    menu_eq (0x5*0xB + 0x3D), potvalues+0xA, numpot_send_all, edit_eq_need_refresh_last
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

END
