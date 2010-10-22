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

#include <cpu.inc>


;;; -----------------------------------------------------------------------
;;; Configuration bits
    __CONFIG _CONFIG1, _INTOSCIO  & _WDT_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOR_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF & _DEBUG_OFF
    __CONFIG _CONFIG2, _BOR21V & _WRT_OFF

#include <global.inc>
#include <interrupt.inc>
#include <io.inc>
#include <lcd.inc>
#include <encoder.inc>
#include <delay.inc>
#include <std.inc>
#include <menu.inc>
#include <menu_button.inc>
#include <spi.inc>
#include <numpot.inc>
#include <edit_common.inc>
#include <edit_eq.inc>
#include <math.inc>
#include <bank.inc>
#include <process.inc>
#include <io_interrupt.inc>

#ifdef TREMOLO
#include <timer.inc>
#endif

;;; Variable declaration
PROG_VAR UDATA

;;;
;;; Startup vector.
;;;
STARTUP CODE 0x000
    nop                    ; necessary for debug with ICD2
    movlw   high start     ; load high order byte from start label
    movwf   PCLATH         ; initialiee PCLATH
    goto    start          ; start

;;;
;;; Interrupt vector. Called when an interrupt occurs.
;;;
INT_VECTOR CODE 0x004
    ;; Save context
    movwf   w_saved
    swapf   STATUS, w
    movwf   status_saved
    movf    PCLATH, w
    movwf   pclath_saved
    clrf    PCLATH

    ;; Manage IO interrupts
    io_interrupt
#ifdef TREMOLO
    ;; Manage timer interrupt
    timer_it
#endif

    ;; Restore context
    movf    pclath_saved, w
    movwf   PCLATH
    swapf   status_saved, w
    movwf   STATUS
    swapf   w_saved, f
    swapf   w_saved, w
    retfie

;;; relocatable code
PROG CODE

start:
    ;; *** SPECIFIC HARDWARE INIT ***
    ;; init clock
    banksel OSCCON
    movlw 0x0F
    andwf OSCCON, 1
    movlw 0x70 ; 8 MHz
    ;; movlw 0x30 ; 500kHz
    ;; movlw 0x00 ; 31kHz
    iorwf OSCCON, 1

    ;; Do not deactivate week pull-up
    banksel OPTION_REG
    bcf OPTION_REG, NOT_RBPU
    ;; disable adc (necessary to use io)
    banksel ANSEL
    clrf ANSEL
    clrf ANSELH
    banksel 0


    ;; *** MODULES INIT ***
    call_other_page io_configure
    call_other_page lcd_init
    call_other_page encoder_init
    call_other_page spi_init
#ifdef TREMOLO
    call_other_page timer_init
#endif
    call_other_page io_interrupt_init
    call_other_page edit_common_init

    ;; activate interrupt for foot switch
    banksel IOCB
    bsf IOCB, UP_SW_BIT
    bsf IOCB, DOWN_SW_BIT

    ;; enable interrupt
    interrupt_enable

    ;; *** SOFTWARE INIT ***
    ;; select first memory bank
    movlw 1
    movwf current_bank

    ;; load bank
    movwf param1
    decf param1, F
    call_other_page bank_load

    ;; apply eq settings
    call_other_page process_change_conf

    ;; *** LAUNCH GUI ***
    call_other_page edit_eq_show

    goto $              ; infinite loop

END
