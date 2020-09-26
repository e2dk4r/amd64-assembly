%include "constants.asm"

;===============================================================================
; section containing initialized data
SECTION .data
    ErrMsg:     db      "err: string is too long", 0x0A
    ERRMSGLEN   equ     $ - ErrMsg

    ; maximum byte limit for env var entry string
    MAXENVLEN   equ     0x0ffff

    ; end of line character
    EOL         equ     0x0A
    
;===============================================================================
; section containing code
SECTION .text
GLOBAL _start

;===============================================================================
; MAIN PROGRAM
_start:
    ; prepare
    mov     rbp, rsp                    ; copy of stack pointer

    mov     rdx, [rbp]                  ; get argument count
    lea     rbx, [rbp + 16 + rdx * 8]   ; get EnvVar address pointer

    xor     r8,  r8                     ; enviromental variable counter
    ; calculate their address
ScanOne:
    xor     rax, rax                    ; zero terminated string search - reg: AL
    mov     rdi, [rbx + r8 * 8]         ; enviromental pointer

    ; validate there is variable
    cmp     rdi, 0                      ; is there more env vars?
    je      ExitS                       ; ... we're done
    
    ; calculate their length
    mov     rdx, rdi        ; copy address
    mov     rcx, MAXENVLEN  ; maximum number of byte search - decimal: 65535
    cld                     ; up memory search
    repne scasb             ; scan string
    jb      Error           ; if maximum number exceeded, fail

    ; change last null(0) char with EOL(\n)
    mov     byte [rdi - 1], EOL ; EOL char

    mov     rsi, rdx        ; get env var entry
    sub     rdi, rdx        ; get env var entry length
    mov     rdx, rdi        ; env var length

    ; show them to console
Show:
    mov     rdi, SYSOUT     ; file descriptor: sysout
    mov     rax, SYS_WRITE  ; SYS_WRITE kernel call
    syscall

    inc     r8      ; increment counter
    jmp     ScanOne ; look for more

Error:
    mov     rdx, ERRMSGLEN  ; error message length
    mov     rsi, ErrMsg     ; error message
    mov     rdi, SYSOUT     ; file descriptor: sysout
    mov     rax, SYS_WRITE  ; SYS_WRITE kernel call
    syscall

ExitF:
    mov     rdi, 1          ; failure status
    jmp     Exit
ExitS:
    mov     rdi, 0          ; successful status
Exit:
    mov     rax, SYS_EXIT   ; SYS_EXIT kernel call
    syscall
