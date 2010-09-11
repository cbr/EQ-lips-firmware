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

#define MENU_M

#include <cpu.inc>
#include <lcd.inc>
#include <std.inc>
#include <global.inc>
#include <menu.inc>
#include <encoder.inc>
#include <interrupt.inc>

#define MENU_ACTION_STEP_1              0x0
#define MENU_ACTION_STEP_2              0x1
#define MENU_ACTION_STEP_3              0x2
#define MENU_ACTION_STEP_4              0x3
#define MENU_ACTION_STEP_5              0x4
#define MENU_ACTION_STEP_6              0x5

#define MENU_BUTTON_NB_DRAW_SELECT  0x8

;;; Global non shared variables
    UDATA_SHR
;;; Current menu_entry
menu_value RES 1
    global menu_value;
;;; Current event to be realized
menu_event RES 1
    global menu_event;

;;; Shared variables
COMMON_VAR UDATA
;;; State of current menu entry
menu_state              RES 1
    global menu_state
;;; Current action step
menu_action_step        RES 1
    global menu_action_step
;;; Current action
menu_action        RES 1
    global menu_action
;;; Asked action
menu_asked_action        RES 1
    global menu_asked_action
;;; Internal value of selected entry
menu_select_value       RES 1
    global menu_select_value
menu_asked_action_param RES 1
    global menu_asked_action_param
menu_focused_entry RES 1
    global menu_focused_entry
;;; relocatable code
COMMON CODE

;;;
;;; Manage main process of menu_start macro
;;; param1: high order byte of menu_get_nb_from_focusable_nb function
;;; param2: low order byte of menu_get_nb_from_focusable_nb function
;;;
menu_start_process:
    global menu_start_process

    ;; If there is no action
    banksel menu_action
    movf menu_action, W
    btfss STATUS, Z
    goto menu_start_process_check_actions
    ;; If there is an asked action
    banksel menu_asked_action
    movf menu_asked_action, W
    btfsc STATUS, Z
    goto menu_start_process_no_asked_action
    ;; action = asked_action
    banksel menu_action
    movwf menu_action
    clrf menu_asked_action
    goto menu_start_process_check_actions
    ;; Else (there is no asked action)
menu_start_process_no_asked_action:
    ;; Check automatic actions
;;;   - Else check automatic action:
;;;     - All states:
;;;       - Timer event -> simple action: tick
;;;     - Current state = selected
;;;       - Encoder move -> simple action: select value change
;;;       - switch press -> simple action select switch
;;;     - Current state = none
;;;       - Encoder move -> complex action: change focus
;;;       - switch press -> simple action: select current entry
    ;; **** ALL STATE ****

#ifdef TREMOLO
menu_start_process_check_tick:
    ;; Check if timer event has occured
    movf timer_cpt, W
    btfsc STATUS, Z
    ;; No timer event -> check next event
    goto menu_start_state_check_event
    ;; Timer event has occured
    ;; -> decrement timer cpt
    decf timer_cpt, F
    ;; -> Set action
    movlw MENU_ACTION_TICK
    banksel menu_action
    movwf menu_action
    goto menu_start_process_check_actions
#endif
menu_start_state_check_event:
    ;; **** specific STATE ? ****
    ;; Check current menu state
    banksel menu_state
    movf menu_state, W
    sublw MENU_STATE_SELECT
    btfss STATUS, Z
    ;; Select state not active
    goto menu_start_process_state_none
    ;; Select state active
    ;; **** STATE SELECT ****
menu_start_process_state_select:

menu_start_process_check_select_enc_change:
    ;; Check if encoder value is equal to current select value
    movf encoder_value, W
    banksel menu_select_value
    subwf menu_select_value, W
    btfsc STATUS, Z
    ;; equal, select value has not changed
    goto menu_start_process_check_select_switch
    ;; not equal !
    ;; -> change select value
    movlw MENU_ACTION_SELECT_VALUE_CHANGE
    banksel menu_action
    movwf menu_action
    ;; memorize new value
    movf encoder_value, W
    banksel menu_select_value
    movwf menu_select_value
    goto menu_start_process_check_actions

menu_start_process_check_select_switch:
    ;; Check if encoder switch is not 0
    movf encoder_sw, F
    btfsc STATUS, Z
    ;; equalt to 0 -> next select event
    goto menu_start_process_check_actions
    ;; the encoder switch has been pressed
    movlw MENU_ACTION_SELECT_SWITCH
    banksel menu_action
    movwf menu_action
    ;; reset encoder_sw
    encoder_ack_sw
    goto menu_start_process_check_actions

    ;; **** STATE NONE ****
menu_start_process_state_none:
menu_start_process_check_refresh_and_focus_change:
    ;; Check if encoder value is equal to current focused menu value
    movf encoder_value, W
    banksel menu_focused_entry
    subwf menu_focused_entry, W
    btfsc STATUS, Z
    ;; equal, focus has not changed
    goto menu_start_process_check_select
    ;; not equal !
    ;; -> change focus
    movlw MENU_ACTION_REFRESH_AND_FOCUS_CHANGE
    banksel menu_action
    movwf menu_action
    ;; However, we do not realize the first step of REFRESH_AND_FOCUS_CHANGE: no refresh is needed
    movlw MENU_ACTION_STEP_2
    banksel menu_action_step
    movwf menu_action_step

    goto menu_start_process_check_actions

menu_start_process_check_select:
    ;; Check if encoder switch is not 0
    movf encoder_sw, F
    btfsc STATUS, Z
    ;; equalt to 0 -> next event
    goto menu_start_process_check_actions
    ;; the encoder switch has been pressed
    movlw MENU_ACTION_SELECT
    banksel menu_action
    movwf menu_action
    ;; Change state
    movlw MENU_STATE_SELECT
    banksel menu_state
    movwf menu_state
    ;; reset encoder_sw
    encoder_ack_sw
    goto menu_start_process_check_actions

    ;; *****************************************************
menu_start_process_check_actions:
    banksel menu_action
    movf menu_action, W
    btfsc STATUS, Z
    ;; No action, leave
    goto menu_start_process_end
    ;; There is a defined action
    btfsc menu_action, 7
    goto menu_start_process_complex_action
;;;   - Simple action: event = action
menu_start_process_simple_action
    ;; event is the action
    banksel menu_action
    movf menu_action, W
    movwf menu_event
    clrf menu_action
    goto menu_start_process_end

;;;   - Complex action:
menu_start_process_complex_action:

menu_start_process_complex_action_refresh_and_focus_change:
    banksel menu_action
    movf menu_action, W
    sublw MENU_ACTION_REFRESH_AND_FOCUS_CHANGE
    btfss STATUS, Z
    goto menu_start_process_complex_action_refresh_and_focus_change_end
    ;; Check action step
    banksel menu_action_step
    movf menu_action_step, W
    sublw MENU_ACTION_STEP_1
    btfss STATUS, Z
    goto menu_start_process_complex_action_refresh_and_focus_change_2
    ;; step 1: refresh
menu_start_process_complex_action_refresh_and_focus_change_1:
    incf menu_action_step, F
    movlw MENU_EVENT_REFRESH
    movwf menu_event
    goto menu_start_process_end

menu_start_process_complex_action_refresh_and_focus_change_2:
    movf menu_action_step, W
    sublw MENU_ACTION_STEP_2
    btfss STATUS, Z
    goto menu_start_process_complex_action_refresh_and_focus_change_3
    ;; step 2: unfocus
    incf menu_action_step, F
    movlw MENU_EVENT_UNFOCUS
    movwf menu_event
    goto menu_start_process_end
    ;; step 3: focus
menu_start_process_complex_action_refresh_and_focus_change_3:
    ;; This is the last step of focus change
    ;; Reinit
    clrf menu_action_step
    clrf menu_action
    ;; Get new focused entry
    movf encoder_value, W
    banksel menu_focused_entry
    movwf menu_focused_entry
    ;; Get corresponding absolute menu entry nb into menu_value
    ;; This value can be get with the help of function given in parameters (param1 and param2)
    ;; We have to make an indirect call to this function by correctly managing page changes.
#if 1
    ;; Do the call locally ... (1)
    call menu_start_process_complex_action_refresh_and_focus_change_3_call_label
    ;; ...(2) function has been returned.
    ;; Store result into menu_value
    movwf menu_value
    ;; reset PCLATH according to current position
    pagesel $
    ;; The operation is finished
    goto menu_start_process_complex_action_refresh_and_focus_change_3_after_call
menu_start_process_complex_action_refresh_and_focus_change_3_call_label:
    ;; ... (1) Now the call have been made:
    ;; returned position has been memorized.
    ;; Now, to go to the function code, 3 step have to be realized:
    ;; Step 1:
    ;; Prepare plcath
    movf param1, W
    movwf PCLATH
    ;; Step 2: Prepare parameter
    ;; prepare parameter
    banksel menu_focused_entry
    movf menu_focused_entry, W
    movwf param1
    ;; Step 3: go to function
    movf param2, W
    movwf PCL
    ;; The function will do a 'return'. It will bring back to (2)...
menu_start_process_complex_action_refresh_and_focus_change_3_after_call:
#else
    banksel menu_focused_entry
    movf menu_focused_entry, W
    movwf menu_value
#endif
#if 0
    movlw 4
    movwf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    movf menu_value, W
    movwf param1
    clrf param2
    call_other_page lcd_int
#endif

    ;; Set event value
    movlw MENU_EVENT_FOCUS
    movwf menu_event
    goto menu_start_process_end
menu_start_process_complex_action_refresh_and_focus_change_end:

menu_start_process_complex_action_complete_init:
    banksel menu_action
    movf menu_action, W
    sublw MENU_ACTION_COMPLETE_INIT
    btfss STATUS, Z
    goto menu_start_process_complex_action_complete_init_end
    ;; Check action step
    banksel menu_action_step
    movf menu_action_step, W
    sublw MENU_ACTION_STEP_1
    btfss STATUS, Z
    goto menu_start_process_complex_action_complete_init_2
    ;; step 1: unfocus
menu_start_process_complex_action_complete_init_1:
    incf menu_action_step, F
    movlw MENU_EVENT_INIT
    movwf menu_event
    goto menu_start_process_end
    ;; step 2: focus
menu_start_process_complex_action_complete_init_2:
    ;; This is the last step of complete init
    clrf menu_action_step
    clrf menu_action
    ;; encoder_set_value 0, 0, MENU_NB_FOCUSABLE_ENTRY-1
    ;; After init, we manage focus entry
    movlw MENU_EVENT_FOCUS
    movwf menu_event
    goto menu_start_process_end
menu_start_process_complex_action_complete_init_end:

menu_start_process_complex_action_leave:
    banksel menu_action
    movf menu_action, W
    sublw MENU_ACTION_LEAVE
    btfss STATUS, Z
    goto menu_start_process_complex_action_leave_end
    ;; Unselect event
    movlw MENU_EVENT_UNSELECT
    movwf menu_event
    ;; This is the last step of complete init
    clrf menu_action_step
    clrf menu_action
    ;; After selection, reset encoder settings
    banksel menu_focused_entry
    movf menu_focused_entry, W
    movwf param1
    clrf param2
    movlw MENU_NB_FOCUSABLE_ENTRY-1
    movwf param3
    ;; call_other_page encoder_set_value
#if 0
    movlw 4
    movwf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    movlw MENU_NB_FOCUSABLE_ENTRY-1
    movwf param1
    clrf param2
    call_other_page lcd_int
#endif
    ;; Change state to none
    movlw MENU_STATE_NONE
    banksel menu_state
    movwf menu_state
    goto menu_start_process_end
menu_start_process_complex_action_leave_end:

menu_start_process_complex_action_select_specific_entry:
    banksel menu_action
    movf menu_action, W
    sublw MENU_ACTION_SELECT_SPEC_ENTRY
    btfss STATUS, Z
    goto menu_start_process_complex_action_select_specific_entry_end
    ;; Check action step
    banksel menu_action_step
    movf menu_action_step, W
    sublw MENU_ACTION_STEP_1
    btfss STATUS, Z
    goto menu_start_process_complex_action_select_specific_entry_2
    ;; step 1:
menu_start_process_complex_action_select_specific_entry_1:
    incf menu_action_step, F
    ;; Refresh
    movlw MENU_EVENT_REFRESH
    movwf menu_event
    goto menu_start_process_end

    ;; step 2:
menu_start_process_complex_action_select_specific_entry_2:
    movf menu_action_step, W
    sublw MENU_ACTION_STEP_2
    btfss STATUS, Z
    goto menu_start_process_complex_action_select_specific_entry_3
    ;; Prepare next step
    incf menu_action_step, F
    ;; Check current menu state
    banksel menu_state
    movf menu_state, W
    sublw MENU_STATE_SELECT
    btfss STATUS, Z
    ;; No current selection, go directly to next step
    goto menu_start_process_complex_action_select_specific_entry_3
    ;; There is a selection -> unselect
    movlw MENU_EVENT_UNSELECT
    movwf menu_event
    goto menu_start_process_end

    ;; step 3:
menu_start_process_complex_action_select_specific_entry_3:
    movf menu_action_step, W
    sublw MENU_ACTION_STEP_3
    btfss STATUS, Z
    goto menu_start_process_complex_action_select_specific_entry_4
    ;; Prepare next step
    incf menu_action_step, F
    ;; Unfocus current entry
    movlw MENU_EVENT_UNFOCUS
    movwf menu_event
    goto menu_start_process_end

    ;; step 4:
menu_start_process_complex_action_select_specific_entry_4:
    movf menu_action_step, W
    sublw MENU_ACTION_STEP_4
    btfss STATUS, Z
    goto menu_start_process_complex_action_select_specific_entry_5
    ;; Prepare next step
    incf menu_action_step, F
    ;; Change current menu entry and focus it
    ;; (todo: but without changing the current focus entry variable ?)
    banksel menu_asked_action_param
    movf menu_asked_action_param, W
    movwf menu_value

    movwf param1
    clrf param2
    movlw MENU_NB_FOCUSABLE_ENTRY-1
    movwf param3
    ;; call_other_page encoder_set_value

    movlw MENU_EVENT_FOCUS
    movwf menu_event
    goto menu_start_process_end

    ;; step 5:
menu_start_process_complex_action_select_specific_entry_5:
    ;; This is the last step of complete init
    clrf menu_action_step
    clrf menu_action
    movlw MENU_EVENT_SELECT
    movwf menu_event
    ;; Change state
    movlw MENU_STATE_SELECT
    banksel menu_state
    movwf menu_state
    goto menu_start_process_end
menu_start_process_complex_action_select_specific_entry_end:

    call_other_page lcd_clear
menu_start_process_end:
    return

;;; Configure encoder and memorize current value
;;; in order to manage encoder change for select sub sate
;;; param1: current_value
;;; param2: value_min
;;; param3: value_max
menu_selection_encoder_configure:
    global menu_selection_encoder_configure
    ;; Set encoder value
    call_other_page encoder_set_value
    ;; Memorize select value
    movf param1, W
    banksel menu_select_value
    movwf menu_select_value

    return

END
