    IFND EXEC_TYPES_I
    include "exec/types.i"
    ENDC

 STRUCTURE IdentDevice,0
    UWORD   idev_GenConfig
    UWORD   idev_Cylinders
    UWORD   idev_Reserved1
    UWORD   idev_Heads
    ULONG   idev_Reserved2
    UWORD   idev_Sectors
    STRUCT  idev_Reserved3,6
    STRUCT  idev_SerialNumber,20
    ULONG   idev_Reserved4
    UWORD   idev_LongCmdBytes
    STRUCT  idev_RevisionNumber,8
    STRUCT  idev_ModelNumber,40
    UBYTE   idev_Reserved5
    UBYTE   idev_MultipleCmd
    UWORD   idev_Reserved6
    UBYTE   idev_Capabilities
    UBYTE   idev_Reserved7
    UWORD   idev_SecurityMode
    UWORD   idev_PioModes
    UWORD   idev_DmaTiming
    UWORD   idev_Validity
    ;Words 54-58:
    UWORD   idev_LogCylinders
    UWORD   idev_LogHeads
    UWORD   idev_LogSectors
    ULONG   idev_LogCapacity

    UWORD   idev_MultipleMode
    ULONG   idev_LbaCapacity
    UWORD   idev_SingDmaModes
    UWORD   idev_MultDmaModes
    ;Words 64-70:
    UWORD   idev_AdvPioModes
    UWORD   idev_MiniDMACycle1
    UWORD   idev_MiniDMACycle2
    UWORD   idev_MiniPIOCycle1
    UWORD   idev_MiniPIOCycle2
    STRUCT  idev_Reserved10,22
    UWORD   idev_MajVerNumber
    UWORD   idev_MinVerNumber
    UWORD   idev_CmdSetSupport
    UWORD   idev_CmdSetValid
    STRUCT  idev_Reserved11,88
    UWORD   idev_SecurityStatus
    STRUCT  idev_Reserved12,254
    LABEL   idev_SIZEOF

**** General config word:

 BITDEF IDEV,PROTOCOL,15   ;0: ATA,      1: ATAPI
 BITDEF IDEV,REMOVABLE,7   ;0: No,       1: Yes           (ATA/ATAPI)
 BITDEF IDEV,DREQMODE,5    ;0: Polling,  1: Interrupt     (ATAPI)
 BITDEF IDEV,PACKET,0      ;0: 12 bytes, 1: 16 bytes      (ATAPI)

**** Capabilities byte:

 BITDEF IDEV,DMA_INT,7     ;Interleaved DMA operation     (ATAPI)
 BITDEF IDEV,PROXY,6       ;Proxy interrupt technique     (ATAPI)
 BITDEF IDEV,OVERLAP,5     ;Overlaped operation supported (ATAPI)
 BITDEF IDEV,STANDBY,5     ;Standby timer supported       (ATA)
 BITDEF IDEV,IORDY_SUP,3   ;IORDY supported               (ATA/ATAPI)
 BITDEF IDEV,IORDY_DIS,2   ;IORDY can be disabled         (ATA/ATAPI)
 BITDEF IDEV,LBA_SUP,1     ;Device support LBA addressing (ATA/ATAPI)
 BITDEF IDEV,DMA_SUP,0     ;Device support DMA            (ATA/ATAPI)

**** Field validity word:

 BITDEF IDEV,TRANSFER,1    ;Words 64-70 are valid
 BITDEF IDEV,LOGICAL,0     ;Words 54-58 are valid

**** Command set supported:

 BITDEF IDEV,CMD_SMART,0    ;SMART commands supported
 BITDEF IDEV,CMD_SECURITY,1 ;Security access commands supported
 BITDEF IDEV,CMD_REMOVE,2   ;Removeable media commands supported
 BITDEF IDEV,CMD_POWER,3    ;Power management commands supported

**** Command support validity:

IDEVF_CMD_MASK  = $C000    ;Bits to test : 15 & 14
IDEVF_CMD_VALID = $4000    ;Bit 15 = 0, Bit 14 = 1

**** Security status word:

 BITDEF IDEV,SEC_LVL,8     ;Security level
 BITDEF IDEV,SEC_EXP,4     ;Security count expired
 BITDEF IDEV,SEC_FRZ,3     ;Security frozen
 BITDEF IDEV,SEC_LCK,2     ;Security locked
 BITDEF IDEV,SEC_ENA,1     ;Security enabled
 BITDEF IDEV,SEC_SUP,0     ;Security supported
