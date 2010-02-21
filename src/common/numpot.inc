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

