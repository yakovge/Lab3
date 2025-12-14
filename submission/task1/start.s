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
    pop    dword ecx    ; ecx = argc
    mov    esi,esp      ; esi = argv
    mov     eax,ecx     ; put the number of arguments into eax
    shl     eax,2       ; compute the size of argv in bytes
    add     eax,esi     ; add the size to the address of argv
    add     eax,4       ; skip NULL at the end of argv
    push    dword eax   ; char *envp[]
    push    dword esi   ; char* argv[]
    push    dword ecx   ; int argc

    call    main        ; int main( int argc, char *argv[], char *envp[] )

    mov     ebx,eax
    mov     eax,1
    int     0x80
    nop

; System call wrapper (CDECL calling convention)
system_call:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...
    mov     ebx, [ebp+12]   ; Next argument...
    mov     ecx, [ebp+16]   ; Next argument...
    mov     edx, [ebp+20]   ; Next argument...
    int     0x80            ; Transfer control to operating system
    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

; Main function
; int main(int argc, char *argv[], char *envp[])
main:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi
    push    edi

    mov     edi, [ebp+8]           ; argc
    mov     esi, [ebp+12]          ; argv

    ; Task 1.A: Print all arguments to stdout
    xor     ebx, ebx               ; i = 0
.print_args_loop:
    cmp     ebx, edi
    jge     .done_print_args

    ; Get argv[i]
    mov     eax, [esi + ebx*4]
    push    eax

    ; Get string length using strlen from util.c
    push    eax
    call    strlen
    add     esp, 4
    mov     ecx, eax               ; length in ecx

    pop     eax                    ; restore string pointer

    ; Write to stdout (fd=1)
    push    ecx                    ; save length
    push    ebx                    ; save counter

    mov     edx, ecx               ; length
    mov     ecx, eax               ; buffer
    mov     ebx, 1                 ; stdout
    mov     eax, 4                 ; sys_write
    int     0x80

    ; Write newline
    mov     edx, 1
    mov     ecx, newline
    mov     ebx, 1
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
