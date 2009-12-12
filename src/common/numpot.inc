
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

