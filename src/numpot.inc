NUMPOT_SET_ONE_VALUE macro potnumber, value
      movlw potnumber
      movwf param1
      movlw value
      movwf param2
      call numpot_set_one_value
      endm

#ifndef LCD_M
    ; Functions
    extern numpot_send_all
    extern numpot_set_one_value
#endif

