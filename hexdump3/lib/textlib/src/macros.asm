; file descriptors
%define SYSIN 0
%define SYSOUT 1

; linux syscall codes from:
;   <kernel source>/arch/x86/entry/syscalls/syscall_64.tbl
%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_EXIT 60
