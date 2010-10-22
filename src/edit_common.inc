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
#define ID_BANK_SELECT  0x1
#define ID_BANK_UP      0x2
#define ID_BANK_DOWN    0x3
#define ID_BANK_SAVE    0x4
#define ID_EQ_BAND_BASE 0x10

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MACROS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;
;;; Manage foot switch. This macro analyze foorswitches state and interract with
;;; menu entrie management in order to realize the following actions:
;;; |--------------+---------------------+-------------------+----------------------|
;;; |              | no entry selected   | bank change entry | other entry selected |
;;; |              |                     | selected          |                      |
;;; |--------------+---------------------+-------------------+----------------------|
;;; | up release   | Next bank & update  | Next bank         | Leave sub state &    |
;;; |              |                     |                   | Next bank & update   |
;;; |--------------+---------------------+-------------------+----------------------|
;;; | down release | Prev bank & update  | Prev bank         | Leave sub state &    |
;;; |              |                     |                   | Prev bank & update   |
;;; |--------------+---------------------+-------------------+----------------------|
;;; | both pressed | Select 'bank change | Update &          | Leave sub state      |
;;; |              | entry'              | leave sub state   |                      |
;;; |--------------+---------------------+-------------------+----------------------|
;;;
edit_common_btn_evt_mgt macro
    local simple_mgt
    local no_entry_selected
    local no_entry_selected_end
    local bank_change_entry_selected
    local other_entry_selected
    local other_entry_selected_end
    local change_entry_selected_end
    local cplx_chk_down
    local cplx_chk_up
    local chk_down
    local chk_up
    local end_mgt
    ;; Check current menu state
    banksel menu_state
    movf menu_state, W
    sublw MENU_STATE_SELECT
    btfss STATUS, Z
    ;; Simple up & down btn management
    goto no_entry_selected
    ;; Check is current select entry is "bank selection" menu entry
    menu_get_nb_from_id_macro ID_BANK_SELECT
    subwf menu_value, W
    btfss STATUS, Z
    goto other_entry_selected

bank_change_entry_selected:
    ;; Check both button evt
    banksel edit_common_both_btn_pressed
    movf edit_common_both_btn_pressed, W
    btfsc STATUS, Z
    goto change_entry_selected_end
    decf edit_common_both_btn_pressed, F
    ;; Simulate encoder swicth in order to validate
    menu_ask_select_switch
change_entry_selected_end:

cplx_chk_down:
    banksel edit_common_down_btn_released
    movf edit_common_down_btn_released, W
    btfsc STATUS, Z
    goto cplx_chk_up
    ;; Down button pressed
    decf edit_common_down_btn_released, F
    ;; Try to inc encoder value if possible
    movf encoder_value, W
    sublw 1
    btfsc STATUS, Z
    ;; Loopback of encoder
    goto cplx_chk_down_loopback
    ;; No loopback of encoder
    decf encoder_value, W
    movwf param1
    goto cplx_chk_set_encoder
cplx_chk_down_loopback:
    movlw BANK_NB
    movwf param1
    goto cplx_chk_set_encoder
    ;; movlw 1
    ;; movwf param2
    ;; movlw BANK_NB
    ;; movwf param3
    ;; call_other_page encoder_set_value
    ;; goto end_mgt
cplx_chk_up:
    banksel edit_common_up_btn_released
    movf edit_common_up_btn_released, W
    btfsc STATUS, Z
    goto end_mgt
    ;; Up button pressed
    decf edit_common_up_btn_released, F
    ;; Try to inc encoder value if possible
    movf encoder_value, W
    sublw BANK_NB
    btfsc STATUS, Z
    ;; Loopback of encoder
    goto cplx_chk_up_loopback
    ;; No loopback of encoder
    incf encoder_value, W
    movwf param1
    goto cplx_chk_set_encoder

cplx_chk_up_loopback:
    movlw 1
    movwf param1
    goto cplx_chk_set_encoder
    ;; movlw 1
    ;; movwf param2
    ;; movlw BANK_NB
    ;; movwf param3
    ;; call_other_page encoder_set_value
    ;; goto end_mgt

no_entry_selected:
    ;; Check both button evt
    banksel edit_common_both_btn_pressed
    movf edit_common_both_btn_pressed, W
    btfsc STATUS, Z
    goto no_entry_selected_end
    ;; Both button pressed !
    ;; -> select "bank change" entry
    decf edit_common_both_btn_pressed, F
    menu_select_specific_entry_from_id ID_BANK_SELECT
no_entry_selected_end:
    goto simple_mgt

other_entry_selected:
    ;; Check both button evt
    banksel edit_common_both_btn_pressed
    movf edit_common_both_btn_pressed, W
    btfsc STATUS, Z
    goto other_entry_selected_end
    decf edit_common_both_btn_pressed, F
    ;; Leave current entry
    menu_leave_selection
other_entry_selected_end:
    goto simple_mgt

simple_mgt:
chk_down:
    banksel edit_common_down_btn_released
    movf edit_common_down_btn_released, W
    btfsc STATUS, Z
    goto chk_up
    ;; Down button pressed
    decf edit_common_down_btn_released, F
    menu_select_specific_entry_from_id ID_BANK_DOWN
    goto end_mgt
chk_up:
    banksel edit_common_up_btn_released
    movf edit_common_up_btn_released, W
    btfsc STATUS, Z
    goto end_mgt
    ;; Up button pressed
    decf edit_common_up_btn_released, F
    menu_select_specific_entry_from_id ID_BANK_UP
    goto end_mgt

cplx_chk_set_encoder:
    movlw 1
    movwf param2
    movlw BANK_NB
    movwf param3
    call_other_page encoder_set_value

end_mgt:
    endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PUBLIC DECLARATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#ifndef EDIT_COMMON_M
    ;; Variables
    extern edit_common_st_bank
    extern edit_common_st_load
    extern edit_common_st_save
    extern edit_common_st_empty_hint
    extern edit_common_down_btn_released
    extern edit_common_up_btn_released
    extern edit_common_both_btn_pressed

    ;; Functions
    extern edit_common_init
    extern edit_common_save
    extern edit_common_load_preview
    extern edit_common_load
    extern edit_common_refresh
    extern edit_common_idle
    extern edit_common_check_buttons
    extern edit_common_bank_up
    extern edit_common_bank_down
    extern edit_common_eq_gain_focus
    extern edit_common_eq_band_focus
    extern edit_common_eq_band_unfocus
    extern edit_common_eq_band_change
#ifdef TREMOLO
    extern edit_common_cycle_period
#endif

#endif
