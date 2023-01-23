    incdir  "AINCLUDE:"

    IFND EXEC_TYPES_I
    include "exec/types.i"
    ENDC

    IFND EXEC_DEVICES_I
    include "exec/devices.i"
    ENDC

    IFND EXEC_TASKS_I
    include "exec/tasks.i"
    ENDC

    IFND EXEC_INTERRUPTS_I
    include "exec/interrupts.i"
    ENDC

    IFND EXEC_SEMAPHORES_I
    include "exec/semaphores.i"
    ENDC

    IFND DEVICES_TIMER_I
    include "devices/timer.i"
    ENDC

**** AT-Apollo.device description :

MAX_UNIT    = 16                 ;Number of supported units

 STRUCTURE ApolloDevice,LIB_SIZE ;Standard Library structure
    APTR    ad_SysLib            ;ExecBase pointer
    APTR    ad_SegList           ;Segment list (not used)
    APTR    ad_TaskData          ;Device task
    UWORD   ad_Flags             ;Flags
    UWORD   ad_NumUnits          ;Number of units
    APTR    ad_CfgDevAddr        ;"ConfigDev" pointers list
    APTR    ad_BoardAddr         ;Boards base addresses
    APTR    ad_DevMaskArray      ;Device selection masks array
    STRUCT  ad_Units,MAX_UNIT*4  ;Units pointers
    ULONG   ad_NumLoop           ;Waiting loop counter value
    APTR    ad_DaemonData        ;"DiskChange" task
    APTR    ad_TimerMP           ;"timer.device" MessagePort
    APTR    ad_TimerIO           ;"timer.device" IORequest

    IFD PVDBG
    APTR    ad_PVBase            ;"powervisor.library" base address
    APTR    ad_PVPort            ;MessagePort address
    APTR    ad_CmdStr            ;SCSI command string
    ENDC

    LABEL   ad_SIZEOF

**** Device's tasks description :

STACK_SIZE = 1024                ;Stack size

 STRUCTURE TaskData,UNIT_SIZE    ;Unit structure for I/O messages
    STRUCT  td_Stack,STACK_SIZE  ;Stack size
    STRUCT  td_Task,TC_SIZE      ;Task structure

    LABEL   td_SIZEOF            ;sizeof()

 STRUCTURE DaemonData,TC_SIZE    ;Task structure
    STRUCT  dd_Sense,MAX_UNIT    ;TEST UNIT sense code
    APTR    dd_DevMP             ;AT-Apollo.device's MessagePort
    STRUCT  dd_DevIO,MAX_UNIT*4  ;AT-Apollo.device's StdIORequests
    APTR    dd_TimerMP           ;timer.device's MessagePort
    APTR    dd_TimerIO           ;timer.device's StdIORequest
    STRUCT  dd_Stack,STACK_SIZE  ;Stack size

    LABEL   dd_SIZEOF            ;sizeof()

**** AT-Apollo.device unit description :

;IMPORTANT OFFSETS: "au_OldDevMask" must be at position 43 ($2B)
;                   "au_DevType"    must be at position 55 ($37)
;                   "au_CtrlNumber" must be at position 58 ($3A)

 STRUCTURE ApolloUnit,0

    ;**** Low-level routines pointers ****

    UWORD   au_ReadJmp
    APTR    au_ReadSub           ;Read routine address
    UWORD   au_WriteJmp
    APTR    au_WriteSub          ;Write routine address
    UWORD   au_FormatJmp
    APTR    au_FormatSub         ;Format routine address
    UWORD   au_SeekJmp
    APTR    au_SeekSub           ;Seek routine address
    UWORD   au_EjectJmp
    APTR    au_EjectSub          ;Eject routine address
    UWORD   au_ScsiJmp
    APTR    au_ScsiSub           ;SCSI-Direct routine address

    ULONG   au_NumLoop           ;Number of retries (for polling)
    UWORD   au_OpenCount         ;Number of opening

    ;**** Drive geometry data ****

    UBYTE   au_DevMask           ;Selection mask
    UBYTE   au_OldDevMask        ;Old selection mask (for compatibility)   ****
    UBYTE   au_Heads             ;Number of heads
    UBYTE   au_SectorsT          ;Number of sectors per tracks
    UWORD   au_SectorsC          ;Number of sectors per cylinders
    ULONG   au_SectSize          ;Block size
    UWORD   au_Cylinders         ;Number of cylinders
    UBYTE   au_SectShift         ;Block size (logical shift)
    UBYTE   au_DevType           ;Peripheral type (SCSI-2 standard)        ****
    UWORD   au_UnitNumber        ;CBM unit number
    UBYTE   au_CtrlNumber        ;Controller number                        ****
    UBYTE   au_Removable         ;Removable media
    ULONG   au_Blocks            ;Number of blocks
    ULONG   au_RDBSector         ;Rigid Disk Block LBA

    ;**** Apollo specific flags ****

    UBYTE   au_Flags             ;Unit flags
    UBYTE   au_ReadMode          ;Read mode
    UBYTE   au_WriteMode         ;Write mode
    UBYTE   au_IntDisable        ;Interrupts disabled
    UBYTE   au_RCacheOn          ;Read-Prefetch cache activated
    UBYTE   au_WCacheOn          ;Write cache activated

    ;**** Disk change management ****

    UBYTE   au_DiskPresent       ;Media present/not present
    UBYTE   au_Used              ;Unit used
    ULONG   au_ChangeNum         ;Number of disk changes
    APTR    au_RemoveInt         ;Interrupt structure for TD_REMOVE
    STRUCT  au_SoftList,MLH_SIZE ;Software interrupts list

    ;**** Cache management ****

    ULONG   au_RCacheSize        ;Size of Read-Prefetch cache (in blocks)
    APTR    au_RCacheAddr        ;Read-Prefetch cache address
    ULONG   au_RCacheBlock       ;Actual Read-Prefetch cache position
    ULONG   au_RCacheNext        ;Next Read-Prefetch cache position
    UBYTE   au_RCacheCount       ;Countdown before Read-Prefetch

    UBYTE   au_WCacheUpd         ;Write cache updated
    UWORD   au_WCacheSize        ;Size - 1 of Write cache (in blocks)
    APTR    au_WCacheFlags       ;Write cache flags address
    APTR    au_WCacheTags        ;Write cache tags address

    ;**** System related data ****

    APTR    au_Device            ;Device pointer
    APTR    au_Task              ;Task pointer
    APTR    au_PortAddr          ;ATA port address
    APTR    au_CfgDevAddr        ;Card's ConfigDev structure

    ;**** ATA specific flags ****

    UBYTE   au_LBAMode           ;LBA mode
    UBYTE   au_AtapiDev          ;ATAPI protocol
    UBYTE   au_Swapped           ;Swapped data
    UBYTE   au_SlowDevice        ;Slow device

    STRUCT  au_ModelID,32        ;Model identification
    STRUCT  au_RevNumber,4       ;Firmware version
    STRUCT  au_SerNumber,12      ;Serial number

    ;**** SCSI emulation ****

    ULONG   au_LBASense          ;Error's LBA
    UBYTE   au_SenseKey          ;SCSI sense key
    UBYTE   au_AddSense          ;SCSI additional sense code

    LABEL   au_SIZEOF            ;sizeof()

**** au_Flags :

 BITDEF AU,INTDIS,0              ;Interrupts disabled
 BITDEF AU,FREAD,2               ;Fast read enabled
 BITDEF AU,RCACHE,3              ;Read cache enabled
 BITDEF AU,WCACHE,4              ;Write cache enabled
 BITDEF AU,REMOVE,5              ;Removable media
 BITDEF AU,FWRITE,7              ;Fast write enabled

 BITDEF AU,SWAP,8                ;Swap mode (A600/A1200/A4000/Buddha compatibility)
 BITDEF AU,SLOW,9                ;Slow peripheral

**** Write cache description :

; Cache flags:
;-------------
cf_Update = 0                    ;Updated block
cf_Valid  = 1                    ;Valid block

cf_SIZEOF = 2                    ;sizeof()

; Cache Tags:
;------------
ct_Offset = 0                    ;Block drive location
ct_Data   = 4                    ;Block memory address

ct_SIZEOF = 8                    ;sizeof()

**** Apollo specific commands :

APCMD_TESTCHANGED = $001D        ;Disk change test
APCMD_UNITPARAMS  = $001E        ;Set/Get unit params
