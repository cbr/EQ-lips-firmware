#define IO_INTERRUPT_M

PROG_VAR_1 UDATA

;;; Last filtered input register
reg_input_last_value RES 1
    global reg_input_last_value
;;; Current filtered input register
reg_input_current_value RES 1
    global reg_input_current_value
;;; Counter of number of down switch pressed event
down_button_pressed RES 1
    global down_button_pressed
;;; Counter of number of down switch released event
down_button_released RES 1
    global down_button_released
;;; Counter of number of up switch pressed event
up_button_pressed RES 1
    global up_button_pressed
;;; Counter of number of up switch released event
up_button_released RES 1
    global up_button_released

; relocatable code
EQ_PROG_1 CODE


END
