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
;;; MODULE DESCRIPTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Manage dialog screen for eqalizer editing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#define EDIT_EQ_M

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; INCLUDES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <lcd.inc>
#include <menu.inc>
#include <menu_button.inc>
#include <menu_eq.inc>
#include <menu_edit.inc>
#include <encoder.inc>
#include <interrupt.inc>
#include <numpot.inc>
#include <math.inc>
#include <bank.inc>
#include <process.inc>
#include <edit_common.inc>
#include <edit_trem.inc>
;; #include <menu_label.inc>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PROG_VAR_1 UDATA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CODE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EQ_PROG_2 CODE

#ifdef TREMOLO
edit_eq_st_trem:
    dt "GOTO TREMOLO", 0
#endif

edit_eq_show:
    global edit_eq_show

    call_other_page lcd_clear

#ifdef TREMOLO
    menu_start edit_common_cycle_period, UNUSED_PARAM
#else
    menu_start UNUSED_PARAM, edit_common_idle

    ;; Before managing every element of menu, check buttons state
    call_other_page edit_common_check_buttons
    edit_common_btn_evt_mgt
#endif

    ;; menu_label_int 0, current_bank
#ifdef TREMOLO
    menu_button_goto edit_eq_st_trem, 0, edit_trem_show
#endif
    menu_edit ID_BANK_SELECT, edit_common_st_bank, 1, 0, 1, BANK_NB, current_bank, ((2 << LCD_INT_SHT_FILLING_ZERO) | (1 << LCD_INT_SHT_BIG_CHAR)), edit_common_load_preview, edit_common_load
    menu_edit_no_show ID_BANK_SAVE, edit_common_st_save, 1, 1, 1, BANK_NB, current_bank, ((2 << LCD_INT_SHT_FILLING_ZERO) | (1 << LCD_INT_SHT_BIG_CHAR)), edit_common_refresh, edit_common_save
    menu_eq ID_EQ_BAND_BASE + 0x0, (0x5*0 + 0x3D), bank_numpot_values, edit_common_eq_band_focus, edit_common_eq_band_unfocus, edit_common_eq_band_change
    menu_eq ID_EQ_BAND_BASE + 0x1, (0x5*1 + 0x3D), bank_numpot_values+1, edit_common_eq_band_focus, edit_common_eq_band_unfocus, edit_common_eq_band_change
    menu_eq ID_EQ_BAND_BASE + 0x2, (0x5*2 + 0x3D), bank_numpot_values+2, edit_common_eq_band_focus, edit_common_eq_band_unfocus, edit_common_eq_band_change
    menu_eq ID_EQ_BAND_BASE + 0x3, (0x5*3 + 0x3D), bank_numpot_values+3, edit_common_eq_band_focus, edit_common_eq_band_unfocus, edit_common_eq_band_change
    menu_eq ID_EQ_BAND_BASE + 0x4, (0x5*4 + 0x3D), bank_numpot_values+4, edit_common_eq_band_focus, edit_common_eq_band_unfocus, edit_common_eq_band_change
    menu_eq ID_EQ_BAND_BASE + 0x5, (0x5*5 + 0x3D), bank_numpot_values+5, edit_common_eq_band_focus, edit_common_eq_band_unfocus, edit_common_eq_band_change
    menu_eq ID_EQ_BAND_BASE + 0x6, (0x5*6 + 0x3D), bank_numpot_values+6, edit_common_eq_band_focus, edit_common_eq_band_unfocus, edit_common_eq_band_change
    menu_eq ID_EQ_BAND_BASE + 0x7, (0x5*7 + 0x3D), bank_numpot_values+7, edit_common_eq_band_focus, edit_common_eq_band_unfocus, edit_common_eq_band_change
    menu_eq ID_EQ_BAND_BASE + 0x8, (0x5*8 + 0x3D), bank_numpot_values+8, edit_common_eq_band_focus, edit_common_eq_band_unfocus, edit_common_eq_band_change
    menu_eq ID_EQ_BAND_BASE + 0x9, (0x5*9 + 0x3D), bank_numpot_values+9, edit_common_eq_band_focus, edit_common_eq_band_unfocus, edit_common_eq_band_change
    menu_eq ID_EQ_BAND_BASE + 0xA,(0x5*0xB + 0x3D), bank_numpot_values+0xA, edit_common_eq_gain_focus, edit_common_eq_band_unfocus, edit_common_eq_band_change
    menu_button_hidden ID_BANK_UP, edit_common_bank_up
    menu_button_hidden ID_BANK_DOWN, edit_common_bank_down
    menu_end

    return


END
