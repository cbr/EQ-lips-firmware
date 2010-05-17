;;;
;;; This macro add a menu button into a dialog screen
;;; id: uniq id of menu_entry element
;;; string: label of the menu button.
;;; pos: y position of menu button
;;; on_select_function: function called on selection
;;; Changed registers: param1, param2, param3, param4
;;;
menu_button macro id, string, pos, on_select_function
    menu_button_common id, string, pos, on_select_function, 0
    endm

;;;
;;; This macro add a menu button into a dialog screen. This variant
;;; goto the specified label on selection
;;; id: uniq id of menu_entry element
;;; string: label of the menu button
;;; pos: y position of menu button
;;; on_select_function: function 'gotoed' on selecttion
;;; Changed registers: param1, param2, param3, param4
;;;
menu_button_goto macro id, string, pos, on_select_function
    menu_button_common id, string, pos, on_select_function, 1
    endm

;;;
;;; This macro add a menu button into a dialog screen
;;; id: uniq id of menu_entry element
;;; string: label of the menu button
;;; pos: y position of menu button
;;; on_select_function: label used on selection
;;; use_goto: if 1, on_select_function is used as a goto, otherwise it is called
;;; Changed registers: param1, param2, param3, param4
;;;
menu_button_common macro id, string, pos, on_select_function, use_goto
    local menu_button_init_or_refresh
    local menu_button_undef
    local menu_button_focus
    local menu_button_unfocus
    local menu_button_select
    local menu_button_unselect

    menu_event_dispatch id, menu_button_init_or_refresh, menu_button_focus, menu_button_unfocus, menu_button_select, menu_button_unselect, UNUSED_PARAM, UNUSED_PARAM, menu_button_init_or_refresh
    goto menu_button_undef

menu_button_init_or_refresh:
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
    goto menu_button_undef

#ifdef SIMPLE_FOCUS
menu_button_unfocus:
    clrf param1
    movlw pos
    movwf param2
    call_other_page lcd_locate
    movlw MENU_UNFOCUS_CHAR
    movwf param1
    call_other_page lcd_char
    goto menu_button_undef
menu_button_focus:
    ;; Current button
    clrf param1
    movlw pos
    movwf param2
    call_other_page lcd_locate
    movlw MENU_FOCUS_CHAR
    movwf param1
    call_other_page lcd_char
    goto menu_button_undef
#else
menu_button_unfocus:
menu_button_focus:
    ;; draw the focus rectangle with XOR
    ;; (So, the same operation can focus and also unfocus)
    ;; Current button
    clrf param1
    movlw pos
    movwf param2
    lshift_f param2, LCD_CHAR_HEIGH_SHIFT
    movlw LCD_WIDTH
    movwf param3
    movf param2, W
    movwf param4
    movlw LCD_CHAR_HEIGH
    movwf param4
    bsf param5, LCD_XOR
    call_other_page lcd_rectangle
#endif
    goto menu_button_undef

menu_button_select:
    movlw pos
    movwf param1
    call_other_page menu_button_select_func
    menu_leave_selection
    goto menu_button_undef

menu_button_unselect:
    ;; call on event function
    if (use_goto == 1)
        goto_other_page on_select_function
    else
        call_other_page on_select_function
    endif
    goto menu_button_undef

menu_button_undef:
    VARIABLE MENU_NB_ENTRY=MENU_NB_ENTRY+1
    endm

#ifndef MENU_BUTTON_M
    extern menu_button_select_func
#endif
