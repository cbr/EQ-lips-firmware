#define IO_INTERRUPT_M

PROG_VAR_1 UDATA

;;; Last filtered input register
reg_input_last_value RES 1
    global reg_input_last_value
;;; Current filtered input register
reg_input_current_value RES 1
    global reg_input_current_value

; relocatable code
EQ_PROG_1 CODE

;;;
;;; Initialize module
;;;
io_interrupt_init:
    global io_interrupt_init
    banksel reg_input_last_value
    movlw 0xFF
    movwf reg_input_last_value
    movwf reg_input_current_value
    return
END
