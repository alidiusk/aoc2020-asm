bits 64

section .rodata
    ; syscall numbers
    NR_READ     equ 0
    NR_WRITE    equ 1
    NR_OPEN     equ 2
    NR_CLOSE    equ 3
    NR_LSEEK    equ 8
    NR_CREATE   equ 85
    NR_UNLINK   equ 87
    NR_EXIT     equ 60

    ; file creation and status flags
    O_CREAT     equ 00000100q
    O_APPEND    equ 00002000q

    ; access mode
    O_RDONLY    equ 000000q
    O_WRONLY    equ 000001q
    O_RDWR      equ 000002q

    ; default input_fds we can use
    STDIN       equ 000000q
    STDOUT      equ 000001q
    STDERR      equ 000002q

section .text
    global open_file
    global read_file
    global close_file

; opens a given file
; params:
;   rdi: filename string address
;   rsi: flags to use when opening file
; returns: file descriptor
open_file:
    mov rax, NR_OPEN
    syscall ; open file
    cmp rax, 0
    jl _open_error
    ret
_open_error:
    mov rax, -1
    ret

; reads from a given file
; params:
;   rdi: filename string address
; returns: -1 for failure
close_file:
    mov rax, NR_CLOSE
    syscall
    cmp rax, 0
    jl _close_error
    ret
_close_error:
    mov rax, -1
    ret

; reads from a file
; NOTE: does not check for buffer overflow
; params:
;   rdi: file desciptor
;   rsi: buffer to write to
;   rdx: length of buffer
; returns: number of bytes read or -1 for failure
read_file:
    mov rax, NR_READ
    syscall ; open file
    cmp rax, 0
    jl _read_error
    jz _read_exit
    add rsi, rax
    jmp read_file
_read_error:
    mov rax, -1
_read_exit:
    ret
