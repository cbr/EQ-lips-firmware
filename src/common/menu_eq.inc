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
#define MENU_EQ_ZERO_VALUE          0xF
#define MENU_EQ_MAX_INPUT           0x1F

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MACROS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;
;;; This macro manage an entry element got eq band
;;; id: uniq id of menu_entry element
;;; pos_x: band x position
;;; value_addr: address of eq value
;;; on_value_change_func: function called when the eq band value is changed
;;;
menu_eq macro id, pos_x, value_addr, on_focus_func, on_unfocus_func, on_value_change_func

    local menu_eq_init
    local menu_eq_undef
    local menu_eq_focus
    local menu_eq_unfocus
    local menu_eq_focus_unfocus_common
    local menu_eq_select
    local menu_eq_unselect
    local menu_eq_refresh
    local menu_eq_select_value_change
    local menu_eq_select_switch

    ;; This operation is needed for most of event, so it is done only once here
    movlw pos_x
    movwf param1

    menu_event_dispatch id, menu_eq_init, menu_eq_focus, menu_eq_unfocus, menu_eq_select, menu_eq_unselect, menu_eq_select_value_change, menu_eq_select_switch, menu_eq_refresh
    goto menu_eq_undef
menu_eq_init:
    movlw value_addr
    movwf FSR
    bankisel value_addr
    movf INDF, W
    movwf param2
    call_other_page menu_draw_eq_band

    goto menu_eq_undef

menu_eq_unfocus:
#if on_unfocus_func == UNUSED_PARAM
#else
    movlw id
    movwf param1
    call_other_page on_unfocus_func
#endif
    goto menu_eq_focus_unfocus_common
menu_eq_focus:
#if on_focus_func == UNUSED_PARAM
#else
    movlw id
    movwf param1
    call_other_page on_focus_func
#endif
menu_eq_focus_unfocus_common
    movlw pos_x
    movwf param1
    call_other_page menu_draw_focus_eq_band
    goto menu_eq_undef

menu_eq_select:
    movlw value_addr
    movwf param2
    bankisel value_addr
    call_other_page menu_eq_manage_select
    goto menu_eq_undef

menu_eq_unselect:
    call_other_page menu_eq_manage_unselect
    goto menu_eq_undef

menu_eq_select_value_change:
    movlw value_addr
    movwf param2
    bankisel value_addr
    call_other_page menu_eq_manage_select_value_change
    movlw id
    movwf param1
    call_other_page on_value_change_func
    goto menu_eq_undef

menu_eq_select_switch:
    menu_leave_selection
    goto menu_eq_undef

menu_eq_refresh:
    movlw value_addr
    movwf FSR
    bankisel value_addr
    movf INDF, W
    movwf param2
    call_other_page menu_refresh_eq_band

menu_eq_undef:
    MENU_NEW_ENTRY_WITH_FOCUS
    endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PUBLIC DECLARATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#ifndef MENU_EQ_M
    extern menu_eq_last_value
    extern menu_eq_draw_select

    extern menu_draw_eq_band
    extern menu_refresh_eq_band
    extern menu_draw_focus_eq_band
    extern menu_eq_manage_select
    extern menu_eq_manage_unselect
    extern menu_eq_manage_select_value_change
#endif
