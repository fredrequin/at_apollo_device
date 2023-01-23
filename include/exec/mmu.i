    IFND EXEC_MMU_I
EXEC_MMU_I SET 1
**
**	$VER: mmu.i 1.0 (24.6.98)
**	Includes Release 1.0
**
**      68851/68030 MMU definition
**

    IFND EXEC_TYPES_I
    INCLUDE "exec/types.i"
    ENDC ; EXEC_TYPES_I

****** Translation control register ******

;Fields definition :
TCR_TID_Mask  = %1111
TCR_TID_Shift = 0            ;Table index D
TCR_TIC_Mask  = %1111
TCR_TIC_Shift = 4            ;Table index C
TCR_TIB_Mask  = %1111
TCR_TIB_Shift = 8            ;Table index B
TCR_TIA_Mask  = %1111
TCR_TIA_Shift = 12           ;Table index A
TCR_IS_Mask   = %1111
TCR_IS_Shift  = 16           ;Initial shift

;Page size definition :
TCR_PS_256    = %1000<<20    ;256 bytes
TCR_PS_512    = %1001<<20    ;512 bytes
TCR_PS_1K     = %1010<<20    ;1K bytes
TCR_PS_2K     = %1011<<20    ;2K bytes
TCR_PS_4K     = %1100<<20    ;4K bytes
TCR_PS_8K     = %1101<<20    ;8K bytes
TCR_PS_16K    = %1110<<20    ;16K bytes
TCR_PS_32K    = %1111<<20    ;32K bytes

;Bits definition :
    BITDEF TCR,FCTable,24    ;Enable function code table
    BITDEF TCR,SupRoot,25    ;Enable supervisor root pointer
    BITDEF TCR,EnableT,31    ;Enable MMU translation

****** Transparent translation register ******

;Fields definition :
TTR_FCM_Mask  = %111
TTR_FCM_Shift = 0            ;Function code mask
TTR_FCB_Mask  = %111
TTR_FCB_Shift = 4            ;Function code base
TTR_ADM_Mask  = %11111111
TTR_ADM_Shift = 16           ;Address mask (bits 31-24)
TTR_ADB_Mask  = %11111111
TTR_ADB_Shift = 24           ;Address base (bits 31-24)

;Access definition :
TTR_ReadOnly  = %10<<8
TTR_WriteOnly = %00<<8
TTR_ReadWrite = %01<<8

;Bits definition :
    BITDEF TTR,NoCache,10    ;Block is not cachable (instruction & data)
    BITDEF TTR,EnableT,15    ;Enable transparent translation

****** Memory descriptors ******

;Memory descriptor type :
MDT_INVALID = %00             ;Invalid descriptor
MDT_PAGE    = %01             ;Page descriptor
MDT_TABLE4  = %10             ;Next table : short format (4 bytes)
MDT_TABLE8  = %11             ;Next table : long format (8 bytes)

;Bits definition :
    BITDEF MD,Protect,2       ;Write protection : no write allowed to that page
    BITDEF MD,Used,3          ;Descriptor accessed, set by the processor
    BITDEF MD,Modified,4      ;Page modified, set by the processor
    BITDEF MD,Lock,5          ;Page locked in the ATC (68851 only !)
    BITDEF MD,NoCache,6       ;Page is not cachable (instruction & data)
    BITDEF MD,Gate,7          ;Module descriptor (68851 only !)
    BITDEF MD,Super,8         ;Supervisor access only
    BITDEF MD,Shared,9        ;Shared globally (68851 only !)
    BITDEF MD,Limit,31        ;Limit type (0 = upper, 1 = lower)

;Fields definition :
MD_WAL_Mask  = %111
MD_WAL_Shift = 10             ;Write access level (68851 only !)
MD_RAL_Mask  = %111
MD_RAL_Shift = 13             ;Read access level (68851 only !)
MD_LIM_Mask  = $7FFF
MD_LIM_Shift = 16             ;Page limit

****** Memory space definition ******

;Zorro II system : 16 MB of memory
TCR_Z2 = (TCRF_EnableT!TCR_PS_32K!(8<<TCR_IS_Shift))

;Zorro III system : 2 GB of memory
TCR_Z3 = (TCRF_EnableT!TCR_PS_32K!(1<<TCR_IS_Shift))

;1-level MMU tree for Zorro II Amiga : 512 x 32 KB pages
TCR_Z2_1L = (TCR_Z2!(9<<TCR_TIA_Shift))

;2-level MMU tree for Zorro II Amiga : 64 x 8 x 32 KB pages
TCR_Z2_2L = (TCR_Z2!(6<<TCR_TIA_Shift)!(3<<TCR_TIB_Shift))

;3-level MMU tree for Zorro II Amiga : 8 x 8 x 8 x 32 KB pages
TCR_Z2_3L = (TCR_Z2!(3<<TCR_TIA_Shift)!(3<<TCR_TIB_Shift)!(3<<TCR_TIC_Shift))

;4-level MMU tree for Zorro III Amiga : 128 x 8 x 8 x 8 x 32 KB pages
TCR_Z3_4L = (TCR_Z3!(7<<TCR_TIA_Shift)!(3<<TCR_TIB_Shift)!(3<<TCR_TIC_Shift)!(3<<TCR_TID_Shift))

****** Memory types ******

MD_RAM  = 0
MD_ROM  = MDF_Protect
MD_IO   = MDF_NoCache

    ENDC ; EXEC_MMU_I

