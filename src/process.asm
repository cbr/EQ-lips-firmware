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
;;; Target eq values used for tremolo type eq
target_numpot_values RES BANK_NB_NUMPOT_VALUES
    ;; Temporary activation data
PROG_VAR_2 UDATA
all_numpot_16   RES (2*BANK_NB_NUMPOT_VALUES)
all_inc_16      RES (2*BANK_NB_NUMPOT_VALUES)

tst_reg         RES 1

; relocatable code
EQ_PROG_1 CODE

;;;
;;; Function called when input data have been changed
;;; (because of gui data change or bank load)
;;;
process_change_conf:
    global process_change_conf

    banksel tst_reg
    clrf tst_reg

    ;; Clear all_inc_16
    banksel all_inc_16
    mem_clear all_inc_16, (2*BANK_NB_NUMPOT_VALUES)

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

    ;; Store value in param2
    movwf param2
    ;; Store value in numpot
    movf index, W
    movwf param1
    decf param1, F
    call_other_page numpot_set_one_value

    ;; Shift param2
    lshift_f param2, SHIFT_NUMPOT_VAL_TO_HIGH_ORDER
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
    ;; Store param2 into hi byte
    incf FSR, F
    movf param2, W
    movwf INDF

    ;; Next index, and loop
    banksel index
    decfsz index, F
    goto process_change_conf_init_value_loop


    ;; *** Check Tremolo type
process_change_conf_check_type_simple:
    banksel bank_trem_type
    movf bank_trem_type, W
    sublw BANK_TREM_TYPE_SIMPLE
    btfsc STATUS, Z
    goto process_change_conf_type_simple

process_change_conf_check_type_eq:
    movf bank_trem_type, W
    sublw BANK_TREM_TYPE_EQ
    btfsc STATUS, Z
    goto process_change_conf_type_eq


    ;; *** No tremolo
process_change_conf_type_none:
    ;; No tremolo
    ;; Update juste one time
    banksel update_info
    bcf update_info, UPDATE_EVERY_TIME
    bsf update_info, UPDATE_ONE_TIME
    goto process_change_conf_end

    ;; *** Simple tremolo type
    ;; *** Eq tremolo type
    ;; inc = amplitude / bank_nb_inc
    ;; inc = (numpot_values_a - (numpot_values_a * trem_rate / 100)) / bank_nb_inc
process_change_conf_type_simple:

    ;; Update every time
    banksel update_info
    bsf update_info, UPDATE_EVERY_TIME
    ;; Init cpt
    banksel bank_nb_inc
    movf bank_nb_inc, W
    sublw BANK_MAX_TREM_SPEED_VALUE
    banksel trem_inc_cpt
    movwf trem_inc_cpt

    ;; Prepare index, in order to only calculate amplitude
    ;; on gain (and not other eq band) when goto process_change_conf_eq_simple_plug
    ;; will be made
    banksel index
    movlw BANK_POS_GAIN_IN_NUMPOT
    movwf index

    ;; Calculate gain target value:
    ;; bank_numpot_values[BANK_POS_GAIN_IN_NUMPOT] * trem_rate / 100
    ;; number_a = bank_numpot_values[BANK_POS_GAIN_IN_NUMPOT]
    banksel bank_numpot_values+BANK_POS_GAIN_IN_NUMPOT
    movf bank_numpot_values+BANK_POS_GAIN_IN_NUMPOT, W
    math_banksel
    movwf number_a_lo
    ;; number_b = trem_rate
    banksel bank_trem_rate
    movf bank_trem_rate, W
    sublw BANK_MAX_TREM_RATE_VALUE
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
    ;; W = number_b_lo
    movf number_b_lo, W
    ;; Now use code from eq tremolo in order to calculate amplitude
    goto process_change_conf_eq_simple_plug


process_change_conf_type_eq:
    ;; Prepare equalizer tremolo

    ;; Update every time
    banksel update_info
    bsf update_info, UPDATE_EVERY_TIME
    ;; Init cpt
    banksel bank_nb_inc
    movf bank_nb_inc, W
    sublw BANK_MAX_TREM_SPEED_VALUE
    banksel trem_inc_cpt
    movwf trem_inc_cpt

    ;; Initialize 'index'
    ;; This index will be used to index array.
    ;; It start to 0 and grow until BANK_NB_NUMPOT_VALUES.
    ;; Simple tremolo also uses a part of this code, but only
    ;; for the gain, so in this case the index is initialized to
    ;; the last value (=gain index), so only gain is initialized in
    ;; this case. It is done with a goto process_change_conf_eq_simple_plug
    banksel index
    clrf index

    ;; Extract target eq value into target_numpot_values
    banksel bank_trem_target
    movf bank_trem_target, W
    movwf param1
    ;; banks are 1-indexed:
    incf param1, F
    movlw target_numpot_values
    movwf param2
    bankisel target_numpot_values
    call_other_page bank_load_eq_gain

process_change_conf_type_eq_loop:
    ;; W = target_numpot_values[index]
    movlw target_numpot_values
    banksel index
    addwf index, W
    movwf FSR
    bankisel target_numpot_values
    movf INDF, W

    ;; This label is used by simple eq in order to only calculate increment
    ;; for gain.
process_change_conf_eq_simple_plug:
    ;; Now calculate the amplitude. This is calculated on 16 bits
    ;; number in order to have more precision. This is why the result is shifted:
    ;; left shift W of 8+SHIFT_NUMPOT_VAL_TO_HIGH_ORDER bits
    ;; (W is put into hi byte of number_a and shifted by SHIFT_NUMPOT_VAL_TO_HIGH_ORDER)
    math_banksel
    movwf number_a_hi
    lshift_f number_a_hi, SHIFT_NUMPOT_VAL_TO_HIGH_ORDER
    clrf number_a_lo
    ;; number_b = bank_numpot_values[index]
    ;; left shift number_b of 8+SHIFT_NUMPOT_VAL_TO_HIGH_ORDER bits
    ;; (the lo byte is put to hi byte and shifted by SHIFT_NUMPOT_VAL_TO_HIGH_ORDER)
    movlw bank_numpot_values
    banksel index
    addwf index, W
    movwf FSR
    bankisel bank_numpot_values
    movf INDF, W
    math_banksel
    movwf number_b_hi
    lshift_f number_b_hi, SHIFT_NUMPOT_VAL_TO_HIGH_ORDER
    clrf number_b_lo
    ;; And the amplitude is:
    ;; number_b = number_b - number_a
    call_other_page math_sub_1616s

    ;; Now calculate the increment which is added at each cycle
    ;; number_a = bank_nb_inc
    banksel bank_nb_inc
    movf bank_nb_inc, W
    sublw BANK_MAX_TREM_SPEED_VALUE
    math_banksel
    movwf number_a_lo
    clrf number_a_hi
    ;; The increment is:
    ;; number_b = number_b / number_a
    call_other_page math_div_16s16s_16s
    call_other_page math_neg_number_b_16s

    ;; FSR = index*2
    banksel index
    movf index, W
    movwf FSR
    lshift_f FSR, 1
    ;; FSR=FSR + all_inc_16
    movlw all_inc_16
    addwf FSR, F
    bankisel all_inc_16
    ;; store number_b into FSR
    math_banksel
    movf number_b_lo, W
    movwf INDF
    incf FSR, F
    movf number_b_hi, W
    movwf INDF

    ;; Next index, and loop
    banksel index
    incf index, F
    movf index, W
    sublw BANK_NB_NUMPOT_VALUES
    btfss STATUS, Z
    goto process_change_conf_type_eq_loop

process_change_conf_end:

    return



;;;
;;; Function called at each tick to update numpot
;;; Variable changes: number_a, number_b, FSR,
;;; all_numpot_16, all_inc_16, index, update_info
;;;
process_update:
    global process_update
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

    ;; End of half period
    ;; -> trem_inc_cpt need to be reset and all_inc_16 have to be negated
    ;; Reinit trem_inc_cpt
    banksel bank_nb_inc
    movf bank_nb_inc, W
    sublw BANK_MAX_TREM_SPEED_VALUE
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

process_update_end:
    ;; Remove UPDATE_ONE_TIME bit from update_info,
    ;; in order to not update data next time if not needed (eg if
    ;; UPDATE_EVERY_TIME bit is not set)
    banksel update_info
    bcf update_info, UPDATE_ONE_TIME

    return


END
