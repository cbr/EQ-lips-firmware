#define MENU_ACTION_UNDEF           0x00
#define MENU_ACTION_INIT            0x01
#define MENU_ACTION_FOCUS           0x02
#define MENU_ACTION_UNFOCUS         0x03
#define MENU_ACTION_SELECT          0x04
#define MENU_ACTION_UNSELECT        0x05
#define MENU_INIT_LAST_VALUE        0xFF

#define MENU_STATE_NONE             0x00
#define MENU_STATE_SELECT           0x01

#define SIMPLE_FOCUS

#ifdef SIMPLE_FOCUS
#define MENU_FOCUS_CHAR            '>'
#define MENU_UNFOCUS_CHAR          ' '
#define MENU_STRING_POS_X           1
#else
#define MENU_STRING_POS_X           0
#endif

    VARIABLE MENU_NB_ENTRY

;;; Macro which manage event dispatching for menu element
;;; parameters: label for different event
menu_event_dispatch macro label_init, label_focus, label_unfocus, label_select, label_unselect
    local menu_event_dispatch_end
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
    goto menu_event_dispatch_end

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
    ;; UNSELECT
    movlw MENU_ACTION_UNSELECT
    subwf menu_action, W
    btfsc STATUS, Z
    goto label_unselect
    ;; Other unknown actions
menu_event_dispatch_end:
    endm

#ifndef menu_number
#define menu_number 0
#else
#define menu_number (menu_number+1)
#endif

;;;
;;; This macro define the begining of a new dialog screen.
;;; A dialog is constantly looping between the 'menu_start'
;;; and the 'menu_end' macro. In 'menu_start' the action
;;; (or event) to be managed is evaluated. Actions are separated
;;; in two categories : states and sub-states.
;;; Changed registers: menu_value, menu_action, param1
;;;
menu_start macro
    VARIABLE MENU_NB_ENTRY=0
    local menu_start_quit
    local menu_start_check_focus_change
    local menu_start_end_return
    local menu_start_check_select
    local menu_start_state_select_check_event
    local menu_start_state_none_check_event
    local menu_start_check_leave_select
    call_other_page lcd_clear
    ;; init variables
    banksel menu_value
    clrf menu_value
    banksel menu_state
    clrf menu_state
    banksel menu_leave_state
    clrf menu_leave_state

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
    ;; Check current menu state
    banksel menu_state
    movf menu_state, W
    sublw MENU_STATE_SELECT
    btfss STATUS, Z
    ;; Select state not active
    goto menu_start_state_none_check_event
    ;; Select state active
    ;; **** STATE SELECT ****
menu_start_state_select_check_event:
menu_start_check_leave_select:
    movf menu_leave_state, W
    btfsc STATUS, Z
    goto menu_start_check_enc_change
    clrf menu_leave_state
    movlw MENU_ACTION_UNSELECT
    movwf menu_action
    goto menu_start_quit

menu_start_check_enc_change:
    goto menu_start_quit

    ;; **** STATE NONE ****
menu_start_state_none_check_event:
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
    ;; Change state
    movlw MENU_STATE_SELECT
    banksel menu_state
    movwf menu_state
    ;; reset encoder_sw
    encoder_ack_sw
    goto menu_start_quit

menu_start_quit:
    endm


;;;
;;; This macro end a dialog screen
;;; Changed registers: menu_action
;;;
menu_end macro
    local menu_end_undef
    local menu_end_quit
    local menu_end_init
    local menu_end_unfocus
    local menu_end_select
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
    ;; UNSELECT
    movlw MENU_ACTION_UNSELECT
    subwf menu_action, W
    btfsc STATUS, Z
    goto menu_end_select
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
menu_end_select:
    ;; After selection, reset encoder settings
    movf menu_value, W
    movwf param1
    clrf param2
    movlw MENU_NB_ENTRY-1
    movwf param3
    call_other_page encoder_set_value
    ;; Change state to none
    movlw MENU_STATE_NONE
    banksel menu_state
    movwf menu_state
    ;; reset action
    movlw MENU_ACTION_UNDEF
    movwf menu_action
    goto menu_end_quit
menu_end_undef:
    ;; reset menu_action
    movlw MENU_ACTION_UNDEF
    movwf menu_action
menu_end_quit:
    goto menu_start_end_return_#v(menu_number)
    endm

;;; This macro ask to leave the selection sub state of a menu.
;;; On the next event loop the event MENU_ACTION_UNSELECT will
;;; be active.
menu_leave_selection macro
    movlw 1
    movwf menu_leave_state
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
    local menu_template_unselect

    menu_event_dispatch menu_template_init, menu_template_focus, menu_template_unfocus, menu_template_select, menu_template_unselect
    goto menu_template_undef
menu_template_init:
    goto menu_template_undef

menu_template_unfocus:
    goto menu_template_undef
menu_template_focus:
    goto menu_template_undef
menu_template_select:
    goto menu_template_undef
menu_template_unselect:
    goto menu_template_undef

menu_template_undef:
    VARIABLE MENU_NB_ENTRY=MENU_NB_ENTRY+1
    endm


#ifndef MENU_M
    extern menu_state
    extern menu_leave_state
#endif
