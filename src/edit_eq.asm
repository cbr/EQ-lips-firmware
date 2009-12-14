;;; Manage dialog screen for eqalizer editing

#define EDIT_EQ_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <lcd.inc>
#include <menu.inc>
#include <eeprom.inc>

#define EDIT_EQ_BANK_EESIZE_SHT     0x05

    UDATA
edit_eq_tmp      RES 1


; relocatable code
PROG CODE
edit_eq_show:
    global edit_eq_show
    ;; Erase screen
    call lcd_clear

    ;; position
    movlw (0x5*0 + 0x3E)
    movwf param1
    ;; value
    movlw 0xFF
    movwf param2
    call menu_draw_eq_band

    ;; position
    movlw (0x5*1 + 0x3E)
    movwf param1
    ;; value
    movlw 0x89
    movwf param2
    call menu_draw_eq_band

    ;; position
    movlw (0x5*2 + 0x3E)
    movwf param1
    ;; value
    movlw 0x81
    movwf param2
    call menu_draw_eq_band

    ;; position
    movlw (0x5*3 + 0x3E)
    movwf param1
    ;; value
    movlw 0x80
    movwf param2
    call menu_draw_eq_band

    ;; position
    movlw (0x5*4 + 0x3E)
    movwf param1
    ;; value
    movlw 0x7F
    movwf param2
    call menu_draw_eq_band

    ;; position
    movlw (0x5*5 + 0x3E)
    movwf param1
    ;; value
    movlw 0x77
    movwf param2
    call menu_draw_eq_band

    ;; position
    movlw (0x5*6 + 0x3E)
    movwf param1
    ;; value
    movlw 0x00
    movwf param2
    call menu_draw_eq_band

    ;; goto $
    ;; Draw eq

;;; Save current eq values in eeprom
;;; param1: bank number
edit_eq_save:
    ;; set param1 to the start of bank in eeprom
    lshift_f param1, EDIT_EQ_BANK_EESIZE_SHT
    ;; Prepare current value counter
    clrf edit_eq_tmp, F

edit_eq_save_loop:
    ;; Calculate value addr
    movlw numpot_values
    addwf edit_eq_tmp, W
    ;; Derefenrence value
    movwf FSR
    movf INDF, W
    ;; Put value in param2
    movwf param2
    ;; Store in eeprom
    call_other_bank eeprom_write
    ;; next value
    incf param1, F
    incf edit_eq_tmp, F
    ;; loop in order to store all values
    movf edit_eq_tmp, W
    subwl NUMPOT_NB_POT * NUMPOT_NB_VAL_IN_POT
    btfss STATUS, Z
    goto edit_eq_save_loop

    return

;;; Load a memorized bank from eeprom to numpot
;;; param1: bank number
edit_eq_load:
    ;; set param1 to the start of bank in eeprom
    lshift_f param1, EDIT_EQ_BANK_EESIZE_SHT
    ;; Prepare current value counter
    clrf edit_eq_tmp, F

edit_eq_load_loop:
    ;; Calculate value addr
    movlw numpot_values
    addwf edit_eq_tmp, W
    ;; Prepare pointer
    movwf FSR
    ;; Get value from eeprom
    call_other_bank eeprom_read
    ;; Store in numpot memory
    movf INDF, W

    ;; next value
    incf param1, F
    incf edit_eq_tmp, F
    ;; loop in order to store all values
    movf edit_eq_tmp, W
    subwl NUMPOT_NB_POT * NUMPOT_NB_VAL_IN_POT
    btfss STATUS, Z
    goto edit_eq_load_loop

    return

END
