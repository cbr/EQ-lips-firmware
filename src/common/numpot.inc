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

;;; Number of chained chips.
#define NUMPOT_NB_CHIP              0x06

;;; Number of left shift to obtain NUMPOT_NB_POT_BY_CHIP
#define NUMPOT_NB_POT_BY_CHIP_SHT   0x01

;;; Number of potentiometer in one chip
;;; This value has to be a power of two
#define NUMPOT_NB_POT_BY_CHIP       (0x01 << NUMPOT_NB_POT_BY_CHIP_SHT)


NUMPOT_SET_ONE_VALUE macro potnumber, value
    movlw potnumber
    movwf param1
    movlw value
    movwf param2
    call_other_page numpot_set_one_value
    endm

#ifndef NUMPOT_M
    ;; Variables
    extern potvalues

    ;; Functions
    extern numpot_send_all
    extern numpot_set_one_value
#endif

