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
;;; Manage dialog screen for tremolo editing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#define EDIT_TREM_M

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
#include <edit_eq.inc>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PROG_VAR_1 UDATA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CODE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EQ_PROG_1 CODE
edit_trem_st_eq:
    dt "GOTO EQUALIZER", 0
edit_trem_st_rate:
    dt "RATE: ", 0
edit_trem_st_speed:
    dt "SPEED: ", 0
edit_trem_st_type:
    dt "TYPE: ", 0
edit_trem_st_target_eq:
    dt "TRGT EQ: ", 0

edit_trem_show:
    global edit_trem_show

    call_other_page lcd_clear

    menu_start edit_common_cycle_period, UNUSED_PARAM
    menu_button_goto edit_trem_st_eq, 0, edit_eq_show
    menu_edit edit_common_st_bank, 1, 1, 1, BANK_NB, current_bank, (2 << LCD_INT_SHT_FILLING_ZERO), edit_common_load_preview, edit_common_load
    menu_edit_no_show edit_common_st_save, 1, 2, 1, BANK_NB, current_bank, (2 << LCD_INT_SHT_FILLING_ZERO), edit_common_refresh, edit_common_save

    menu_edit edit_trem_st_type, (LCD_WIDTH_TXT/2+1), 0, 0, 2, bank_trem_type, 0, process_change_conf, UNUSED_PARAM
    menu_edit edit_trem_st_rate, (LCD_WIDTH_TXT/2+1), 1, 1, BANK_MAX_TREM_RATE_VALUE, bank_trem_rate, 0, process_change_conf, UNUSED_PARAM
    menu_edit edit_trem_st_speed, (LCD_WIDTH_TXT/2+1), 2, 0, BANK_MAX_TREM_SPEED_VALUE, bank_nb_inc, 0, process_change_conf, UNUSED_PARAM
    menu_edit edit_trem_st_target_eq, (LCD_WIDTH_TXT/2+1), 3, 1, BANK_NB, bank_trem_target, 0, process_change_conf, UNUSED_PARAM
    menu_end
    return


END
