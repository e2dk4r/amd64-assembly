; executable name   : toup
; version           : 1.0
; created date      : 2019-01-24
; modified date     : 2019-01-24 
; author            : e2dk4r
; description:
;   simple program that runs on Linux,
;   using nasm,
;   reading input file to buffer of blocks,
;   converting lowercase characters to uppercase
; usage:
;   toup > output_file < input_file

%define BUFSZ 1024

%define SYSIN 0
%define SYSOUT 1

%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_EXIT 60

section .bss
    Buff:		resd BUFSZ

section .text
global _start

_start:

read: ; get strings from standard input
	mov		rdi, SYSIN		; stdin file descriptor
	mov		rsi, Buff		; buffer address
	mov		rdx, BUFSZ		; buffer size	
	mov		rax, SYS_READ	; sys_read syscall
	syscall

	; test input validation
	cmp		rax, 0			; look sys_read syscall's return code
	je		exit			; exit if is it EOL

scan: ; uppercase lowercase characters in buffer
	mov		rcx, rax		; set counter to input length

.loop:
	cmp		byte [Buff + rcx - 1], 0x61 ; compare input char against lowercase 'a'
	jb		.next
	cmp		byte [Buff + rcx - 1], 0x7a ; compare input char against lowercase 'z'
	ja		.next

	sub		byte [Buff + rcx - 1], 0x20 ; from lowercase to uppercase

.next:
	loop	.loop

write: ; write buffer to output
	mov		rdi, SYSOUT		; stdout file descriptor
	mov		rdx, rax		; size of buffer
	mov		rax, SYS_WRITE	; sys_write syscall
	syscall

exit:
	; exit program
	mov		rdi, 0			; status
	mov		rax, SYS_EXIT	; syscall code
	syscall

;vi:ft=nasm
