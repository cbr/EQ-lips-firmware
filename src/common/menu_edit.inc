#define MENU_EDIT_NO_PRINT_VAL      0xFF

;;;
;;; This macro add a menu edit into a dialog screen.
;;; The value managed by edit is printed just after the string.
;;; string: label of the menu edit
;;; pos_y: y position of menu edit
;;; Changed registers: param1, param2, param3, param4
;;;
menu_edit macro string, pos_x, pos_y, min_value, max_value, value_addr, on_value_change_func, on_valid_value_func
    menu_edit_comon string, pos_x, pos_y, min_value, max_value, value_addr, on_value_change_func, on_valid_value_func, 1
    endm

;;;
;;; This macro add a menu edit into a dialog screen.
;;; The value managed by edit is not printed.
;;; string: label of the menu edit
;;; pos_y: y position of menu edit
;;; Changed registers: param1, param2, param3, param4
;;;
menu_edit_no_show macro string, pos_x, pos_y, min_value, max_value, value_addr, on_value_change_func, on_valid_value_func
    menu_edit_comon string, pos_x, pos_y, min_value, max_value, value_addr, on_value_change_func, on_valid_value_func, 0
    endm

;;;
;;; This macro add a menu edit into a dialog screen.
;;; Simplier alias macro can be used instead: menu_edit, menu_edit_no_show
;;; string: label of the menu edit
;;; pos_y: y position of menu edit
;;; Changed registers: param1, param2, param3, param4
;;;
menu_edit_comon macro string, pos_x, pos_y, min_value, max_value, value_addr, on_value_change_func, on_valid_value_func, print_value
    local menu_edit_init_or_refresh
    local menu_edit_undef
    local menu_edit_focus
    local menu_edit_unfocus
    local menu_edit_select
    local menu_edit_unselect
    local menu_edit_select_switch
    local menu_edit_select_value_change
    local menu_edit_select_unselect_draw
    menu_event_dispatch menu_edit_init_or_refresh, menu_edit_focus, menu_edit_unfocus, menu_edit_select, menu_edit_unselect, menu_edit_select_value_change, menu_edit_select_switch, menu_edit_init_or_refresh
    goto menu_edit_undef

menu_edit_init_or_refresh:
    ;; Print string
    movlw pos_x
    movwf param1
    movlw pos_y
    movwf param2
    movlw low string
    movwf param3
    movlw high string
    movwf param4
    call_other_page lcd_loc_string
#if print_value == 1
    ;; Print value
    movlw value_addr
    movwf FSR
    bankisel value_addr
    movf INDF, W
    movwf param1
    clrf param2
    call_other_page lcd_int
    goto menu_edit_undef
#endif

menu_edit_unfocus:
    movlw pos_x
    movwf param1
    decf param1, F
    movlw pos_y
    movwf param2
    call_other_page lcd_locate
    movlw MENU_UNFOCUS_CHAR
    movwf param1
    call_other_page lcd_char
    goto menu_edit_undef

menu_edit_focus:
    ;; Current edit
    movlw pos_x
    movwf param1
    decf param1, F
    movlw pos_y
    movwf param2
    call_other_page lcd_locate
    movlw MENU_FOCUS_CHAR
    movwf param1
    call_other_page lcd_char
    goto menu_edit_undef

menu_edit_select:
    ;; configure encoder
    banksel value_addr
    movf value_addr, W
    movwf param1
    movlw min_value
    movwf param2
    movlw low max_value
    movwf param3
    call_other_page menu_selection_encoder_configure
    ;; draw selection rectangle: the code is shared with unselect event, so
    ;; continue with select/unselect drawing part
    goto menu_edit_select_unselect_draw

menu_edit_unselect:

menu_edit_select_unselect_draw:
    ;; calculate size of string
    movlw high string
    movwf param1
    movlw low string
    movwf param2
    call_other_page std_strlen
    ;; store in param1
    movwf param3

    ;; draw selection rectangle
    movlw pos_x
    movwf param1
    movlw pos_y
    movwf param2
    call_other_page menu_edit_draw_select
    goto menu_edit_undef

menu_edit_select_switch:
    ;; Call value valid function callback
#if on_valid_value_func == UNUSED_PARAM
#else
    call_other_page on_valid_value_func
#endif
    menu_leave_selection
    goto menu_edit_undef

menu_edit_select_value_change:
    movlw high string
    movwf param1
    movlw low string
    movwf param2
    movlw pos_x
    movwf param3
#if print_value == 1
    movlw pos_y
#else
    movlw MENU_EDIT_NO_PRINT_VAL
#endif
    movwf param4
    bankisel value_addr
    movlw value_addr
    movwf param5
    call_other_page menu_edit_manage_select_value_change
#if on_value_change_func == UNUSED_PARAM
#else
    call_other_page on_value_change_func
#endif
    goto menu_edit_undef

menu_edit_undef:
    VARIABLE MENU_NB_ENTRY=MENU_NB_ENTRY+1
    endm

#ifndef MENU_EDIT_M
    extern menu_edit_draw_select
    extern menu_edit_manage_select_value_change
#endif
