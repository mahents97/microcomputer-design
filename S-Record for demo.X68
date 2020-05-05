*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $4000
START:                  ; first instruction of program

* Put program code here       

        MOVEM.L D0-D7/A0-A7,-(SP)
            
        MOVE.L  #PURPLE,D1
        MOVE.B  #21,d0
        TRAP    #15     
    
        LEA      MESSAGE,A1
        MOVE.B   #14,D0
        TRAP     #15

        MOVE.L  #WHITE,D1
        MOVE.B  #21,D0
        TRAP    #15
        
        MOVEM.L (SP)+,D0-D7/A0-A7
    
        RTS
        
*    SIMHALT             ; halt simulator

* Put variables and constants here

CR  EQU $0D
LF  EQU $0A

YELLOW  EQU $0000FFFF
PURPLE  EQU $00FFB6C1
WHITE   EQU $00FFFFFF
        
MESSAGE DC.B    '  ______________________ ', CR, LF
        DC.B    ' |                      |', CR, LF
        DC.B    ' |    THANK YOU FOR     |', CR, LF
        DC.B    ' |  ATTENDING MY DEMO!  |', CR, LF
        DC.B    ' |                      |', CR, LF
        DC.B    ' |    ANY QUESTIONS?    |', CR, LF
        DC.B    ' |______________________|', CR, LF
        DC.B    '           ||            ', CR, LF 
        DC.B    '  /\___/\  ||            ', CR, LF
        DC.B    ' / o   o \ ||            ', CR, LF
        DC.B    '( == ^ == )||            ', CR, LF
        DC.B    ' \       / ||            ', CR, LF
        DC.B    ' /       \//             ', CR, LF, 0
        
        

    END    START        ; last line of source





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
