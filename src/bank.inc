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
#define BANK_NB_NUMPOT_VALUES            0xB
#define BANK_POS_GAIN_IN_NUMPOT          0xA
#define BANK_MAX_TREM_RATE_VALUE         0x64
#define BANK_MAX_TREM_SPEED_VALUE        0xFF

#define BANK_TREM_TYPE_NONE              0x00
#define BANK_TREM_TYPE_SIMPLE            0x01
#define BANK_TREM_TYPE_EQ                0x02

;;; Size of a bank in EEPROM
#define BANK_EESIZE         0xB
;;; Number of total bank
#define BANK_NB                          (0xFF/BANK_EESIZE)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PUBLIC DECLARATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#ifndef BANK_M
    ;; Variables
    extern bank_numpot_values
#ifdef TREMOLO
    extern bank_trem_type
    extern bank_trem_rate
    extern bank_trem_target
    extern bank_nb_inc
#endif
    ;; Functions
    extern bank_load
    extern bank_save
    extern bank_load_eq_gain
    extern bank_save_eq_gain
#endif
