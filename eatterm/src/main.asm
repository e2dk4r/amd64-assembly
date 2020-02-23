; Author:       e2dk4r
; Created:      2020-02-22
; Description:  using nasm,
;               for linux 64,
;               demonstrating the use of escape sequences to do simple
;               "full-screen" text output
; Notes:        see console_codes(4)

; include linux specific constants
%include "constants.asm"

;===============================================================================
; section containing initialized data
SECTION .data

    ; screen width: by default assume 80 chars wide
    SCRWIDTH:   equ 80

    ; <ESC>[<Y>;<X>H
    PosTerm:    db  0x1b, "[01;01H"
    ; length of term position string
    POSLEN:     equ $ - PosTerm

    ; <ESC>[2J
    ClrTerm:    db  0x1b, "[2J"
    ; length of term clear string
    CLRLEN:     equ $ - ClrTerm

    ; ad message
    AdMsg:      db 0x1b, "[1;31m"   ; set bold attribute (1) and red foreground (31)
                db "Eat At Joe's"
                db 0x1b, "[0m"      ; reset attributes
    ; length of ad message
    ADLEN:      equ $ - AdMsg

    ; user prompt
    Prompt:     db "Press enter: "
    ; length of user prompt
    PROMPTLEN:  equ $ - Prompt

; This table gives us pairs of ASCII digits from 0-80. Rather than 
; calculate ASCII digits to insert in the terminal control string, 
; we look them up in the table and read back two digits at once to 
; a 16-bit register like DX, which we then poke into the terminal 
; control string PosTerm at the appropriate place. See GotoXY.
; If you intend to work on a larger console than 80 X 80, you must
; add additional ASCII digit encoding to the end of Digits. Keep in
; mind that the code shown here will only work up to 99 X 99.
    Digits: db "0001020304050607080910111213141516171819"
            db "2021222324252627282930313233343536373839"
            db "4041424344454647484950515253545556575859"
            db "606162636465666768697071727374757677787980"
    
;===============================================================================
; section containing code
SECTION .text
GLOBAL _start

;===============================================================================
; ClearScreen:  Clear the linux console
; UPDATED:      2020-02-22
; INPUT:        none
; RETURN:       none
; MODIFIES:     none
; CALLS:        WriteString
; DESCRIPTION:  Sends the predefined control string <ESC>[2J to the console,
;               which clears the full display
ClearScreen:
    push    rsi ; store used registers
    push    rdx

    mov     rsi, ClrTerm    ; pass offset of terminal control string
    mov     rdx, CLRLEN     ; pass length of terminal control string
    call    WriteString     ; send control string to console

    pop     rdx ; restore used registers
    pop     rsi
    ret         ; return to caller

;===============================================================================
; GotoXY:       Position the linux console cursor to an X, Y position
; UPDATED:      2020-02-22
; INPUT:        AH: x position
;               AL: y position
; RETURN:       none
; MODIFIES:     PosTerm terminal control sequence string
; CALLS:        WriteString
; DESCRIPTION:  Prepares a terminal control string for X, Y coordinates
;               passed in AL and AH and calls sys_write to position the
;               console cursor to that X, Y position. Writing text to the
;               console after calling GotoXY will begin display of text
;               at that X, Y position.
GotoXY:
    ; store used registers
    push    rbx ; use as scale term
    push    rcx ; use as decimal digits
    push    rsi
    push    rdx

    xor     rbx, rbx ; clear scale term register
    xor     rcx, rcx ; clear decimal digits register

    ; poke the Y digits
    mov     bl, al                      ; put Y value into scale term RBX
    mov     cx, word [Digits + rbx * 2] ; fetch decimal digits to CX
    mov     word [PosTerm + 2], cx      ; poke digits into control string

    ; poke the X digits
    mov     bl, ah                      ; put X value into scale term RBX
    mov     cx, word [Digits + rbx * 2] ; fetch decimal digits to CX
    mov     word [PosTerm + 5], cx      ; poke digits into control string

    ; send control sequence to stdout
    mov     rsi, PosTerm    ; pass address of control string
    mov     rdx, POSLEN     ; pass length of control string
    call    WriteString     ; send control string to stdout

    ; finish up
    pop     rdx ; restore used registers
    pop     rsi
    pop     rcx
    pop     rbx
    ret         ; return to caller

;===============================================================================
; WriteCenter:  send a string centered to 80-char wide Linux console
; UPDATED:      2020-02-22
; INPUT:        - AL:     Y value
;               - RSI:    string address 
;               - RDX:    string length
; RETURN:       none
; MODIFIES:     PosTerm: terminal control sequence string
; CALLS:        - GotoXY
;               - WriteString
; DESCRIPTION:  displays a string to the Linux console centered in an 80-column
;               display. Calculates the X for passed-in string length, then
;               calls GotoXY and WriteString to send the string to the console
WriteCenter:
    ; save used registers
    push    rbx ; use as center offset of screen

    xor     rbx, rbx ; clear center offset

    ; calculate center offset of screen
    mov     bl, SCRWIDTH    ; load screen width value to BL
    sub     bl, dl          ; take differentiate of screen and string length
    shr     bl, 1           ; divide differentiate by 2 for X value

    ; center cursor
    mov     ah, bl  ; pass X value
    call    GotoXY  ; position the cursor for display

    ; write string to output
    call    WriteString ; write string to console

    pop     rbx ; restore used registers
    ret         ; return to caller

;===============================================================================
; WriteString:  write
; UPDATED:      2020-02-22
; INPUT:        RSI: address of string
;               RDX: length of string
; RETURN:       none
; MODIFIES:     none
; CALLS:        Kernel sys_write
; DESCRIPTION:  
; NOTES:        sys_write uses RAX, RCX, R11 registers
WriteString:
    push    rax ; store used registers
    push    rcx
    push    r11

    ; write string to stdout 
    mov     rdi, SYSOUT     ; specify file descriptor 0: Standart Output
    mov     rax, SYS_WRITE  ; specify sys_write kernel code
    syscall

    pop     r11 ; restore used registers
    pop     rcx
    pop     rax
    ret         ; return to caller

;===============================================================================
; MAIN PROGRAM
_start:
    ; clear terminal display
    call    ClearScreen

    ; post the ad message centered on 80-wide console
    mov     al, 12      ; specify line 12
    mov     rsi, AdMsg  ; place address of message
    mov     rdx, ADLEN  ; place length of message
    call    WriteCenter ; display it to the console

    ; position the cursor for "Press Enter" prompt
    mov     ax, 0x117   ; X, Y = 1, 23 as single hex value in AX
    call    GotoXY      ; position the cursor
    
    ; display "Press Enter" prompt
    mov     rsi, Prompt     ; pass address of prompt
    mov     rdx, PROMPTLEN  ; pass length of prompt
    call    WriteString     ; display it to the console

    ; wait for user to press Enter
    mov     rdi, SYSIN      ; specify file descriptor 1: Standart Input
    mov     rax, SYS_READ   ; sys_read syscall code
    mov		rdx, 1          ; read only one character
    syscall                 ; kernel call

    ; exit program
    mov     rdi, 0          ; status code 0: meaning ok
    mov     rax, SYS_EXIT   ; syscall code
    syscall
