
; ========================================================
; Some simple C string functions which might be useful 
; to those wishing to understand how they work in x86 asm.
;
; These are written with size in mind, not speed.
;
; Kevin Devine
; ========================================================
    [bits 32]
    [section .text]
  
; ************************************************************************ 
; const void * memchr ( const void * ptr, int value, size_t num );
;       void * memchr (       void * ptr, int value, size_t num );
;
; Searches within the first num bytes of the block of memory pointed by 
; ptr for the first occurrence of ; value (interpreted as an unsigned char), 
; and returns a pointer to it.
; ************************************************************************      
    global x86_memchr
    global _x86_memchr
    
_x86_memchr:
x86_memchr:
    xor    eax, eax
    pushad
    mov    edi, [esp+32+4]    ; ptr
    mov    eax, [esp+32+8]    ; value
    mov    ecx, [esp+32+12]   ; num
    repnz  scasb
    jecxz  exit_memchr
    dec    edi
    mov    [esp+28], edi
exit_memchr:
    popad
    ret
    
; ************************************************************************
; int memcmp ( const void * ptr1, const void * ptr2, size_t num );
;
; < 0 if ptr1 is less than ptr2
; = 0 if ptr1 is the same as ptr2
; > 0 if ptr1 is greater than ptr2
; ************************************************************************
    global x86_memcmp
    global _x86_memcmp
_x86_memcmp:
x86_memcmp:
    pushad
    xor    edx, edx
    mov    esi, [esp+32+4]    ; ptr1
    mov    edi, [esp+32+8]    ; ptr2
    mov    ecx, [esp+32+12]   ; num
    rep    cmpsb
    setnz  dl                 ; edx = ZF==1 ? 1 : 0
    sbb    eax, eax           ; eax = (eax - eax) - (CF==1 ? 1 : 0)
    xor    eax, edx
    mov    [esp+28], eax
    popad
    ret
    
; ************************************************************************  
; void * memcpy ( void * destination, const void * source, size_t num );
;
; Copies the values of num bytes from the location pointed by source directly 
; to the memory block pointed by destination.
; ************************************************************************
    global x86_memcpy
    global _x86_memcpy
_x86_memcpy:
x86_memcpy:
    mov    eax, [esp+4]       ; destination
    pushad
    xchg   eax, edi   
    mov    esi, [esp+32+8]    ; source
    mov    ecx, [esp+32+12]   ; num
    rep    movsb
    popad
    ret
   
; ************************************************************************ 
; void * memmove ( void * destination, const void * source, size_t num );
;
; Copies the values of num bytes from the location pointed by source to 
; the memory block pointed by destination. Copying takes place as if an 
; intermediate buffer were used, allowing the destination and source to overlap.
; ************************************************************************      
    global x86_memmove
    global _x86_memmove
    
_x86_memmove:
x86_memmove:
    mov    eax, [esp+4]
    pushad
    xchg   eax, edi
    mov    esi, [esp+32+8]
    mov    ecx, [esp+32+12]
    rep    movsb
    popad
    ret
    
; ************************************************************************
; void * memset ( void * ptr, int value, size_t num );
;
; Sets the first num bytes of the block of memory pointed by ptr to the 
; specified value (interpreted as an unsigned char).
; ************************************************************************
    global x86_memset
    global _x86_memset
_x86_memset:
x86_memset:
    mov    eax, [esp+4]     ; eax = ptr
    pushad
    xchg   eax, edi         ; edi = ptr
    mov    eax, [esp+32+8 ] ; value
    mov    ecx, [esp+32+12] ; num
    rep    stosb
    popad
    ret
    
; ************************************************************************    
; char * strcat ( char * destination, const char * source );
;
; Appends a copy of the source string to the destination string. 
; The terminating null character in destination is overwritten by the first 
; character of source, and a null-character is included at the end of the 
; new string formed by the concatenation of both in destination.
; ************************************************************************
    global x86_strcat
    global _x86_strcat
_x86_strcat:
x86_strcat:
    mov    eax, [esp+4]      ; destination
    pushad
    xchg   eax, edi
    mov    esi, [esp+32+8]   ; source
    or     ecx, -1
    xor    eax, eax          ; eax = 0
find_end:
    scasb                    ; cmp byte ptr[edi], al
    jnz    find_end          ;
    dec    edi
cat_loop:
    lodsb                    ; destination[i] = source[i]
    stosb
    test   al, al
    jnz    cat_loop    
    popad
    ret

; ************************************************************************
; const char * strchr ( const char * str, int character );
;       char * strchr (       char * str, int character );
;
; Returns a pointer to the first occurrence of character in the C string str.
; The terminating null-character is considered part of the C string. 
; Therefore, it can also be located in order to retrieve a pointer to the end 
; of a string.
; ************************************************************************
    global x86_strchr
    global _x86_strchr
_x86_strchr:
x86_strchr:
    xor    eax, eax
    pushad
    mov    edi, [esp+32+4]    ; str
    mov    edx, [esp+32+8]    ; c
str_loop:
    movzx  ecx, byte[edi]
    inc    edi
    jecxz  exit_strchr
    cmp    cl, dl
    jne    str_loop
    xchg   eax, edi
    dec    eax
exit_strchr:
    mov    [esp+28], eax
    popad
    ret
    
; ************************************************************************
; int strcmp ( const char * str1, const char * str2 );
;
; Compares the C string str1 to the C string str2.
;
; < 0 if str1 is less than str2
; = 0 if str1 is the same as str2
; > 0 if str1 is greater than str2
; ************************************************************************
    global x86_strcmp
    global _x86_strcmp
_x86_strcmp:
x86_strcmp:
    pushad
    mov    esi, [esp+32+4]   ; str1
    mov    edi, [esp+32+8]   ; str2
    xor    edx, edx
cmp_loop:
    cmp    byte [edi], dl
    je     exit_cmp
    cmpsb
    je     cmp_loop
exit_cmp:
    setnz  dl
    sbb    eax, eax
    xor    eax, edx
    mov    [esp+28], eax
    popad
    ret
    
; ************************************************************************
; char * strcpy ( char * destination, const char * source );
;
; Copies the C string pointed by source into the array pointed by destination, 
; including the terminating null character (and stopping at that point).
; ************************************************************************
    global x86_strcpy
    global _x86_strcpy
_x86_strcpy:
x86_strcpy:
    mov    eax, [esp+4]     ; destination
    pushad
    xchg   eax, edi
    mov    esi, [esp+32+8]  ; source
cpy_loop:
    lodsb
    stosb
    or     al, al
    jnz    cpy_loop
    popad
    ret

; ************************************************************************ 
; size_t strlen ( const char * str );
;
; Returns the length of the C string str.
; ************************************************************************
    global x86_strlen
    global _x86_strlen
_x86_strlen:
x86_strlen:
    or     eax, -1
    mov    edx, [esp+4]
len_loop:
    inc    eax
    cmp    byte [edx+eax], 0
    jne    len_loop
    test   eax, eax
    ret
    
; ************************************************************************
; const char * strpbrk ( const char * str1, const char * str2 );
;       char * strpbrk (       char * str1, const char * str2 );
;
; Returns a pointer to the first occurrence in str1 of any of the 
; characters that are part of str2, or a null pointer if there are no matches.
; ************************************************************************
    global x86_strpbrk
    global _x86_strpbrk
_x86_strpbrk:
x86_strpbrk:
    xor    eax, eax
    pushad
    or     ebx, -1          ; ptr to string if we find occurrence
    mov    esi, [esp+32+8]  ; str2
load_byte:
    mov    edi, [esp+32+4]  ; str1
    lodsb
    or     al, al
    jz     exit_pbrk
find_byte:
    cmp    byte[edi], al    ; found byte?
    jz     save_pos         ; we found occurrence, save position
    
    inc    edi
    
    cmp    byte[edi], al    ; end of string?
    jnz    find_byte
    
    jmp    load_byte        ; load another
save_pos:
    cmp    edi, ebx
    cmovb  ebx, edi
    mov    [esp+28], ebx
    jmp    load_byte
exit_pbrk:
    popad
    ret
    
; ************************************************************************
; char *strrchr (const char *str, short c);
;
; Returns a pointer to the last occurrence of character in the C string str.
; The terminating null-character is considered part of the C string. 
; Therefore, it can also be located to retrieve a pointer to the end of a string.
; ************************************************************************
    global x86_strrchr
    global _x86_strrchr
_x86_strrchr:
x86_strrchr:
    xor    eax, eax
    pushad
    or     ecx, -1
    mov    edi, [esp+32+4]    ; str
    mov    edx, [esp+32+8]    ; c
scan_loop:
    inc    ecx
    cmp    byte [edi+ecx], al
    jne    scan_loop
    dec    edi
strr_loop:
    cmp    byte [edi+ecx], dl
    loopne strr_loop
    jne    exit_strrchr
    lea    eax, [edi+ecx+1]
exit_strrchr:
    mov    [esp+28], eax
    popad
    ret
  
; ************************************************************************
; const char * strstr ( const char * str1, const char * str2 );
;       char * strstr (       char * str1, const char * str2 );
;
; Returns a pointer to the first occurrence of str2 in str1, 
; or a null pointer if str2 is not part of str1.
; The matching process does not include the terminating null-characters, 
; but it stops there.
; ************************************************************************
    global x86_strstr
    global _x86_strstr
    
_x86_strstr:
x86_strstr:
    xor    eax, eax
    pushad
    mov    edi, [esp+32+4]     ; str1
    mov    esi, [esp+32+8]     ; str2
    
    push   esi
    call   x86_strlen
    pop    esi
    jz     save_ptr            ; nothing to find?
    
    xchg   eax, ecx            ; ecx = strlen (str2)
    
    push   edi
    call   x86_strlen          ; eax = strlen (str1)
    pop    edi
    jz     exit_strstr         ; nothing to search?
find_substr:
    cmp    ecx, eax            ; if (s2_len > s1_len) goto exit_strstr;
    ja     exit_strstr
    
    pushad
    rep    cmpsb               ; strncmp (esi, edi, ecx)
    popad
    je     save_ptr
    inc    edi                 ; s1_ptr++;
    dec    eax                 ; s1_len--; 
    jmp    find_substr
save_ptr:
    mov    [esp+28], edi
exit_strstr:
    popad
    ret
   
; ************************************************************************
; int stricmp( const char *str1, const char *str2 );
;
; Compares regardless of case the C string str1 to the C string str2.
;
; < 0 if str1 is less than str2
; = 0 if str1 is the same as str2
; > 0 if str1 is greater than str2
; ************************************************************************
    global x86_stricmp
    global _x86_stricmp
_x86_stricmp:
x86_stricmp:
    pushad
    mov    esi, [esp+32+4]   ; s1
    mov    edi, [esp+32+8]   ; s2
icmp_loop:
    lodsb
    movzx  ecx, byte[edi]
    inc    edi
    jecxz  exit_icmp
    or     al, 32            ; convert to lowercase
    or     cl, 32
    cmp    al, cl
    je     icmp_loop
    sbb    eax, eax
    sbb    eax, -1
exit_icmp:
    mov    [esp+28], eax
    popad
    ret
    
