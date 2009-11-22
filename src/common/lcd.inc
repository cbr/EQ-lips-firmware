#define LCD_COMMAND        0x01
#define LCD_FIRST_CHIP     0x02

#define LCD_SET_PIXEL      0x01
#define LCD_XOR            0x02

#define LCD_DISPLAY_ON_OFF          0xAE
#define LCD_DISPLAY_START_LINE      0xC0
#define LCD_SET_PAGE_ADDRESS        0xB8
#define LCD_COLUMN_ADDRESS          0x00
;#define LCD_READ_STATUS
;#define LCD_WRITE_DISPLAY_DATA
;#define LCD_READ_DISPLAY_DATA
#define LCD_SELECT_ADC              0xA0
#define LCD_STATIC_DRIVE_ON_OFF     0xA4
#define LCD_SELECT_DUTY             0xA8
#define LCD_READ_MODIFY_WRITE       0xE0
#define LCD_END                     0xEE
#define LCD_RESET                   0xE2


#define LCD_WIDTH   0x7a
#define LCD_HEIGH   0x20

#define LCD_WIDTH_TXT   0x1e
#define LCD_HEIGH_TXT   0x4

#define LCD_CHAR_WIDTH        4
#define LCD_CHAR_HEIGH        8
#define LCD_CHAR_WIDTH_SHIFT  2
#define LCD_CHAR_HEIGH_SHIFT  3
#define FIRST_FONT_CHAR_NUM   0x20


lcd_recv_cmd_1 macro
    bsf param2, LCD_COMMAND
    bsf param2, LCD_FIRST_CHIP
    call lcd_read
    endm

lcd_recv_cmd_2 macro
    bsf param2, LCD_COMMAND
    bcf param2, LCD_FIRST_CHIP
    call lcd_read
    endm

lcd_recv_data_1 macro
    bcf param2, LCD_COMMAND
    bsf param2, LCD_FIRST_CHIP
    call lcd_read
    endm

lcd_recv_data_2 macro
    bcf param2, LCD_COMMAND
    bcf param2, LCD_FIRST_CHIP
    call lcd_read
    endm


lcd_send_data_1 macro value
    movlw value
    movwf param1
    bcf param2, LCD_COMMAND
    bsf param2, LCD_FIRST_CHIP
    call lcd_write
    endm

lcd_send_data_2 macro value
    movlw value
    movwf param1
    bcf param2, LCD_COMMAND
    bcf param2, LCD_FIRST_CHIP
    call lcd_write
    endm

lcd_send_cmd_1 macro cmd, value
    movlw cmd | value
    movwf param1
    bsf param2, LCD_COMMAND
    bsf param2, LCD_FIRST_CHIP
    call lcd_write
    endm

lcd_send_cmd_2 macro cmd, value
    movlw cmd | value
    movwf param1
    bsf param2, LCD_COMMAND
    bcf param2, LCD_FIRST_CHIP
    call lcd_write
    endm


#ifndef LCD_M
    ; Functions
    extern lcd_init
    extern lcd_clear
    extern lcd_plot
    extern lcd_int
    extern lcd_string
    extern lcd_loc_string
    extern lcd_rectangle
    extern lcd_write
    extern lcd_read
    extern set_lcd_data
    extern get_lcd_data
    extern lcd_char
    extern lcd_locate
    extern lcd_test_io_blink
    extern lcd_test_io_on
    extern lcd_test_io_off
#endif

