#define MENU_EQ_MAX_INPUT           0x1F

;;;
;;; Manage eq band selection: change value with encoder and return from selection
;;; when encoder sw is pressed
;;; pos_x: band x position
;;; value_addr: address of eq value
;;; on_value_change_func: function called when the eq band value is changed
;;;
menu_eq_manage_selection macro pos_x, value_addr, on_value_change_func
    ;; To be cleanup
#if 0
    local menu_eq_manage_selection_loop
    local menu_eq_manage_selection_quit
    local menu_eq_manage_selection_check_sw
    local menu_eq_manage_selection_check_rot
    ;; Draw selection
    movlw pos_x
    movwf param1
    call_other_page menu_eq_draw_select
    ;; mem current value
    movlw value_addr
    movwf FSR
    movf INDF, W
    movwf menu_eq_last_value
    ;; configure encoder
    movwf param1
    clrf param2
    movlw MENU_EQ_MAX_INPUT
    movwf param3
    call_other_page encoder_set_value

menu_eq_manage_selection_loop:
    ;; Check events

menu_eq_manage_selection_check_sw:
    ;; Check if encoder switch is not 0
    movf encoder_sw, F
    btfsc STATUS, Z
    ;; equal to 0 -> next event
    goto menu_eq_manage_selection_check_rot
    ;; the encoder switch has been pressed
    ;; draw eq as unselect
    movlw pos_x
    movwf param1
    call_other_page menu_eq_draw_select
    ;; reset encoder_sw
    encoder_ack_sw
    ;; quit selection
    goto menu_eq_manage_selection_quit

menu_eq_manage_selection_check_rot:
    ;; check if encoder value has changed
    movf menu_eq_last_value, W
    subwf encoder_value, W
    btfsc STATUS, Z
    ;; values are equal -> nothing to do
    goto menu_eq_manage_selection_loop
    ;; values are not equal
    ;; -> manage changes
    ;; ***************
    ;; undraw band
    movlw pos_x
    movwf param1
    movf menu_eq_last_value, W
    movwf param2
    call_other_page menu_draw_eq_band
    ;; draw new band and memorize
    movlw value_addr
    movwf FSR
    movlw pos_x
    movwf param1
    movf encoder_value, W
    movwf menu_eq_last_value
    movwf INDF
    movwf param2
    call_other_page menu_draw_eq_band
    ;; ***************
    call_other_page on_value_change_func
    goto menu_eq_manage_selection_loop

menu_eq_manage_selection_quit:
#else
    ;; Implementation with function
    movlw pos_x
    movwf param1
    movlw value_addr
    movwf param2
    call_other_page menu_eq_manage_selection_func
    call_other_page on_value_change_func
#endif
    endm

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
    local menu_eq_refresh

    menu_event_dispatch menu_eq_init, menu_eq_focus, menu_eq_unfocus, menu_eq_select

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
    menu_eq_manage_selection pos_x, value_addr, on_value_change_func
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
    extern menu_eq_manage_selection_func
#endif
