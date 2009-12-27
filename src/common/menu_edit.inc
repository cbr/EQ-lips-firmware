;;;
;;; This macro add a menu edit into a dialog screen
;;; string: label of the menu edit
;;; pos: y position of menu edit
;;; Changed registers: param1, param2, param3, param4
;;;
menu_edit macro string, pos, on_select_function
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
    movlw pos
    movwf param1
    call_other_page menu_edit_select_func
    ;; call on event function
    call_other_page on_select_function
    goto menu_edit_undef

menu_edit_undef:
    VARIABLE MENU_NB_ENTRY=MENU_NB_ENTRY+1
    endm

#ifndef MENU_EDIT_M
    extern menu_edit_select_func
#endif
