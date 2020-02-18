; executable name   : hexdump
; version           : 1.0
; created date      : 2019-01-26
; modified date     : 2019-01-26 
; author            : e2dk4r
; description:
;   simple program that runs on Linux,
;   using nasm,
;   reading input file to buffer of blocks,
;   converting digits to hex values
; usage:
;   toup > output_file < input_file

%define BUFSZ 16

%define SYSIN 0
%define SYSOUT 1

%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_EXIT 60

section .bss
    buf:		resb BUFSZ

section .data
	HexStr:		db	" 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", 0xa, 0x0
	HexStrLen	equ	$ - HexStr - 1

	Digits:		db "0123456789ABCDEF"

section .text
global _start

_start:

read: ; get strings from standard input
	mov		rdi, SYSIN		; stdin file descriptor
	mov		rsi, buf		; buffer address
	mov		rdx, BUFSZ		; buffer size	
	mov		rax, SYS_READ	; sys_read syscall
	syscall

	; test input validation
	cmp		rax, 0			; look sys_read syscall's return code
	je		exit			; exit if is it EOL

	; set up registers for processing buffer
	mov		rbp, rax		; save # of bytes written in rbp
	mov		rsi, buf		; place address of file buffer into rsi
	mov		rdi, HexStr		; place address of line string into rdi
	xor		rcx, rcx		; clear line string pointer to 0

; loop through the buffer and convert binary to hex digits:
scan:
	xor		rax, rax		; clear eax

	; calculate the offset into HexStr, which is value in (ecx X 3):
	mov		rdx, rcx		; copy the character counter into rdx
	lea		rdx, [rdx * 2 + rdx] ; multiply edx X 3
	;shl		rdx, 1			; multiply pointer by 2 using left shift
	;add		rdx, rcx		; complete the multiplication

	; get a character from buffer and insert into the string:
	mov		al, byte [rsi + rcx] ; put a byte from input buffer into al
	mov		rbx, rax		; duplicate the byte in bl for second nybble

	; look up low nybble character and insert it into the string:
	and		al, 0x0f		; mask out all but low nybble
	mov		al, byte [Digits + rax]		; look up the char equivalent of nybble
	mov		byte [HexStr + rdx + 2], al ; write lsb char digit to line string

	; look up high nybble character and insert it into the string:
	shr		bl, 0x4			; shift high 4 bit of char into low 4 bits
	mov		bl, byte [Digits + rbx]		; look up the char equivalent of nybble
	mov		byte [HexStr + rdx + 1], bl	; write msb char digit to line string

	; bump buffer pointer to next character and see if we're done
	inc		rcx				; increment the line string pointer
	cmp		rcx, rbp		; compare to number of chars in the buffer
	jna		scan			; loop back if rcx <= number of chars in the buffer


write: ; write buffer to output
	mov		rdi, SYSOUT		; stdout file descriptor
	mov		rsi, HexStr		; place address of hex string
	mov		rdx, HexStrLen	; place length of hex string
	mov		rax, SYS_WRITE	; sys_write syscall
	syscall

	jmp		read			; loop back and load file buffer again

exit:
	; exit program
	mov		rdi, 0			; status
	mov		rax, SYS_EXIT	; syscall code
	syscall

;vi:ft=nasm
