; Difine shit for long

EFLAGS_ID equ 1 << 21   

CPUID_FEATURES equ 1
CPUID_EXTENSIONS equ 0x80000000 ; returns the maximum extended requests for cpuid
CPUID_EXT_FEATURES equ 0x80000001 ; returns flags containing long mode support among other things

CPUID_EDX_EXT_FEAT_LM equ (1 << 29) ; Define the 29th bit for Long Mode

CR0_PAGING equ 1 << 31
EFER_LME equ 1 << 8

; PAE
PML4T_ADDR equ 0x1000
SIZEOF_PAGE_TABLE equ 4096

PML4T_ADDR equ 0x1000
PDPT_ADDR equ 0x2000
PDT_ADDR equ 0x3000
PT_ADDR equ 0x4000

; the page table only uses certain parts of the actual address
PT_ADDR_MASK equ 0xffffffffff000
PT_PRESENT equ 1                 ; marks the entry as in use
PT_READABLE equ 2                ; marks the entry as r/w

ENTRIES_PER_PT equ 512
SIZEOF_PT_ENTRY equ 8
PAGE_SIZE equ 0x200000

CR4_PAE_ENABLE equ 1 << 5

; 64-bit submode

; Access bits
PRESENT        equ 1 << 7
NOT_SYS        equ 1 << 4
EXEC           equ 1 << 3
DC             equ 1 << 2
RW             equ 1 << 1
ACCESSED       equ 1 << 0

; Flags bits
GRAN_4K       equ 1 << 7
SZ_32         equ 1 << 6
LONG_MODE     equ 1 << 5

;gdt
CODE_SEG_64 equ 0x28
DATA_SEG_64 equ 0x30