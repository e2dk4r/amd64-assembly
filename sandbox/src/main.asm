;===============================================================================
; linux specific constants
%define SYSOUT      1
%define SYS_WRITE   1
%define SYS_EXIT    60

;===============================================================================
; section containing initialized data
SECTION .data
    ; message that will print out stdout
    msg:    db "First line", 0xa,   \
               "Second line", 0xa,  \
               "Third line", 0xa, 0x0,
    MSGLEN:  equ $-msg
    
;===============================================================================
; section containing code
SECTION .text
GLOBAL _start

;===============================================================================
; MAIN PROGRAM
_start:
    ; print message
    mov     rdi, SYSOUT     ; file descriptor 1: Standart Output
    mov     rsi, msg        ; put message address
    mov     rdx, MSGLEN     ; put message length 
    mov     rax, SYS_WRITE  ; syscall code
    syscall

    ; exit program
    mov     rdi, 0          ; status
    mov     rax, SYS_EXIT   ; syscall code
    syscall
