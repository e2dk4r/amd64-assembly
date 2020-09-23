; name:         showcchar
; created:      Mon 13 Jul 2020 04:44:47 PM +03
; author:       e2dk4r
; description:  clears the screen, displays a ruler on line 1, and below that
;               shows a table containing 224 of the 256 ASCII characters, 
;               neatly displayed in seven lines of 32 characters each. The 
;               table includes the "high" 127 ASCII characters, including 
;               foreign-language characters, line-draw characters, and 
;               miscellaneous symbols. What it does not display are very first
;               32 ASCII characters. Linux treats these as control characters,
;               an not even those characters for which glyphs are available are
;               not displayed to the console
; notes:        see console_codes(4)

; linux specific constants
%include "constants.asm"

;===============================================================================
; section containing initialized data
SECTION .data
    EOL         equ 0x0A ; linux end-of-line character    
    FILLCHR     equ 0x20 ; ASCII space character
    HBARCHR     equ 0x2D ; use dash char if this won't display
    STRTROW     equ 0x02 ; row where the graph begins

    ; the dataset is just a table of byte-length numbers
    DataSet     db  9, 71, 17, 52, 55, 18, 29, 36, 18, 68, 77, 63, 58, 44, 0

    Message     db  "Data current as of 2020-02-24" ; message
    MSGLEN      equ $ - Message                     ; message length

    ; this escape sequence will clear the console terminal and place the text
    ; cursor to origin (1, 1) on virtualy all Linux console
    ClrHome     db  0x1B, "[2J"      ; clear screen
                db  0x1B, "[01;01H"  ; move cursor to origin 1, 1
    CLRLEN      equ $ - ClrHome     ; length of term clear string

    ; this is ruler
    RulerSet    db "0123456789"
    RLRLEN      equ $ - RulerSet

;===============================================================================
; section containing uninitialized data
SECTION .bss
    COLS        equ     81          ; line length + 1 char for EOL
    ROWS        equ     25          ; number of lines in display
    VidBuff     resb    COLS * ROWS ; buffer size adapts to ROWS & COLS
    
;===============================================================================
; section containing code
SECTION .text
GLOBAL _start

;*******************************************************************************
; ClearTerminal:    clear the terminal
; IN:               none
; RET:              none
; MOD:              none
; CALLS:            - kernel sys_write
; DESC:             clear Linux console terminal and set cursor to origin 1, 1
;                   using predefined escape sequence
ClearTerminal:
    push    rax ; store used registers
    push    rdi
    push    rsi
    push    rdx
    push    rcx ; kernel sys_write uses
    push    r11 ; kernel sys_write uses

    mov     rdi, STDOUT     ; specify file descriptor 1: Standart Output
    mov     rsi, ClrHome    ; pass address of escape sequence
    mov     rdx, CLRLEN     ; pass length of escape sequence
    mov     rax, SYS_WRITE  ; specify kernel sys_write code
    syscall                 ; call kernel code
    
    pop    r11  ; restore used registers
    pop    rcx
    pop    rdx
    pop    rsi
    pop    rdi
    pop    rax
    ret

;*******************************************************************************
; Show:         display a text buffer to linux console
; UPDATED:      2020-02-24
; INPUT:        none
; RETURN:       none
; MODIFIES:     none
; CALLS:        - kernel sys_write
; DESCRIPTION:  sends the buffer VidBuffer to the linux console via sys_write.
;               the number of bytes sent to the console is calculated by
;               multiplying COLS equate by the ROWS equate
Show:
    push    rax ; store used registers
    push    rdi
    push    rsi
    push    rdx
    push    rcx ; kernel sys_write uses
    push    r11 ; kernel sys_write uses

    mov     rdi, STDOUT     ; specify file descriptor 1: Standart Output
    mov     rsi, VidBuff    ; pass address of buffer
    mov     rdx, COLS*ROWS  ; pass length of buffer
    mov     rax, SYS_WRITE  ; specify kernel sys_write code
    syscall                 ; call kernel code

    pop    r11  ; restore used registers
    pop    rcx
    pop    rdx
    pop    rsi
    pop    rdi
    pop    rax
    ret         ; return to caller


;*******************************************************************************
; ClrVid:       clears a text buffer to spaces and replaces all EOLs
; UPDATED:      2020-02-24
; INPUT:        none
; RETURN:       none
; MODIFIES:     - VidBuff
;               - Flag: DF
; CALLS:        none
; DESCRIPTION:  fills the buffer VidBuff with a predefined character (FILLCHR)
;               and then places an EOL character at the end of every line,
;               where a line ends every COLS bytes in VidBuff
; NOTE:         
ClrVid:
    push    rax ; store used registers
    push    rdi
    push    rdx

    ; fill buffer with predefined character
    cld                         ; clear direction flag (DF) for up-memory write
    mov     al,  FILLCHR        ; put the buffer filler char in AL
    mov     rdi, VidBuff        ; point destination index at buffer
    mov     rcx, COLS * ROWS    ; put count of chars stored into RCX
    rep     stosb               ; blast chars at buffer

    ; buffer is cleared. reinsert EOL char after each line
    mov     rdi, VidBuff    ; point destination at buffer
    dec     rdi             ; start EOL position count at VidBuff char 0
    mov     rcx, ROWS       ; put number of rows in count register
.putEOL:
    add     rdi, COLS       ; add column count to destination index
    mov     byte [rdi], EOL ; store EOL char at the end of row
    loop    .putEOL

    pop    rdx  ; restore used registers
    pop    rdi
    pop    rax
    ret         ; return to caller

;*******************************************************************************
; WrtLn:        write a string to a text buffer at 1-based XY position
; UPDATED:      2020-02-25
; INPUT:        - RSI: address of the string
;               - RCX: length of the string
;               - RBX: x position (row #)
;               - RAX: y position (column #)
; RETURN:       none
; MODIFIES:     - VidBuff
;               - RDI
;               - Flag: DF
; CALLS:        none
; DESCRIPTION:  uses REP MOVSB to copy a string from the address in RSI
;               to an XY location in the text buffer VidBuff
WrtLn:
    push    rax ; store used registers
    push    rbx
    push    rcx
    push    rdi
    
    cld                     ; clear direction flag (DF)
    mov     rdi, VidBuff    ; put buffer address to destination index
    dec     rax             ; y-- for address calculation
    dec     rbx             ; x-- for address calculation
    mov     ah,  COLS       ; move screen width to AH
    mul     ah              ; do 8-bit multiply AL*AH to AX
    add     rdi, rax        ; add y offset into VidBuff to RDI
    add     rdi, rbx        ; add x offset into VidBuff to RDI
    rep     movsb           ; blast the string into buffer


    pop     rdi ; restore used registers
    pop     rcx
    pop     rbx
    pop     rax
    ret         ; return to caller

;*******************************************************************************
; WriteHB:      generate a horizontal line bar XY in text buffer
; UPDATED:      2020-02-25
; INPUT:        - RBX: x position (row #)
;               - RAX: y position (column #)
;               - RCX: length of the bar in chars
; RETURN:       none
; MODIFIES:     - VidBuff
;               - Flag: DF
; CALLS:        none
; DESCRIPTION:  writes a horizontal bar to the video buffer VidBuff, at the
;               1-based X,Y values passed in RBX,RAX. The bar is "made-of" the
;               character in the equate HBARCHR. The default is character 196;
;               if your terminal won't display that (you need the IBM 850 char
;               set) change the value in HBARCHR to ASCII dash or something 
;               else supported in your terminal
WriteHB:
    push    rax ; store used registers
    push    rbx
    push    rcx
    push    rsi
    push    rdi
    
    cld                     ; clear direction flag (DF) for up-memory write
    mov     rdi, VidBuff    ; put buffer address to destination index
    dec     rax             ; y-- for address calculation
    dec     rbx             ; x-- for address calculation
    mov     ah,  COLS       ; put screen width to AH
    mul     ah              ; do 8-bit multiply AL(operand)*AH to AX
    add     rdi, rax        ; add Y offset into VidBuff to RDI
    add     rdi, rbx        ; add X offset into VidBuff to RDI
    mov     al,  HBARCHR    ; put the char to use for the bar in AL
    rep     movsb           ; blast the string into the buffer
    
    pop     rdi ; restore used registers
    pop     rsi
    pop     rcx
    pop     rbx
    pop     rax
    ret         ; return to caller

;*******************************************************************************
; Ruler:        generates a "1234567890"-style ruler at XY in text buffer
; UPDATED:      2020-02-26
; INPUT:        - RBX: x position (row #)
;               - RAX: y position (column #)
;               - RCX: length of the ruler in chars
; RETURN:       none
; MODIFIES:     VidBuff
; CALLS:        none
; DESCRIPTION:  Writes a ruler to the video buffer VidBuff, at the 1-based XY
;               position passed in RBX,RAX. The ruler consists of a repeating
;               sequence of the digits 1 through 0. The ruler will wrap to
;               subsequent lines and overwrite whatever EOL characters fall
;               within its length, if it will not fit entirely on the line 
;               where it begins. Note that the Show procedure must be called
;               after Ruler to display the ruler on the console.
Ruler:
    push    rax ; store used registers
    push    rbx
    push    rcx
    push    rdi
    
    mov     rdi, VidBuff    ; put buffer address to destination index
    dec     rax             ; y-- for address calculation
    dec     rbx             ; x-- for address calculation
    mov     ah,  COLS       ; put screen width to AH
    mul     ah              ; do 8-bit multiply AL(operand)*AH to AX
    add     rdi, rax        ; add Y offset into VidBuff to RDI
    add     rdi, rbx        ; add X offset into VidBuff to RDI

;    ; RDI now contains the memory address in the buffer where the ruler is to
;    ; begin. Now we display the ruler, starting at that position
;    mov     al,  '1'    ; start the ruler with digit '1'
;.doChar:
;    stosb           ; write digit
;    add     al, '1' ; bump the character value in AL by '1'
;    ;aaa             ; adjust AX to make this a BCD addition
;    add     al, '0' ; make sure we have binary 3 in AL's high nyblle
;    loop    .doChar ; do another char until RCX goes to 0

    ; write ruler to buffer
.doChar:
    mov     al,  byte [RulerSet + rbx]   ; put address of ruler char digit
    stosb                           ; write digit
    inc     rbx                     ; increase ruler char index
    cmp     rbx, RLRLEN             ; look if we are at last char digit
    jnz     .continue               ; continue increasing ruler char index
    mov     rbx, 0                  ; clear ruler char index
.continue:
    loop    .doChar                 ; continue to write digits until RCX goes to 0
    
    pop     rdi ; restore used registers
    pop     rcx
    pop     rbx
    pop     rax
    ret         ; return to caller

;===============================================================================
; MAIN PROGRAM

SECTION .data
    CHRTROW equ 2 ; chart begins 2 lines from top of the display
    CHRTLEN equ 32 ; each chart line show 32 characters

SECTION .text
_start:
    ; get the console and text display buffer ready to go
    call    ClearTerminal
    call    ClrVid
    
    ; show a 64-character ruler above the table display
    mov     rax, 1      ; start ruler at display position 1, 1
    mov     rbx, 1
    mov     rcx, 32     ; make ruler 32 characters wide
    call    Ruler

    ; generate the chart itself
    mov     rdi, VidBuff        ; set buffer address to RDI
    add     rdi, COLS * CHRTROW ; begin table display down CHRTROW lines
    mov     rcx, 224            ; show 256 chars minus first 32
    mov     al,  32             ; written char - start from char #32
.DoLn: mov  bl,  CHRTLEN        ; line counter - each line will consist of 32 chars
.DoChr: stosb                   ; write the char to buffer
    jrcxz   AllDone             ; when full set printed, quit
    inc     al                  ; bump the character value in AL up by 1
    dec     bl                  ; decrement the line counter by 1
    loopnz  .DoChr              ; do chars until BL goes to 0
    add     rdi, (COLS - CHRTLEN) ; move RDI to start of the next line
    jmp     .DoLn               ; start display of the next line

    ; send buffer to console
AllDone:
    call    Show

Exit:
    ; exit the program
    mov     rdi, 0          ; status code
    mov     rax, SYS_EXIT   ; kernel sys_exit
    syscall
