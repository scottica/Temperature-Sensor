$NOLIST
$MODN76E003
$LIST

; --- System Clock ---
CLK               EQU 16600000
BAUD              EQU 115200
TIMER1_RELOAD     EQU (0x100-(CLK/(16*BAUD)))
VREF_SCALED       EQU 50000         ; 5.0000V Reference

; --- Pin Definitions ---
LCD_RS            EQU P1.3
LCD_E             EQU P1.4
LED_ALARM         EQU P1.7          ; Pin 6

; Buttons (Active Low)
BTN_MODE          EQU P1.5          ; Pin 10
BTN_UP            EQU P1.0          ; Pin 15
BTN_DOWN          EQU P3.0          ; Pin 5
BTN_RESET         EQU P1.2          ; Pin 13

ORG 0000H
    ljmp Main

; --- Variables ---
DSEG at 30H
x:          ds 4    
y:          ds 4    
bcd:        ds 5    
max_temp:   ds 4    
alarm_limit: ds 1   
mode:       ds 1    

BSEG
mf:         dbit 1

CSEG

; =============================================================================
;  LCD DRIVER
; =============================================================================

LCD_4BIT:
    clr LCD_E
    mov R2, #40
    lcall WaitmilliSec
    mov a, #33H
    lcall WriteCommand
    mov a, #33H
    lcall WriteCommand
    mov a, #32H
    lcall WriteCommand
    mov a, #28H
    lcall WriteCommand
    mov a, #0CH
    lcall WriteCommand
    mov a, #01H
    lcall WriteCommand
    mov R2, #2
    lcall WaitmilliSec
    ret

WriteCommand:
    clr LCD_RS
    sjmp SendByte
WriteData:
    setb LCD_RS
SendByte:
    mov c, ACC.7
    mov P0.3, c
    mov c, ACC.6
    mov P0.2, c
    mov c, ACC.5
    mov P0.1, c
    mov c, ACC.4
    mov P0.0, c
    setb LCD_E
    clr LCD_E
    mov c, ACC.3
    mov P0.3, c
    mov c, ACC.2
    mov P0.2, c
    mov c, ACC.1
    mov P0.1, c
    mov c, ACC.0
    mov P0.0, c
    setb LCD_E
    clr LCD_E
    lcall Wait40uSec
    ret

WaitmilliSec:
    push AR0
    push AR1
L3: mov R1, #40
L2: mov R0, #104
L1: djnz R0, L1
    djnz R1, L2
    djnz R2, L3
    pop AR1
    pop AR0
    ret

Wait40uSec:
    push AR0
    mov R0, #133
W40_Loop:
    nop
    djnz R0, W40_Loop
    pop AR0
    ret

SendString:
    clr a
    movc a, @a+dptr
    jz StringDone
    lcall WriteData
    inc dptr
    sjmp SendString
StringDone:
    ret

Clear_LCD:
    mov a, #01H
    lcall WriteCommand
    mov R2, #2
    lcall WaitmilliSec
    ret

; =============================================================================
;  MATH & LOGIC
; =============================================================================

Load_y MAC
    mov y+0, #low (%0 % 0x10000) 
    mov y+1, #high(%0 % 0x10000) 
    mov y+2, #low (%0 / 0x10000) 
    mov y+3, #high(%0 / 0x10000) 
ENDMAC

hex2bcd:
    push acc
    push psw
    push AR0
    push AR1
    push AR2
    clr a
    mov bcd+0, a
    mov bcd+1, a
    mov bcd+2, a
    mov bcd+3, a
    mov bcd+4, a
    mov r2, #32
hex2bcd_L0:
    mov a, x+3
    mov c, acc.7 
    mov r1, #4
    mov r0, #(x+0)
hex2bcd_L1:
    mov a, @r0
    rlc a
    mov @r0, a
    inc r0
    djnz r1, hex2bcd_L1
    mov r1, #5
    mov r0, #(bcd+0)
hex2bcd_L2:   
    mov a, @r0
    addc a, @r0
    da a
    mov @r0, a
    inc r0
    djnz r1, hex2bcd_L2
    djnz r2, hex2bcd_L0
    pop AR2
    pop AR1
    pop AR0
    pop psw
    pop acc
    ret

mul32:
    push acc
    push b
    push psw
    push AR0
    push AR1
    push AR2
    push AR3
    mov a,x+0
    mov b,y+0
    mul ab      
    mov R0,a
    mov R1,b
    mov a,x+1
    mov b,y+0
    mul ab      
    add a,R1
    mov R1,a
    clr a
    addc a,b
    mov R2,a
    mov a,x+0
    mov b,y+1
    mul ab      
    add a,R1
    mov R1,a
    mov a,b
    addc a,R2
    mov R2,a
    clr a
    rlc a
    mov R3,a
    mov a,x+2
    mov b,y+0
    mul ab      
    add a,R2
    mov R2,a
    mov a,b
    addc a,R3
    mov R3,a
    mov a,x+1
    mov b,y+1
    mul ab      
    add a,R2
    mov R2,a
    mov a,b
    addc a,R3
    mov R3,a
    mov a,x+0
    mov b,y+2
    mul ab      
    add a,R2
    mov R2,a
    mov a,b
    addc a,R3
    mov R3,a
    mov a,x+3
    mov b,y+0
    mul ab      
    add a,R3
    mov R3,a
    mov a,x+2
    mov b,y+1
    mul ab      
    add a,R3
    mov R3,a
    mov a,x+1
    mov b,y+2
    mul ab      
    add a,R3
    mov R3,a
    mov a,x+0
    mov b,y+3
    mul ab      
    add a,R3
    mov R3,a
    mov x+3,R3
    mov x+2,R2
    mov x+1,R1
    mov x+0,R0
    pop AR3
    pop AR2
    pop AR1
    pop AR0
    pop psw
    pop b
    pop acc
    ret

div32:
    push acc
    push psw
    push AR0
    push AR1
    push AR2
    push AR3
    push AR4
    mov R4,#32
    clr a
    mov R0,a
    mov R1,a
    mov R2,a
    mov R3,a
div32_loop:
    clr c
    mov a,x+0
    rlc a
    mov x+0,a
    mov a,x+1
    rlc a
    mov x+1,a
    mov a,x+2
    rlc a
    mov x+2,a
    mov a,x+3
    rlc a
    mov x+3,a
    mov a,R0
    rlc a 
    mov R0,a
    mov a,R1
    rlc a
    mov R1,a
    mov a,R2
    rlc a
    mov R2,a
    mov a,R3
    rlc a
    mov R3,a
    clr c        
    mov a,R0
    subb a,y+0
    mov a,R1
    subb a,y+1
    mov a,R2
    subb a,y+2
    mov a,R3
    subb a,y+3
    jc div32_minus
    mov a,R0
    subb a,y+0 
    mov R0,a
    mov a,R1
    subb a,y+1
    mov R1,a
    mov a,R2
    subb a,y+2
    mov R2,a
    mov a,R3
    subb a,y+3
    mov R3,a
    orl x+0,#1
div32_minus:
    djnz R4, div32_loop
    pop AR4
    pop AR3
    pop AR2
    pop AR1
    pop AR0
    pop psw
    pop acc
    ret

sub32:
    push acc
    push psw
    clr c
    mov a, x+0
    subb a, y+0
    mov x+0, a
    mov a, x+1
    subb a, y+1
    mov x+1, a
    mov a, x+2
    subb a, y+2
    mov x+2, a
    mov a, x+3
    subb a, y+3
    mov x+3, a
    pop psw
    pop acc
    ret

; =============================================================================
;  SYSTEM INIT
; =============================================================================

Init_System:
    ; Init Serial
    orl CKCON, #0x10   
    orl PCON, #0x80    
    mov SCON, #0x52    
    anl T3CON, #0xDF   
    anl TMOD, #0x0F    
    orl TMOD, #0x20    
    mov TH1, #TIMER1_RELOAD
    setb TR1           

    ; Init ADC (P1.1)
    orl P1M1, #0b00000010
    anl P1M2, #0b11111101
    anl ADCCON0, #0xF0
    orl ADCCON0, #0x07
    mov AINDIDS, #0x00 
    orl AINDIDS, #0b10000000
    orl ADCCON1, #0x01
    
    anl P1M1, #0b01111111
    orl P1M2, #0b10000000
    setb LED_ALARM ; Start with LED OFF (High)
    ret

Send_Char_Serial:
    jnb TI, $
    clr TI
    mov SBUF, a
    ret

Send_Nibble_Serial:
    push acc
    anl a, #0x0F
    add a, #0x30
    lcall Send_Char_Serial
    pop acc
    ret

Send_Nibble_LCD_Digit:
    push acc
    anl a, #0x0F
    add a, #0x30    
    lcall WriteData 
    pop acc
    ret

; =============================================================================
;  MAIN PROGRAM
; =============================================================================

Main:
    mov SP, #7FH
    mov P0M1, #00H
    mov P0M2, #00H
    mov P1M1, #00H
    mov P1M2, #00H
    
    lcall LCD_4BIT
    mov a, #80H
    lcall WriteCommand
    mov dptr, #Msg_Boot
    lcall SendString
    mov R2, #200
    lcall WaitmilliSec
    lcall Clear_LCD

    lcall Init_System
    
    mov alarm_limit, #24
    mov mode, #0
    
    mov max_temp+0, #0
    mov max_temp+1, #0
    mov max_temp+2, #0
    mov max_temp+3, #0

Main_Loop:
    ; --- ADC ---
    clr ADCF
    setb ADCS
    jnb ADCF, $
    
    mov a, ADCRH
    swap a
    push acc
    anl a, #0x0F
    mov R1, a
    pop acc
    anl a, #0xF0
    orl a, ADCRL
    mov R0, a

    mov x+0, R0
    mov x+1, R1
    mov x+2, #0
    mov x+3, #0

    Load_y(VREF_SCALED) 
    lcall mul32
    Load_y(4095)
    lcall div32
    Load_y(27300)       
    lcall sub32
    ; x = Temp * 100

    ; --- CHECK ALARM ---
    mov y+0, #100
    mov y+1, #0
    mov y+2, #0
    mov y+3, #0
    mov a, alarm_limit
    mov b, #100
    mul ab
    mov y+0, a
    mov y+1, b
    
    ; Compare X vs Y
    clr c
    mov a, x+0
    subb a, y+0
    mov a, x+1
    subb a, y+1
    mov a, x+2
    subb a, y+2
    mov a, x+3
    subb a, y+3
    
    ; jnc = Jump if No Carry (No Borrow) = X >= Y
    jnc Alarm_Triggered 
    setb LED_ALARM 
    sjmp Alarm_Done
    
Alarm_Triggered:
    clr LED_ALARM
Alarm_Done:

    ; --- UPDATE MAX TEMP ---
    mov y+0, max_temp+0
    mov y+1, max_temp+1
    mov y+2, max_temp+2
    mov y+3, max_temp+3
    
    clr c
    mov a, x+0
    subb a, y+0
    mov a, x+1
    subb a, y+1
    mov a, x+2
    subb a, y+2
    mov a, x+3
    subb a, y+3
    
    jc Skip_Max ; Jump if Carry (Borrow) = X < Max
    
    ; New Max
    mov max_temp+0, x+0
    mov max_temp+1, x+1
    mov max_temp+2, x+2
    mov max_temp+3, x+3
Skip_Max:

    ; --- SERIAL ---
    push x+0
    push x+1
    push x+2
    push x+3
    lcall hex2bcd
    mov a, bcd+1
    swap a
    lcall Send_Nibble_Serial
    mov a, bcd+1
    lcall Send_Nibble_Serial
    mov a, #'.'
    lcall Send_Char_Serial
    mov a, bcd+0
    swap a
    lcall Send_Nibble_Serial
    mov a, bcd+0
    lcall Send_Nibble_Serial
    mov a, #0x0D 
    lcall Send_Char_Serial
    mov a, #0x0A 
    lcall Send_Char_Serial
    pop x+3
    pop x+2
    pop x+1
    pop x+0

    ; --- BUTTONS ---
    jnb BTN_MODE, Change_Mode
    sjmp Check_Mode_1

Change_Mode:
    inc mode
    mov a, mode
    cjne a, #3, Mode_Safe
    mov mode, #0
Mode_Safe:
    lcall Clear_LCD
    lcall Wait_Debounce
    sjmp Display_Refresh

Check_Mode_1:
    mov a, mode
    cjne a, #1, Check_Mode_2
    jnb BTN_UP, Inc_Alarm
    jnb BTN_DOWN, Dec_Alarm
    sjmp Display_Refresh

Inc_Alarm:
    inc alarm_limit
    lcall Wait_Debounce
    sjmp Display_Refresh
Dec_Alarm:
    dec alarm_limit
    lcall Wait_Debounce
    sjmp Display_Refresh

Check_Mode_2:
    mov a, mode
    cjne a, #2, Display_Refresh
    jnb BTN_RESET, Do_Reset
    sjmp Display_Refresh

Do_Reset:
    mov max_temp+0, #0
    mov max_temp+1, #0
    mov max_temp+2, #0
    mov max_temp+3, #0
    lcall Wait_Debounce

    ; --- DISPLAY ---
Display_Refresh:
    mov a, mode
    jz Show_0
    dec a
    jz Show_1
    sjmp Show_2

Show_0: 
    mov a, #80H
    lcall WriteCommand
    mov dptr, #Msg_Temp
    lcall SendString
    lcall hex2bcd
    lcall Display_BCD_Num
    
    mov a, #0C0H
    lcall WriteCommand
    mov dptr, #Msg_Alrm
    lcall SendString
    lcall Display_Alarm_Val
    ljmp End_Loop

Show_1: 
    mov a, #80H
    lcall WriteCommand
    mov dptr, #Msg_Set
    lcall SendString
    
    mov a, #0C0H
    lcall WriteCommand
    mov dptr, #Msg_Lim
    lcall SendString
    lcall Display_Alarm_Val
    ljmp End_Loop

Show_2: 
    mov a, #80H
    lcall WriteCommand
    mov dptr, #Msg_Rec
    lcall SendString
    
    mov a, #0C0H
    lcall WriteCommand
    mov dptr, #Msg_Max
    lcall SendString
    
    mov x+0, max_temp+0
    mov x+1, max_temp+1
    mov x+2, max_temp+2
    mov x+3, max_temp+3
    lcall hex2bcd
    lcall Display_BCD_Num

End_Loop:
    mov R2, #100
    lcall WaitmilliSec
    ljmp Main_Loop

; --- Helpers ---

Display_BCD_Num:
    mov a, bcd+1
    swap a
    lcall Send_Nibble_LCD_Digit
    mov a, bcd+1
    lcall Send_Nibble_LCD_Digit
    mov a, #'.'
    lcall WriteData
    mov a, bcd+0
    swap a
    lcall Send_Nibble_LCD_Digit
    mov a, bcd+0
    lcall Send_Nibble_LCD_Digit
    mov a, #' '
    lcall WriteData
    mov a, #'C'
    lcall WriteData
    ret

Display_Alarm_Val:
    mov a, alarm_limit
    mov b, #100
    div ab
    mov a, b
    mov b, #10
    div ab
    add a, #30h
    lcall WriteData
    mov a, b
    add a, #30h
    lcall WriteData
    mov a, #'C'
    lcall WriteData
    ret

Wait_Debounce:
    mov R2, #200
    lcall WaitmilliSec
    ret

; --- Strings ---
Msg_Boot: db 'Booting...', 0
Msg_Temp: db 'Temp: ', 0
Msg_Alrm: db 'Limit: ', 0
Msg_Set:  db 'Set Alarm Temp', 0
Msg_Lim:  db 'Adj Limit: ', 0
Msg_Rec:  db 'Max Temp Record', 0
Msg_Max:  db 'Max:  ', 0

END