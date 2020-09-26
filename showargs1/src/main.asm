%include "constants.asm"

;===============================================================================
; section containing initialized data
SECTION .data
    ErrMsg db "Terminated with error", 0x0A, 0x00
    ERRLEN equ $-ErrMsg

;===============================================================================
; section containing uninitialized data
SECTION .bss

; This program handles up to MAXARGS command-line arguments. Change the 
; value of MAXARGS if you need to handle more arguments than the default 10.
; In essence we store pointers to the arguments in a 0-based array, with the
; first arg pointer at array element 0, the second at array element 1, etc.
; Ditto the arg lengths. Access the args and their lengths this way:
;       Arg strings:        [ArgPtrs + <index reg>*8]
;       Arg string lengths: [ArgLens + <index reg>*8]
; Note that when the argument lengths are calculated an EOL char (0x0A) is
; stored into each string where the terminating null was originally. This 
; makes it easy to print out an argument using sys_write. This is not
; essential, and if you prefer to retain the 0-termination in the arguments,
; you can comment out that line, keeping in mind that the arguments will not
; display correctly without EOL characters at their ends
    MAXARGS     equ 10          ; Maximum # of args we support
    ArgCount:   resd 1          ; # of arguments passed to program
    ArgPtrs:    resq MAXARGS    ; Table of pointers to arguments
    ArgLens:    resq MAXARGS    ; Table of argument lengths
    
;===============================================================================
; section containing code
SECTION .text
GLOBAL _start

;===============================================================================
; MAIN PROGRAM
_start:
    ; get the command line argument count off the stack and validate it
    pop     rcx                   ; TOS contains the argument count
    cmp     rcx, MAXARGS          ; see if the arg count exceeds MAXARGS
    ja      Error                 ; if so, exit with an error message
    mov     dword [ArgCount], ecx ; save arg count in memory variable

    ; once we know how many args we have, a loop will pop them into ArgPtrs:
    xor     rdx, rdx                    ; zero loop counter
SaveArgs:
    pop     qword [ArgPtrs + rdx * 8]   ; pop an arg addr into the memory table
    inc     rdx                         ; bump the counter to the next arg addr
    cmp     rdx, rcx                    ; is the counter = the argument count?
    jb      SaveArgs                    ; if not, loop back and do another

    ; with the argument pointers stored in ArgPtrs, we calculate their lengths:
    xor     rax, rax        ; searching for 0, so clear AL to 0
    xor     rbx, rbx        ; argument counter - pointer table offset starts at 0
ScanOne:
    mov     rcx, 0x0000ffff                 ; limit search to 65535 bytes max
    mov     rdi, qword [ArgPtrs + rbx * 8]  ; put address of string to search in RDI
    mov     rdx, rdi                        ; copy starting address into RDX
    cld                                     ; set search direction to up-memory
    repne scasb                             ; search for null(0 char) in string at RDI
    jnz     Error                           ; REPNE SCASB ended without finding AL
    mov     byte [rdi - 1], 0x0A            ; store an EOL where the null used to be
    sub     rdi, rdx                        ; subtract position of 0 from start address
    mov     qword [ArgLens + rbx * 8], rdi  ; put length of arg into table
    inc     rbx                             ; increment argument counter
    cmp     ebx, [ArgCount]                 ; see if arg counter exceeds argument counter
    jb      ScanOne                         ; if not, loop back and do another one

    ; display all arguments to stdout
    xor     r8, r8          ; start (for table addressing reasons) at 0
Showem:
    mov     rdx, [ArgLens + r8 * 8] ; argument length address
    mov     rsi, [ArgPtrs + r8 * 8] ; argument address
    mov     rdi, SYSOUT     ; file descriptor 1: Standart Output
    mov     rax, SYS_WRITE  ; syscall code
    syscall

    inc     r8              ; increment argument counter
    cmp     r8d, [ArgCount] ; see if we've displayed all the arguments
    jb      Showem          ; if not, loop back and do another

    jmp     ExitS           ; we're done

Error:
    mov     rdi, SYSOUT     ; file descriptor 1: Standart Output
    mov     rsi, ErrMsg     ; put error message address
    mov     rdx, ERRLEN     ; put error message length 
    mov     rax, SYS_WRITE  ; syscall code
    syscall

ExitF: 
    mov     rdi, 1          ; status code
    jmp     Exit
ExitS: 
    mov     rdi, 0          ; status code
Exit:
    mov     rax, SYS_EXIT   ; syscall code
    syscall
