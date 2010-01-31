#define MENU_EQ_MAX_INPUT           0x1F
;;;
;;; This macro manage an entry element got eq band
;;; pos_x: band x position
;;; value_addr: address of eq value
;;; on_value_change_func: function called when the eq band value is changed
;;;
menu_eq macro pos_x, value_addr, on_value_change_func
    local menu_eq_init
    local menu_eq_undef
    local menu_eq_focus
    local menu_eq_unfocus
    local menu_eq_select
    local menu_eq_unselect
    local menu_eq_refresh
    local menu_eq_select_value_change
    local menu_eq_select_switch

    menu_event_dispatch menu_eq_init, menu_eq_focus, menu_eq_unfocus, menu_eq_select, menu_eq_unselect, menu_eq_select_value_change, menu_eq_select_switch, menu_eq_refresh
    goto menu_eq_undef
menu_eq_init:
    movlw pos_x
    movwf param1
    movlw value_addr
    movwf FSR
    movf INDF, W
    movwf param2
    call_other_page menu_draw_eq_band

    goto menu_eq_undef

menu_eq_unfocus:
menu_eq_focus:
    movlw pos_x
    movwf param1
    call_other_page menu_draw_focus_eq_band
    goto menu_eq_undef

menu_eq_select:
    movlw pos_x
    movwf param1
    movlw value_addr
    movwf param2
    call_other_page menu_eq_manage_select
    goto menu_eq_undef

menu_eq_unselect:
    movlw pos_x
    movwf param1
    call_other_page menu_eq_manage_unselect
    goto menu_eq_undef

menu_eq_select_value_change:
    movlw pos_x
    movwf param1
    movlw value_addr
    movwf param2
    call_other_page menu_eq_manage_select_value_change
    call_other_page on_value_change_func
    goto menu_eq_undef

menu_eq_select_switch:
    menu_leave_selection
    goto menu_eq_undef

menu_eq_refresh:
    movlw pos_x
    movwf param1
    movlw value_addr
    movwf FSR
    movf INDF, W
    movwf param2
    call_other_page menu_refresh_eq_band

menu_eq_undef:
    VARIABLE MENU_NB_ENTRY=MENU_NB_ENTRY+1
    endm


#ifndef MENU_EQ_M
    extern menu_eq_last_value
    extern menu_eq_draw_select

    extern menu_draw_eq_band
    extern menu_refresh_eq_band
    extern menu_draw_focus_eq_band
    extern menu_eq_manage_select
    extern menu_eq_manage_unselect
    extern menu_eq_manage_select_value_change
#endif
