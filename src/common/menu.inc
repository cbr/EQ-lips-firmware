#define MENU_ACTION_UNDEF           0x00
#define MENU_ACTION_INIT            0x01
#define MENU_ACTION_SELECT_CHANGE   0x02
#define MENU_INIT_LAST_VALUE        0xFF

;#define SIMPLE_SELECT

#ifdef SIMPLE_SELECT
#define MENU_SELECT_CHAR            '>'
#define MENU_UNSELECT_CHAR          ' '
#define MENU_STRING_POS_X           2
#else
#define MENU_STRING_POS_X           0
#endif

    extern menu_last_value
    VARIABLE MENU_NB_ENTRY

menu_start macro
    VARIABLE MENU_NB_ENTRY=0
    local menu_start_quit
    local menu_start_select_change
    call lcd_clear
    ;; init variable
    movlw MENU_INIT_LAST_VALUE
    movwf menu_last_value
    movlw 0x00
    movwf menu_value

    ;; Action to realize is 'init' the first time
    movlw MENU_ACTION_INIT
    movwf menu_action
    goto menu_start_quit
    ;; define return label for 'end' macro
    ;; (An xcoff symbol is used, because of relocatable code)
    .DEF LABEL_MENU_START, global, value=$
menu_start_select_change:
    ;; Check if encoder value is equal to current menu value
    movf encoder_value, W
    subwf menu_value, W
    btfsc STATUS, Z
    goto menu_start_quit
    ;; not equal !
    ;; -> change selection
    movlw MENU_ACTION_SELECT_CHANGE
    movwf menu_action
    movf encoder_value, W
    movwf menu_value
menu_start_quit:
    endm


menu_end macro
    local menu_end_undef
    local menu_end_init
    local menu_end_select_change
    ;; *** Check current action
    ;; INIT
    movlw MENU_ACTION_INIT
    subwf menu_action, W
    btfsc STATUS, Z
    goto menu_end_init
    ;; SELECT_CHANGE
    movlw MENU_ACTION_SELECT_CHANGE
    subwf menu_action, W
    btfsc STATUS, Z
    goto menu_end_select_change
    ;; Other unknown actions
    goto menu_end_undef

menu_end_init:
    ;; todo to be put in 'end' when the number of entry is known !
    encoder_set_value 0, 0, MENU_NB_ENTRY-1
    ;; At init, we also manage a selection change
    ;; -> no goto
menu_end_select_change:
    ;; Store last value
    movf menu_value, W
    movwf menu_last_value
    goto menu_end_undef
menu_end_undef:
    ;; reset menu_action
    movlw MENU_ACTION_UNDEF
    movwf menu_action
    goto LABEL_MENU_START
    endm

lshift_f macro reg, value
    if (value != 0)
        bcf STATUS, C
        rlf reg, F
        lshift_f reg, (value-1)
    endif
    endm






menu_entry macro string
    local menu_entry_end_select
    local menu_entry_init
    local menu_entry_undef
    local menu_entry_select_change
    local menu_entry_draw_select
    local menu_entry_draw_unselect
    ;; *** Check current action
    ;; INIT
    movlw MENU_ACTION_INIT
    subwf menu_action, W
    btfsc STATUS, Z
    goto menu_entry_init
    ;; SELECT_CHANGE
    movlw MENU_ACTION_SELECT_CHANGE
    subwf menu_action, W
    btfsc STATUS, Z
    goto menu_entry_select_change
    ;; Other unknown actions
    goto menu_entry_undef

menu_entry_init:
    ;; Print string
    movlw MENU_STRING_POS_X
    movwf param1
    movlw MENU_NB_ENTRY
    movwf param2


    movlw low string
    movwf param3
    movlw high string
    movwf param4

    call lcd_loc_string
    ;; At end of init, we manage the selection, so
    ;; we continue :
menu_entry_select_change:
    ;; New selected entry ?
    movlw MENU_NB_ENTRY
    movwf param2
    subwf menu_value, W
    btfsc STATUS, Z
    goto menu_entry_draw_select
    ;; Last selected entry ?
    movlw MENU_NB_ENTRY
    subwf menu_last_value, W
    btfsc STATUS, Z
    goto menu_entry_draw_unselect
    goto menu_entry_end_select
#ifdef SIMPLE_SELECT
menu_entry_draw_unselect:
    movlw 0
    movwf param1
    call lcd_locate
    movlw MENU_UNSELECT_CHAR
    movwf param1
    call lcd_char
    goto menu_entry_end_select
menu_entry_draw_select:
    movlw 0
    movwf param1
    call lcd_locate
    movlw MENU_SELECT_CHAR
    movwf param1
    call lcd_char
    goto menu_entry_end_select
#else
menu_entry_draw_unselect:
menu_entry_draw_select:
    ;; draw the selection rectangle with XOR
    ;; (So, the same operation can select and also deselect)
    movlw 0
    movwf param1
    lshift_f param2, LCD_CHAR_HEIGH_SHIFT
    movlw LCD_WIDTH
    movwf param3
    movf param2, W
    movwf param4
    movlw LCD_CHAR_HEIGH
    movwf param4
    bsf param5, LCD_XOR
    call lcd_rectangle
#endif
menu_entry_end_select:


menu_entry_undef:
    VARIABLE MENU_NB_ENTRY=MENU_NB_ENTRY+1
    endm
