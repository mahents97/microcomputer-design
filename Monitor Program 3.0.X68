*-----------------------------------------------------------
* Title      : Monitor Program 3.0
* Written by : Mahents Ravelomanantsoa
* Date       : 04/19/2020
* Description: Monitor program for Microcomputer Design
*-----------------------------------------------------------
    ORG    $1000    * cannot start at $0000 because Stack starts at $0000
START:                  ; first instruction of program

* Put program code here
            MOVEM.L D0-D1/A1,-(SP)
        
            MOVE.L  #GREEN,D1
            MOVE.B  #21,D0
            TRAP    #15

            LEA     WELCOME,A1
            MOVE.B  #14,D0
            TRAP    #15 

            MOVE.L  #WHITE,D1
            MOVE.B  #21,D0
            TRAP    #15
            
            MOVEM.L (SP)+,D0-D1/A1

*Subroutine for main display menu
*The different options are: 1. Read from memory
*                           2. Write to memory
*                           3. Read from registers
*                           4. Write to registers
*                           5. Load an S-record
*                           6. Run an S-record
MAIN_MENU   MOVE.L  D0,-(SP)
            MOVE.L  A1,-(SP)
            LEA     MENU,A1 * loads the address for the MENU prompt into A1 for display
            MOVE.B  #14,D0 * task 14: Display the NULL terminated string at (A1) without CR, LF.
            TRAP    #15 * simulator I/O
            MOVE.L  (SP)+,A1 *MOVE.L  #$0,A1
            MOVE.L  (SP)+,D0 *CLR.L   D0
            
            MOVE.L  D1,-(SP)
            MOVE.L  D0,-(SP)
            MOVE.B  #4,D0 * task 4: Read a number from the keyboard into D1
            TRAP    #15 * simulator I/O
            MOVE.L  (SP)+,D0 *CLR.L   D0
            CMP     #1,D1 * if D1 (input) is 1,
            BEQ     READMEM * go to READMEM: read from memory
            CMP     #2,D1 * if D1 is 2,
            BEQ     WRITEMEM * go to WRITEMEM: write to memory
            CMP     #3,D1 * if D1 is 3,
            BEQ     READREG * go to READREG: read from register
            CMP     #4,D1 * if D1 is 4,
            BEQ     WRITEREG * go to WRITEREG: write to register
            CMP     #5,D1 * if D1 is 5,
            BEQ     LOADSREC * go to LOADSREC: load s-record
            CMP     #6,D1 * if D1 is 6,
            BEQ     RUNSREC * go to RUNSREC: run s-record   
            JSR     INVALID_INPUT * if no match, display error message
            BRA     MAIN_MENU * goes back to main menu

* ---- OPTION 1: Subroutine to read from memory ---- *
READMEM     MOVE.L  (SP)+,D1
            MOVE.L  D0,-(SP)
            MOVE.L  A1,-(SP)
            LEA     OPTION1,A1 * loads prompt to ask input for memory address
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.L  (SP)+,A1 *MOVE.L  #$0,A1
            MOVE.L  (SP)+,D0 *CLR.L   D0
            JSR     GET_STRING
            JSR     ASCII_TO_HEX
            JSR     GET_LONGWORD
            MOVE.L  LONGWORD,ADDRESS
            JSR     DISPLAY_MEM
            BRA     MAIN_MENU           
* -------------------------------------- *

* ---- OPTION 2: Subroutine to write to memory ---- *
WRITEMEM    MOVE.L  (SP)+,D1            
            MOVE.L  D0,-(SP)
            MOVE.L  A1,-(SP)
            LEA     OPTION2A,A1 * loads prompt to ask input for memory address
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.L  (SP)+,A1 *MOVE.L  #$0,A1
            MOVE.L  (SP)+,D0 *CLR.L   D0
            
            JSR     GET_STRING
            JSR     ASCII_TO_HEX
            JSR     GET_LONGWORD
            
            MOVE.L  A0,-(SP)
            MOVE.L  A1,-(SP)
            MOVE.L  #$0000FFFF,A0
            MOVE.L  LONGWORD,A1         
            CMP.L   A0,A1
            BLS     MEM_ERROR * Cannot write to ROM // (also, for an unsigned number use BLS instead of BLT)
            MOVE.L  (SP)+,A1
            MOVE.L  (SP)+,A0
            
            MOVE.L  LONGWORD,ADDRESS   
            
            MOVE.L  D0,-(SP)
            MOVE.L  A1,-(SP) 
            LEA     OPTION2B,A1 * loads prompt to ask input for content
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.L  (SP)+,A1 *MOVE.L  #$0,A1
            MOVE.L  (SP)+,D0 *CLR.L   D0
            
            JSR     GET_STRING
            JSR     ASCII_TO_HEX
            * instead of getting a longword, get bytes 4 times with some tweaking in between 
            * because odd addresses can only take bytes (not word or longword)            
            MOVE.L  A0,-(SP)
            MOVE.L  A2,-(SP)
            MOVE.L  A3,-(SP)
            MOVE.L  ADDRESS,A0
            LEA     INPUT_BUFFER,A2
            LEA     INPUT_BUFFER,A3
            JSR     GET_BYTE
            MOVE.B  BYTE,(A0)+
            ADDA    #2,A2 
            MOVE.L  (A2),(A3)
            JSR     GET_BYTE
            MOVE.B  BYTE,(A0)+
            ADDA    #2,A2 
            MOVE.L  (A2),(A3)
            JSR     GET_BYTE
            MOVE.B  BYTE,(A0)+
            ADDA    #2,A2 
            MOVE.L  (A2),(A3)
            JSR     GET_BYTE
            MOVE.B  BYTE,(A0)+ * now the longword is inside the memory address
            MOVE.L  (SP)+,A3
            MOVE.L  (SP)+,A2
            MOVE.L  (SP)+,A0

            JSR     SUCCESS
            BRA     MAIN_MENU
            
MEM_ERROR   MOVE.L  D0,-(SP)        
            LEA     INVALID_MEM,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.L  (SP)+,D0
            MOVE.L  (SP)+,A1
            MOVE.L  (SP)+,A0 
            BRA     WRITEMEM     
* --------------------------------------- *

* ---- OPTION 3: Subroutine to read from register ---- *
READREG     MOVE.L  (SP)+,D1
            MOVEM.L D0-D7/A0-A7,-(SP)
            
            MOVE.L  D0,-(SP)
            MOVE.L  A1,-(SP) 
            LEA     OPTION3,A1 * loads prompt to ask input for register name
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.L  (SP)+,A1 *MOVE.L  #$0,A1
            MOVE.L  (SP)+,D0 *CLR.L   D0
            JSR     GET_REG
            MOVEM.L (SP)+,D0-D7/A0-A7
            JSR     DISPLAY_REG
            BRA     MAIN_MENU
* ------------------------------------------ *

* ---- OPTION 4: Subroutine to write to register ---- *
WRITEREG    MOVE.L  (SP)+,D1
            
            MOVE.L  D0,-(SP)
            MOVE.L  A1,-(SP)
            LEA     OPTION4A,A1 * loads prompt to ask input for register name
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.L  (SP)+,A1 *MOVE.L  #$0,A1
            MOVE.L  (SP)+,D0 *CLR.L   D0
            
            JSR     GET_REG
            
            MOVE.L  D1,-(SP)
            CLR.L   D1
            MOVE.B  REG_NAME,D1
            CMPI    #$A7,D1
            BEQ     A7_ERROR
            MOVE.L  (SP)+,D1 *CLR.L   D1
            
            MOVE.L  D0,-(SP)
            MOVE.L  A1,-(SP)
            LEA     OPTION4B,A1 * loads prompt to ask input for content
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.L  (SP)+,A1 *MOVE.L  #$0,A1
            MOVE.L  (SP)+,D0 *CLR.L   D0
            JSR     GET_STRING
            JSR     ASCII_TO_HEX
            JSR     GET_LONGWORD
           
            MOVE.L  D0,-(SP)
            CLR.L   D0
            MOVE.B  REG_NAME,D0
            CMPI    #$D0,D0
            BEQ     WRITE_TO_D0
            CMPI    #$D1,D0
            BEQ     WRITE_TO_D1
            CMPI    #$D2,D0
            BEQ     WRITE_TO_D2
            CMPI    #$D3,D0
            BEQ     WRITE_TO_D3
            CMPI    #$D4,D0
            BEQ     WRITE_TO_D4
            CMPI    #$D5,D0
            BEQ     WRITE_TO_D5
            CMPI    #$D6,D0
            BEQ     WRITE_TO_D6
            CMPI    #$D7,D0
            BEQ     WRITE_TO_D7
            CMPI    #$A0,D0
            BEQ     WRITE_TO_A0
            CMPI    #$A1,D0
            BEQ     WRITE_TO_A1
            CMPI    #$A2,D0
            BEQ     WRITE_TO_A2
            CMPI    #$A3,D0
            BEQ     WRITE_TO_A3
            CMPI    #$A4,D0
            BEQ     WRITE_TO_A4
            CMPI    #$A5,D0
            BEQ     WRITE_TO_A5
            CMPI    #$A6,D0
            BEQ     WRITE_TO_A6

WRITE_TO_D0 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,D0
            BRA     WRITEREG_OK
WRITE_TO_D1 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,D1
            BRA     WRITEREG_OK            
WRITE_TO_D2 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,D2
            BRA     WRITEREG_OK
WRITE_TO_D3 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,D3
            BRA     WRITEREG_OK
WRITE_TO_D4 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,D4
            BRA     WRITEREG_OK            
WRITE_TO_D5 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,D5
            BRA     WRITEREG_OK
WRITE_TO_D6 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,D6
            BRA     WRITEREG_OK
WRITE_TO_D7 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,D7
            BRA     WRITEREG_OK            
WRITE_TO_A0 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,A0
            BRA     WRITEREG_OK
WRITE_TO_A1 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,A1
            BRA     WRITEREG_OK
WRITE_TO_A2 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,A2
            BRA     WRITEREG_OK
WRITE_TO_A3 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,A3
            BRA     WRITEREG_OK
WRITE_TO_A4 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,A4
            BRA     WRITEREG_OK
WRITE_TO_A5 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,A5
            BRA     WRITEREG_OK
WRITE_TO_A6 MOVE.L  (SP)+,D0
            MOVE.L  LONGWORD,A6
            BRA     WRITEREG_OK
            
WRITEREG_OK JSR     SUCCESS
            BRA     MAIN_MENU

A7_ERROR    MOVE.L  (SP)+,D1
            MOVE.L  D0,-(SP)
            MOVE.L  A1,-(SP)
            LEA     A7_INVALID,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.L  (SP)+,A1 *MOVE.L  #$0,A1
            MOVE.L  (SP)+,D0 *CLR.L   D0
            BRA     WRITEREG
* ----------------------------------------- *

* ---- OPTION 5: Subroutine to load s-record ---- *
LOADSREC    MOVE.L  (SP)+,D1
            MOVEM.L D0-D7/A0-A7,-(SP)
            
            LEA     OPTION5,A1 * loads prompt to ask input for s-record
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.L  #$0,A1
            CLR.L   D0
            
NEXT_LINE   LEA     INPUT_BUFFER,A1
            MOVE.B  #2,D0 *  Task #2 Read string from keyboard and store at (A1), NULL terminated, length retuned in D1.W (max 80)
            TRAP    #15 
            CLR.L   D0
            CLR.L   D1 * because length is returned in D1.W
            * with the string stored in (A1), replace each byte by its HEX number equivalent
            LEA     (A1),A0 * Copies the address of the string over to A0   
            * skips the first two bytes (i.e. S) because it's already stored as an HEX ASCII
            ADDA.L  #$1,A0
            ADDA.L  #$1,A1
            
ASCII_TO_HEX_LOOP1  MOVE.B  (A1),D0
                    CMPI    #$0,D0 
                    BEQ     END_CONVERSION1 * if the current byte is the NULL element, end the conversion because end of string reached
                    CMPI    #$30,D0 * make sure that it is a digit between 0 and F
                    BLT     TRY_AGAIN1
                    CMPI    #$39,D0
                    BGT     CHECK_LETTER1
TO_HEX1             SUBI    #$30,D0 * subtract the number by 30 to get the desired number
                    MOVE.B  D0,(A1)+
                    BRA     ASCII_TO_HEX_LOOP1
CHECK_LETTER1       CMPI    #$41,D0
                    BLT     TRY_AGAIN1
                    CMPI    #$46,D0
                    BGT     TRY_AGAIN1
                    SUBI    #$07,D0
                    BRA     TO_HEX1
END_CONVERSION1     MOVE.B  #$0,D0 * Null terminate the string so task 14 can be used to output it if needed
                    MOVE.B  D0,(A1)
                    CLR.L   D0  
                    BRA     RETURN
TRY_AGAIN1          LEA     INVALID_CHAR,A1
                    MOVE.B  #14,D0
                    TRAP    #15
                    MOVE.L  #$0,A1
                    CLR.L   D0
                    MOVEM.L (SP)+,D0-D7/A0-A7
                    BRA     LOADSREC            
RETURN  MOVE.B  #$7E,(A1)+ * puts a ~ character to mark the end of the string
        LEA     STRING,A4
        LEA     INPUT_BUFFER,A0
        MOVE.B  (A0)+,(A4)+
        MOVE.B  (A0)+,(A4)+
GET_STRING2 MOVE.B  (A0)+,D1
            CMPI    #$7E,D1
            BEQ     END_STRING
            MOVE.B  (A0)+,D2
            LSL.B   #4,D1
            ADD     D2,D1
            MOVE.B  D1,(A4)+
            CLR.L   D1
            CLR.L   D2
            BRA     GET_STRING2         
            * now the HEX string is located into STRING
            * Validate that string
END_STRING  LEA     STRING,A0
            LEA     (A0),A1
            MOVE.B  (A1)+,D0
            CMPI    #$53,D0
            BNE     NOT_SREC
            MOVE.B  (A1)+,D0
            CMPI    #$00,D0
            BEQ     TYPE0
            CMPI    #$01,D0
            BEQ     TYPE1
            CMPI    #$02,D0
            BEQ     TYPE2
            CMPI    #$08,D0
            BEQ     TYPE8
             
LOAD_DATA   * starts copying data...
            MOVE.B  (A1)+,(A2)+
            ADDI    #1,D7
            CMP     D7,D0 * compare counter to the length of the data 
            BEQ     DONE_LOADING * if the whole data was processed, get out of this loop
            BRA     LOAD_DATA                        
        
DONE_LOADING    CLR.L   D0
                CLR.L   D7
                BRA     NEXT_LINE
                                              
TYPE0       LEA     SREC_MEMORY,A2
            BRA     NEXT_LINE   

TYPE1       MOVE.B  (A1)+,D0 * store byte count into D0
            SUBI    #3,D0 * byte count minus 3 is the length of the data
            ADDA    #2,A1 * skip the address
            MOVEQ   #0,D7 * initialize counter
            BRA     LOAD_DATA

TYPE2       MOVE.B  (A1)+,D0 * store byte count into D0
            SUBI    #4,D0 * byte count minus 4 is the length of the data
            ADDA    #3,A1 * skip the address
            MOVEQ   #0,D7 * initialize counter
            BRA     LOAD_DATA

TYPE8       LEA     LOAD_DONE,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.L  #$0,A1
            CLR.L   D0
            MOVEM.L (SP)+,D0-D7/A0-A7
            BRA     MAIN_MENU
            
NOT_SREC    LEA     INVALID_SREC,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.L  #$0,A1
            CLR.L   D0
            MOVEM.L (SP)+,D0-D7/A0-A7
            BRA     LOADSREC
* ------------------------------------- *

* ---- OPTION 6: Subroutine to run s-record ---- *
RUNSREC     MOVE.L  (SP)+,D1
            MOVEM.L D0/A1,-(SP)
            CMP.B   #$FF,SREC_MEMORY * checks to see if SREC_MEMORY is empty
            BEQ     SREC_ERROR * if no s-record found, display an error message
            LEA     OPTION6,A1 * otherwise, loads message to let the user know that they chose to run an s-record
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.L  #$0,A1
            CLR.L   D0            
            JSR     SREC_MEMORY * go to the allocated memory location for s-records to run it
            LEA     RUN_DONE,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVE.L  #$0,A1
            CLR.L   D0
            MOVEM.L (SP)+,D0/A1
            BRA     MAIN_MENU
            
SREC_ERROR  LEA     NO_SREC,A1 * display an error message for no s-record found
            MOVE.B  #14,D0
            TRAP    #15  
            MOVE.L  #$0,A1
            CLR.L   D0
            MOVEM.L (SP)+,D0/A1
            BRA     MAIN_MENU        
* ------------------------------------ *


* ---- Subroutines shared by other subroutines ---- *
* ------------------------------------------------- *
* ---- Display an error message for invalid input ---- *
INVALID_INPUT   MOVEM.L D0/A1,-(SP)
                LEA     INVALID_CHOICE,A1
                MOVE.B  #14,D0
                TRAP    #15
                MOVEM.L (SP)+,D0/A1
                RTS
* ---------------------------------------------------- *

* ---- Subroutine to input a string character by character ---- *
GET_STRING  MOVEM.L D0-D1/A1,-(SP)
            LEA     INPUT_BUFFER,A1 * Loads address of INPUT_BUFFER into A1
            CLR.L   (A1)
            CLR.L   D1
GET_CHAR_LOOP   MOVE.B  #5,D0  * Read single character from the keyboard into D1.B
                TRAP    #15
                MOVE.B  D1,(A1)+
                CMPI    #$0D,D1 * If inputted character is not CR (carriage return),
                BNE     GET_CHAR_LOOP * keep inputting character    
                CLR.L   D0                
                MOVE.B  #$0,-(A1) * Null terminate the string so task 14 can be used to output it if needed
                MOVEM.L (SP)+,D0-D1/A1
                RTS
* ------------------------------------------------------------- *            

* ---- Subroutine to convert keyboard input values needing to be processed (i.e address, register) into HEX value ---- * 
ASCII_TO_HEX    MOVEM.L D0/A1,-(SP)
                LEA     INPUT_BUFFER,A1
                CLR.L   D0
ASCII_TO_HEX_LOOP   MOVE.B  (A1),D0
                    CMPI    #$0,D0 
                    BEQ     END_CONVERSION * if the current byte is the NULL element, end the conversion because end of string reached
                    CMPI    #$30,D0 * make sure that it is a digit between 0 and F
                    BLT     TRY_AGAIN
                    CMPI    #$39,D0
                    BGT     CHECK_LETTER
TO_HEX              SUBI    #$30,D0 * subtract the number by 30 to get the desired number
                    MOVE.B  D0,(A1)+
                    BRA     ASCII_TO_HEX_LOOP
CHECK_LETTER        CMPI    #$41,D0
                    BLT     TRY_AGAIN
                    CMPI    #$46,D0
                    BGT     TRY_AGAIN
                    SUBI    #$07,D0
                    BRA     TO_HEX
END_CONVERSION      MOVE.B  D0,(A1) * Null terminate the string so task 14 can be used to output it if needed
                    CLR.L   D0
                    MOVEM.L (SP)+,D0/A1
                    RTS
TRY_AGAIN           LEA     INVALID_CHAR,A1
                    MOVE.B  #14,D0
                    TRAP    #15
                    MOVE.L  #$0,A1
                    CLR.L   D0
                    MOVEM.L (SP)+,D0/A1
                    BRA     MAIN_MENU         
* ---------------------------------------------------------------------------------- *   

* ---- Subroutine to get a byte from HEX ---- *
GET_BYTE        MOVEM.L D0-D1/A1-A2,-(SP)
                LEA     INPUT_BUFFER,A1
                LEA     BYTE,A2
                CLR.L   D0
                MOVE.B  (A1)+,D0 * assuming the HEX values are referenced by A1
                MOVE.B  (A1)+,D1
                LSL.B   #4,D0
                ADD     D1,D0
                MOVE.B  D0,(A2) * puts byte in BYTE
                CLR.L   D0
                CLR.L   D1
                MOVEM.L (SP)+,D0-D1/A1-A2
                RTS
* -------------------------------------------------- *

* ---- Subroutine to get a longword from HEX ---- *
GET_LONGWORD    MOVEM.L D0-D1/A1-A3/A5,-(SP)
                LEA     INPUT_BUFFER,A1
                LEA     BYTE,A2
                LEA     WORD,A3
                LEA     LONGWORD,A5
                CLR.L   D0
                MOVE.B  (A1)+,D0 * assuming contents of INPUT_BUFFER are HEX ASCII values
                MOVE.B  (A1)+,D1
                LSL.B   #4,D0
                ADD     D1,D0
                MOVE.B  D0,(A2) * puts byte in BYTE
                CLR.L   D0
                CLR.L   D1
                MOVE.B  BYTE,(A3)+
                
                MOVE.B  (A1)+,D0
                MOVE.B  (A1)+,D1
                LSL.B   #4,D0
                ADD     D1,D0
                MOVE.B  D0,(A2)
                CLR.L   D0
                CLR.L   D1
                MOVE.B  BYTE,(A3)     
                
                MOVE.W  WORD,(A5)
                ADDA    #2,A5
                LEA     WORD,A3              

                MOVE.B  (A1)+,D0
                MOVE.B  (A1)+,D1
                LSL.B   #4,D0
                ADD     D1,D0
                MOVE.B  D0,(A2)
                CLR.L   D0
                CLR.L   D1
                MOVE.B  BYTE,(A3)+
                
                MOVE.B  (A1)+,D0
                MOVE.B  (A1)+,D1
                LSL.B   #4,D0
                ADD     D1,D0
                MOVE.B  D0,(A2)
                CLR.L   D0
                CLR.L   D1
                MOVE.B  BYTE,(A3)     
                
                MOVE.W   WORD,(A5)
                
                MOVEM.L (SP)+,D0-D1/A1-A3/A5
                RTS        
* -------------------------------------------------- *

* ---- Subroutine to get a register name ---- *
GET_REG     MOVEM.L D0/A1/A3,-(SP)
            LEA     REG_NAME,A3
            JSR     GET_STRING
            JSR     ASCII_TO_HEX
            JSR     GET_BYTE
            MOVE.B  BYTE,(A3)
            
            * check if valid register name
            CMPI.B    #$D0,(A3)
            BEQ       IS_REG
            CMPI.B    #$D1,(A3)
            BEQ       IS_REG
            CMPI.B    #$D2,(A3)
            BEQ       IS_REG
            CMPI.B    #$D3,(A3)
            BEQ       IS_REG
            CMPI.B    #$D4,(A3)
            BEQ       IS_REG
            CMPI.B    #$D5,(A3)
            BEQ       IS_REG
            CMPI.B    #$D6,(A3)
            BEQ       IS_REG
            CMPI.B    #$D7,(A3)
            BEQ       IS_REG
            CMPI.B    #$A0,(A3)
            BEQ       IS_REG
            CMPI.B    #$A1,(A3)
            BEQ       IS_REG
            CMPI.B    #$A2,(A3)
            BEQ       IS_REG
            CMPI.B    #$A3,(A3)
            BEQ       IS_REG
            CMPI.B    #$A4,(A3)
            BEQ       IS_REG
            CMPI.B    #$A5,(A3)
            BEQ       IS_REG
            CMPI.B    #$A6,(A3)
            BEQ       IS_REG
            CMPI.B    #$A7,(A3)
            BEQ       IS_REG
            * if no match, invalid register name
            LEA     IS_NOT_REG,A1
            MOVE.L  #14,D0
            TRAP    #15
            MOVE.L  #$0,A1
            CLR.L   D0
            MOVEM.L (SP)+,D0/A1/A3
            BRA     GET_REG
            
IS_REG      MOVEM.L (SP)+,D0/A1/A3
            RTS        
* -------------------------------------------------- *

* ---- Subroutine to display memory content ---- *
DISPLAY_MEM     MOVEM.L D0-D7/A0-A7,-(SP)
                LEA     MEM_HEADER_ROW,A1
                MOVE.B  #14,D0
                TRAP    #15
                MOVE.L  #$0,A1
                CLR.L   D0
                
                MOVE.L  ADDRESS,LONGWORD
                JSR     HEX_TO_ASCII
                LEA     OUTPUT_BUFFER,A1
                MOVE.B  #14,D0
                TRAP    #15
                CLR.L   D0
                CLR.L   D1
                MOVE.B  #$3A,D1 * Colon
                MOVE.B  #6,D0 * Display single character in D1.B.
                TRAP    #15
                CLR.L   D0
                CLR.L   D1
                
                MOVE.B  #$20,D1 * Space
                MOVE.B  #6,D0  
                TRAP    #15
                CLR.L   D0
                CLR.L   D1  
                CLR.L   D3
                LEA     LONGWORD,A0
                MOVE.L  ADDRESS,A1
                
                MOVE.B  #0,D3 * initialize counter 
NEXT_BYTE       MOVE.B  (A1)+,(A0)+
                ADDI    #1,D3
                CMPI    #4,D3
                BLT     NEXT_BYTE
                
                JSR     HEX_TO_ASCII
                LEA     OUTPUT_BUFFER,A1
                MOVE.B  #14,D0
                TRAP    #15

                MOVEM.L (SP)+,D0-D7/A0-A7
                RTS
* ------------------------------------------------------- *

*--- Subroutine to display register content ---*
DISPLAY_REG    MOVEM.L D0-D7/A0-A7,-(SP) * save every register!!!

               MOVE.L  D0,-(SP)
               MOVE.L  A1,-(SP) 
               LEA     REG_HEADER_ROW,A1
               MOVE.B  #14,D0
               TRAP    #15
               MOVE.L  (SP)+,A1 *MOVE.L  #$0,A1
               MOVE.L  (SP)+,D0 *CLR.L   D0
               
               MOVE.L  D0,-(SP)
               MOVE.L  D1,-(SP) 
               MOVE.B  #$20,D1 * Space
               MOVE.B  #6,D0  
               TRAP    #15               
               MOVE.B  #$20,D1 * Space
               MOVE.B  #6,D0  
               TRAP    #15
               
               MOVE.L  D2,-(SP)
               CLR.L   D1
               MOVE.B  REG_NAME,D1
               MOVE.B  #15,D0 * Display the unsigned number in D1.L converted to number base (2 through 36) contained in D2.B.
               MOVE.B  #16,D2
               TRAP    #15
               MOVE.L  (SP)+,D2
               
               MOVE.B  #$3A,D1 * Colon
               MOVE.B  #6,D0 * Display single character in D1.B.
               TRAP    #15
               MOVE.B  #$20,D1 * Space
               MOVE.B  #6,D0  
               TRAP    #15
               MOVE.B  #$20,D1 * Space
               MOVE.B  #6,D0  
               TRAP    #15
               MOVE.B  #$20,D1 * Space
               MOVE.B  #6,D0  
               TRAP    #15    
               MOVE.B  #$20,D1 * Space
               MOVE.B  #6,D0  
               TRAP    #15
               MOVE.B  #$20,D1 * Space
               MOVE.B  #6,D0  
               TRAP    #15
               MOVE.L  (SP)+,D1
               MOVE.L  (SP)+,D0
            
            CLR.L   D1   
            MOVE.B  REG_NAME,D1
            CMPI    #$D0,D1
            BEQ     GOTO_D0
            CMPI    #$D1,D1
            BEQ     GOTO_D1
            CMPI    #$D2,D1
            BEQ     GOTO_D2
            CMPI    #$D3,D1
            BEQ     GOTO_D3
            CMPI    #$D4,D1
            BEQ     GOTO_D4
            CMPI    #$D5,D1
            BEQ     GOTO_D5
            CMPI    #$D6,D1
            BEQ     GOTO_D6
            CMPI    #$D7,D1
            BEQ     GOTO_D7
            CMPI    #$A0,D1
            BEQ     GOTO_A0
            CMPI    #$A1,D1
            BEQ     GOTO_A1
            CMPI    #$A2,D1
            BEQ     GOTO_A2
            CMPI    #$A3,D1
            BEQ     GOTO_A3
            CMPI    #$A4,D1
            BEQ     GOTO_A4
            CMPI    #$A5,D1
            BEQ     GOTO_A5
            CMPI    #$A6,D1
            BEQ     GOTO_A6
            CMPI    #$A7,D1
            BEQ     GOTO_A7  
            
* put the content of the specified individual register into D1
GOTO_D0     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  D0,D1
            BRA     READREG_OK
GOTO_D1     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  D1,D1
            BRA     READREG_OK
GOTO_D2     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  D2,D1
            BRA     READREG_OK
GOTO_D3     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  D3,D1
            BRA     READREG_OK
GOTO_D4     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  D4,D1
            BRA     READREG_OK
GOTO_D5     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  D5,D1
            BRA     READREG_OK
GOTO_D6     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  D6,D1
            BRA     READREG_OK            
GOTO_D7     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  D7,D1
            BRA     READREG_OK
GOTO_A0     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  A0,D1
            BRA     READREG_OK
GOTO_A1     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  A1,D1
            BRA     READREG_OK
GOTO_A2     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  A2,D1
            BRA     READREG_OK
GOTO_A3     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  A3,D1
            BRA     READREG_OK
GOTO_A4     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  A4,D1
            BRA     READREG_OK
GOTO_A5     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  A5,D1
            BRA     READREG_OK
GOTO_A6     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  A6,D1
            BRA     READREG_OK          
GOTO_A7     MOVEM.L (SP)+,D0-D7/A0-A7
            MOVE.L  D1,-(SP)
            MOVE.L  A7,D1
            BRA     READREG_OK

READREG_OK     MOVE.L  D1,$3000
               MOVE.L  (SP)+,D1
               MOVEM.L D0/A1,-(SP)
               MOVE.L  $3000,LONGWORD
               JSR     HEX_TO_ASCII
               LEA     OUTPUT_BUFFER,A1
               MOVE.B  #14,D0
               TRAP    #15  
               MOVEM.L (SP)+,D0/A1 
    
               RTS
* ----------------------------------------------- *

* ---- Confirmation message ---- *
SUCCESS     MOVEM.L D0/A1,-(SP)
            LEA     WRITE_DONE,A1
            MOVE.B  #14,D0
            TRAP    #15
            MOVEM.L (SP)+,D0/A1
            RTS
* ------------------------------ *

* ---- Subroutine to transform HEX to ASCII ---- *
HEX_TO_ASCII    MOVEM.L D0-D7/A0-A7,-(SP)
                LEA     OUTPUT_BUFFER,A0
                LEA     LONGWORD,A1 * the HEX longword to convert to ASCII
                MOVE.L  #0,D2 * counter
                CLR.L   D0
                CLR.L   D1
               
SPLIT_BYTE   MOVE.B  (A1),D0
             MOVE.B  (A1)+,D1
             LSR.B   #4,D0
             MOVE.B  D0,(A0)+
             LSL.B   #4,D1
             LSR.B   #4,D1
             MOVE.B  D1,(A0)+
             ADDI    #1,D2
             CMP.B   #4,D2
             BLT     SPLIT_BYTE
                    
             LEA    OUTPUT_BUFFER,A0
             MOVE.L #0,D1
             CLR.L  D0
HEX_TO_ASCII_LOOP    MOVE.B (A0),D0
                     CMPI   #$09,D0
                     BGT    LETTER
                     ADDI   #$30,D0
                     MOVE.B D0,(A0)+
                     ADDI   #1,D1 
                     CMP.B  #8,D1
                     BNE    HEX_TO_ASCII_LOOP
                     BRA    ASCII_READY                  
                     
LETTER               ADDI   #$37,D0 
                     MOVE.B D0,(A0)+   
                     ADDI   #1,D1  
                     CMP.B  #8,D1       
                     BNE    HEX_TO_ASCII_LOOP
                     BRA    ASCII_READY

ASCII_READY MOVE.B  #$0,(A0) * null terminate the string for output
            MOVEM.L (SP)+,D0-D7/A0-A7
            RTS
                     
* ---------------------------------------------- *


    SIMHALT             ; halt simulator

* Put variables and constants here

WHITE   EQU $00FFFFFF
GREEN   EQU $0000FF00

SREC_MEMORY EQU $4000 * Memory block for S-Records (Match the origin of the s-record to this)

CR  EQU $0D
LF  EQU $0A

WELCOME DC.B    '||      ||  |||||  ||      ||||   ||||   |||  |||  |||||  ', CR, LF
        DC.B    '||      ||  ||     ||     ||     ||  ||  ||||||||  ||     ', CR, LF
        DC.B    '||  ||  ||  |||||  ||     ||     ||  ||  || || ||  |||||  ', CR, LF
        DC.B    '|| |||| ||  ||     ||     ||     ||  ||  ||    ||  ||     ', CR, LF
        DC.B    '||||  ||||  |||||  |||||   ||||   ||||   ||    ||  |||||  ', CR, LF, 0

MENU    DC.B    '', CR, LF, LF
        DC.B    'What would you like to do?', CR, LF
        DC.B    '  1. Read from memory ($00000000 - $FFFFFFFF)', CR, LF
        DC.B    '  2. Write to memory  ($00010000 - $FFFFFFFF)', CR, LF
        DC.B    '  3. Read from register (D0-D7/A0-A7)', CR, LF
        DC.B    '  4. Write to register  (D0-D7/A0-A6)', CR, LF
        DC.B    '  5. Load s-record', CR, LF
        DC.B    '  6. Run s-record', CR, LF
        DC.B    'Please type in the number of your choice: ', 0
        
INVALID_CHOICE DC.B    'Invalid choice. Please try again.', CR, LF, LF, 0

OPTION1 DC.B    'Type in the address you wish to read from (00000000-FFFFFFFF) : ', CR, LF, 0
OPTION2A DC.B   'Type in the address you wish to write to (00010000-FFFFFFFF) : ', CR, LF, 0
OPTION2B DC.B   'Type in the 8-digit HEX you wish to put into that address (00000000-FFFFFFFF): ', CR, LF, 0
OPTION3 DC.B    'Type in the register you wish to read from (D0-D7/A0-A7): ', CR, LF, 0
OPTION4A DC.B   'Type in the register you wish to write to (D0-D7/A0-A6): ', CR, LF, 0
OPTION4B DC.B   'Type in the 8-digit HEX you wish to put into the register (00000000-FFFFFFFF): ', CR, LF, 0
OPTION5 DC.B    'To load an S-Record, please paste the S-Record here: ', CR, LF, 0
OPTION6 DC.B    'Running S-Record ...', CR, LF, 0

NO_SREC DC.B    'S-Record not found. Load an S-Record first by choosing 5 in Main Menu.', CR, LF, 0

WRITE_DONE DC.B 'Your entry was successful.', CR, LF, 0

IS_NOT_REG DC.B 'Invalid input. Please try another register (D0-D7 or A0-A7): ', CR, LF, 0

A7_INVALID DC.B  'The register A7 cannot be written to. Please try another register.', CR, LF, LF, 0

INVALID_MEM DC.B 'Invalid memory. Please try again with an address within the given range.', CR, LF, LF, 0

INVALID_LONG DC.B  'Invalid input. Please type in a longword (00000000-FFFFFFFF).', CR, LF, LF, 0

INVALID_CHAR DC.B   'Invalid character in input.', CR, LF, LF, 0

INVALID_SREC DC.B   'Invalid input. Please only type in an S-Record at a time.', CR, LF, LF, 0

LOAD_DONE DC.B  'The S-Record has been successfully loaded.', CR, LF, LF, 0

RUN_DONE DC.B   'The S-Record ran successfully.', CR, LF, LF, 0

MEM_HEADER_ROW  DC.B    ' MEMORY :  CONTENT ', CR, LF
                DC.B    '--------  ---------', CR, LF, 0

REG_HEADER_ROW  DC.B    'REGISTER:  CONTENT ', CR, LF
                DC.B    '--------  ---------', CR, LF, 0

INPUT_BUFFER EQU $3008
STRING   EQU $3090
LONGWORD    EQU $3100
ADDRESS    EQU $3104
WORD        EQU $3108
BYTE        EQU $310A
REG_NAME    EQU $310C
OUTPUT_BUFFER   EQU $3110

    END    START        ; last line of source














*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
