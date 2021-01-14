bits 64

section .rodata
    ; syscall numbers
    NR_READ        equ 0
    NR_WRITE       equ 1
    NR_OPEN        equ 2
    NR_CLOSE       equ 3

    ; file access modes
    O_RDONLY       equ 0
    O_WRONLY       equ 1
    O_RDWR         equ 2

    ; default file descriptors
    STDIN          equ 0
    STDOUT         equ 1
    STDERR         equ 2

section .data
    inputfilename   db "input.txt", 0
    foundpairstr    db "Found pair: %d * %d = %d", 10, 0
    foundtripletstr db "Found triplet: %d * %d * %d = %d", 10, 0
    inputfile       db 0
    inputbufferlen  equ 1024
    intarraylen     equ 200
    numberbuflen    equ 32

section .bss
    ; When we run the program, allocate inputbufferlen
    ; worth of bytes for inputbuffer
    inputbuffer    resb inputbufferlen
    ; Allocate intarraylen worth of dwords for
    ; our intarray. This allows us to store 200 integers
    intarray       resd intarraylen
    numberbuf      resb numberbuflen

section .text
    extern printf

    global main

main:
    push rbp
    mov rbp, rsp

    ; open the input file
    mov rax, NR_OPEN            ; set our syscall to 'open'
    lea rdi, [inputfilename]    ; load the address of the filename
    mov rsi, O_RDONLY           ; set read only
    syscall

    ; if the syscall succeeded, rax will be a positive number
    ; representing the file descriptor. if it failed, it will
    ; be a negative number indicating the error.
    cmp rax, 0                  ; compare rax to 0
    jl .exit                    ; if rax < 0, there was an error, so exit

    ; read the input file
    mov [inputfile], rax        ; move the file descriptor into the global variable
    mov rdi, [inputfile]        ; load the file descriptor into rdi
    mov rax, NR_READ            ; set our syscall to 'read'
    lea rsi, [inputbuffer]      ; load the address of our buffer into rsi
    mov rdx, inputbufferlen     ; load the length of our buffer into rdx
.read:
    syscall                     ; read from the file

    ; if the read succeeded, the number of bytes read will be put into rax
    ; if it failed, rax will hold a negative number
    ; we must check for the error and also continue reading until rax holds
    ; 0, indicating that there are no bytes to read
    cmp rax, 0
    jl .cleanup                 ; if rax < 0, there was an error, so exit
    je .read_done               ; if rax == 0, we are done, so stop reading
    ; calculate the next offset in the buffer to read into and adjust the
    ; buffer length accordingly
    add rsi, rax
    sub rdx, rax
    mov rax, NR_READ
    jmp .read

.read_done:
    ; Add a zero to the end of the input from the buffer
    ; to terminate the string
    inc rsi
    mov [rsi], byte 0
    ; calculate the length of the string we read
    mov rdx, rsi
    sub rdx, inputbuffer

    ; Clear rax, rcx, rdx for the integer parsing loop
    xor rax, rax
    xor rcx, rcx
    xor rbx, rbx

    ; Load the address of inputbuffer into rsi
    lea rsi, [inputbuffer]

.int_parse:
    mov al, byte [rsi]          ; Get the next byte
    inc rsi                     ; Increment our inputbuffer string index
    cmp al, 0xa                 ; Check if the byte is a newline; if so, we are done
    je .end_of_num              ; gathering the substring

    mov [numberbuf+rcx], al     ; Load the byte into numberbuf at the rcx-th index
    inc rcx                     ; Increase our numberbuf index
    jmp .int_parse              ; Loop to next byte

.end_of_num:
    lea rdi, [numberbuf]        ; Load the address of numberbuf into rdi
    call atoi                   ; Call the atoi function on our numberbuf string
    mov [intarray+rbx*4], eax   ; Move the parsed number into the array

    ; Zero out the bytes we used in numberbuf
    xor rax, rax                ; Clear rax to 0
    lea rdi, [numberbuf]        ; move the address of numberbuf into rdi
    repe stosb                  ; Zero out the first rcx bytes of numberbuf

    ; Prepare for next loop
    inc rbx                     ; Increment our intarray index
    xor rcx, rcx                ; Clear rcx for next loop
    cmp rbx, intarraylen        ; Check if we have parsed all of the numbers
    jl .int_parse               ; If we have not parsed all the numbers, loop

    ; For now, just write the intarry to stdout to verify this works
    ; mov rax, NR_WRITE
    ; mov rdi, STDOUT
    ; lea rsi, [intarray]
    ; mov rdx, intarraylen * 4
    ; syscall

    ; Our starting indices into intarray, held in r12 and r13
    mov r12, 0
    mov r13, 1
.find_pair:
    mov eax, [intarray+r12*4]   ; Move the first 4 byte number into eax
    add eax, [intarray+r13*4]   ; Add the second number to get the sum
    cmp eax, 2020               ; Check if their sum is 2020
    je .found_pair              ; If so, exit the loop
    inc r13                     ; Increment the inner loop variable
    cmp r13, intarraylen        ; Check if we just reached the last number
    jne .find_pair              ; If not, loop
    inc r12                     ; If so, increment the outer loop variable
    mov r13, r12                ; and set the inner loop variable to be one
    inc r13                     ; one more
    jmp .find_pair              ; Loop
.found_pair:
    ; Clear the following registers in case there is
    ; data in the top 32 bits that will change the
    ; numbers we will print
    xor rsi, rsi
    xor rdx, rdx
    xor rcx, rcx
    ; We have found the pair, so print them and their product out
    lea rdi, [foundpairstr]     ; Load the address of the string into rdi
    mov esi, [intarray+r12*4]   ; Load the first 4 byte number into esi
    mov edx, [intarray+r13*4]   ; Load the second 4 byte number into edx
    mov ecx, esi                ; Move the first number into ecx
    imul ecx, edx               ; Multiply by edx to get their product
    xor rax, rax                ; Clear rax (required by printf)
    call printf                 ; Call printf

    ; Our starting indices into intarray, held in r12, r13, and r14
    mov r12, 0
    mov r13, 1
    mov r14, 2
.find_triplet:
    mov eax, [intarray+r12*4]   ; Move the first 4 byte number into eax
    add eax, [intarray+r13*4]   ; Add the second number to the sum
    add eax, [intarray+r14*4]   ; Add the third number to the sum
    cmp eax, 2020               ; Check if their sum is 2020
    je .found_triplet           ; If so, exit the loop
    inc r14                     ; Increment the inner loop variable
    cmp r14, intarraylen        ; Check if we just reached the last number
    jne .find_triplet           ; If not, loop
    inc r13                     ; If so, increment the middle loop variable
    mov r14, r13                ; and set the inner loop variable to be
    inc r14                     ; one more
    cmp r13, intarraylen-1      ; Check if the middle loop reached the end
    jne .find_triplet           ; If not, loop
    inc r12                     ; If so, increment the outer loop variable
    mov r13, r12                ; and set the other two variables to be
    inc r13                     ; one and two more, respectively
    mov r14, r13
    inc r14
    jmp .find_triplet           ; Loop
.found_triplet:
    ; Clear the following registers in case there is
    ; data in the top 32 bits that will change the
    ; numbers we will print
    xor rsi, rsi
    xor rdx, rdx
    xor rcx, rcx
    xor r8, r8
    ; We have found the pair, so print them and their product out
    lea rdi, [foundtripletstr]     ; Load the address of the string into rdi
    mov esi, [intarray+r12*4]   ; Load the first 4 byte number into esi
    mov edx, [intarray+r13*4]   ; Load the second 4 byte number into edx
    mov ecx, [intarray+r14*4]   ; Load the third 4 byte number into ecx
    mov r8d, esi                ; Move the first number into ecx
    imul r8d, edx               ; Multiply by edx to get their product
    imul r8d, ecx               ; Multiply by ecx to get the total product
    xor rax, rax                ; Clear rax (required by printf)
    call printf                 ; Call printf

.cleanup:
    ; we must now close the input file descriptor if we opened it
    ; if it is not 0, then we have opened the file and must close it
    mov rdi, [inputfile]
    cmp rdi, 0                  ; check if we opened the file
    je .exit                    ; if inputfile == 0, we did not
    ; we opened the file, so must close it using the 'close' syscall
    mov rax, NR_CLOSE           ; set our syscall to 'close'
    ; note that we already put the file descriptor into rdi
    syscall

.exit:
    leave
    ret

; Interprets a string and returns its content as an integral number.
; NOTE: the string should contain only ASCII digits and be null terminated.
; NOTE: this assumes *little endian* format.
;
; Parameters:
;   * `rdi` : pointer to the start of the string
;
; Returns:
;   * `rax` : 8 byte parsed integer
atoi:
    ; set up the stack frame
    push rbp
    mov rbp, rsp

    ; set rdx and rax to 0
    xor rax, rax
    xor rdx, rdx

; We are going to loop through all of the bytes of the string,
; turn the ASCII digit into a number from 0-9, multiply the
; existing number by 10, and then add it to the total number
;
; We will know to stop looping when the current byte is '0',
; the null byte terminating the string
;
; This total number will be stored in rax for the duration
; of the loop
.next_byte:
    mov dl, byte [rdi]      ; Get the next byte
    cmp rdx, 0              ; If rdx is the null byte, we are done
    je .exit                ; jump to exit
    sub rdx, 0x30           ; subtract 0x30 from the ASCII digit to map it to 0-9
    imul rax, 0xa           ; multiply the number by 10 to make space in the one's digit
    add rax, rdx            ; add the digit to the sum
    inc rdi                 ; increment our byte pointer to the next byte in the string
    jmp .next_byte          ; loop

; Upon exit, the 8 byte number is stored in rax
.exit:
    leave
    ret
