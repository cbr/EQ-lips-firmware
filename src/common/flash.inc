;;; Get flash data from a label and an offset stored in a register
;;; base_addr: base address label
;;; offset_register: register in which offset is stored
get_flash_data macro base_addr, offset_register
    ;;  set base_addr to read
    banksel EEADR
    movlw high base_addr
    movwf EEADRH
    movlw low base_addr
    movwf EEADR

    ;; add offset
    banksel offset_register
    ;; bcf STATUS, C
    movf offset_register, W
    banksel EEADR
    addwf EEADR, F
    btfsc STATUS, C
    incf EEADRH, F
    ;; get data
    banksel EEDAT
    movf EEDAT, W

    endm
