section .data
	msg:	db "First line", 0xa, \
			   "Second line", 0xa, \
			   "Third line", 0xa, 0x0,
	msgsz:	equ	$-msg

	SYSOUT:		equ 1
	SYS_WRITE:	equ 1
	SYS_EXIT:	equ 60
	
section .text
	global _start

_start:
	; print string
	mov		rdi, SYSOUT		; file discriptor
	mov		rsi, msg		; msg address
	mov		rdx, msgsz		; msg length
	mov		rax, SYS_WRITE	; syscall code
	syscall

	; exit program
	mov		rdi, 0			; status
	mov		rax, SYS_EXIT	; syscall code
	syscall

;vi:ft=nasm
