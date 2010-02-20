;;; Variables declaration
 UDATA_SHR
w_saved      RES 1 ; variable used for context saving
    global w_saved
status_saved RES 1 ; variable used for context saving
    global status_saved
pclath_saved RES 1 ; variable used for context saving
    global pclath_saved
param1       RES 1 ; parameter 1 of functions
    global param1;
param2       RES 1 ; parameter 2 of functions
    global param2
param3       RES 1 ; parameter 3 of functions
    global param3
param4       RES 1 ; parameter 4 of functions
    global param4;
param5       RES 1 ; parameter 5 of functions
    global param5;
encoder_sw RES 1 ; encoder value
    global encoder_sw;
encoder_value RES 1 ; encoder value
    global encoder_value;
encoder_last_value RES 1 ; encoder last value TODO to be removed, for test only !
    global encoder_last_value;
menu_value RES 1 ; current menu value (selected entry)
    global menu_value;
menu_action RES 1 ; current menu action (event)
    global menu_action;
interrupt_var_1 RES 1 ; variable used by ISR
    global interrupt_var_1;
current_bank       RES 1 ; Currently selected memory bank
    global current_bank;

tst_timer       RES 1
    global tst_timer;


END