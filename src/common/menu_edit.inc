;;;
;;; This macro add a menu edit into a dialog screen
;;; string: label of the menu edit
;;; pos: y position of menu edit
;;; Changed registers: param1, param2, param3, param4
;;;
menu_edit macro string, pos, min_value, max_value, value_addr, on_value_change_func
    local menu_edit_init
    local menu_edit_undef
    local menu_edit_focus
    local menu_edit_unfocus
    local menu_edit_select

    menu_event_dispatch menu_edit_init, menu_edit_focus, menu_edit_unfocus, menu_edit_select
    goto menu_edit_undef

menu_edit_init:
    ;; Print string
    movlw MENU_STRING_POS_X
    movwf param1
    movlw pos
    movwf param2
    movlw low string
    movwf param3
    movlw high string
    movwf param4
    call_other_page lcd_loc_string

    ;; Print value
    movlw value_addr
    movwf FSR
    movf INDF, W
    movwf param1
    clrf param2
    call_other_page lcd_int
    goto menu_edit_undef


menu_edit_unfocus:
    clrf param1
    movlw pos
    movwf param2
    call_other_page lcd_locate
    movlw MENU_UNFOCUS_CHAR
    movwf param1
    call_other_page lcd_char
    goto menu_edit_undef
menu_edit_focus:
    ;; Current edit
    clrf param1
    movlw pos
    movwf param2
    call_other_page lcd_locate
    movlw MENU_FOCUS_CHAR
    movwf param1
    call_other_page lcd_char
    goto menu_edit_undef
    goto menu_edit_undef

menu_edit_select:
    ;; configure encoder
    movf value_addr, W
    movwf param1
    movlw min_value
    movwf param2
    movlw max_value
    movwf param3
    call_other_page encoder_set_value
    ;; call function which manage edit
    movlw high string
    movwf param1
    movlw low string
    movwf param2
    movlw pos
    movwf param3
    movlw value_addr
    movwf param4
    call_other_page menu_edit_manage_selection
    call_other_page on_value_change_func
    goto menu_edit_undef

menu_edit_undef:
    VARIABLE MENU_NB_ENTRY=MENU_NB_ENTRY+1
    endm

#ifndef MENU_EDIT_M
    extern menu_edit_manage_selection
#endif
