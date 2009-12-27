;;; Get flash data from a label and an offset stored in a register
;;; base_addr: base address label
;;; offset_register: register in which offset is stored
get_flash_data_reg macro base_addr, offset_register
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

;;; Get flash data from a label and an offset stored in W
;;; base_addr: base address label
get_flash_data_w macro base_addr
    banksel EEADR
    ;; reset hight order bits of pointer
    clrf EEADRH
    ;; store offset
    movwf EEADR

    ;; add low order bits of base address
    movlw low base_addr
    addwf EEADR, F
    ;; Check if high order bits need to be inc
    btfsc STATUS, C
    incf EEADRH, F
    ;; add high order bits of base address
    movlw high base_addr
    addwf EEADRH, F

    ;;  read  flash
    banksel EECON1
    bsf EECON1, EEPGD
    bsf EECON1, RD
    nop
    nop

    ;; get data
    banksel EEDAT
    movf EEDAT, W

    endm
