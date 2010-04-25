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

