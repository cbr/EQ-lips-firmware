#define MENU_EQ_MAX_INPUT           0x1F

#if 0
;;;
;;; Manage eq band selection: change value with encoder and return from selection
;;; when encoder sw is pressed
;;; pos_x: band x position
;;; value_addr: address of eq value
;;; on_value_change_func: function called when the eq band value is changed
;;;
menu_eq_manage_selection macro pos_x, value_addr, on_value_change_func
    ;; Implementation with function
    movlw pos_x
    movwf param1
    movlw value_addr
    movwf param2
    call_other_page menu_eq_manage_selection_func
    call_other_page on_value_change_func
    endm
#else
;;;
;;; Manage entering in selection sub state of eq band
;;; pos_x: band x position
;;; value_addr: address of eq value
;;;
menu_eq_manage_select macro pos_x, value_addr
    ;; Implementation with function
    movlw pos_x
    movwf param1
    movlw value_addr
    movwf param2
    call_other_page menu_eq_manage_select_func
    endm

;;;
;;; Manage entering in selection sub state of eq band
;;; pos_x: band x position
;;; value_addr: address of eq value
;;;
menu_eq_manage_unselect macro pos_x
    ;; Implementation with function
    movlw pos_x
    movwf param1
    call_other_page menu_eq_manage_unselect_func
    endm


;;;
;;; Manage encoder value change during selection sub state
;;; pos_x: band x position
;;; value_addr: address of eq value
;;; on_value_change_func: function called when the eq band value is changed
;;;
menu_eq_manage_select_value_change macro pos_x, value_addr, on_value_change_func
    ;; Implementation with function
    movlw pos_x
    movwf param1
    movlw value_addr
    movwf param2
    call_other_page menu_eq_manage_select_value_change_func
    call_other_page on_value_change_func
    endm

;;;
;;; Manage selection exiting
;;;
menu_eq_manage_select_switch macro
    menu_leave_selection
    endm

#endif

;;;
;;; This macro manage an entry element got eq band
;;; pos_x: band x position
;;; value_addr: address of eq value
;;; on_value_change_func: function called when the eq band value is changed
;;; need_refresh_func: function called to need if refresh is needed. At return if W = 1, refresh is needed
;;;
menu_eq macro pos_x, value_addr, on_value_change_func, need_refresh_func
    local menu_eq_init
    local menu_eq_undef
    local menu_eq_focus
    local menu_eq_unfocus
    local menu_eq_select
    local menu_eq_unselect
    local menu_eq_refresh
    local menu_eq_select_value_change
    local menu_eq_select_switch

    menu_event_dispatch menu_eq_init, menu_eq_focus, menu_eq_unfocus, menu_eq_select, menu_eq_unselect, menu_eq_select_value_change, menu_eq_select_switch

    ;; no event found
    ;; check if refresh is needed
    call_other_page need_refresh_func
    sublw 1
    btfsc STATUS, Z
    ;; refresh needed
    goto menu_eq_refresh
    ;; no refresh needed
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
#if 0
    menu_eq_manage_selection pos_x, value_addr, on_value_change_func
#else
    menu_eq_manage_select pos_x, value_addr
#endif
    goto menu_eq_undef

menu_eq_unselect:
    menu_eq_manage_unselect pos_x
    goto menu_eq_undef

menu_eq_select_value_change:
    menu_eq_manage_select_value_change pos_x, value_addr, on_value_change_func
    goto menu_eq_undef

menu_eq_select_switch:
    menu_eq_manage_select_switch
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
#if 0
    extern menu_eq_manage_selection_func
#else
    extern menu_eq_manage_select_func
    extern menu_eq_manage_unselect_func
    extern menu_eq_manage_select_value_change_func
#endif
#endif
