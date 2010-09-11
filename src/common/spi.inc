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

spi_send_w_and_wait macro
    ;; send cmd
    banksel SSPBUF
    movwf SSPBUF
    banksel SSPSTAT
    ;; wait end of transmission
    btfss SSPSTAT, BF
    goto $ - 1


    endm


#ifndef SPI_M
    ; Functions
    extern spi_init
    extern spi_send
    extern spi_set_res
#endif

