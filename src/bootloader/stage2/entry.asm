%include "longDefs.inc"

bits 16

section .entry



extern __bss_start
extern __end

extern start
global vbe_screen
global entry




entry:
    cli

    ; save boot drive
    mov [g_BootDrive], dl

    ; setup stack
    mov ax, ds
    mov ss, ax
    mov sp, 0xFFF0 ;0xFFF0
    mov bp, sp

    ; set a VBE graphics mode (e.g., 1024x768x32bpp)
    mov ax, 1920    ; width
    mov bx, 1080    ; height
    mov cl, 32      ; bpp
    call vbe_set_mode
    ; jc .vbe_error ; uncomment to handle VBE errors

    ; switch to protected mode
    call EnableA20          ; 2 - Enable A20 gate
    call LoadGDT            ; 3 - Load GDT

    ; 4 - set protection enable flag in CR0
    mov eax, cr0
    or al, 1
    mov cr0, eax

    ; 5 - far jump into protected mode
    jmp dword 08h:.pmode

.pmode:
    ; we are now in protected mode!
    [bits 32]
    
    ; 6 - setup segment registers
    mov ax, 0x10
    mov ds, ax
    mov ss, ax

    ; --- Draw a test pixel from assembly ---
    ; Draw a RED pixel at (x=50, y=50) to verify VBE mode
    mov edi, [vbe_screen.physical_buffer]   ; Get framebuffer base address
    movzx eax, word [vbe_screen.pitch]      ; eax = bytes per scanline (pitch)
    mov ebx, 50                             ; y = 50
    mul ebx                                 ; eax = y * pitch
    mov ebx, 50                             ; x = 50
    shl ebx, 2                              ; ebx = x * 4 (for 32 bpp)
    add eax, ebx                            ; eax = y * pitch + x * 4
    add edi, eax                            ; edi = framebuffer + offset
    mov dword [edi], 0x00FF0000             ; Draw a red pixel (0x00RRGGBB)

    call longMode

    ; --- Draw a test pixel from assembly ---
    ; Draw a RED pixel at (x=50, y=50) to verify VBE mode
    mov edi, [vbe_screen.physical_buffer]   ; Get framebuffer base address
    movzx eax, word [vbe_screen.pitch]      ; eax = bytes per scanline (pitch)
    mov ebx, 51                             ; y = 50
    mul ebx                                 ; eax = y * pitch
    mov ebx, 51                             ; x = 50
    shl ebx, 2                              ; ebx = x * 4 (for 32 bpp)
    add eax, ebx                            ; eax = y * pitch + x * 4
    add edi, eax                            ; edi = framebuffer + offset
    mov dword [edi], 0x000000FF             ; bu
    ; --- End of test pixel code ---
   
    ; clear bss (uninitialized data)
    ;mov edi, __bss_start
    ;mov ecx, __end
    ;sub ecx, edi
    ;mov al, 0
    ;cld
    ;rep stosb

    ; expect boot drive in dl, send it as argument to cstart function
    ;xor edx, edx
    ;mov dl, [g_BootDrive]
    ;push edx
    ;call start

    ;cli
    ;hlt


EnableA20:
    [bits 16]
    ; disable keyboard
    call A20WaitInput
    mov al, KbdControllerDisableKeyboard
    out KbdControllerCommandPort, al

    ; read control output port
    call A20WaitInput
    mov al, KbdControllerReadCtrlOutputPort
    out KbdControllerCommandPort, al

    call A20WaitOutput
    in al, KbdControllerDataPort
    push eax

    ; write control output port
    call A20WaitInput
    mov al, KbdControllerWriteCtrlOutputPort
    out KbdControllerCommandPort, al
    
    call A20WaitInput
    pop eax
    or al, 2                                    ; bit 2 = A20 bit
    out KbdControllerDataPort, al

    ; enable keyboard
    call A20WaitInput
    mov al, KbdControllerEnableKeyboard
    out KbdControllerCommandPort, al

    call A20WaitInput
    ret


A20WaitInput:
    [bits 16]
    ; wait until status bit 2 (input buffer) is 0
    ; by reading from command port, we read status byte
    in al, KbdControllerCommandPort
    test al, 2
    jnz A20WaitInput
    ret

A20WaitOutput:
    [bits 16]
    ; wait until status bit 1 (output buffer) is 1 so it can be read
    in al, KbdControllerCommandPort
    test al, 1
    jz A20WaitOutput
    ret


LoadGDT:
    [bits 16]
    lgdt [g_GDTDesc]
    ret



KbdControllerDataPort               equ 0x60
KbdControllerCommandPort            equ 0x64
KbdControllerDisableKeyboard        equ 0xAD
KbdControllerEnableKeyboard         equ 0xAE
KbdControllerReadCtrlOutputPort     equ 0xD0
KbdControllerWriteCtrlOutputPort    equ 0xD1

ScreenBuffer                        equ 0xB8000

g_GDT:      ; NULL descriptor
            dq 0

            ; 32-bit code segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
            db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 32-bit data segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
            db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 16-bit code segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
            db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 16-bit data segment
            dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
            dw 0                        ; base (bits 0-15) = 0x0
            db 0                        ; base (bits 16-23)
            db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
            db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
            db 0                        ; base high

            ; 
            ; L-mode
            ; 

            ; 0x28: 64-bit Kernel Code Segment
            dw 0xFFFF                   ; Limit (Ignored in 64-bit mode)
            dw 0x0000                   ; Base low
            db 0x00                     ; Base middle
            db 10011010b                ; Access byte (Present, Ring 0, Code, Executable)
            db 10101111b                ; Granularity (Bit 5 'L' flag IS SET here for 64-bit)
            db 0x00                     ; Base high

            ; 0x30: 64-bit Kernel Data Segment
            dw 0xFFFF                   ; Limit (Ignored in 64-bit mode)
            dw 0x0000                   ; Base low
            db 0x00                     ; Base middle
            db 10010010b                ; Access byte (Present, Ring 0, Data, Writable)
            db 10001111b                ; Granularity (Bit 5 'L' flag is 0 for data)
            db 0x00                     ; Base high

g_GDTDesc:  dw g_GDTDesc - g_GDT - 1    ; limit = size of GDT
            dd g_GDT                    ; address of GDT

g_BootDrive: db 0

; --- VBE ---

; vbe_set_mode:
; Sets a VESA mode
; In:   AX = Width
; In:   BX = Height
; In:   CL = Bits per pixel
; Out:  FLAGS = Carry clear on success, set on failure
; Out:  vbe_screen structure is filled on success
vbe_set_mode:
    [bits 16]
    mov [.width], ax
    mov [.height], bx
    mov [.bpp], cl

    sti ; some BIOSes need interrupts for VBE calls

    push es ; some VESA BIOSes destroy ES
    mov ax, ds
    mov es, ax ; ES must point to our data segment for the BIOS call
    mov ax, 0x4F00 ; get VBE BIOS info
    mov di, vbe_info_block ; DI is the offset in the ES segment
    int 0x10
    pop es
    cli

    cmp ax, 0x4F ; BIOS doesn't support VBE?
    jne .error

    ; Get pointer to video modes list
    mov ax, [vbe_info_block.video_modes + 2] ; segment
    mov es, ax
    mov si, [vbe_info_block.video_modes]     ; offset

.find_mode:
    mov dx, [es:si]
    add si, 2

    cmp dx, 0xFFFF ; end of list?
    je .error

    push es
    mov ax, ds
    mov es, ax ; ES must point to our data segment for the BIOS call
    mov ax, 0x4F01 ; get VBE mode info
    mov cx, dx     ; mode number to query
    mov di, mode_info_block
    int 0x10
    pop es

    cmp ax, 0x4F
    jne .next_mode ; if call fails, try next mode

    ; Check if mode attributes match what we want
    mov ax, [.width]
    cmp ax, [mode_info_block.width]
    jne .next_mode

    mov ax, [.height]
    cmp ax, [mode_info_block.height]
    jne .next_mode

    mov al, [.bpp]
    cmp al, [mode_info_block.bpp]
    jne .next_mode

    ; Found a suitable mode!
    ; Populate our vbe_screen structure
    mov ax, [mode_info_block.width]
    mov [vbe_screen.width], ax
    mov ax, [mode_info_block.height]
    mov [vbe_screen.height], ax
    mov eax, [mode_info_block.framebuffer]
    mov [vbe_screen.physical_buffer], eax
    mov ax, [mode_info_block.pitch]
    mov [vbe_screen.pitch], ax
    mov al, [mode_info_block.bpp]
    mov [vbe_screen.bpp], al

    ; Set the mode
    mov ax, 0x4F02
    mov bx, dx
    or bx, 0x4000 ; enable Linear Frame Buffer (LFB)
    int 0x10

    cmp ax, 0x4F
    jne .error

    clc ; success
    ret

.next_mode:
    jmp .find_mode

.error:
    stc ; failure
    ret

; Local variables for vbe_set_mode
.width  dw 0
.height dw 0
.bpp    db 0
















;
; SET UP LONG!!!
;

longMode:

    ; --- Draw a test pixel from assembly ---
    ; Draw a MInt pixel at (x=50, y=50) to verify VBE mode
    mov edi, [vbe_screen.physical_buffer]   ; Get framebuffer base address
    movzx eax, word [vbe_screen.pitch]      ; eax = bytes per scanline (pitch)
    mov ebx, 85                             ; y = 85
    mul ebx                                 ; eax = y * pitch
    mov ebx, 90                             ; x = 90
    shl ebx, 2                              ; ebx = x * 4 (for 32 bpp)
    add eax, ebx                            ; eax = y * pitch + x * 4
    add edi, eax                            ; edi = framebuffer + offset
    mov dword [edi], 0x00AAFFCA             ; Draw a mint-y pixel (0x00RRGGBB)

    call checkCPUID
    cmp eax, 1
    jne .failed

    call disablePaging32

    ; TEMP
    ;hlt

    .failed:
        hlt








checkCPUID:
    pushfd
    pop eax

    ; Save value fr comp
    mov ecx, eax
    xor eax, EFLAGS_ID

    ; storing the eflags and then retrieving it again will show whether or not
    ; the bit could successfully be flipped

    ; Test if it can be flipped
    push eax                    ; save to eflags
    popfd
    pushfd                      ; restore from eflags
    pop eax

    ; Restore EFLAGS to its original value
    push ecx
    popfd

    ; if the bit in eax was successfully flipped (eax != ecx), CPUID is supported.
    xor eax, ecx
    jz .notSupported

    ;query max extend leaves
    mov eax, CPUID_EXTENSIONS
    cpuid
    cmp eax, CPUID_EXT_FEATURES
    jb .notSupported            ; if the CPU can't report long mode support, then it likely
                                ; doesn't have it

    ; Query ext feat for l-mode flap
    mov eax, CPUID_EXT_FEATURES
    cpuid
    test edx, CPUID_EDX_EXT_FEAT_LM
    jz .notSupported

    .notSupported:
        mov eax, 0
        ret

    .supported:
        mov eax, CPUID_EXTENSIONS
        cpuid
        cmp eax, CPUID_EXT_FEATURES
        jz .NoLongModeSupport

        ;sucsess
        mov eax, 1
        ret

        .NoLongModeSupport:
            mov eax, 0
            ret
    
        


.queryLongMode:
    mov eax, CPUID_EXTENSIONS
    cpuid
    cmp eax, CPUID_FEATURES
    jb .NoLongMode              ; if the CPU can't report long mode support, then it likely
                                ; doesn't have it

    mov eax, CPUID_EXT_FEATURES
    cpuid
    test edx, CPUID_EDX_EXT_FEAT_LM
    jz .NoLongMode

        .NoLongMode:
            hlt

disablePaging32:
    mov eax, cr0
    and eax, ~(CR0_PAGING)  ; Brckets for NASM lololol
    mov cr0, eax



    ; PAE

    mov edi, PML4T_ADDR
    mov cr3, edi       ; cr3 lets the CPU know where the page tables are

    ; Clear Old Tables
    xor eax, eax
    mov ecx, 4096
    rep stosd                    ; Zero out the RAM allocation
    
    mov edi, PML4T_ADDR          ; Reset EDI back to PML4T_ADDR
    mov DWORD [edi], PDPT_ADDR | PT_PRESENT | PT_READABLE       ;Link Paging strucs, Entries must have present (0x1) and writable (0x2) flags set
    mov DWORD [edit + 4], 0 Clear upper 32bits

    mov edi, PDPT_ADDR
    mov DWORD [edi], PT_ADDR | PT_PRESENT | PT_READABLE
    mov DWORD [edi + 4], 0  ; Clear upper 32

    mov edi, PDT_ADDR
    mov DWORD [edi], PT_ADDR | PT_PRESENT | PT_READABLE
    mov DWORD [edi + 4], 0  ; Clear up 32 again lololol



    ; Identity map the first 2mb of ram via 4kb pages (kinda complete and utter gibberish)
    mov edi, PT_ADDR
    mov ebx, PT_PRESENT | PT_READABLE   ; Base physical addr 0x0 + flags (0x3)
    mov ecx, ENTRIES_PER_PT             ; 512 Entries

.SetEntry:
    mov DWORD [edi], ebx    ; Write low 32 (phy addr flags)
    mov DWORD [edi + 4], 0  ; Clear upper 32 of page explicetly
    add ebx, PAGE_SIZE      ;   move  to next 4kb phyical page frame 
    add edi, SIZEOF_PT_ENTRY    ; Move to next 8byte page temble entry
    loop .SetEntry               ; Set the next entry.

    ; Switch phy extentions flag (PAE) in CR4
    mov ecx, 0xC0000080         ; IA32_EFER MSR adress (idk either lol look it up)
    rdmsr
    or eax, CR0_PAGING
    mov cr0, eax

    ; Architectural far jump to load 64bit
    jmp CODE_SEG_64:.long_mode_64   ;Why did i use underscores you ask? Well, Idk lol


;
; 64 BITS BABY
;





[bits 64]
.long_mode_64:
    ; 10. Update all execution unit segment data registers to 64-bit equivalents
    mov ax, DATA_SEG_64
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; --- Draw Pixel 4: SOLID BRIGHT GREEN pixel at (x=150, y=150) ---
    ; This explicitly validates that we are parsing native 64-bit logic loops!
    mov rdi, [vbe_screen.physical_buffer]
    movzx rax, word [vbe_screen.pitch]
    mov rbx, 150
    mul rbx
    mov rbx, 150
    shl rbx, 2
    add rax, rbx
    add rdi, rax
    mov dword [rdi], 0x0000FF00             ; Draw 64-bit validation pixel

    cli
.lock:
    hlt
    jmp .lock





; PAE shit idk if need
;
;    ; PAE Enable Physical
;    mov eax, cr4
;    or eax, CR4_PAE_ENABLE       ; Turn on PAE bit (Bit 5)
;    mov cr4, eax
;
;    ret    ; Go back lolol














section .bss

; VBE Info Block (VBE 2.0+)
vbe_info_block:
    .signature       resb 4
    .version         resw 1
    .oem_string_ptr  resd 1
    .capabilities    resd 1
    .video_modes     resd 1
    .total_memory    resw 1
    .oem_sw_rev      resw 1
    .oem_vendor_name resd 1
    .oem_prod_name   resd 1
    .oem_prod_rev    resd 1
    .reserved        resb 222
    .oem_data        resb 256

; VBE Mode Info Block
mode_info_block:
    .attributes      resw 1
    .window_a        resb 2
    .granularity     resw 1
    .window_size     resw 1
    .segment_a       resw 1
    .segment_b       resw 1
    .win_func_ptr    resd 1
    .pitch           resw 1
    .width           resw 1
    .height          resw 1
    .w_char          resb 1
    .y_char          resb 1
    .planes          resb 1
    .bpp             resb 1
    .banks           resb 1
    .memory_model    resb 1
    .bank_size       resb 1
    .image_pages     resb 1
    .reserved1       resb 1
    .red_mask        resb 1
    .red_position    resb 1
    .green_mask      resb 1
    .green_position  resb 1
    .blue_mask       resb 1
    .blue_position   resb 1
    .rsv_mask        resb 1
    .rsv_position    resb 1
    .direct_color    resb 1
    .framebuffer     resd 1
    .off_screen_mem  resd 1
    .off_screen_size resw 1
    .reserved2       resb 206

section .data

; This structure will hold the graphics mode info for the kernel
vbe_screen:
    .width            dw 0
    .height           dw 0
    .pitch            dw 0
    .bpp              db 0
    .physical_buffer  dd 0