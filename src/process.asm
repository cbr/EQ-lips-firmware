;;; Manage process data: update, loading and saving

#define PROCESS_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <process.inc>
#include <bank.inc>
#include <math.inc>
#include <numpot.inc>
#include <lcd.inc>

#define SHIFT_NUMPOT_VAL_TO_HIGH_ORDER  0x02
#define UPDATE_ONE_TIME             0x01
#define UPDATE_EVERY_TIME           0x02




PROG_VAR_1 UDATA
trem_inc_cpt    RES 1
;;; Data update info. Tell if numpot have to be updated or not.
;;; If this value is not 0, then data have to be updated.
;;; Bit UPDATE_ONE_TIME tell to only update data one time, and bit
;;; UPDATE_EVERY_TIME tell to update data at every tick.
update_info     RES 1
;;; Loop index used to update numpot next values
index           RES 1

    ;; Temporary activation data
PROG_VAR_2 UDATA
all_numpot_16   RES (2*BANK_NB_NUMPOT_VALUES)
all_inc_16      RES (2*BANK_NB_NUMPOT_VALUES)

tst_reg         RES 1

; relocatable code
EQ_PROG_2 CODE

;;;
;;; Function called when input data have been changed
;;; (because of gui data change or bank load)
;;;
process_change_conf:
    global process_change_conf

#if 1
    ;; for testing
    movlw .50
    movwf bank_trem_rate

    banksel bank_nb_inc
    movlw 0x30
    movwf bank_nb_inc
    banksel trem_inc_cpt
    movwf trem_inc_cpt

    banksel tst_reg
    clrf tst_reg

#endif

    ;; Reset all_inc_16 and all_numpot_16

    ;; clear all_inc_16
    banksel all_inc_16
    mem_clear all_inc_16, (2*BANK_NB_NUMPOT_VALUES)
    ;; Manage simple tremolo
    ;; inc = amplitude / bank_nb_inc
    ;; inc = (numpot_values_a - (numpot_values_a * trem_rate / 100)) / bank_nb_inc

#if 1
    banksel index
    movlw BANK_NB_NUMPOT_VALUES
    movwf index
process_change_conf_init_value_loop:
    ;; Get value from bank_numpot_values
    movlw bank_numpot_values
    banksel index
    addwf index, W
    movwf FSR
    decf FSR, F
    bankisel bank_numpot_values
    movf INDF, W
    ;; Store value in param1 with appropriate shift
    movwf param1
    lshift_f param1, SHIFT_NUMPOT_VAL_TO_HIGH_ORDER
    ;; Prepare all_numpot_16 ptr
    banksel index
    movf index, W
    movwf FSR
    decf FSR, F
    lshift_f FSR, 1
    movlw all_numpot_16
    addwf FSR, F
    bankisel all_numpot_16
    ;; Clear lo byte
    clrf INDF
    ;; Store param1 into hi byte
    incf FSR, F
    movf param1, W
    movwf INDF

    ;; Next index, and loop
    banksel index
    decfsz index, F
    goto process_change_conf_init_value_loop
#else
    banksel all_numpot_16
    mem_set all_numpot_16, (2*BANK_NB_NUMPOT_VALUES), 0x40
#endif

#if 0
    movlw 0x0
    movwf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    banksel all_numpot_16
    movf all_numpot_16+BANK_POS_GAIN_IN_NUMPOT*2+1, W
    movwf param1
    clrf param2
    call_other_page lcd_int
    banksel all_numpot_16
    movf all_numpot_16+BANK_POS_GAIN_IN_NUMPOT*2, W
    movwf param1
    clrf param2
    call_other_page lcd_int
#endif
    ;; Calculate bank_numpot_values[BANK_POS_GAIN_IN_NUMPOT] * trem_rate / 100
    ;; number_a = bank_numpot_values[BANK_POS_GAIN_IN_NUMPOT]
    banksel bank_numpot_values+BANK_POS_GAIN_IN_NUMPOT
    movf bank_numpot_values+BANK_POS_GAIN_IN_NUMPOT, W
    math_banksel
    movwf number_a_lo
    ;; number_b = trem_rate
    banksel bank_trem_rate
    movf bank_trem_rate, W
    math_banksel
    movwf number_b_lo
    ;; number_c = number_a * number b
    call_other_page math_mult_08u08u_16u
    ;; number_b = number_c
    math_copy_16 number_c, number_b
    ;; number_a = 100
    movlw 0x64
    movwf number_a_lo
    clrf number_a_hi
    ;; number_b = number_b/number_a
    call_other_page math_div_16s16s_16s
    ;; number_a = number_b
    ;; left shift number_b of 8+SHIFT_NUMPOT_VAL_TO_HIGH_ORDER bits
    ;; (the lo byte is put to hi byte and shifted by SHIFT_NUMPOT_VAL_TO_HIGH_ORDER)
    movf number_b_lo, W
    movwf number_a_hi
    lshift_f number_a_hi, SHIFT_NUMPOT_VAL_TO_HIGH_ORDER
    clrf number_a_lo
    ;; number_b = bank_numpot_values[BANK_POS_GAIN_IN_NUMPOT]
    ;; left shift number_b of 8+SHIFT_NUMPOT_VAL_TO_HIGH_ORDER bits
    ;; (the lo byte is put to hi byte and shifted by SHIFT_NUMPOT_VAL_TO_HIGH_ORDER)
    banksel bank_numpot_values+BANK_POS_GAIN_IN_NUMPOT
    movf bank_numpot_values+BANK_POS_GAIN_IN_NUMPOT, W
    math_banksel
    movwf number_b_hi
    lshift_f number_b_hi, SHIFT_NUMPOT_VAL_TO_HIGH_ORDER
    clrf number_b_lo
    ;; number_b = number_b - number_a
    call_other_page math_sub_1616s
#if 0
    ;; left shift number_b of 8+SHIFT_NUMPOT_VAL_TO_HIGH_ORDER bits
    ;; (the lo byte is put to hi byte and shifted by SHIFT_NUMPOT_VAL_TO_HIGH_ORDER)
    movf number_b_lo, W
    movwf number_b_hi
    lshift_f number_b_hi, SHIFT_NUMPOT_VAL_TO_HIGH_ORDER
    clrf number_b_lo
#endif
    ;; number_a = bank_nb_inc
    banksel bank_nb_inc
    movf bank_nb_inc, W
    math_banksel
    movwf number_a_lo
    clrf number_a_hi
    ;; number_b = number_b / number_a
    call_other_page math_div_16s16s_16s
    call_other_page math_neg_number_b_16s


#if 0
    movlw 0x0
    movwf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    math_banksel
    movf number_b_hi, W
    movwf param1
    clrf param2
    call_other_page lcd_int
    math_banksel
    movf number_b_lo, W
    movwf param1
    clrf param2
    call_other_page lcd_int
#endif
    math_copy_16 number_b, all_inc_16+(BANK_POS_GAIN_IN_NUMPOT*2)

#if 0
    ;; For testing
    banksel all_numpot_16
    movlw .16
    movwf all_numpot_16+(0xA*2)+1
    lshift_f all_inc_16+(0xA*2)+1, 3
    clrf all_numpot_16+(0xA*2)

    banksel all_inc_16
    movlw 0x00
    movwf all_inc_16+(0xA*2)
    movlw 0x04
    movwf all_inc_16+(0xA*2)+1

    banksel update_info
    bsf update_info, UPDATE_EVERY_TIME

#endif
    return



;;;
;;; Function called at each tick to update numpot
;;; Variable changes: number_a, number_b, FSR,
;;; all_numpot_16, all_inc_16, index, update_info
;;;
process_update:
    global process_update
#if 1
    ;; Check if numpot have to be changed
    banksel update_info
    movf update_info, W
    btfsc STATUS, Z
    goto process_update_end

    ;; Send previously prepared numpot values
    call_other_page numpot_send_all

    ;; Prepare next values

    ;; Prepate loop
    banksel index
    movlw BANK_NB_NUMPOT_VALUES
    movwf index
process_update_loop_update_gain:
    ;; Put address of 16 bit increment (all_inc_16) value in FSR
    banksel index
    movf index, W
    movwf FSR
    decf FSR, F
    lshift_f FSR, 1
    movlw all_inc_16
    addwf FSR, F
    ;; take care of bank
    bankisel all_inc_16
    ;; Extract 16 bit value into number_a
    math_banksel
    movf INDF, W
    movwf number_a_lo
    incf FSR, F
    movf INDF, W
    movwf number_a_hi

    ;; Put address of indexed 16 bit numpot (all_numpot_16) value in FSR
    banksel index
    movf index, W
    movwf FSR
    decf FSR, F
    lshift_f FSR, 1
    movlw all_numpot_16
    addwf FSR, F
    ;; take care of bank
    bankisel all_numpot_16
    ;; Extract 16 bit value into number_b
    math_banksel
    movf INDF, W
    movwf number_b_lo
    incf FSR, F
    movf INDF, W
    movwf number_b_hi

    ;; add number_a and number_b
    call_other_page math_add_1616s

    ;; store back result (number_b) into all_numpot_16
    movf number_b_hi, W
    movwf INDF
    decf FSR, F
    movf number_b_lo, W
    movwf INDF

    ;; store value in numpot
    ;; Set gain value (keep only the high order bits corresponding to real value)
    movf number_b_hi, W
    movwf param2
    rshift_f param2, SHIFT_NUMPOT_VAL_TO_HIGH_ORDER
    ;; set numpot index in param 1
    banksel index
    movf index, W
    movwf param1
    decf param1, F
    call_other_page numpot_set_one_value

    ;; Next index, and loop
    banksel index
    decfsz index, F
    goto process_update_loop_update_gain

    ;; Check if inc values have to be negated
    banksel trem_inc_cpt
    decfsz trem_inc_cpt, F
    goto process_update_end

#if 0
    banksel tst_reg
    movlw 0x08
    xorwf tst_reg, W
    movwf tst_reg
    movwf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    banksel all_numpot_16
    movf all_numpot_16+BANK_POS_GAIN_IN_NUMPOT*2+1, W
    movwf param1
    clrf param2
    call_other_page lcd_int
    banksel all_numpot_16
    movf all_numpot_16+BANK_POS_GAIN_IN_NUMPOT*2, W
    movwf param1
    clrf param2
    call_other_page lcd_int
#endif
#if 1
    banksel tst_reg
    movlw 0x08
    xorwf tst_reg, W
    movwf tst_reg
    movwf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    banksel potvalues
    movf potvalues+BANK_POS_GAIN_IN_NUMPOT, W
    movwf param1
    clrf param2
    call_other_page lcd_int
#endif
    ;; End of half period
    ;; -> trem_inc_cpt need to be reset and all_inc_16 have to be negated
    ;; Reinit trem_inc_cpt
    banksel bank_nb_inc
    movf bank_nb_inc, W
    banksel trem_inc_cpt
    movwf trem_inc_cpt
    ;; Prepare loop
    banksel index
    movlw BANK_NB_NUMPOT_VALUES
    movwf index
process_update_loop_negate_inc:
    ;; inverse inc
    ;; Put address of 16 bit increment (all_inc_16) value in FSR
    banksel index
    movf index, W
    movwf FSR
    decf FSR, F
    lshift_f FSR, 1
    movlw all_inc_16
    addwf FSR, F
    ;; take care of bank
    bankisel all_inc_16
    ;; Extract 16 bit value into number_a
    math_banksel
    movf INDF, W
    movwf number_a_lo
    incf FSR, F
    movf INDF, W
    movwf number_a_hi

    call_other_page math_neg_number_a_16s

    ;; store back value in all_inc_16
    movf number_a_hi, W
    movwf INDF
    decf FSR, F
    movf number_a_lo, W
    movwf INDF

    ;; Next index, and loop
    banksel index
    decfsz index, F
    goto process_update_loop_negate_inc

#endif
process_update_end:
    ;; Remove UPDATE_ONE_TIME bit from update_info,
    ;; in order to not update data next time if not needed (eg if
    ;; UPDATE_EVERY_TIME bit is not set)
    banksel update_info
    bcf update_info, UPDATE_ONE_TIME

    return


END
