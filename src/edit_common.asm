;;; Manage dialog screen for eqalizer editing

#define EDIT_COMMON_M

#include <cpu.inc>
#include <edit_common.inc>
#include <global.inc>
#include <std.inc>
#include <menu.inc>
#include <process.inc>
#include <bank.inc>
#include <lcd.inc>
#include <io_interrupt.inc>
#include <math.inc>
#include <io.inc>
#include <flash.inc>
#include <menu_eq.inc>

#define HINT_X              1
#define HINT_X_VALUE        .7
#define HINT_Y              3

#define BOTH_BUTTON_MASK    ((1 << DOWN_SW_BIT) | (1 << UP_SW_BIT))

#ifdef TREMOLO
#include <timer.inc>
#endif
PROG_VAR_1 UDATA
#ifdef TREMOLO
button_up_time_cpt  RES 2
button_down_time_cpt  RES 2
#endif
edit_common_var1 RES 1
edit_common_var2 RES 1
edit_common_button_free_to_use RES 1
edit_common_button_last_value RES 1
;;; Counter of number of down switch released event
edit_common_down_btn_released RES 1
    global edit_common_down_btn_released
;;; Counter of number of up switch released event
edit_common_up_btn_released RES 1
    global edit_common_up_btn_released
;;; Counter of number of both button press event
edit_common_both_btn_pressed RES 1
    global edit_common_both_btn_pressed

; relocatable code
EQ_PROG_1 CODE
edit_common_st_bank:
    global edit_common_st_bank
    dt "Bank: ", 0
edit_common_st_load:
    global edit_common_st_load
    dt "Load", 0
edit_common_st_save:
    global edit_common_st_save
    dt "Save", 0
edit_common_st_empty_hint:
    global edit_common_st_empty_hint
    dt "               ", 0
edit_common_st_gain_hint_label:
    dt "Gain", 0
edit_common_st_eq_band_hint_unit:
    dt "Hz", 0
edit_common_st_eq_band_hint_value_unit:
    dt "dB ", 0

edit_common_st_freq_value_0:
    dt "32", 0
edit_common_st_freq_value_1:
    dt "64", 0
edit_common_st_freq_value_2:
    dt "125", 0
edit_common_st_freq_value_3:
    dt "250", 0
edit_common_st_freq_value_4:
    dt "500", 0
edit_common_st_freq_value_5:
    dt "1k", 0
edit_common_st_freq_value_6:
    dt "2k", 0
edit_common_st_freq_value_7:
    dt "4k", 0
edit_common_st_freq_value_8:
    dt "8k", 0
edit_common_st_freq_value_9:
    dt "16k", 0
edit_common_mapping_values:
#include <numpot_mapping_value.inc>

;;;
;;; Initialize module
;;;
edit_common_init:
    global edit_common_init
    banksel edit_common_button_free_to_use
    movlw 0xFF
    movwf edit_common_button_free_to_use
    movwf edit_common_button_last_value
    clrf edit_common_up_btn_released
    clrf edit_common_down_btn_released
    clrf edit_common_both_btn_pressed
    return

edit_common_save:
    global edit_common_save

    movf current_bank, W
    movwf param1
    decf param1, F
    call_other_page bank_save
    return

edit_common_load_preview:
    global edit_common_load_preview

    movf current_bank, W
    movwf param1
    decf param1, F
    call_other_page bank_load
    menu_ask_refresh
    return

edit_common_load:
    global edit_common_load
    call_other_page process_change_conf
    menu_change_focus
    return

edit_common_refresh:
    global edit_common_refresh

    menu_ask_refresh
    return


edit_common_sleep:
    global edit_common_sleep
    ;; Nothing to do -> put processor in sleep mode
    sleep
    nop
    ;; We have been wake up
    return


edit_common_down_short:
    clrf param1
    movlw 3
    movwf param2
    ;; call_other_page lcd_locate
    movlw 1
    movwf param1
    clrf param2
    ;; call_other_page lcd_int
    return
edit_common_down_long:
    clrf param1
    movlw 3
    movwf param2
    ;; call_other_page lcd_locate
    movlw 2
    movwf param1
    clrf param2
    ;; call_other_page lcd_int
    return
edit_common_up_short:
    clrf param1
    movlw 3
    movwf param2
    ;; call_other_page lcd_locate
    movlw 3
    movwf param1
    clrf param2
    ;; call_other_page lcd_int
    return
edit_common_up_long:
    clrf param1
    movlw 3
    movwf param2
    ;; call_other_page lcd_locate
    movlw 4
    movwf param1
    clrf param2
    ;; call_other_page lcd_int
    return

;;;
;;; This function checks the state of foot switches.
;;; The following variables are updated:
;;; - edit_common_both_btn_pressed
;;; - edit_common_up_btn_released
;;; - edit_common_down_btn_released
;;;
edit_common_check_buttons:
    global edit_common_check_buttons
#if 0
    clrf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    banksel reg_input_current_value
    movf reg_input_current_value, W
    movwf param1
    clrf param2
    call_other_page lcd_int
#endif
    ;; Check if both button are pressed and not used
    ;; (bits are active when equal to 0, so the value is first negated)
    banksel reg_input_current_value
    comf reg_input_current_value, W
    banksel edit_common_button_free_to_use
    andwf edit_common_button_free_to_use, W
    andlw BOTH_BUTTON_MASK
    sublw BOTH_BUTTON_MASK
    btfss STATUS, Z
    goto chk_btn_both_button_not_pressed

    ;; Both button are pressed !
chk_btn_both_button_pressed:
    ;; Memorized that button state have been used
    movlw BOTH_BUTTON_MASK
    xorlw 0xFF
    banksel edit_common_button_free_to_use
    andwf edit_common_button_free_to_use, F
    banksel edit_common_both_btn_pressed
    incf edit_common_both_btn_pressed, F
    ;; call_other_page lcd_clear

    ;; Both button are not pressed
chk_btn_both_button_not_pressed:
    ;; Check pressed -> released transition
    ;; Put (state change AND reg_input_current_value AND edit_common_button_free_to_use) into edit_common_var1
    banksel edit_common_button_last_value
    movf edit_common_button_last_value, W
    banksel reg_input_current_value
    xorwf reg_input_current_value, W
    andwf reg_input_current_value, W
    banksel edit_common_button_free_to_use
    andwf edit_common_button_free_to_use, W
    banksel edit_common_var1
    movwf edit_common_var1
    ;; Check UP button
    btfss edit_common_var1, UP_SW_BIT
    goto chk_btn_up_button_not_released

    ;; Button UP released
chk_btn_up_button_released:
    ;; call_other_page lcd_clear
    banksel edit_common_up_btn_released
    incf edit_common_up_btn_released, F
    goto chk_btn_up_button_released_end

chk_btn_up_button_released_end:
chk_btn_up_button_not_released:
    ;; Check DOWN button
    btfss edit_common_var1, DOWN_SW_BIT
    goto chk_btn_down_button_not_released

    ;; Button DOWN released
chk_btn_down_button_released:
    ;; call_other_page lcd_clear
    banksel edit_common_down_btn_released
    incf edit_common_down_btn_released, F
    goto chk_btn_down_button_released_end

chk_btn_down_button_released_end:
chk_btn_down_button_not_released:

    ;; Memorize last button values
    banksel reg_input_current_value
    movf reg_input_current_value, W
    banksel edit_common_button_last_value
    movwf edit_common_button_last_value
    ;; Reset if necessary
    banksel reg_input_current_value
    movf reg_input_current_value, W
    andlw BOTH_BUTTON_MASK
    banksel edit_common_button_free_to_use
    iorwf edit_common_button_free_to_use, F
    return

;;;
;;; Select next memory bank
;;;
edit_common_bank_up:
    global edit_common_bank_up
    ;; Try to inc bank number if possible
    banksel current_bank
    movf current_bank, W
    sublw BANK_NB
    btfsc STATUS, Z
    goto edit_common_bank_up_end
    incf current_bank, F
    call_other_page edit_common_load_preview
    call_other_page edit_common_load
    menu_change_focus
edit_common_bank_up_end:
    return

;;;
;;; Select previous memory bank
;;;
edit_common_bank_down:
    global edit_common_bank_down
    ;; Try to dec bank number if possible
    banksel current_bank
    movf current_bank, W
    sublw 1
    btfsc STATUS, Z
    goto edit_common_bank_down_end
    decf current_bank, F
    call_other_page edit_common_load_preview
    call_other_page edit_common_load
edit_common_bank_down_end:
    menu_change_focus
    return

edit_common_freq_val_macro macro eq_nb
    local not_this_one
    local found

    movf edit_common_var1, W
    sublw eq_nb
    btfss STATUS, Z
    goto not_this_one
    movlw low edit_common_st_freq_value_#v(eq_nb)
    movwf param1
    movlw high edit_common_st_freq_value_#v(eq_nb)
    movwf param2
    goto found
not_this_one:
    if (eq_nb > 0)
    edit_common_freq_val_macro (eq_nb-1)
    endif
found:
    endm

;;;
;;; Function called when an eq band gain the focus
;;; param1: id of menu entry which gain focus (not used here)
;;;
edit_common_eq_gain_focus:
    global edit_common_eq_gain_focus
    ;; Locate
    movlw HINT_X
    movwf param1
    movlw HINT_Y
    movwf param2
    call_other_page lcd_locate
    ;; Draw legend string
    movlw low edit_common_st_gain_hint_label
    movwf param1
    movlw high edit_common_st_gain_hint_label
    movwf param2
    call_other_page lcd_string

    ;; Draw value
    movlw ID_EQ_BAND_BASE + 0xA
    movwf param1
    call_other_page edit_common_eq_band_change
    return

;;;
;;; Function called when an eq band gain the focus
;;; param1: id of menu entry which gain focus
;;;
edit_common_eq_band_focus:
    global edit_common_eq_band_focus
    ;; save param
    movf param1, W
    banksel edit_common_var2
    movwf edit_common_var2
    ;; Get 0-indexed value
    movlw ID_EQ_BAND_BASE
    subwf param1, W
    banksel edit_common_var1
    movwf edit_common_var1
    ;; Locate
    movlw HINT_X
    movwf param1
    movlw HINT_Y
    movwf param2
    call_other_page lcd_locate
    ;; Draw legend string
    ;; movlw low edit_common_st_eq_band_hint_label
    ;; movwf param1
    ;; movlw high edit_common_st_eq_band_hint_label
    ;; movwf param2
    ;; call_other_page lcd_string
    ;; Draw freq value
    banksel edit_common_var1
    edit_common_freq_val_macro 9
    call_other_page lcd_string
    ;; Draw unit
    movlw low edit_common_st_eq_band_hint_unit
    movwf param1
    movlw high edit_common_st_eq_band_hint_unit
    movwf param2
    call_other_page lcd_string

    ;; Draw value
    banksel edit_common_var2
    movf edit_common_var2, W
    movwf param1
    call_other_page edit_common_eq_band_change
    return

;;;
;;; Function called when an eq band loose the focus
;;; param1: id of menu entry which loose focus
;;;
edit_common_eq_band_unfocus:
    global edit_common_eq_band_unfocus
    ;; Locate
    movlw HINT_X
    movwf param1
    movlw HINT_Y
    movwf param2
    call_other_page lcd_locate
    ;; Draw empty string
    movlw low edit_common_st_empty_hint
    movwf param1
    movlw high edit_common_st_empty_hint
    movwf param2
    call_other_page lcd_string

    return

;;;
;;; Function called when an eq band has its value changed
;;; param1: id of menu entry which have vakue change
;;;
edit_common_eq_band_change:
    global edit_common_eq_band_change

    ;; Extract band value and put it into edit_common_var1
    bankisel bank_numpot_values
    movlw ID_EQ_BAND_BASE
    subwf param1, W
    addlw low bank_numpot_values
    movwf FSR
    movf INDF, W
    banksel edit_common_var1
    movwf edit_common_var1

    ;; Locate
    movlw HINT_X_VALUE
    movwf param1
    movlw HINT_Y
    movwf param2
    call_other_page lcd_locate
    ;; Check sign
    movlw MENU_EQ_ZERO_VALUE
    banksel edit_common_var1
    subwf edit_common_var1, F
    btfss STATUS, C
    goto edit_common_eq_band_change_neg
edit_common_eq_band_change_pos:
    movlw '+'
    movwf param1
    call_other_page lcd_char
    goto edit_common_eq_band_change_print_val
edit_common_eq_band_change_neg:
    comf edit_common_var1, F
    incf edit_common_var1, F
    movlw '-'
    movwf param1
    call_other_page lcd_char
edit_common_eq_band_change_print_val
    ;; print
    movlw low edit_common_mapping_values
    movwf param1
    movlw high edit_common_mapping_values
    movwf param2
    banksel edit_common_var1
    movf edit_common_var1, W
    movwf param3
    call_other_page flash_get_data
    movwf param1
    movlw (1 | (2 << LCD_INT_SHT_FILLING_ZERO))
    movwf param2
    call_other_page lcd_int

    movlw low edit_common_st_eq_band_hint_value_unit
    movwf param1
    movlw high edit_common_st_eq_band_hint_value_unit
    movwf param2
    call_other_page lcd_string

    ;; Update numpot
    call_other_page process_change_conf

    return

#ifdef TREMOLO
;;; Function called periodically in order to do periodic actions:
;;; - evaluate button press (short/long)
;;; - update numpot values (very important for tremolo)
edit_common_cycle_period:
    global edit_common_cycle_period
#if 0
    clrf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    clrf param2
    movf timer_cpt, W
    movwf param1
    call_other_page lcd_int
#endif
    ;; Check up & down switches
    io_cycle_check_button reg_input_current_value, UP_SW_BIT, button_up_time_cpt, edit_common_up_short, edit_common_up_long
    io_cycle_check_button reg_input_current_value, DOWN_SW_BIT, button_down_time_cpt, edit_common_down_short, edit_common_down_long

    ;; Update numpot according to conf
    call_other_page process_update

    return
#endif

END
