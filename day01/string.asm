bits 64

section .text
    global atoi

; Interprets a string and returns its content as an integral number.
; NOTE: the string must contain only integer digits.
; NOTE: this assumes *little endian* format
;
; Parameters:
;   * `rdi` : pointer to the string
;
; Returns:
;   * `rax` : 4 byte integer
atoi:
section .text
    push rbp
    mov rbp, rsp

    xor rax, rax                ; clear rax
    xor rdx, rdx                ; clear rdx
    xor rcx, rcx                ; clear rcx
    mov rsi, 0xa                ; set to ten for multiplying below

next_byte:
    mov dl, byte [rdi]          ; get next byte
    cmp dl, 0                   ; if it is a nullbyte, the string has ended, we are done
    je exit
    sub dl, 0x30                ; convert from ascii
    mov eax, ecx                ; copy number to rax for multiply
    imul eax, esi               ; multiply existing number by 10
    adc al, dl                  ; add with carry
    mov ecx, eax                ; copy number back to rcx
    inc rdi                     ; increment pointer
    jmp next_byte
exit:
    mov eax, ecx

    leave
    ret
