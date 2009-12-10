#define MENU_ACTION_UNDEF           0x00
#define MENU_ACTION_INIT            0x01
#define MENU_ACTION_FOCUS_CHANGE   0x02
#define MENU_INIT_LAST_VALUE        0xFF

#define SIMPLE_FOCUS

#ifdef SIMPLE_FOCUS
#define MENU_FOCUS_CHAR            '>'
#define MENU_UNFOCUS_CHAR          ' '
#define MENU_STRING_POS_X           1
#else
#define MENU_STRING_POS_X           0
#endif

    extern menu_last_value
    VARIABLE MENU_NB_ENTRY

;;;
;;; This macro start a new dialog screen
;;; Changed registers: menu_value, menu_last_value, menu_action, param1
;;;
menu_start macro
    VARIABLE MENU_NB_ENTRY=0
    local menu_start_quit
    local menu_start_focus_change
    call lcd_clear
    ;; init variable
    movlw MENU_INIT_LAST_VALUE
    movwf menu_last_value
    movlw 0x00
    movwf menu_value

    ;; Action to realize is 'init' the first time
    movlw MENU_ACTION_INIT
    movwf menu_action
    goto menu_start_quit
    ;; define return label for 'end' macro
    ;; (An xcoff symbol is used, because of relocatable code)
    .DEF LABEL_MENU_START, global, value=$
menu_start_focus_change:
    ;; Check if encoder value is equal to current menu value
    movf encoder_value, W
    subwf menu_value, W
    btfsc STATUS, Z
    goto menu_start_quit
    ;; not equal !
    ;; -> change focus
    movlw MENU_ACTION_FOCUS_CHANGE
    movwf menu_action
    movf encoder_value, W
    movwf menu_value
menu_start_quit:
    endm


;;;
;;; This macro end e dialog screen
;;; Changed registers: menu_last_value, menu_action
;;;
menu_end macro
    local menu_end_undef
    local menu_end_init
    local menu_end_focus_change
    ;; *** Check current action
    ;; INIT
    movlw MENU_ACTION_INIT
    subwf menu_action, W
    btfsc STATUS, Z
    goto menu_end_init
    ;; FOCUS_CHANGE
    movlw MENU_ACTION_FOCUS_CHANGE
    subwf menu_action, W
    btfsc STATUS, Z
    goto menu_end_focus_change
    ;; Other unknown actions
    goto menu_end_undef

menu_end_init:
    ;; todo to be put in 'end' when the number of entry is known !
    encoder_set_value 0, 0, MENU_NB_ENTRY-1
    ;; At init, we also manage a focus change
    ;; -> no goto
menu_end_focus_change:
    ;; Store last value
    movf menu_value, W
    movwf menu_last_value
    goto menu_end_undef
menu_end_undef:
    ;; reset menu_action
    movlw MENU_ACTION_UNDEF
    movwf menu_action
    goto LABEL_MENU_START
    endm


;;;
;;; This macro add a menu entry into a dialog screen
;;; string: label of the menu entry
;;; pos: y position of menu entry
;;; Changed registers: param1, param2, param3, param4
;;;
menu_entry macro string, pos
    local menu_entry_end_focus
    local menu_entry_init
    local menu_entry_undef
    local menu_entry_focus_change
    local menu_entry_draw_focus
    local menu_entry_draw_unfocus
    ;; *** Check current action
    ;; INIT
    movlw MENU_ACTION_INIT
    subwf menu_action, W
    btfsc STATUS, Z
    goto menu_entry_init
    ;; FOCUS_CHANGE
    movlw MENU_ACTION_FOCUS_CHANGE
    subwf menu_action, W
    btfsc STATUS, Z
    goto menu_entry_focus_change
    ;; Other unknown actions
    goto menu_entry_undef

menu_entry_init:
    ;; Print string
    movlw MENU_STRING_POS_X
    movwf param1
    movlw pos
    movwf param2


    movlw low string
    movwf param3
    movlw high string
    movwf param4

    call lcd_loc_string
    ;; At end of init, we manage the focus, so
    ;; we continue :
menu_entry_focus_change:
    ;; Store menu entry position
    movlw pos
    movwf param2
    ;; New focused entry ?
    movlw MENU_NB_ENTRY
    subwf menu_value, W
    btfsc STATUS, Z
    goto menu_entry_draw_focus
    ;; Last focused entry ?
    movlw MENU_NB_ENTRY
    subwf menu_last_value, W
    btfsc STATUS, Z
    goto menu_entry_draw_unfocus
    goto menu_entry_end_focus
#ifdef SIMPLE_FOCUS
menu_entry_draw_unfocus:
    movlw 0
    movwf param1
    call lcd_locate
    movlw MENU_UNFOCUS_CHAR
    movwf param1
    call lcd_char
    goto menu_entry_end_focus
menu_entry_draw_focus:
    movlw 0
    movwf param1
    call lcd_locate
    movlw MENU_FOCUS_CHAR
    movwf param1
    call lcd_char
    goto menu_entry_end_focus
#else
menu_entry_draw_unfocus:
menu_entry_draw_focus:
    ;; draw the focus rectangle with XOR
    ;; (So, the same operation can focus and also unfocus)
    movlw 0
    movwf param1
    lshift_f param2, LCD_CHAR_HEIGH_SHIFT
    movlw LCD_WIDTH
    movwf param3
    movf param2, W
    movwf param4
    movlw LCD_CHAR_HEIGH
    movwf param4
    bsf param5, LCD_XOR
    call lcd_rectangle
#endif
menu_entry_end_focus:

menu_entry_undef:
    VARIABLE MENU_NB_ENTRY=MENU_NB_ENTRY+1
    endm


#ifndef MENU_M
    extern menu_draw_eq_band
#endif
