section .data
    newline:    db 10              ; newline character
    Infile:     dd 0               ; stdin file descriptor (0)
    Outfile:    dd 1               ; stdout file descriptor (1)

section .bss
    buffer:     resb 1             ; buffer for reading one character

section .text
    global _start
    global system_call
    extern strlen

; Entry point - sets up stack and calls main
_start:
    pop     dword ecx              ; argc
    mov     esi, esp               ; argv pointer
    push    ecx                    ; push argc for main
    push    esi                    ; push argv for main
    call    main

    ; Exit with return value from main
    mov     ebx, eax               ; exit code
    mov     eax, 1                 ; sys_exit
    int     0x80

; System call wrapper (CDECL calling convention)
; int system_call(int syscall_num, int arg1, int arg2, int arg3)
system_call:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    ecx
    push    edx

    mov     eax, [ebp+8]           ; syscall number
    mov     ebx, [ebp+12]          ; arg1
    mov     ecx, [ebp+16]          ; arg2
    mov     edx, [ebp+20]          ; arg3
    int     0x80

    pop     edx
    pop     ecx
    pop     ebx
    pop     ebp
    ret

; Main function
; int main(char **argv, int argc)
main:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    mov     esi, [ebp+8]           ; argv
    mov     edi, [ebp+12]          ; argc

    ; Task 1.A: Print all arguments to stderr
    xor     ebx, ebx               ; i = 0
.print_args_loop:
    cmp     ebx, edi
    jge     .done_print_args

    ; Get argv[i]
    mov     eax, [esi + ebx*4]
    push    eax

    ; Get string length
    push    eax
    call    strlen
    add     esp, 4
    mov     ecx, eax               ; length in ecx

    pop     eax                    ; restore string pointer

    ; Write to stderr (fd=2)
    push    ecx                    ; save length
    push    ebx                    ; save counter

    mov     edx, ecx               ; length
    mov     ecx, eax               ; buffer
    mov     ebx, 2                 ; stderr
    mov     eax, 4                 ; sys_write
    int     0x80

    ; Write newline
    mov     edx, 1
    mov     ecx, newline
    mov     ebx, 2
    mov     eax, 4
    int     0x80

    pop     ebx                    ; restore counter
    pop     ecx                    ; discard saved length

    inc     ebx
    jmp     .print_args_loop

.done_print_args:
    ; Task 1.C: Parse command line arguments for -i and -o
    mov     ebx, 1                 ; start from argv[1]
.parse_args:
    cmp     ebx, edi
    jge     .start_encode

    mov     eax, [esi + ebx*4]     ; argv[i]

    ; Check for -i (input file)
    cmp     byte [eax], '-'
    jne     .next_arg
    cmp     byte [eax+1], 'i'
    jne     .check_output

    ; Open input file: open(filename, O_RDONLY, 0)
    lea     ecx, [eax+2]           ; filename starts after "-i"
    push    ebx
    mov     ebx, ecx
    mov     ecx, 0                 ; O_RDONLY
    mov     edx, 0
    mov     eax, 5                 ; sys_open
    int     0x80
    pop     ebx

    ; Check for error
    cmp     eax, 0
    jl      .error_exit

    mov     [Infile], eax          ; store file descriptor
    jmp     .next_arg

.check_output:
    cmp     byte [eax+1], 'o'
    jne     .next_arg

    ; Open output file: open(filename, O_WRONLY|O_CREAT|O_TRUNC, 0644)
    lea     ecx, [eax+2]           ; filename starts after "-o"
    push    ebx
    mov     ebx, ecx
    mov     ecx, 0x241             ; O_WRONLY|O_CREAT|O_TRUNC
    mov     edx, 0644o             ; permissions
    mov     eax, 5                 ; sys_open
    int     0x80
    pop     ebx

    ; Check for error
    cmp     eax, 0
    jl      .error_exit

    mov     [Outfile], eax         ; store file descriptor
    jmp     .next_arg

.next_arg:
    inc     ebx
    jmp     .parse_args

.start_encode:
    ; Task 1.B: Encode loop
    call    encode

    ; Close files if opened
    mov     eax, [Infile]
    cmp     eax, 0
    je      .check_outfile
    push    eax
    mov     ebx, eax
    mov     eax, 6                 ; sys_close
    int     0x80
    pop     eax

.check_outfile:
    mov     eax, [Outfile]
    cmp     eax, 1
    je      .exit_ok
    mov     ebx, eax
    mov     eax, 6                 ; sys_close
    int     0x80

.exit_ok:
    xor     eax, eax               ; return 0
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret

.error_exit:
    mov     eax, 0x55              ; error exit code
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret

; Encode function - reads from Infile, encodes A-Z by adding 3, writes to Outfile
encode:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

.encode_loop:
    ; Read one character
    mov     eax, 3                 ; sys_read
    mov     ebx, [Infile]          ; input file descriptor
    mov     ecx, buffer            ; buffer address
    mov     edx, 1                 ; read 1 byte
    int     0x80

    ; Check if EOF or error
    cmp     eax, 0
    jle     .encode_done

    ; Get character
    mov     al, [buffer]

    ; Check if in range 'A' to 'Z'
    cmp     al, 'A'
    jl      .write_char
    cmp     al, 'Z'
    jg      .write_char

    ; Encode: add 3
    add     al, 3
    mov     [buffer], al

.write_char:
    ; Write character
    mov     eax, 4                 ; sys_write
    mov     ebx, [Outfile]         ; output file descriptor
    mov     ecx, buffer            ; buffer address
    mov     edx, 1                 ; write 1 byte
    int     0x80

    jmp     .encode_loop

.encode_done:
    pop     edi
    pop     esi
    pop     ebx
    pop     ebp
    ret
