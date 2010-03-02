;;;
;;; This macro add label representing int variable.
;;; pos: y position of menu edit
;;; value_addr: variable to be printed
;;; Changed registers: param1, param2, param3, param4
;;;
menu_label_int macro pos, value_addr
    local menu_label_init_or_refresh
    local menu_label_undef

    menu_event_dispatch menu_label_init_or_refresh, UNUSED_PARAM, UNUSED_PARAM, UNUSED_PARAM, UNUSED_PARAM, UNUSED_PARAM, UNUSED_PARAM, menu_label_init_or_refresh
    goto menu_label_undef

menu_label_init_or_refresh:
    ;; Print string
    movlw MENU_STRING_POS_X
    movwf param1
    movlw pos
    movwf param2
    call_other_page lcd_locate
    ;; Print value
    movlw value_addr
    movwf FSR
    bankisel value_addr
    movf INDF, W
    movwf param1
    clrf param2
    call_other_page lcd_int
    goto menu_label_undef


menu_label_undef:
    endm

#ifndef MENU_LABEL_M
#endif
