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
;;; Global variables of software
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#define GLOBAL_M

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Variables declaration
 UDATA_SHR
w_saved      RES 1 ; variable used for context saving
    global w_saved
status_saved RES 1 ; variable used for context saving
    global status_saved
pclath_saved RES 1 ; variable used for context saving
    global pclath_saved
param1       RES 1 ; parameter 1 of functions
    global param1;
param2       RES 1 ; parameter 2 of functions
    global param2
param3       RES 1 ; parameter 3 of functions
    global param3
param4       RES 1 ; parameter 4 of functions
    global param4;
param5       RES 1 ; parameter 5 of functions
    global param5;
param6       RES 1 ; parameter 6 of functions
    global param6;
encoder_sw RES 1 ; encoder value
    global encoder_sw;
encoder_value RES 1 ; encoder value
    global encoder_value;
encoder_last_value RES 1 ; encoder last value TODO to be removed, for test only !
    global encoder_last_value;
interrupt_var_1 RES 1 ; variable used by ISR
    global interrupt_var_1;
current_bank       RES 1 ; Currently selected memory bank
    global current_bank;



END