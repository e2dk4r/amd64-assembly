%include "macros.asm" ; enviromental variables in linux

SECTION .bss ; Section containing uninitialized data
    BUFFLEN equ 10
    Buff    resb BUFFLEN

SECTION .data ; Section containing initialized data

SECTION .text

EXTERN ClearLine, DumpChar, PrintLine
GLOBAL _start

;===============================================================================
; MAIN PROGRAM
_start:
    xor     r8, r8 ; clear total byte counter to 0

; read a buffer full of text from stdin
Read:
    mov     rdi, SYSIN      ; specify file descriptor 0: Standart Input
    mov     rsi, Buff       ; put address of buffer
    mov     rdx, BUFFLEN    ; put number of bytes to read at one time
    mov     rax, SYS_READ   ; specify sys_read
    syscall

    mov     rbp, rax    ; save # of bytes read from file for later
    cmp     rax, 0      ; if rax=0, sys_read reached EOF on stdin
    je      Done        ; jump if equal (to 0, from compare)

; set up the registers for the process buffer step
    xor     rcx, rcx    ; clear buffer pointer

; go through the buffer and convert binary byte values to hex digits:
Scan:
    xor     rax, rax                ; clear rax to 0
    mov     al, byte [Buff + rcx]   ; get a byte from the buffer into AL
    mov     rdx, r8                 ; copy total counter into RDX
    and     rdx, 0x0f               ; mask out lowest 4 bits of char counter
    call    DumpChar                ; call the char poke procedure

    ; bump the buffer pointer to the next character and see if buffer's done
    inc     r8          ; increment total chars processed counter
    inc     rcx         ; increment buffer pointer
    cmp     rcx, rbp    ; compare with # of chars in buffer
    jae     Read        ; if we've done the buffer, go get more

    ; see if we're at the end of a block of 16 and need to display a line 
    test    r8, 0x0f    ; test 4 lowest bits in counter for 0
    jnz     Scan        ; if counter is *not* modulo 16, loop back
    call    PrintLine   ; ..otherwise print the line
    call    ClearLine   ; clear hex dump line to 0's
    jmp     Scan        ; continue scanning the buffer

; all done! end this
Done:
    call    PrintLine       ; print the "leftovers" line
    mov     rdi, 0          ; 0 status code
    mov     rax, SYS_EXIT   ; sys_exit system call
    syscall
