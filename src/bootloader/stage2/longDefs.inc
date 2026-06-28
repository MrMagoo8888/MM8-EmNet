; Difine shit for long

EFLAGS_ID equ 1 << 21   

CPUID_FEATURES equ 1
CPUID_EXTENSIONS equ 0x80000000 ; returns the maximum extended requests for cpuid
CPUID_EXT_FEATURES equ 0x80000001 ; returns flags containing long mode support among other things

CPUID_EDX_EXT_FEAT_LM equ (1 << 29) ; Define the 29th bit for Long Mode

CR0_PAGING equ 1 << 31