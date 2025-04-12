ORG 0

    ; Get and store the switch values
CheckSwitches:
	Loadi  1
    OUT    TIMERL
	CALL   Delay
Wait:
	CALL   Delay
	ADDI 1
	OUT Hex0
	Jump Wait
	
	

    
Flashing:
	Load  Edit2
	OUT    LEDs
    CALL   Delay
	Load  Bit9
	OUT    LEDs
    CALL   Delay
    JUMP   Flashing
    



; To make things happen on a human timescale, the timer is
; used to delay for half a second.
Delay:
    OUT    Timer
WaitingLoop:
    IN     Timer
    ADDI   -100
    JNEG   WaitingLoop
    RETURN

; Variables
Pattern:   DW 0
TempPattern: DW 0
Zero: DW 0
Count:      DW 0

; Useful values
Bit0:      DW &B1000000000000001
Bit1:      DW &B0100000000000010
Bit2:      DW &B0010000000000100
Bit3:      DW &B0001000000001000
Bit4:      DW &B0000100000010000
Bit5:      DW &B0000010000100000
Bit6:      DW &B0000110001000000
Bit7:      DW &B0001110010000000
Bit8:      DW &B0111100100000000
Bit9:      DW &B1111101000000001
Edit:	   DW &B0000000000000110
Edit1:	   DW &B1111100011000000
Edit2:	   DW &B0000001000000001
; IO address constants
Switches:  EQU 000
LEDs:      EQU 032
TimerL:     EQU 033
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005