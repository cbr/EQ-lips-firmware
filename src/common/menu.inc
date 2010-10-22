;;;
;;; Copyright 2010 Cedric Bregardis.
;;;
;;; This file is part of EQ-lips firmware.
;;;
;;; EQ-lips firmware is free software: you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundation, version 3 of the
;;; License.
;;;
;;; EQ-lips firmware is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with EQ-lips firmware.  If not, see <http://www.gnu.org/licenses/>.
;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DEFINES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#define MENU_EVENT_UNDEF               0x00
#define MENU_EVENT_INIT                0x01
#define MENU_EVENT_FOCUS               0x02
#define MENU_EVENT_UNFOCUS             0x03
#define MENU_EVENT_SELECT              0x04
#define MENU_EVENT_UNSELECT            0x05
#define MENU_EVENT_SELECT_VALUE_CHANGE 0x06
#define MENU_EVENT_SELECT_SWITCH       0x07
#define MENU_EVENT_REFRESH             0x08
#define MENU_EVENT_TICK                0x09
#define MENU_INIT_LAST_VALUE            0xFF

#define MENU_ACTION_UNDEF               0x00
#define MENU_ACTION_INIT                MENU_EVENT_INIT
#define MENU_ACTION_FOCUS               MENU_EVENT_FOCUS
#define MENU_ACTION_UNFOCUS             MENU_EVENT_UNFOCUS
#define MENU_ACTION_UNSELECT            MENU_EVENT_UNSELECT
#define MENU_ACTION_SELECT              MENU_EVENT_SELECT
#define MENU_ACTION_SELECT_VALUE_CHANGE MENU_EVENT_SELECT_VALUE_CHANGE
#define MENU_ACTION_SELECT_SWITCH       MENU_EVENT_SELECT_SWITCH
#define MENU_ACTION_REFRESH             MENU_EVENT_REFRESH
#define MENU_ACTION_TICK                MENU_EVENT_TICK
#define MENU_ACTION_REFRESH_AND_FOCUS_CHANGE        (0x80 + 0x01)
#define MENU_ACTION_COMPLETE_INIT       (0x80 + 0x02)
#define MENU_ACTION_LEAVE               (0x80 + 0x03)
#define MENU_ACTION_SELECT_SPEC_ENTRY   (0x80 + 0x04)

#define MENU_STATE_NONE                 0x00
#define MENU_STATE_SELECT               0x01
#define SIMPLE_FOCUS

#ifdef SIMPLE_FOCUS
#define MENU_FOCUS_CHAR                 '>'
#define MENU_UNFOCUS_CHAR               ' '
#define MENU_STRING_POS_X               1
#else
#define MENU_STRING_POS_X               0
#endif



    VARIABLE MENU_NB_TOTAL_ENTRY
    VARIABLE MENU_NB_FOCUSABLE_ENTRY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MACROS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;
;;; Get absolute menu entry number from its id
;;;
menu_get_nb_from_id_macro macro id
    movlw entry_nb_from_id_#v(id)
    endm

;;;
;;; Get absolute menu entry nb from its number among focusable entries subset
;;;
menu_get_nb_from_focusable_nb_macro macro focus_nb
    movlw entry_nb_from_focus_nb_#v(focus_nb)
    endm

;;;
;;; Declare a menu entry which is focusable
;;;
MENU_NEW_ENTRY_WITH_FOCUS macro
entry_nb_from_focus_nb_#v(MENU_NB_FOCUSABLE_ENTRY) equ MENU_NB_TOTAL_ENTRY
    VARIABLE MENU_NB_TOTAL_ENTRY=MENU_NB_TOTAL_ENTRY+1
    VARIABLE MENU_NB_FOCUSABLE_ENTRY=MENU_NB_FOCUSABLE_ENTRY+1
    endm

;;;
;;; Declare a menu entry which is not focusable
;;;
MENU_NEW_ENTRY_WITHOUT_FOCUS macro
    ;; Menu entry ID
    VARIABLE MENU_NB_TOTAL_ENTRY=MENU_NB_TOTAL_ENTRY+1
    endm

;;;
;;; Macro which manage event dispatching for menu element
;;; id: uniq id of menu_entry element
;;; label_init: label for initialization event
;;; label_focus: label for focus event
;;; label_unfocus: label for unfocus event
;;; label_select: label for select event
;;; label_unselect: label for unselect event
;;; label_select_value_change: label for 'encoder value change' event during select sub state
;;; label_select_switch: label for 'encoder switch' event during select sub state
;;; label_refresh: label for refresh event
;;;
menu_event_dispatch macro id, label_init, label_focus, label_unfocus, label_select, label_unselect, label_select_value_change, label_select_switch, label_refresh

entry_nb_from_id_#v(id) equ MENU_NB_TOTAL_ENTRY

    local menu_event_dispatch_end
    local menu_event_not_current_entry
    ;; *** Check event for all entries
#if label_init == UNUSED_PARAM
#else
    ;; INIT
    movlw MENU_EVENT_INIT
    subwf menu_event, W
    btfsc STATUS, Z
    goto label_init
#endif

    ;; ** Following events are for specific entry
    ;; -> Check if it applies to current entry
    movlw MENU_NB_TOTAL_ENTRY
    subwf menu_value, W
    btfss STATUS, Z
    ;; not applied to current entry
    goto menu_event_not_current_entry

#if label_focus == UNUSED_PARAM
#else
    ;; FOCUS
    movlw MENU_EVENT_FOCUS
    subwf menu_event, W
    btfsc STATUS, Z
    goto label_focus
#endif

#if label_unfocus == UNUSED_PARAM
#else
    ;; UNFOCUS
    movlw MENU_EVENT_UNFOCUS
    subwf menu_event, W
    btfsc STATUS, Z
    goto label_unfocus
#endif

#if label_select == UNUSED_PARAM
#else
    ;; SELECT
    movlw MENU_EVENT_SELECT
    subwf menu_event, W
    btfsc STATUS, Z
    goto label_select
#endif

#if label_unselect == UNUSED_PARAM
#else
    ;; UNSELECT
    movlw MENU_EVENT_UNSELECT
    subwf menu_event, W
    btfsc STATUS, Z
    goto label_unselect
#endif

#if label_select_value_change == UNUSED_PARAM
#else
    ;; SELECT_VALUE_CHANGE
    movlw MENU_EVENT_SELECT_VALUE_CHANGE
    subwf menu_event, W
    btfsc STATUS, Z
    goto label_select_value_change
#endif

#if label_select_switch == UNUSED_PARAM
#else
    ;; SELECT_SWITCH
    movlw MENU_EVENT_SELECT_SWITCH
    subwf menu_event, W
    btfsc STATUS, Z
    goto label_select_switch
#endif

    goto menu_event_dispatch_end

    ;; ** Following events are for all entries execpt the current one
menu_event_not_current_entry:
#if label_refresh == UNUSED_PARAM
#else
    ;; REFRESH
    movlw MENU_EVENT_REFRESH
    subwf menu_event, W
    btfsc STATUS, Z
    goto label_refresh
#endif

    ;; Other unknown actions
menu_event_dispatch_end:
    endm

#ifndef menu_number
#define menu_number 0
#else
#define menu_number (menu_number+1)
#endif


;;;
;;; This macro define the beginning of a new dialog screen.
;;; A dialog is constantly looping between the 'menu_start'
;;; and the 'menu_end' macro. In 'menu_start' the following process
;;; is realized:
;;; - If there is no action
;;;   - If there is an asked action
;;;     - action = asked_action
;;;   - Else check automatic action:
;;;     - Current state = none
;;;       - Encoder move -> complex action: change focus
;;;       - switch press -> simple action: select current entry
;;;     - Current state = selected
;;;       - Encoder move -> simple action: select value change
;;;       - switch press -> simple action select switch
;;; - Realize action:
;;;   - Simple action: event = action
;;;   - Complex action:
;;;     - Evaluate action step
;;;       - Refresh
;;;       - Leave selection
;;;       - Select other entry
;;;
;;; There are two kinds of actions: simple and complex. Simple action only consist
;;; to set the event to the value of the simple action. Complex action are identified
;;; by the high order bit which is set. They are managed on multiple cycle. In each cycle,
;;; a step of the action is realized (most often setting a particular event). On the last
;;; step the current action register must be cleared in order to be able to manage another
;;; action on next cycle.
;;; Events can be separated in two categories: events of states and event of sub-states.
;;; tick_function: function called at every timer tick (period to be checked in timer.h)
;;; Changed registers: menu_value, menu_event, param1
;;; idle_function: called (if defined) if there is no action to execute
;;;
menu_start macro tick_function, idle_function
    local menu_start_quit
    local menu_start_no_idle
    local menu_start_end_return
    local menu_start_no_tick
#ifdef TREMOLO
    local menu_start_check_tick
#endif
    call_other_page lcd_clear
    ;; init variables
    clrf menu_value
    clrf menu_event
    ;; Only one banksel for all variable (they are on the same page)
    banksel menu_state
    clrf menu_state
    clrf menu_action
    clrf menu_action_step
    clrf menu_focused_entry

    ;; Action to realize is 'complete init' the first time
    movlw MENU_ACTION_COMPLETE_INIT
    banksel menu_asked_action
    movwf menu_asked_action

    ;; define return label for 'end' macro
    ;; (An xcoff symbol is used, because of relocatable code)
    ;; .DEF LABEL_MENU_START, global, value=$
    ;; .DEF LABEL_MENU_START, extern, value=$
menu_start_end_return:
menu_start_end_return_#v(menu_number)

    movlw high menu_get_nb_from_focusable_nb
    movwf param1
    movlw low menu_get_nb_from_focusable_nb
    movwf param2
    call_other_page menu_start_process

#if tick_function == UNUSED_PARAM
#else

#ifndef TREMOLO
    ;; Timer is not activated, so tick_function cannot be defined in menu_start macro
#error timer_error
#endif
    movf menu_event, W
    sublw MENU_EVENT_TICK
    btfss STATUS, Z
    goto menu_start_no_tick
    call_other_page tick_function
menu_start_no_tick:
#endif


#if idle_function == UNUSED_PARAM
#else
    movlw MENU_EVENT_UNDEF
    subwf menu_event, W
    btfss STATUS, Z
    goto menu_start_no_idle
    call_other_page idle_function
menu_start_no_idle:
#endif
menu_start_quit:
    VARIABLE MENU_NB_FOCUSABLE_ENTRY=0
    VARIABLE MENU_NB_TOTAL_ENTRY=0
    endm

;;;
;;; This macro end a dialog screen
;;; Changed registers: menu_event
;;;
menu_end macro
    local menu_end_init_encoder
    local menu_end_do_not_init_encoder
    movf menu_event, W
    sublw MENU_EVENT_INIT
    btfsc STATUS, Z
    goto menu_end_init_encoder
    movf menu_event, W
    sublw MENU_EVENT_UNSELECT
    btfss STATUS, Z
    goto menu_end_do_not_init_encoder
menu_end_init_encoder:
#if 0
    movlw .16
    movwf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    movlw  MENU_NB_FOCUSABLE_ENTRY
    movwf param1
    clrf param2
    call_other_page lcd_int

    movlw .20
    movwf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    movlw  MENU_NB_TOTAL_ENTRY
    movwf param1
    clrf param2
    call_other_page lcd_int
#endif
    ;; After unfocus and init, encoder have to be initialized
    banksel menu_focused_entry
    movf menu_focused_entry, W
    movwf param1
    clrf param2
    movlw MENU_NB_FOCUSABLE_ENTRY-1
    movwf param3
    call_other_page encoder_set_value

menu_end_do_not_init_encoder:
    local menu_end_undef
    ;; reset menu_event
    movlw MENU_EVENT_UNDEF
    movwf menu_event
    goto menu_start_end_return_#v(menu_number)

;;;
;;; In the 'end' macro we also write the function which return the
;;; absolute menu entry number from the focusable number
;;; param1: focusable entry nb for which absolute entry nb must be returned (in W)
;;;
menu_get_nb_from_focusable_nb:
    ;; This function is realized by recursively calling a macro
    menu_get_nb_from_focusable_nb_func_write MENU_NB_FOCUSABLE_ENTRY-1
    return

    endm

;;;
;;; This macro ask to leave the selection sub state of a menu.
;;; On the next event loop the event MENU_EVENT_UNSELECT will
;;; be active.
;;;
menu_leave_selection macro
    movlw MENU_ACTION_LEAVE
    banksel menu_asked_action
    movwf menu_asked_action
    endm

;;;
;;; This macro ask to refresh all menu entries except the current one,
;;; on next event loop
;;;
menu_ask_refresh macro
    movlw MENU_ACTION_REFRESH
    banksel menu_asked_action
    movwf menu_asked_action
    endm

;;;
;;; This macro ask to refresh simulate an encoder switch press while
;;; being in select state
;;;
menu_ask_select_switch macro
    movlw MENU_ACTION_SELECT_SWITCH
    banksel menu_asked_action
    movwf menu_asked_action
    endm

;;;
;;; This macro ask to select the given menu entry
;;; on next event loop
;;;
menu_select_specific_entry_from_id macro entry_id
    movlw MENU_ACTION_SELECT_SPEC_ENTRY
    banksel menu_asked_action
    movwf menu_asked_action
    menu_get_nb_from_id_macro entry_id
    banksel menu_asked_action_param
    movwf menu_asked_action_param
    endm

menu_change_focus macro
    movlw MENU_ACTION_REFRESH_AND_FOCUS_CHANGE
    banksel menu_asked_action
    movwf menu_asked_action
    endm

;;;
;;; This macro ask to select the given menu entry
;;; on next event loop
;;;
menu_select_specific_entry_from_nb macro entry_nb
    movlw MENU_ACTION_SELECT_SPEC_ENTRY
    banksel menu_asked_action
    movwf menu_asked_action
    movlw entry_nb
    banksel menu_asked_action_param
    movwf menu_asked_action_param

    endm

;;;
;;; This macro is used recusively to write function menu_get_nb_from_focusable_nb
;;;
menu_get_nb_from_focusable_nb_func_write macro nb_focusable_entry
    ;; local not_this_number
    movf param1, W
    sublw nb_focusable_entry
    btfss STATUS, Z
    goto not_this_number_#v(nb_focusable_entry)
    menu_get_nb_from_focusable_nb_macro nb_focusable_entry
    return
not_this_number_#v(nb_focusable_entry)
    if nb_focusable_entry > 0
    menu_get_nb_from_focusable_nb_func_write (nb_focusable_entry-1)
    endif
    endm


;;;
;;; This macro is a template (exemple) for menu entry element
;;;
menu_template macro id
    local menu_template_init
    local menu_template_undef
    local menu_template_focus
    local menu_template_unfocus
    local menu_template_select
    local menu_template_unselect
    local menu_template_select_value_change

    menu_event_dispatch id, menu_template_init, menu_template_focus, menu_template_unfocus, menu_template_select, menu_template_unselect, menu_template_select_value_change, menu_template_select_switch, menu_template_refresh

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
menu_template_select_value_change:
    goto menu_template_undef
menu_template_select_switch:
    goto menu_template_undef
menu_template_refresh:
    goto menu_template_undef
menu_template_undef:
    MENU_NEW_ENTRY_WITH_FOCUS
    endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PUBLIC DECLARATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#ifndef MENU_M
    ;; Variables (non shared)
    extern menu_value
    extern menu_event
    ;; Variables (shared)
    extern menu_state
    extern menu_select_value
    extern menu_action
    extern menu_action_step
    extern menu_asked_action
    extern menu_asked_action_param
    extern menu_focused_entry
    ;; Functions
    extern menu_selection_encoder_configure
    extern menu_start_process
#endif
