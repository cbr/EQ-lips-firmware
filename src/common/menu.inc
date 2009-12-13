#define MENU_ACTION_UNDEF           0x00
#define MENU_ACTION_INIT            0x01
#define MENU_ACTION_FOCUS           0x02
#define MENU_ACTION_UNFOCUS         0x03
#define MENU_ACTION_SELECT          0x04
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

;;; Macro which manage event dispatching for menu element
;;; parameters: label for different event
menu_event_dispatch macro label_init, label_focus, label_unfocus, label_select, label_undef
    ;; *** Check current action
    ;; INIT
    movlw MENU_ACTION_INIT
    subwf menu_action, W
    btfsc STATUS, Z
    goto label_init

    ;; ** Following events are  for specific entry
    ;; -> Check if it applies to current entry
    movlw MENU_NB_ENTRY
    subwf menu_value, W
    btfss STATUS, Z
    ;; not applied to current entry
    goto label_undef

    ;; FOCUS
    movlw MENU_ACTION_FOCUS
    subwf menu_action, W
    btfsc STATUS, Z
    goto label_focus
    ;; UNFOCUS
    movlw MENU_ACTION_UNFOCUS
    subwf menu_action, W
    btfsc STATUS, Z
    goto label_unfocus
    ;; SELECT
    movlw MENU_ACTION_SELECT
    subwf menu_action, W
    btfsc STATUS, Z
    goto label_select
    ;; Other unknown actions
    goto label_undef
    endm

#ifndef menu_number
#define menu_number 0
#else
#define menu_number (menu_number+1)
#endif

;;;
;;; This macro start a new dialog screen
;;; Changed registers: menu_value, menu_last_value, menu_action, param1
;;;
menu_start macro
    VARIABLE MENU_NB_ENTRY=0
    local menu_start_quit
    local menu_start_check_focus_change
    local menu_start_end_return
    local menu_start_check_select
    call_other_page lcd_clear
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
    ;; .DEF LABEL_MENU_START, global, value=$
    ;; .DEF LABEL_MENU_START, extern, value=$
menu_start_end_return:
menu_start_end_return_#v(menu_number)
    ;; Check if an action is already defined
    movf menu_action, W
    sublw MENU_ACTION_UNDEF
    btfss STATUS, Z
    goto menu_start_quit

    ;; No action defined
menu_start_check_focus_change:
    ;; Check if encoder value is equal to current menu value
    movf encoder_value, W
    banksel menu_value
    subwf menu_value, W
    btfsc STATUS, Z
    ;; equal, focus has not changed
    goto menu_start_check_select
    ;; not equal !
    ;; -> change focus
    movlw MENU_ACTION_UNFOCUS
    movwf menu_action
    goto menu_start_quit

menu_start_check_select:
    ;; Check if encoder switch is not 0
    movf encoder_sw, F
    btfsc STATUS, Z
    ;; equalt to 0 -> next event
    goto menu_start_quit
    ;; the encoder switch has been pressed
    movlw MENU_ACTION_SELECT
    movwf menu_action
    ;; reset encoder_sw
    encoder_ack_sw
    goto menu_start_quit

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
    banksel menu_value
    movwf menu_value
    movlw MENU_ACTION_FOCUS
    banksel menu_action
    movwf menu_action
    goto menu_end_quit
menu_end_undef:
    ;; reset menu_action
    movlw MENU_ACTION_UNDEF
    movwf menu_action
menu_end_quit:
    goto menu_start_end_return_#v(menu_number)
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

    menu_event_dispatch menu_entry_init, menu_entry_focus, menu_entry_unfocus, menu_entry_undef, menu_entry_undef

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

    call_other_page lcd_loc_string
    goto menu_entry_undef

#ifdef SIMPLE_FOCUS
menu_entry_unfocus:
    movlw 0
    movwf param1
    movlw pos
    movwf param2
    call_other_page lcd_locate
    movlw MENU_UNFOCUS_CHAR
    movwf param1
    call_other_page lcd_char
    goto menu_entry_undef
menu_entry_focus:
    ;; Current entry
    movlw 0
    movwf param1
    movlw pos
    movwf param2
    call_other_page lcd_locate
    movlw MENU_FOCUS_CHAR
    movwf param1
    call_other_page lcd_char
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
    call_other_page lcd_rectangle
#endif

menu_entry_undef:
    VARIABLE MENU_NB_ENTRY=MENU_NB_ENTRY+1
    endm


;;;
;;; This macro manage an entry element got eq band
;;; pos_x: band x position
;;; value_addr: address of eq value
;;;
menu_eq macro pos_x, value_addr
    local menu_eq_init
    local menu_eq_undef
    local menu_eq_focus
    local menu_eq_unfocus
    local menu_eq_select

    menu_event_dispatch menu_eq_init, menu_eq_focus, menu_eq_unfocus, menu_eq_select, menu_eq_undef

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
    call_other_page menu_draw_select
    goto menu_eq_undef

menu_eq_undef:
    VARIABLE MENU_NB_ENTRY=MENU_NB_ENTRY+1
    endm

;;;
;;; This macro is a template (exemple) for menu entry element
;;;
menu_template macro
    local menu_template_init
    local menu_template_undef
    local menu_template_focus
    local menu_template_unfocus
    local menu_template_select

    menu_event_dispatch menu_template_init, menu_template_focus, menu_template_unfocus, menu_template_select, menu_template_undef

menu_template_init:
    goto menu_template_undef

menu_template_unfocus:
    goto menu_template_undef
menu_template_focus:
    goto menu_template_undef
menu_template_select:
    goto menu_template_undef

menu_template_undef:
    VARIABLE MENU_NB_ENTRY=MENU_NB_ENTRY+1
    endm


#ifndef MENU_M
    extern menu_draw_eq_band
    extern menu_draw_focus_eq_band
    extern menu_draw_select
#endif
