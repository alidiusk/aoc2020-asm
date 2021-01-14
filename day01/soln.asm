bits 64

; INCLUDES
; ----------------------------------------------------------

extern atoi
extern printf

%include "io.asm"

; DATA
; ----------------------------------------------------------

section .rodata
    ; newline character
    NL          equ 0xa

section .data
    part01_found_nums_string db "Found nums: %d and %d", NL, 0
    part02_found_nums_string db "Found nums: %d and %d and %d", NL, 0
    product_string           db "Product: %d", NL, 0
    inputfile                db  'input.txt', 0
    outputfile               db  'output.txt', 0
    input_fd                 dq  0
    output_fd                dq  0
    open_error_string        db  "Failed to open file, %s", NL, 0
    close_error_string       db  "Failed to close file, %s", NL, 0
    read_error_string        db  "Failed to read from file, %s", NL, 0
    bufferlen                equ 8192
    intbuflen                equ 200
    numbuflen                equ 50
    intbufidx                dd 0

section .bss
    buffer      resb bufferlen
    intbuffer   resd intbuflen
    numbuffer   resb numbuflen

section .text
    global main

; CODE
; ----------------------------------------------------------

main:
    push rbp
    mov rbp, rsp

; SETUP
; ----------------------------------------------------------

; open the input file
    mov rdi, inputfile
    mov rsi, O_RDONLY
    call open_file ; rax now has fd
; check if error
    cmp rax, 0
    jl _open_err_exit

; save the file descriptor
    mov qword [input_fd], rax

; open output file (for debugging
    mov rdi, outputfile
    mov rsi, O_WRONLY
    add rsi, O_CREAT
    call open_file
    cmp rax, 0
    jl _open_err_exit

; save the file descriptor
    mov qword [output_fd], rax

; read from the file
; NOTE: we are trying to read _all_ of the contents
; if we do not get all of the contents into bufferlen,
; we will fail.
    mov rdi, [input_fd]               ; load the file descriptor
    lea rsi, qword [buffer]     ; load the buffer
    mov rdx, bufferlen          ; set the buffer length
    call read_file
; check if error
    cmp rax, 0
    jl _read_err_exit

; add a zero to the end
    mov byte [rsi+rax], 0

; GETTING THE NUMBERS
; ----------------------------------------------------------

; extract the numbers from the buffer
    xor rax, rax                ; clear rax
    xor rcx, rcx                ; clear rbx
    xor r12, r12                ; clear r12

    lea rbx, qword [buffer]     ; load buffer address
get_num_start:
    mov al, byte [rbx]          ; move the current byte into rax
    inc rbx                     ; increment pointer after getting the current byte
    cmp al, NL                  ; check if it is a newline
    je end_of_num
    cmp al, 0                   ; check if it is nullbyte (we are done)
    je end_loop

    mov [numbuffer+rcx], al     ; copy the byte into number

    inc rcx                     ; increment current byte in this number
    jmp get_num_start           ; loop
end_loop:
    mov r12, 1                  ; flag that we are done now
end_of_num:
    lea rdi, [numbuffer]
    call atoi                   ; rax now holds corresponding number
    mov rcx, [intbufidx]        ; mov intbufindex into rcx
    mov [intbuffer+4*rcx], dword eax  ; copy dword into intbuffer at correct index
    inc rcx                     ; increment the index
    mov [intbufidx], dword ecx  ; copy new index in
    lea rdi, [numbuffer]        ; load numbuffer address into rdi
    mov rax, 0                  ; mov 0 into rax
    mov rcx, numbuflen          ; mov numbuflen into rcx
    rep stosb                   ; zero out numbuffer
    xor rcx, rcx
    cmp r12, 1                  ; check if we reached EOF
    jne get_num_start           ; loop

; write buffer to output file
    mov rax, NR_WRITE
    mov rdi, [output_fd]
    lea rsi, [intbuffer]
    mov rdx, 4*200
    syscall

; PART 01
; ----------------------------------------------------------

; clear rax for next part
    xor rax, rax

; we now have an array of the numbers
; lets just brute force find one pair that sums to 2020
    lea r12, [intbuffer]        ; first number
    lea r13, [intbuffer+4]      ; second number
part01_sum_start:
    mov eax, dword [r12d]       ; check if number sum to 2020
    add eax, dword [r13d]
    cmp eax, 2020
    je part01_found_nums
    mov rax, r13                ; check if outer loop iteration is done
    sub rax, r12
    mov rbx, r12
    sub rbx, intbuffer-800
    cmp rax, rbx
    je part01_next_iter
    add r13, 4                  ; get next number and loop
    jmp part01_sum_start
part01_next_iter:
    add r12, 4                  ; get next number
    lea r13, [r12 + 4]          ; set second number
    jmp part01_sum_start        ; loop
part01_found_nums:
; print the two numbers
    lea rdi, [part01_found_nums_string]
    mov rsi, [r12]
    mov rdx, [r13]
    xor rax, rax
    call printf

    xor rax, rax

; print product
    lea rdi, [product_string]
    mov eax, dword [r12d]
    imul dword [r13d]
    mov rsi, rax
    call printf

; PART 02
; ----------------------------------------------------------

; clear rax for next part
    xor rax, rax

; we now have an array of the numbers
; lets just brute force find one pair that sums to 2020
    lea r12, [intbuffer]        ; first number
    lea r13, [intbuffer+4]      ; second number
    lea r14, [intbuffer+8]      ; third number
part02_sum_start:
    mov eax, dword [r12d]       ; check if number sum to 2020
    add eax, dword [r13d]
    add eax, dword [r14d]
    cmp eax, 2020
    je part02_found_nums
    mov rax, r14                ; check if middle loop iteration is done
    sub rax, r13
    mov rbx, r13
    sub rbx, intbuffer-800
    cmp rax, rbx
    je part02_inner_iter
    mov rax, r13                ; check if outer loop iteration is done
    sub rax, r12
    mov rbx, r12
    sub rbx, intbuffer-800
    cmp rax, rbx
    je part02_outer_iter
    add r14, 4                  ; get next number and loop
    jmp part02_sum_start
part02_inner_iter:
    add r13, 4                  ; get next number
    lea r14, [r13 + 4]          ; set second number
    jmp part02_sum_start        ; loop
part02_outer_iter:
    add r12, 4                  ; get next number
    lea r13, [r12 + 4]          ; set second number
    lea r14, [r12 + 8]          ; set third number
    jmp part02_sum_start        ; loop
part02_found_nums:
; print the two numbers
    lea rdi, [part02_found_nums_string]
    mov rsi, [r12]
    mov rdx, [r13]
    mov rcx, [r14]
    xor rax, rax
    call printf
; we are done

    xor rax, rax

; print product
    lea rdi, [product_string]
    mov eax, dword [r12d]
    imul dword [r13d]
    imul dword [r14d]
    mov rsi, rax
    call printf

; CLEANUP
; ----------------------------------------------------------

; close the input file
    mov rdi, qword [input_fd]
    call close_file
; check if error
    cmp rax, 0
    jl _close_err_exit
; close the output file
    mov rdi, qword [output_fd]
    call close_file
; check if error
    cmp rax, 0
    jl _close_err_exit

    mov rsp, rbp
    pop rbp
    ret

; ERROR HANDLING
; ----------------------------------------------------------

; we could not open file, print problem and exit with failure
_open_err_exit:
    ; print error message
    mov rdi, open_error_string
    mov rsi, inputfile
    mov rax, 0 ; no xmm involved
    call printf
    ; exit
    mov rax, NR_EXIT
    mov rdi, -1 ; there was an error
    syscall

; we could not read from file, print problem and exit with failure
_close_err_exit:
    ; print error message
    mov rdi, close_error_string
    mov rsi, inputfile
    mov rax, 0 ; no xmm involved
    call printf
    ; exit
    mov rax, NR_EXIT
    mov rdi, -1 ; there was an error
    syscall

; we could not read from file, print problem and exit with failure
_read_err_exit:
    ; print error message
    mov rdi, read_error_string
    mov rsi, inputfile
    mov rax, 0 ; no xmm involved
    call printf
    ; exit
    mov rax, NR_EXIT
    mov rdi, -1 ; there was an error
    syscall
