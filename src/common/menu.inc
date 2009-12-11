#define MENU_ACTION_UNDEF           0x00
#define MENU_ACTION_INIT            0x01
#define MENU_ACTION_FOCUS           0x02
#define MENU_ACTION_UNFOCUS         0x03
#define MENU_INIT_LAST_VALUE        0xFF

;; #define SIMPLE_FOCUS

#ifdef SIMPLE_FOCUS
#define MENU_FOCUS_CHAR            '>'
#define MENU_UNFOCUS_CHAR          ' '
#define MENU_STRING_POS_X           1
#else
#define MENU_STRING_POS_X           0
#endif

    ;; extern menu_last_value
    VARIABLE MENU_NB_ENTRY

;;;
;;; This macro start a new dialog screen
;;; Changed registers: menu_value, menu_last_value, menu_action, param1
;;;
menu_start macro
    VARIABLE MENU_NB_ENTRY=0
    local menu_start_quit
    local menu_start_check_focus_change
    local menu_start_end_return
    call lcd_clear
    ;; init variable
    ;; movlw MENU_INIT_LAST_VALUE
    ;; movwf menu_last_value
    movlw 0x00
    movwf menu_value

    ;; Action to realize is 'init' the first time
    movlw MENU_ACTION_INIT
    movwf menu_action
    goto menu_start_quit
    ;; define return label for 'end' macro
    ;; (An xcoff symbol is used, because of relocatable code)
    .DEF LABEL_MENU_START, global, value=$
menu_start_end_return:
    ;; Check if an action is already defined
    movf menu_action, W
    sublw MENU_ACTION_UNDEF
    btfss STATUS, Z
    goto menu_start_quit

    ;; No action defined
menu_start_check_focus_change:
    ;; Check if encoder value is equal to current menu value
    movf encoder_value, W
    subwf menu_value, W
    btfsc STATUS, Z
    goto menu_start_quit
    ;; not equal !
    ;; -> change focus
    movlw MENU_ACTION_UNFOCUS
    movwf menu_action
menu_start_quit:
    endm


;;;
;;; This macro end a dialog screen
;;; Changed registers: menu_last_value, menu_action
;;;
menu_end macro
    local menu_end_undef
    local menu_end_quit
    local menu_end_init
    local menu_end_unfocus
    ;; *** Check current action
    ;; INIT
    movlw MENU_ACTION_INIT
    subwf menu_action, W
    btfsc STATUS, Z
    goto menu_end_init
    ;; UNFOCUS
    movlw MENU_ACTION_UNFOCUS
    subwf menu_action, W
    btfsc STATUS, Z
    goto menu_end_unfocus
    ;; Other unknown actions
    goto menu_end_undef

menu_end_init:
    encoder_set_value 0, 0, MENU_NB_ENTRY-1
    ;; After init, we manage focus entry
    movlw MENU_ACTION_FOCUS
    movwf menu_action
    goto menu_end_quit
menu_end_unfocus:
    ;; After unfocus, manage focus
    movf encoder_value, W
    movwf menu_value
    movlw MENU_ACTION_FOCUS
    movwf menu_action
    goto menu_end_quit
menu_end_undef:
    ;; reset menu_action
    movlw MENU_ACTION_UNDEF
    movwf menu_action
menu_end_quit:
    goto LABEL_MENU_START
    endm


;;;
;;; This macro add a menu entry into a dialog screen
;;; string: label of the menu entry
;;; pos: y position of menu entry
;;; Changed registers: param1, param2, param3, param4
;;;
menu_entry macro string, pos
    local menu_entry_init
    local menu_entry_undef
    local menu_entry_focus
    local menu_entry_unfocus
    ;; *** Check current action
    ;; INIT
    movlw MENU_ACTION_INIT
    subwf menu_action, W
    btfsc STATUS, Z
    goto menu_entry_init

    ;; ** Following events are  for specific entry
    ;; -> Check if it applies to current entry
    movlw MENU_NB_ENTRY
    subwf menu_value, W
    btfss STATUS, Z
    ;; not applied to current entry
    goto menu_entry_undef

    ;; FOCUS
    movlw MENU_ACTION_FOCUS
    subwf menu_action, W
    btfsc STATUS, Z
    goto menu_entry_focus
    ;; UNFOCUS
    movlw MENU_ACTION_UNFOCUS
    subwf menu_action, W
    btfsc STATUS, Z
    goto menu_entry_unfocus
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
    goto menu_entry_undef

#ifdef SIMPLE_FOCUS
menu_entry_unfocus:
    movlw 0
    movwf param1
    movlw pos
    movwf param2
    call lcd_locate
    movlw MENU_UNFOCUS_CHAR
    movwf param1
    call lcd_char
    goto menu_entry_undef
menu_entry_focus:
    ;; Current entry
    movlw 0
    movwf param1
    movlw pos
    movwf param2
    call lcd_locate
    movlw MENU_FOCUS_CHAR
    movwf param1
    call lcd_char
    goto menu_entry_undef
#else
menu_entry_unfocus:
menu_entry_focus:
    ;; draw the focus rectangle with XOR
    ;; (So, the same operation can focus and also unfocus)
    ;; Current entry
    movlw 0
    movwf param1
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
    call lcd_rectangle
#endif

menu_entry_undef:
    VARIABLE MENU_NB_ENTRY=MENU_NB_ENTRY+1
    endm


#ifndef MENU_M
    extern menu_draw_eq_band
#endif
