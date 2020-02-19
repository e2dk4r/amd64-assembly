%include "macros.asm" ; enviromental variables in linux

SECTION .bss ; Section containing uninitialized data
	BUFFLEN equ 10
	Buff	resb BUFFLEN

SECTION .data ; Section containing initialized data
; text line of hex dump utilty
; first part displays 16 bytes in hex seperated by spaces
; second part displays 16-character line
; Note: if DumpLin is used seperatedly, append EOL
DumpLin:	db " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
DUMPLEN		equ $-DumpLin
ASCLin:		db "|................|", 0xa
ASCLEN		equ	$-ASCLin
FULLLEN		equ $-DumpLin

; HexDigits is used to convert numeric values to their hex
; equivalents. Index by nybble without a scale: [HexDigits + eax]
HexDigits:	db "0123456789ABCDEF"

; This table is used for ASCII character translation, into the ASCII
; portion of the hex dump line, via XLAT or ordinary memory lookup. 
; All printable characters "play through" as themselves. The high 128 
; characters are translated to ASCII period (2Eh). The non-printable
; characters in the low 128 are also translated to ASCII period, as is
; char 127.
DotXlat: 
	db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
	db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
	db 20h,21h,22h,23h,24h,25h,26h,27h,28h,29h,2Ah,2Bh,2Ch,2Dh,2Eh,2Fh
	db 30h,31h,32h,33h,34h,35h,36h,37h,38h,39h,3Ah,3Bh,3Ch,3Dh,3Eh,3Fh
	db 40h,41h,42h,43h,44h,45h,46h,47h,48h,49h,4Ah,4Bh,4Ch,4Dh,4Eh,4Fh
	db 50h,51h,52h,53h,54h,55h,56h,57h,58h,59h,5Ah,5Bh,5Ch,5Dh,5Eh,5Fh
	db 60h,61h,62h,63h,64h,65h,66h,67h,68h,69h,6Ah,6Bh,6Ch,6Dh,6Eh,6Fh
	db 70h,71h,72h,73h,74h,75h,76h,77h,78h,79h,7Ah,7Bh,7Ch,7Dh,7Eh,2Eh
	db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
	db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
	db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
	db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
	db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
	db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
	db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
	db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh

SECTION .text ; Section containing code
GLOBAL _start

;===============================================================================
; ClearLine:	clear hex dump line	string to 16 0 values
; INPUT:		<none>
; RETURN:		<none>
; MODIFIES:		<none>
; CALLS:		DumpChar
; DESCRIPTION:	The hex dump line string is cleared to binary 0 by
;				call DumpChar 16 times, passing it 0 each time

ClearLine:
	push	rax			; store used registers
	push 	rdx

	mov		rdx, 15		; we are going through 16 pokes, counting from 0
.poke:
	mov		rax, 0		; tell `DumpChar` to poke a '0'
	call	DumpChar	; insert '0' into hex dump string
	sub		rdx, 1		; NOTE: DEC doesn't affect CF
	jae		.poke		; loop back if RDX >= 0

	pop		rdx			; restore used registers
	pop		rax
	ret					; return to caller

;===============================================================================
; DumpChar:	"Poke" a value into hex dump line string
; INPUT:		RAX: pass the 8-bit value to be poked in RAX
;				RDX: pass the value's position in the line (0-15) in RDX
; RETURN:		<none>
; MODIFIES:		RAX, ASCLin, DumpLin
; CALLS:		<none>
; DESCRIPTION:	The value passed in RAX will be put in both the hex dump
;				portion and in the ASCII portion, at the position passed
;				in RDX, represented by a space where it is not a
;				printable character

DumpChar:
	push	rbx			; save caller's RBX
	push	rdi			; save caller's RDI

	; first we insert the input char into ASCII portion of the dump line
	mov		bl,	byte [DotXlat + rax]	; translate nonprintables to '.'
	mov		byte [ASCLin + rdx + 1], bl ; write to ASCII portion

	; next we insert the hex equvilant of the input char in the hex portion
	; of the hex dump line
	mov		rbx, rax			 ; save second copy of the input char
	lea		rdi, [rdx * 2 + rdx] ; calculate offset into line string (RDX * 3)

	; look up low nyblle character and insert it into the string
	and		rax, 0x0f					 ; mask out all but the low nybble
	mov		al,	byte [HexDigits + rax]   ; look up the char equvialent of nyblle
	mov		byte [DumpLin + rdi + 2], al ; write the char equvialent to line string

	; look up high nyblle character and insert it into the string
	and		rbx, 0xf0					 ; mask out all but second lowest nyblle
	shr		rbx, 0x4					 ; shift high 4 bits of byte into low 4 bits
	mov		bl, byte [HexDigits + rbx]	 ; look up char equivalent of nyblle
	mov		byte [DumpLin + rdi + 1], bl ; write the char equivalent to line string

	pop		rdi			; restore caller's RDI
	pop		rbx			; restore caller's RBX
	ret					; return to caller

;===============================================================================
; PrintLine:	display DumpLin to stdout
; INPUT:		<none>
; RETURN:		<none>
; MODIFIES:		<none>
; CALLS:		Kernel sys_write
; DESCRIPTION:	The hex dump line string DumpLin is displayed to stdout
;				using syscall. 
; NOTE:			sys_write uses RAX, RCX, R11 registers
PrintLine:
	push rax	; store used registers
	push rdi
	push rsi
	push rdx
	push rcx
	push r11

	mov		rdi, SYSOUT		; specify file descriptor 1: standard output
	mov		rsi, DumpLin	; pass offset of line string
	mov		rdx, FULLLEN	; pass size of line string
	mov		rax, SYS_WRITE	; specify sys_write call
	syscall

	pop r11		; restore used registers 
	pop rcx		
	pop rdx		
	pop rsi
	pop rdi
	pop rax
	ret			; return to caller


;===============================================================================
; LoadBuff:	fills a buffer with data from stdin via syscall sys_read
; INPUT:		<none>
; RETURN:		number of bytes in RBP
; MODIFIES:		RCX, RBP, Buff
; CALLS:		Kernel sys_read
; DESCRIPTION:	Loads a buffer full of data (BUFFLEN bytes) from stdin
;				using syscall sys_read and places it in Buff. Buffer
;				offset counter RCX is zeroed, because we're starting in
;				on a new buffer full of data. Caller must test value in
;				RBP: if RBP contains zero on return, we hit EOF on stdin,
;				less than 0 in RBP on return indicates some kind of error
; NOTE:			sys_read uses RAX, RCX
LoadBuff:
	push	rax	; save used registers
	push	rdi
	push	rsi
	push	rdx

	mov		rdi, SYSIN		; specify file descriptor 0: Standart Input
	mov		rsi, Buff		; pass offset of the buffer to read to
	mov		rdx, BUFFLEN	; pass number of bytes to read at one pass
	mov		rax, SYS_READ	; specify sys_read call
	syscall

	mov		rbp, rax	; save number of bytes read from file for later
	xor		rcx, rcx	; clear buffer pointer RCX to 0

	pop		rdx ; restore used registers
	pop		rsi
	pop		rdi
	pop		rax 
	ret			; return to caller

;===============================================================================
; MAIN PROGRAM
_start:
	; initialization before scan
	xor		rsi, rsi	; clear total byte counter to 0
	call	LoadBuff	; read first buffer of data from stdin
	cmp		rbp, 0		; if rbp=0, sys_read reached EOF on stdin
	jbe		Exit

; go through the buffer and convert binary byte values to hex digits:
Scan:
	xor		rax, rax			  ; clear rax to 0
	mov		al, byte [Buff + rcx] ; get a byte from the buffer into AL
	mov		rdx, rsi			  ; copy total counter into RDX
	and		rdx, 0x0f			  ; mask out lowest 4 bits of char counter
	call	DumpChar			  ; call the char poke procedure

	; bump the buffer pointer to the next character and see if buffer's done
	inc		rsi			; increment total chars processed counter
	inc		rcx			; increment buffer pointer
	cmp		rcx, rbp	; compare with # of chars in buffer
	jb		.modTest	; if we've processed all chars in buffer...
	call	LoadBuff	; ... go fill the buffer again
	cmp		rbp, 0		; if rbp=0, sys_read reached EOF on stdin
	jbe		Done		; if we got EOF, we're done

; see if we're at the end of a block of 16 and need to display a line 
.modTest:
	test	rsi, 0x0f	; test 4 lowest bits in counter for 0
	jnz		Scan		; if counter is *not* modulo 16, loop back
	call	PrintLine	; ..otherwise print the line
	call	ClearLine	; clear hex dump line to 0's
	jmp		Scan		; continue scanning the buffer

; all done! end this
Done:
	call	PrintLine	; print the "leftovers" line

Exit:
	mov		rdi, 0			; 0 status code
	mov		rax, SYS_EXIT	; sys_exit system call
	syscall
