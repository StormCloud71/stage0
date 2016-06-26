start
	LOADUI R10 0x0F			; Byte mask
	LOADUI R11 1				; Our toggle
	LOADUI R13 0x600			; Where we are starting our Stack
	;;  R14 will be storing our condition
	FALSE R15					; Our holder

	;; Prep TAPE_01
	LOADUI R0 0x1100
	FOPEN_WRITE

	;; Prep TAPE_02
	LOADUI R0 0x1101
	FOPEN_WRITE

loop
	LOADUI R1 0				; Read from tty
	FGETC						; Read a Char

	;; Check for Ctrl-D
	CMPUI R14 R0 4
	JUMP.NE R14 @.L0
	CALLI R13 @finish

.L0
	;; Check for EOF
	JUMP.P R0 @.L1
	CALLI R13 @finish

.L1
	LOADUI R1 0x1101			; Write to TAPE_02
	FPUTC						; Print the Char
	CALLI R13 @hex				; Convert it
	JUMP.NP R0 @loop			; Don't use nonhex chars
	JUMP.Z R11 @.L99			; Jump if toggled

	;; Process first byte of pair
	AND R15 R0 R10				; Store First nibble
	FALSE R11					; Flip the toggle
	JUMP @loop

.L99
	SL0I R15 4					; Shift our first nibble
	AND R0 R0 R10				; Mask out top
	ADD R0 R0 R15				; Combine nibbles
	LOADI R11 1				; Flip the toggle
	LOADUI R1 0x1100			; Write the combined byte
	FPUTC						; To TAPE_01
	JUMP @loop					; Try to get more bytes

hex
	;; Deal with line comments starting with #
	CMPUI R14 R0 35
	JUMP.E R14 @ascii_comment
	;; Deal with line comments starting with ;
	CMPUI R14 R0 59
	JUMP.E R14 @ascii_comment
	;; Deal with all ascii less than '0'
	CMPUI R14 R0 48
	JUMP.L R14 @ascii_other
	;; Deal with '0'-'9'
	CMPUI R14 R0 57
	JUMP.LE R14 @ascii_num
	;; Deal with all ascii less than 'A'
	CMPUI R14 R0 65
	JUMP.L R14 @ascii_other
	;; Deal with 'A'-'F'
	CMPUI R14 R0 70
	JUMP.LE R14 @ascii_high
	;; Deal with all ascii less than 'a'
	CMPUI R14 R0 97
	JUMP.L R14 @ascii_other
	;;  Deal with 'a'-'f'
	CMPUI R14 R0 102
	JUMP.LE R14 @ascii_low
	;; Ignore the rest
	JUMP @ascii_other

ascii_num
	SUBUI R0 R0 48
	RET R13
ascii_low
	SUBUI R0 R0 87
	RET R13
ascii_high
	SUBUI R0 R0 55
	RET R13
ascii_other
	TRUE R0
	RET R13
ascii_comment
	LOADUI R1 0				; Read from tty
	FGETC						; Read another char
	CMPUI R14 R0 10			; Stop at the end of line
	LOADUI R1 0x1101			; Write to TAPE_02
	FPUTC						; The char we just read
	JUMP.NE R14 @ascii_comment	; Otherwise keep looping
	JUMP @ascii_other

finish
	LOADUI R0 0x1100			; Close TAPE_01
	FCLOSE
	LOADUI R0 0x1101			; Close TAPE_02
	FCLOSE
	HALT
