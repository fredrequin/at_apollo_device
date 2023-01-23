;******************************************************************************
;******                                                                  ******
;******              "AT-Apollo.device" v5.03 driver source              ******
;******                                                                  ******
;****** ---------------------------------------------------------------- ******
;******                                                                  ******
;******              (c) Copyright 1996-2023 Frédéric REQUIN             ******
;******                                                                  ******
;******************************************************************************

;******** Usage under PowerVisor v1.42 ********
;>mode no more
;>log main ram:scsi.log
;>log

CPU020 SET 1
;DEBUG   SET 1
;SERDBG  SET 1
;PROTECT SET 1
PVDBG = 0

    incdir  "AINCLUDE:"
    include "exec/ables.i"
    include "exec/devices.i"
    include "exec/errors.i"
    include "exec/execbase.i"
    include "exec/interrupts.i"
    include "exec/initializers.i"
    include "exec/memory.i"
    include "exec/resident.i"
    include "exec/tasks.i"
    include "hardware/intbits.i"
    include "hardware/ata_apollo.i"
    include "hardware/ata_ident.i"
    include "hardware/ata_regs.i"
    include "devices/apollo_at.i"
    include "devices/cd.i"
    include "devices/hardblocks.i"
    include "devices/newstyle.i"
    include "devices/timer.i"
    include "devices/trackdisk.i"
    include "devices/scsicmds.i"
    include "devices/scsidisk.i"
    include "libraries/configvars.i"
    include "lvo/exec.i"
    include "lvo/expansion.i"
    include "lvo/pv.i"
    include "lvo/timer.i"

;---------------
;Constants used:
;---------------

BLOCK_SIZE    = 512         ;Block/sector size (in bytes)
CONST_NUM     = $2222       ;Manufacturer : 3-States / ACT
PRODUCT_COMBI = $22         ;AT + SCSI + memory card
PRODUCT_ATA   = $33         ;AT only controller card

ATA_TimeOut   =  500000
ATAPI_TimeOut = 1000000

    IFD DEBUG
Debug
    move.l  4.w,a6
    lea     ApolloRomTag(pc),a1
    moveq   #0,d1
    jsr     _LVOInitResident(a6)

    move.l  d0,a6
    lea     IoStd(pc),a1
    moveq   #0,d0
    moveq   #0,d1
    bsr.w   Open

    lea     IoStd(pc),a1
    move.l  IO_DEVICE(a1),a6
    move.w  #CMD_READ,IO_COMMAND(a1)
    move.l  #BLOCK_SIZE*16,IO_LENGTH(a1)
    move.l  #Buffer,IO_DATA(a1)
    move.l  #0,IO_OFFSET(a1)
    bset    #IOB_QUICK,IO_FLAGS(a1)
    bsr.w   BeginIO

    lea     IoStd(pc),a1
    move.l  IO_DEVICE(a1),a6
    move.w  #CMD_READ,IO_COMMAND(a1)
    move.l  #BLOCK_SIZE*16,IO_LENGTH(a1)
    move.l  #Buffer,IO_DATA(a1)
    move.l  #0,IO_OFFSET(a1)
    bset    #IOB_QUICK,IO_FLAGS(a1)
    bra.w   BeginIO

    lea     IoStd(pc),a1
    lea     ScsiCmd(pc),a2
    move.l  IO_DEVICE(a1),a6

    move.w  #HD_SCSICMD,IO_COMMAND(a1)
    move.l  #scsi_SIZEOF,IO_LENGTH(a1)
    move.l  a2,IO_DATA(a1)
    bset    #IOB_QUICK,IO_FLAGS(a1)

    move.l  #Buffer,scsi_Data(a2)
    move.l  #BLOCK_SIZE*16,scsi_Length(a2)
    move.l  #Command,scsi_Command(a2)
    move.w  #10,scsi_CmdLength(a2)

    bra.w   BeginIO

IoStd
    blk.b   IOSTD_SIZE,0
ScsiCmd
    blk.b   scsi_SIZEOF,0
Command
    dc.b    $28,$00,$00,$00,$01,$00,$00,$00,$04,$00
Buffer
    blk.b   BLOCK_SIZE*16,$55

    ENDC

ProgStart
    moveq   #0,d0
    rts

ApolloRomTag
    dc.w    RTC_MATCHWORD
    dc.l    ApolloRomTag
    dc.l    EndRomTag
    dc.b    RTF_AUTOINIT
    dc.b    5               ;Version
    dc.b    NT_DEVICE       ;Node type
    dc.b    0               ;Priority
    dc.l    ATName
    dc.l    IDString
    dc.l    Init
Init
    dc.l    ad_SIZEOF       ;Device structure size
    dc.l    FuncTable       ;Functions table
    dc.l    DataTable       ;Data to initialize
    dc.l    InitRoutine     ;Init routine

;*************** Device initialization table **********************************

DataTable
    INITBYTE LN_TYPE,NT_DEVICE         ;LN_TYPE = NT_DEVICE
    INITLONG LN_NAME,ATName            ;LN_NAME = ATName
    INITBYTE LIB_FLAGS,LIBF_CHANGED!LIBF_SUMUSED
    INITWORD LIB_VERSION,5
    INITWORD LIB_REVISION,3
    INITLONG LIB_IDSTRING,IDString
    dc.w     0

;*************** Device verification through checksum *************************

    IFD PROTECT
Cks
    dc.l    $11111111

NumLong
    dc.w    (EndRomTag-NumLong)/4-1
    ENDC

;*************** Device functions table ****************************************

FuncTable
    dc.w    -1                        ;Relative pointers
    dc.w    Open-FuncTable            ;OpenDevice() call
    dc.w    Close-FuncTable           ;CloseDevice() call
    dc.w    Expunge-FuncTable         ;Expunge() call
    dc.w    Null-FuncTable            ;Not used
    dc.w    BeginIO-FuncTable         ;BeginIO() call
    dc.w    AbortIO-FuncTable         ;AbortIO() call
    dc.w    GetRdskLba-FuncTable      ;Not standard : RDB sector number
    dc.w    GetBlkSize-FuncTable      ;Not standard : sector size
    dc.w    Null-FuncTable            ;Not used
    dc.w    -1

ATName
    dc.b    "AT-Apollo.device",0
    dc.b    "$VER: "
IDString
    dc.b    "AT-Apollo.device 5.03 (8 Dec 1999 F.Requin)",13,10,0
CDName
    dc.b    "Apollo device rewrite by F. Requin",0
TaskName
    dc.b    "AT-Apollo.task",0
DaemonName
    dc.b    "AT-Apollo.daemon",0
ExpansionName
    dc.b    "expansion.library",0
TimerName
    dc.b    "timer.device",0

    IFD SERDBG
DbgInitMess
    dc.b    "init",10,0
DbgDev0Mess
    dc.b    "dev0",10,0
DbgDev1Mess
    dc.b    "dev1",10,0
DbgDev2Mess
    dc.b    "dev2",10,0
DbgDev3Mess
    dc.b    "dev3",10,0
DbgEndMess
    dc.b    "end scan",10,0
DbgTaskMess
    dc.b    "task",10,0
DbgDaemonMess
    dc.b    "daemon",10,0
DbgOpenMess
    dc.b    "open *",10,0
DbgUnitMess
    dc.b    "init *",10,0
DbgBusOkMess
    dc.b    "bus ok",10,0
DbgSelectMess
    dc.b    "select",10,0
DbgReadyMess
    dc.b    "ready",10,0
DbgDetectMess
    dc.b    "detect",10,0
    ENDC

    even

;******************************************************************************
;********                                                              ********
;********                Device initialization routine                 ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;D0.l : AT-Apollo.device base address
;A0.l : AmigaDos SegList
;A4.l : expansion.library base address
;A6.l : ExecBase

InitRoutine
    movem.l d1-d7/a0-a5,-(sp)
    move.l  d0,a5                       ;A5 : AT-Apollo.device base address
    move.l  a6,ad_SysLib(a5)            ;Save ExecBase
    move.l  a0,ad_SegList(a5)           ;Save SegList

    IFD SERDBG
    movem.l a0-a3/d0/d1,-(sp)
    lea     DbgInitMess(pc),a0
    sub.l   a1,a1
    lea     _LVORawPutChar(a6),a2
    sub.l   a3,a3
    jsr     _LVORawDoFmt(a6)
    movem.l (sp)+,a0-a3/d0/d1
    ENDC

;*************** Checksum test ************************************************

    IFD PROTECT
    lea     FuncTable(pc),a0
    move.l  Cks(pc),d0
    move.w  NumLong(pc),d1
.CheckLoop
    add.l   (a0)+,d0
    dbra    d1,.CheckLoop
    tst.l   d0
    beq.b   .CksOk
    move.l  #$BADC0DE,d7
    jsr     _LVOAlert(a6)
    bra.w   .Error
.CksOk
    ENDC

;*************** Memory allocation ********************************************

    moveq   #MAX_UNIT*4,d0
    move.l  #(MEMF_PUBLIC!MEMF_CLEAR),d1
    jsr     _LVOAllocMem(a6)
    move.l  d0,ad_CfgDevAddr(a5)
    beq.w   .Error
    move.l  d0,a4                       ;A4 : 16-pointer array of
                                        ;     "ConfigDev" structures

    moveq   #MAX_UNIT*4,d0
    move.l  #MEMF_PUBLIC!MEMF_CLEAR,d1
    jsr     _LVOAllocMem(a6)
    move.l  d0,ad_BoardAddr(a5)
    beq.w   .Error
    move.l  d0,a3                       ;A3 : 16-pointer array of
                                        ;     board base addresses

    moveq   #MAX_UNIT,d0
    move.l  #MEMF_PUBLIC!MEMF_CLEAR,d1
    jsr     _LVOAllocMem(a6)
    move.l  d0,ad_DevMaskArray(a5)
    beq.w   .Error
    move.l  d0,a2                       ;A2 : 16-byte array of
                                        ;     device selection masks

;*************** Opening "timer.device" ***************************************

    moveq   #IOTV_SIZE,d0
    move.l  #MEMF_PUBLIC!MEMF_CLEAR,d1
    jsr     _LVOAllocMem(a6)
    move.l  d0,ad_TimerIO(a5)
    beq.w   .Error

    lea     TimerName(pc),a0            ;A0: "timer.device"
    move.l  d0,a1                       ;A1: timerequest structure
    moveq   #UNIT_VBLANK,d0             ;D0: Precision : 1/50th second
    moveq   #0,d1                       ;D1: Flags
    jsr     _LVOOpenDevice(a6)          ;Open device
    tst.l   d0                          ;Everything went well ?
    bne.w   .Error                      ;No, end of init

;*************** Opening "expansion.library" **********************************

    lea     ExpansionName(pc),a1
    moveq   #0,d0
    jsr     _LVOOpenLibrary(a6)
    tst.l   d0
    beq.w   .Error
    move.l  d0,a6                       ;A6 : ExpansionBase

;*************** Scanning of "Apollo" cards and drives ************************

    moveq   #0,d7                       ;Unit number = 0
    moveq   #0,d5                       ;Controller number = 0
    sub.l   a0,a0                       ;Start of "ConfigDev" list
.Loop
    move.l  #CONST_NUM,d0               ;Manufacturer ID
    moveq   #-1,d1                      ;Any product ID
    jsr     _LVOFindConfigDev(a6)
    tst.l   d0
    beq.w   .End                        ;0 : no more card, end of loop
    move.l  d0,a0                       ;A0 : "ConfigDev" structure
    move.b  cd_Rom+er_Product(a0),d0    ;D0 : Product ID
    cmpi.b  #PRODUCT_ATA,d0             ;AT card?
    beq.b   .FoundProd                  ;Yes, continue
    cmpi.b  #PRODUCT_COMBI,d0           ;AT + SCSI card ?
    bne.b   .Loop                       ;No, next card

.FoundProd
    move.l  cd_Unused(a0),d0            ;D0 : Special identifier
    cmpi.l  #'APOL',d0                  ;Apollo controller ON ?
    beq.b   .FoundCtrl                  ;Yes, continue
    cmpi.l  #'APOX',d0                  ;Apollo controller OFF ?
    bne.b   .Loop                       ;No, next card

.FoundCtrl
    move.l  #113,cd_Unused+4(a0)
    lea     CDName(pc),a1
    move.l  a1,LN_NAME(a0)              ;"ConfigDev" structure name
    move.l  a5,cd_Driver(a0)            ;Device address
    move.l  cd_BoardAddr(a0),a1         ;A1 : First IDE port address

;*************** Primary connector auto-detect ********************************

    IFD SERDBG
    movem.l a0-a3/a6/d0/d1,-(sp)
    move.l  ad_SysLib(a5),a6
    lea     DbgDev0Mess(pc),a0
    sub.l   a1,a1
    lea     _LVORawPutChar(a6),a2
    sub.l   a3,a3
    jsr     _LVORawDoFmt(a6)
    movem.l (sp)+,a0-a3/a6/d0/d1
    ENDC

    move.b  #ATAF_MASTER,d6             ;Disk #0 (master)
    bsr.w   TestDevice                  ;Test if drive is present
    beq.b   .NoMaster1

    bsr.w   TestMirror                  ;Décodage incomplet ?
    beq.b   .NoSlave1                   ;Yes, no slave present

    IFD SERDBG
    movem.l a0-a3/a6/d0/d1,-(sp)
    move.l  ad_SysLib(a5),a6
    lea     DbgDev1Mess(pc),a0
    sub.l   a1,a1
    lea     _LVORawPutChar(a6),a2
    sub.l   a3,a3
    jsr     _LVORawDoFmt(a6)
    movem.l (sp)+,a0-a3/a6/d0/d1
    ENDC

.NoMaster1
    move.b  #ATAF_SLAVE,d6              ;Disk #1 (slave)
    bsr.w   TestDevice                  ;Test if drive is present

.NoSlave1
    addq.b  #1,d5                       ;Next controller
    bsr.w   TestPort2                   ;4-IDE interface present ?
    bne.b   .Loop                       ;No, next Apollo card

;*************** Secondary connector auto-detect ******************************

    lea     ata_NextPort(a1),a1         ;Yes, second IDE port address

    IFD SERDBG
    movem.l a0-a3/a6/d0/d1,-(sp)
    move.l  ad_SysLib(a5),a6
    lea     DbgDev2Mess(pc),a0
    sub.l   a1,a1
    lea     _LVORawPutChar(a6),a2
    sub.l   a3,a3
    jsr     _LVORawDoFmt(a6)
    movem.l (sp)+,a0-a3/a6/d0/d1
    ENDC

    move.b  #ATAF_MASTER,d6             ;Disk #0 (master)
    bsr.w   TestDevice                  ;Test if drive is present
    beq.b   .NoMaster2

    bsr.w   TestMirror                  ;Incomplete decoding ?
    beq.b   .NoSlave2                   ;Yes, no slave present

    IFD SERDBG
    movem.l a0-a3/a6/d0/d1,-(sp)
    move.l  ad_SysLib(a5),a6
    lea     DbgDev3Mess(pc),a0
    sub.l   a1,a1
    lea     _LVORawPutChar(a6),a2
    sub.l   a3,a3
    jsr     _LVORawDoFmt(a6)
    movem.l (sp)+,a0-a3/a6/d0/d1
    ENDC

.NoMaster2
    move.b  #ATAF_SLAVE,d6              ;Disk #1 (slave)
    bsr.w   TestDevice                  ;Test if drive is present

.NoSlave2
    addq.b  #1,d5                       ;Next controller
    bra.w   .Loop                       ;Next Apollo card

;*************** End : closing "expansion.library" ****************************

.End
    IFD SERDBG
    movem.l a0-a3/a6/d0/d1,-(sp)
    move.l  ad_SysLib(a5),a6
    lea     DbgEndMess(pc),a0
    sub.l   a1,a1
    lea     _LVORawPutChar(a6),a2
    sub.l   a3,a3
    jsr     _LVORawDoFmt(a6)
    movem.l (sp)+,a0-a3/a6/d0/d1
    ENDC

    move.l  a6,a1                       ;A1 : ExpansionBase
    move.l  ad_SysLib(a5),a6            ;A6 : ExecBase
    jsr     _LVOCloseLibrary(a6)        ;Close the library

;*************** Closing "timer.device" ***************************************

    move.l  ad_TimerIO(a5),a1           ;A1 : timerequest
    jsr     _LVOCloseDevice(a6)         ;Close the device

    move.l  ad_TimerIO(a5),a1           ;A1 : timerequest
    moveq   #IOTV_SIZE,d0               ;D0 : Size
    jsr     _LVOFreeMem(a6)             ;Free the memory

;*************** Start the device tasks ***************************************

    move.w  d7,ad_NumUnits(a5)          ;Number of detected units
    beq.b   .Error                      ;No unit : error

    IFD SERDBG
    movem.l a0-a3/a6/d0/d1,-(sp)
    move.l  ad_SysLib(a5),a6
    lea     DbgTaskMess(pc),a0
    sub.l   a1,a1
    lea     _LVORawPutChar(a6),a2
    sub.l   a3,a3
    jsr     _LVORawDoFmt(a6)
    movem.l (sp)+,a0-a3/a6/d0/d1
    ENDC

    bsr.b   InitTask                    ;Apollo task initialization
    beq.b   .Error                      ;Error : exit

    IFD SERDBG
    movem.l a0-a3/a6/d0/d1,-(sp)
    move.l  ad_SysLib(a5),a6
    lea     DbgDaemonMess(pc),a0
    sub.l   a1,a1
    lea     _LVORawPutChar(a6),a2
    sub.l   a3,a3
    jsr     _LVORawDoFmt(a6)
    movem.l (sp)+,a0-a3/a6/d0/d1
    ENDC

    bsr.w   InitDaemon                  ;Apollo deamon initialization
    beq.b   .Error                      ;Error : exit

    move.l  a5,d0                       ;Return the device's pointer
    movem.l (sp)+,d1-d7/a0-a5           ;Restore registers
    rts                                 ;End

;*************** Error : return a null pointer ********************************

.Error
    moveq   #0,d0                       ;Return a null pointer
    movem.l (sp)+,d1-d7/a0-a5           ;Restore registers
    rts                                 ;End

;;*****************************************************************************
;********                                                              ********
;********                  Initialize the device task                  ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A5.l : AT-Apollo.device base address
;A6.l : ExecBase

;Return value:
;-------------
;Z Flag (0:Ok, 1:Error)

InitTask
    movem.l a2/a3,-(sp)                 ;Save A2 & A3

;*************** Memory allocation of the "TaskData" structure ****************

    move.l  #td_SIZEOF,d0               ;Memory allocation
    move.l  #MEMF_PUBLIC!MEMF_CLEAR,d1  ;for "Unit" & "Task" structures
    jsr     _LVOAllocMem(a6)            ;and for the task's stack
    move.l  d0,ad_TaskData(a5)          ;Save the pointer
    beq.b   .Error                      ;Null pointer : error
    move.l  d0,a2                       ;A2 : "TaskData" structure 
    lea     td_Task(a2),a1              ;A1 : "Task" structure 
    lea     td_Stack(a2),a0             ;A0 : Task's stack

;*************** Initialization of the task's stack ***************************

    move.l  a0,TC_SPLOWER(a1)           ;Lower limit
    lea     STACK_SIZE(a0),a0           ;+ Stack size
    move.l  a0,TC_SPUPPER(a1)           ;Upper limit
    move.l  a5,-(a0)                    ;Save the device address on the stack
    move.l  a0,TC_SPREG(a1)             ;Current stack pointer

;*************** Initialization of the message list ***************************

    lea     MP_MSGLIST+LH_HEAD(a2),a0
    move.l  a0,LH_TAILPRED(a0)          ;lh_TailPred = &lh_Head;
    addq.l  #LH_TAIL,a0
    clr.l   (a0)                        ;lh_Tail = NULL;
    move.l  a0,-(a0)                    ;lh_Head = &lh_Tail;

;*************** Initialization of "Task" & "MsgPort" structures **************

    lea     TaskName(pc),a0
    move.l  a0,LN_NAME(a1)              ;Node name
    move.b  #NT_TASK,LN_TYPE(a1)        ;Node type : Task
    move.b  #5,LN_PRI(a1)               ;Priority : 5

    move.l  a1,MP_SIGTASK(a2)           ;Task to wake-up : the device
    lea     ATName(pc),a0
    move.l  a0,LN_NAME(a2)              ;Node name
    moveq   #NT_MSGPORT,d0
    move.b  d0,LN_TYPE(a2)              ;Node type : MessagePort
    moveq   #PA_IGNORE,d0
    move.b  d0,MP_FLAGS(a2)             ;Flags : ignore messages

;*************** Add the task to Exec's task list *****************************

    lea     TaskCode(pc),a2             ;A2: Start of execution
    sub.l   a3,a3                       ;A3: End of execution
    jsr     _LVOAddTask(a6)             ;Add the task to Exec's list

    moveq   #1,d0                       ;Flag Z=0 : Ok
    movem.l (sp)+,a2/a3                 ;Restore registers
    rts                                 ;End

.Error
    moveq   #0,d0                       ;Flag Z=1 : Error
    movem.l (sp)+,a2/a3                 ;Restore registers
    rts                                 ;End

;;*****************************************************************************
;********                                                              ********
;********            Initialize the device diskchange deamon           ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A5.l : AT-Apollo.device base address
;A6.l : ExecBase

;Return value:
;-------------
;Z Flag (0:Ok, 1:Error)

InitDaemon
    movem.l a2/a3,-(sp)                 ;Save A2 & A3

;*************** Memory allocation ********************************************

    move.l  #dd_SIZEOF,d0               ;Structure size
    move.l  #MEMF_PUBLIC!MEMF_CLEAR,d1  ;Public memory, cleared
    jsr     _LVOAllocMem(a6)            ;Memory allocation
    move.l  d0,ad_DaemonData(a5)        ;Save the pointer
    beq.b   .Error                      ;Null pointer : error

;*************** Initialization of the "DeamonData" structure *****************

    move.l  d0,a1                       ;A1 : "DeamonData" structure
    lea     dd_Stack(a1),a0             ;A0 : Task's stack

    move.l  a0,TC_SPLOWER(a1)           ;Lower limit
    lea     STACK_SIZE(a0),a0           ;+ Stack size
    move.l  a0,TC_SPUPPER(a1)           ;Upper limit
    move.l  a5,-(a0)                    ;Save the device address on the stack
    move.l  a0,TC_SPREG(a1)             ;Current stack pointer

    lea     DaemonName(pc),a0
    move.l  a0,LN_NAME(a1)              ;Task's name
    move.b  #NT_TASK,LN_TYPE(a1)        ;Node type : Task
    move.b  #5,LN_PRI(a1)               ;Priority : 5

;*************** Add the task to Exec's tasks list ****************************

    lea     DaemonCode(pc),a2           ;Start of code
    lea     -1,a3                       ;End of code : address Error
    jsr     _LVOAddTask(a6)             ;Add the task

    moveq   #1,d0                       ;Flag Z=0: Ok
    movem.l (sp)+,a2/a3                 ;Restore registers
    rts                                 ;End

.Error
    moveq   #0,d0                       ;Flag Z=1: Error
    movem.l (sp)+,a2/a3                 ;Restore registers
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********              Read/write caches memory allocate               ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address
;A6.l : ExecBase

AllocCache
    tst.b   au_RCacheOn(a3)             ;Read cache activated ?
    beq.b   .NoReadCache                ;No, skip read cache memory allocate

;*************** Read cache memory allocate ***********************************

    move.l  au_RCacheSize(a3),d0        ;D0: Number of buffers
    move.b  au_SectShift(a3),d1         ;D1: Block size
    lsl.l   d1,d0                       ;D0 x D1 = Cache size
    moveq   #0,d1                       ;Any memory type
    jsr     _LVOAllocMem(a6)            ;Memory allocation
    move.l  d0,au_RCacheAddr(a3)        ;Save the cache address
    beq.b   .Error                      ;No memory : exit
    move.b  #4,au_RCacheCount(a3)       ;4 reads before cache fetch
    moveq   #-1,d0
    move.l  d0,au_RCacheBlock(a3)       ;Cache not valid

.NoReadCache
    tst.b   au_WCacheOn(a3)             ;Write cache activated ?
    beq.b   .NoWriteCache               ;No, skip write cache memory allocate
    tst.b   au_DevType(a3)              ;Direct access peripheral ?
    bne.b   .NoWriteCache               ;No, skip write cache memory allocate

;*************** Write cache memory allocate : tags & flags *******************

    moveq   #1,d2
    add.w   au_WCacheSize(a3),d2        ;D2: Number of buffers
    move.w  d2,d0
    mulu    #(ct_SIZEOF+cf_SIZEOF),d0   ;D0: Cache size
    move.l  #MEMF_PUBLIC!MEMF_CLEAR,d1  ;Public memory, cleared
    jsr     _LVOAllocMem(a6)            ;Memory allocation
    move.l  d0,au_WCacheTags(a3)        ;Save tags address
    beq.b   .Error                      ;No memory : exit
    move.l  d0,a2                       ;A2: Tags address
    mulu    #ct_SIZEOF,d2               ;D2: Flags offset
    add.l   d2,d0
    move.l  d0,au_WCacheFlags(a3)       ;Save flags address

;*************** Write cache memory allocate : buffers ************************

    addq.l  #ct_Data,a2
    move.w  au_WCacheSize(a3),d2        ;D2: Number of buffers - 1
.Loop
    move.l  au_SectSize(a3),d0          ;D0: Block size
    moveq   #0,d1                       ;Any memory type
    jsr     _LVOAllocMem(a6)            ;Memory allocation
    move.l  d0,(a2)                     ;Save the buffer address
    beq.b   .Error                      ;No memory : exit
    addq.l  #ct_SIZEOF,a2               ;Next buffer
    dbra    d2,.Loop                    ;Loop

.NoWriteCache
    moveq   #1,d0                       ;Flag Z=0: Ok
.Error
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********             Read/Write caches memory de-allocate             ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address
;A6.l : ExecBase

FreeCache
    move.l  au_WCacheTags(a3),d3        ;Write cache activated ?
    beq.b   .NoWriteCache               ;No, skip write cache memory de-allocate

;*************** Write cache buffers de-allocate ******************************

    move.l  d3,a2                       ;A2: Tags address
    addq.l  #ct_Data,a2
    move.w  au_WCacheSize(a3),d2        ;D2: Number of buffers - 1
.Loop
    move.l  (a2),d0                     ;D0: Buffer address
    beq.b   .Empty                      ;Null, exit from the loop 
    move.l  d0,a1                       ;A1: Buffer address to free-up
    move.l  au_SectSize(a3),d0          ;D0: Size of the memory to free-up
    jsr     _LVOFreeMem(a6)             ;Free the memory
    clr.l   (a2)                        ;Clear the pointer
    addq.l  #ct_SIZEOF,a2               ;Next buffer
    dbra    d2,.Loop                    ;Loop

;*************** Write cache Flags & Tags de-allocate *************************

.Empty
    move.l  d3,a1                       ;A1: Flags & Tags address
    moveq   #1,d0
    add.w   au_WCacheSize(a3),d0        ;D0: Number of buffers
    mulu    #(ct_SIZEOF+cf_SIZEOF),d0   ;Size of the memory to free-up
    jsr     _LVOFreeMem(a6)             ;Free the memory
    clr.l   au_WCacheTags(a3)
    clr.l   au_WCacheFlags(a3)          ;Clear the pointers
    sf.b    au_WCacheOn(a3)             ;Clear the flag

.NoWriteCache
    move.l  au_RCacheAddr(a3),d0        ;Read cache activated ?
    beq.b   .NoReadCache                ;No, skip read cache memory de-allocate

;*************** Read cache memory de-allocate ********************************

    move.l  d0,a1                       ;A1: Read cache address
    move.l  au_RCacheSize(a3),d0        ;D0: Number of buffers
    move.b  au_SectShift(a3),d1         ;D1: Block size
    lsl.l   d1,d0                       ;D0 x D1 = Cache size
    jsr     _LVOFreeMem(a6)             ;Free the memory
    clr.l   au_RCacheAddr(a3)           ;Clear the pointer
    sf.b    au_RCacheOn(a3)             ;Clear the flag

.NoReadCache
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                    Device opening routine                    ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;D0.l : Unit number
;D1.l : Flags
;A1.l : Standard I/O Request
;A6.l : AT-Apollo.device base address

Open
    IFD SERDBG
    movem.l a0-a3/a6/d0/d1,-(sp)
    move.l  ad_SysLib(a6),a6
    lea     DbgOpenMess(pc),a0
    addi.b  #'0',d0
    move.b  d0,5(a0)
    sub.l   a1,a1
    lea     _LVORawPutChar(a6),a2
    sub.l   a3,a3
    jsr     _LVORawDoFmt(a6)
    movem.l (sp)+,a0-a3/a6/d0/d1
    ENDC

    movem.l d2/a2-a4,-(sp)
    move.l  a1,a2                       ;A2 : Standard I/O Request
    move.l  a6,IO_DEVICE(a2)            ;Device pointer
    cmp.w   ad_NumUnits(a6),d0          ;Unit number too high ?
    bcc.b   .Error                      ;Yes, error

    move.w  d0,d2                       ;D2 : Unit number

    ;-------- 68000 --------
    IFND CPU020
    add.w   d0,d0
    add.w   d0,d0                       ;Unit number x 4
    lea     ad_Units(a6,d0.w),a4
    ENDC

    ;-------- 68020+ --------
    IFD CPU020
    lea     ad_Units(a6,d0.w*4),a4
    ENDC

    move.l  (a4),d0                     ;"ApolloUnit" structure pointer
    bne.b   .AlreadyInit                ;Not null : structure already initialized
    bsr.b   InitUnit                    ;Otherwise, initialize the structure
    move.l  (a4),d0
    beq.b   .Error                      ;Still null : error
.AlreadyInit
    move.l  d0,a3                       ;A3 : "ApolloUnit" structue
    move.l  d0,IO_UNIT(a2)              ;Save the pointer
    addq.w  #1,LIB_OPENCNT(a6)          ;Increment both counters
    addq.w  #1,au_OpenCount(a3)         ;(Device & Unit)
    bclr    #LIBB_DELEXP,ad_Flags(a6)   ;Clear the "Expunge" flag
    moveq   #0,d0                       ;No error
.End
    move.b  d0,IO_ERROR(a2)             ;End
    movem.l (sp)+,d2/a2-a4
    rts
.Error
    moveq   #IOERR_OPENFAIL,d0          ;Error : opening has failed
    bra.b   .End

;******************************************************************************
;********                                                              ********
;********                    Device closing routine                    ********
;********                                                              ********
;******************************************************************************

;A1.l : Standard I/O Request
;A6.l : AT-Apollo.device base address

Close
    move.l  a2,-(sp)                    ;Save A2
    move.l  IO_UNIT(a1),a2              ;A2 : "ApolloUnit" structure

    moveq   #-1,d0                      ;Forbid I/O structure use
    move.l  d0,IO_UNIT(a1)              ;by putting -1
    move.l  d0,IO_DEVICE(a1)            ;in both fields

    subq.w  #1,au_OpenCount(a2)         ;Decrease the open counter
    subq.w  #1,LIB_OPENCNT(a6)          ;(Device & Unit)
    bne.b   .End                        ;Not the last close ?
    btst    #LIBB_DELEXP,ad_Flags(a6)   ;"Expunge" flag set ?
    beq.b   .End                        ;No
    bsr.b   Expunge                     ;Yes
.End
    moveq   #0,d0                       ;End, return null
    move.l  (sp)+,a2                    ;Restore A2
    rts

;******************************************************************************
;********                                                              ********
;********                    Device expunge routine                    ********
;********                                                              ********
;******************************************************************************

;A6.l : AT-Apollo.device base address

Expunge
    bset    #LIBB_DELEXP,ad_Flags(a6)   ;Set the "Expunge" flag
Null
    moveq   #0,d0                       ;End, return null
    rts

;******************************************************************************
;********                                                              ********
;********                  ApolloUnit initialization                   ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;D2.w : Unit number
;A2.l : Standard I/O Request
;A6.l : AT-Apollo.device base address

InitUnit
    IFD SERDBG
    movem.l a0-a3/a6/d0/d1,-(sp)
    move.l  ad_SysLib(a6),a6
    lea     DbgUnitMess(pc),a0
    move.b  d2,d0
    addi.b  #'0',d0
    move.b  d0,5(a0)
    sub.l   a1,a1
    lea     _LVORawPutChar(a6),a2
    sub.l   a3,a3
    jsr     _LVORawDoFmt(a6)
    movem.l (sp)+,a0-a3/a6/d0/d1
    ENDC

    movem.l d1-d7/a0-a6,-(sp)

    move.l  a6,a5                       ;A5: AT-Apollo.device base address
    move.l  ad_SysLib(a5),a6            ;A6: ExecBase

;*************** "ApolloUnit" structure initialization ************************

    move.l  #au_SIZEOF,d0               ;D0: ApolloUnit structure size
    move.l  #MEMF_PUBLIC!MEMF_CLEAR,d1  ;Public memory, cleared
    jsr     _LVOAllocMem(a6)            ;Allocate memory for ApolloUnit
    tst.l   d0
    beq.w   .End                        ;Out of memory error : exit

    move.l  d0,a3                       ;A3: ApolloUnit base address
    move.b  d2,au_UnitNumber(a3)        ;Unit number
    move.l  a5,au_Device(a3)            ;AT-Apollo.device base address

    move.w  #$4EF9,d0                   ;JMP instruction
    move.w  d0,au_ReadJmp(a3)
    move.w  d0,au_WriteJmp(a3)
    move.w  d0,au_FormatJmp(a3)
    move.w  d0,au_SeekJmp(a3)
    move.w  d0,au_EjectJmp(a3)
    move.w  d0,au_ScsiJmp(a3)           ;Jump table initialization

    lea     au_SoftList(a3),a0          ;Interrupts list
    move.l  a0,LH_TAILPRED(a0)
    addq.l  #LH_TAIL,a0
    clr.l   (a0)
    move.l  a0,-(a0)                    ;The list is empty

    move.l  ad_DevMaskArray(a5),a0      ;ATA/ATAPI device mask
    move.b  (a0,d2.w),d0                ;for "ata_DevHead" register
    move.b  d0,d1

    btst    #ATAB_LBA,d0                ;LBA addressing ?
    beq.b   .NoLBA                      ;No, skip
    st.b    au_LBAMode(a3)              ;Yes, set au_LBAMode flag
.NoLBA

    bset    #ATAB_ATAPI,d0              ;ATAPI drive ?
    beq.b   .Ata                        ;No, skip

    ;-------- 68000 --------
    IFND CPU020
    move.l  #ATAPI_TimeOut,au_NumLoop(a3)   ;Number of loops for BUSY
    ENDC

    ;-------- 68020+ --------
    IFD CPU020
    move.l  #ATAPI_TimeOut*8,au_NumLoop(a3) ;Number of loops x 8 for BUSY
    ENDC

    lea     atapi_Read(pc),a0
    move.l  a0,au_ReadSub(a3)           ;Read routine
    lea     atapi_Write(pc),a0
    move.l  a0,au_WriteSub(a3)          ;Write routine
    lea     atapi_Write(pc),a0
    move.l  a0,au_FormatSub(a3)         ;Format routine
    lea     atapi_Seek(pc),a0
    move.l  a0,au_SeekSub(a3)           ;Seek routine
    lea     atapi_Eject(pc),a0
    move.l  a0,au_EjectSub(a3)          ;Eject routine
    lea     atapi_ScsiCmd(pc),a0
    move.l  a0,au_ScsiSub(a3)           ;SCSI-Direct routine

    st.b    au_AtapiDev(a3)             ;au_AtapiDev set
    st.b    au_LBAMode(a3)              ;au_LBAMode set
    bra.b   .Atapi

.Ata
    ;-------- 68000 --------
    IFND CPU020
    move.l  #ATA_TimeOut,au_NumLoop(a3)     ;Number of loops for BUSY
    ENDC

    ;-------- 68020+ --------
    IFD CPU020
    move.l  #ATA_TimeOut*8,au_NumLoop(a3)   ;Number of loops x 8 for BUSY
    ENDC

    lea     ata_SlowReadNorm(pc),a0
    move.l  a0,au_ReadSub(a3)           ;Read routine
    lea     ata_SlowWriteNorm(pc),a0
    move.l  a0,au_WriteSub(a3)          ;Write routine
    lea     ata_SlowWriteNorm(pc),a0
    move.l  a0,au_FormatSub(a3)         ;Format routine
    lea     ata_Seek(pc),a0
    move.l  a0,au_SeekSub(a3)           ;Seek routine
    lea     ata_Eject(pc),a0
    move.l  a0,au_EjectSub(a3)          ;Eject routine
    lea     ata_ScsiCmd(pc),a0
    move.l  a0,au_ScsiSub(a3)           ;SCSI-Direct routine

.Atapi
    andi.b  #%11110000,d0               ;Keep the selection bits
    move.b  d0,au_DevMask(a3)           ;Unit select mask (ATA & ATAPI)

    andi.b  #ATAF_DEV,d0
    move.b  d0,au_OldDevMask(a3)        ;Unit select mask (ATA only)

    andi.b  #%00001111,d1               ;Keep the controller number
    move.b  d1,au_CtrlNumber(a3)

    ;-------- 68000 --------
    IFND CPU020
    move.w  d2,d1                       ;D1 : Unit number
    add.w   d1,d1
    add.w   d1,d1                       ;Unit number x 4
    ENDC

    move.l  ad_CfgDevAddr(a5),a0        ;"ConfigDev" structure address

    ;-------- 68020+ --------
    IFND CPU020
    move.l  (a0,d1.w),au_CfgDevAddr(a3) ;"ConfigDev" linked to the unit
    ENDC

    ;-------- 68020+ --------
    IFD CPU020
    move.l  (a0,d2.w*4),au_CfgDevAddr(a3) ;"ConfigDev" linked to the unit
    ENDC

    move.l  ad_BoardAddr(a5),a0         ;Board address

    ;-------- 68000 --------
    IFND CPU020
    move.l  (a0,d1.w),au_PortAddr(a3)   ;IDE port linked to the unit
    ENDC

    ;-------- 68020+ --------
    IFD CPU020
    move.l  (a0,d2.w*4),au_PortAddr(a3) ;IDE port linked to the unit
    ENDC

    bsr.w   UnitInfo                    ;Retrieve the unit info
    beq.b   .End                        ;Error : exit

    ;-------- 68000 --------
    IFND CPU020
    move.l  a3,ad_Units(a5,d1.w)        ;ApolloUnit structure address
    ENDC

    ;-------- 68020+ --------
    IFD CPU020
    move.l  a3,ad_Units(a5,d2.w*4)      ;ApolloUnit structure address
    ENDC

.End
    movem.l (sp)+,d1-d7/a0-a6           ;Restore registers
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                Return the RDB's block address                ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : Standard I/O Request

GetRdskLba
    move.l  IO_UNIT(a1),a0
    move.l  au_RDBSector(a0),d0         ;Block address of the RDB
    rts

;******************************************************************************
;********                                                              ********
;********              Return sector size (in power of 2!)             ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : Standard I/O Request

GetBlkSize
    moveq   #0,d0
    move.l  IO_UNIT(a1),a0
    move.b  au_SectShift(a0),d0         ;Sector size
    rts

;******************************************************************************
;********                                                              ********
;********                       Fast block copy                        ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A0.l : Source address
;A1.l : Destination address
;A3.l : ApolloUnit base address

CopyBlock
    movem.l d0-d7/a0-a6,-(sp)           ;Save all registers

    moveq   #11*4,d7                    ;D7: address increment
    move.l  au_SectSize(a3),d6
    lsr.w   #8,d6
    subq.w  #1,d6                       ;D6: number of 256-byte chunks
.CopyLoop
    movem.l (a0)+,d0-d5/a2-a6
    movem.l d0-d5/a2-a6,(a1)            ;1st transfer of 11 long words
    add.l   d7,a1
    movem.l (a0)+,d0-d5/a2-a6
    movem.l d0-d5/a2-a6,(a1)            ;2nd transfer of 11 long words
    add.l   d7,a1
    movem.l (a0)+,d0-d5/a2-a6
    movem.l d0-d5/a2-a6,(a1)            ;3rd transfer of 11 long words
    add.l   d7,a1
    movem.l (a0)+,d0-d5/a2-a6
    movem.l d0-d5/a2-a6,(a1)            ;4th transfer of 11 long words
    add.l   d7,a1
    movem.l (a0)+,d0-d5/a2-a6
    movem.l d0-d5/a2-a6,(a1)            ;5th transfer of 11 long words
    add.l   d7,a1
    movem.l (a0)+,d0-d5/a2-a4
    movem.l d0-d5/a2-a4,(a1)            ;One more transfer of 9 long words
    lea     9*4(a1),a1                  ;256 bytes : 5 * 11 + 9 long words
    dbra    d6,.CopyLoop                ;Loop

    movem.l (sp)+,d0-d7/a0-a6           ;Restore all registers
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********               AT-Apollo.device BeginIO() entry               ********
;********                                                              ********
;******************************************************************************

    IFD DEBUG
IMMEDIATES_CMD = %11111111111111111111111111111111
    ENDC

    IFND DEBUG
IMMEDIATES_CMD = %10000000001111111111000111100011
    ENDC

;Parameters:
;-----------
;A1.l : Standard I/O Request
;A6.l : AT-Apollo.device base address
  
BeginIO
    movem.l d0-d7/a0-a6,-(sp)           ;Save all registers

    move.b  #NT_MESSAGE,LN_TYPE(a1)     ;For WaitIO() correct behavior

    move.l  IO_UNIT(a1),a3              ;A3 : ApolloUnit base address
    move.l  ad_TaskData(a6),a4          ;A4 : TaskData structure
    move.l  ad_SysLib(a6),a5            ;A5 : ExecBase

;*************** Commands decode **********************************************

    move.w  IO_COMMAND(a1),d0           ;D0 : Command sent to the device
    cmpi.w  #APCMD_UNITPARAMS,d0        ;Command <= APCMD_UNITPARAMS ?
    bls.b   .Ok1                        ;Yes, valid command
    cmpi.w  #NSCMD_DEVICEQUERY,d0       ;NSCMD_DEVICEQUERY command ?
    beq.b   .Ok2                        ;Yes, valid command
    cmpi.w  #NSCMD_TD_READ64,d0         ;Command < NSCMD_TD_READ64 ?
    bcs.w   .Error                      ;Yes, invalid command
    cmpi.w  #NSCMD_TD_FORMAT64,d0       ;Command > NSCMD_TD_FORMAT64 ?
    bhi.b   .Error                      ;Yes, invalid command
    subi.w  #$8007,d0                   ;$C000-$C003 -> bits #24-27
.Ok2
    subi.w  #$3FE1,d0                   ;$4000       -> bit #31
.Ok1

    move.w  #$4000,$DFF09A              ;Disable interrupts
    addq.b  #1,IDNestCnt(a5)            ;Increment Exec counter

    move.l  #IMMEDIATES_CMD,d1
    btst    d0,d1                       ;Immediate command ?
    bne.b   .Immediate                  ;Yes, execute it right away

;    btst    #UNITB_STOPPED,UNIT_FLAGS(a4) ;Unit stopped ?
;    bne.b   .QueueMsg                   ;Yes, queue the message

    tst.b   au_AtapiDev(a3)             ;ATAPI protocol ?
    bne.b   .QueueMsg                   ;Yes, queue the message

    bset    #UNITB_ACTIVE,UNIT_FLAGS(a4) ;Set unit as active
    beq.b   .Immediate                  ;Unit was not active : immediate command

;*************** Deferred command execution ***********************************

.QueueMsg
    bset    #UNITB_INTASK,UNIT_FLAGS(a4) ;Command will run inside the unit task
    bclr    #IOB_QUICK,IO_FLAGS(a1)     ;Clear the "quick" bit

    subq.b  #1,IDNestCnt(a5)            ;Decrement Exec counter
    bge.b   .Enable1                    ;> 0 : skip next instruction
    move.w  #$C000,$DFF09A              ;Enable interrupts
.Enable1

    move.l  a4,a0
    move.l  a5,a6                       ;A6: ExecBase
    jsr     _LVOPutMsg(a6)              ;Send the I/O request

    movem.l (sp)+,d0-d7/a0-a6           ;Restore registers
    rts                                 ;End

;*************** Immediate command execution **********************************

.Immediate
;    bset    #UNITB_ACTIVE,UNIT_FLAGS(a4) ;The unit is active
    subq.b  #1,IDNestCnt(a5)            ;Decrement Exec counter
    bge.b   .Enable2                    ;> 0 : skip next instruction
    move.w  #$C000,$DFF09A              ;Enable interrupts
.Enable2

    bsr.b   PerformIO                   ;Execute the command

    bclr    #UNITB_ACTIVE,UNIT_FLAGS(a4) ;End of the command

    btst    #IOB_QUICK,IO_FLAGS(a1)     ;If "quick" bit is set :
    bne.b   .NoReply                    ;No answer
    move.l  a5,a6                       ;A6 : ExecBase
    jsr     _LVOReplyMsg(a6)            ;Otherwise, reply to the message
.NoReply

    movem.l (sp)+,d0-d7/a0-a6           ;Restore registers
    rts                                 ;End

;*************** Error : command is not supported *****************************

.Error
    move.b  #IOERR_NOCMD,IO_ERROR(a1)   ;Error code
    bset    #IOB_QUICK,IO_FLAGS(a1)     ;No waiting

    movem.l (sp)+,d0-d7/a0-a6           ;Restore registers
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                     I/O request dispatch                     ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : Standard I/O Request
;A3.l : ApolloUnit base address
;A4.l : TaskData structure
;A5.l : ExecBase
;A6.l : AT-Apollo.device base address

PerformIO
    clr.b   IO_ERROR(a1)                ;No error
    move.w  IO_COMMAND(a1),d0           ;D0 : I/O command
    cmpi.w  #NSCMD_DEVICEQUERY,d0       ;Check NSD device query command
    beq.w   cmd_DevQuery
    cmpi.w  #NSCMD_TD_READ64,d0         ;Check NSD 64-bit commands
    bcc.b   .Cmd64

    ;-------- Optimized code --------
    IFND CPU020
    add.w   d0,d0
    move.w  .Map32(pc,d0.w),d0          ;Indexed by the command value
    ENDC

    IFD CPU020
    move.w  .Map32(pc,d0.w*2),d0        ;Indexed by the command value
    ENDC

    jmp     .Map32(pc,d0.w)             ;Execute command

.Cmd64
    subi.w  #NSCMD_TD_READ64,d0

    ;-------- Optimized code --------
    IFND CPU020
    add.w   d0,d0
    move.w  .Map64(pc,d0.w),d0          ;Indexed by the command value
    ENDC

    IFD CPU020
    move.w  .Map64(pc,d0.w*2),d0        ;Indexed by the command value
    ENDC

    jmp     .Map64(pc,d0.w)             ;Execute command

;******************************************************************************
;********                                                              ********
;********                AT-Apollo.device command table                ********
;********                                                              ********
;******************************************************************************

                                    ;Command:           Code:   Mask:
                                    ;-------------------------------------
.Map64
    dc.w    cmd_Read64-.Map64       ;NSCMD_TD_READ64   ($C000) ($01000000)
    dc.w    cmd_Write64-.Map64      ;NSCMD_TD_WRITE64  ($C001) ($02000000)
    dc.w    cmd_Seek64-.Map64       ;NSCMD_TD_SEEK64   ($C002) ($04000000)
    dc.w    cmd_Write64-.Map64      ;NSCMD_TD_FORMAT64 ($C003) ($08000000)

.Map32
    dc.w    cmd_Invalid-.Map32      ;CMD_INVALID       ($0000) ($00000001)
    dc.w    cmd_Reset-.Map32        ;CMD_RESET         ($0001) ($00000002)
    dc.w    cmd_Read32-.Map32       ;CMD_READ          ($0002) ($00000004)
    dc.w    cmd_Write32-.Map32      ;CMD_WRITE         ($0003) ($00000008)
    dc.w    cmd_Update-.Map32       ;CMD_UPDATE        ($0004) ($00000010)
    dc.w    cmd_Reset-.Map32        ;CMD_CLEAR         ($0005) ($00000020)
    dc.w    cmd_Reset-.Map32        ;CMD_STOP          ($0006) ($00000040)
    dc.w    cmd_Reset-.Map32        ;CMD_START         ($0007) ($00000080)
    dc.w    cmd_Flush-.Map32        ;CMD_FLUSH         ($0008) ($00000100)
    dc.w    cmd_Reset-.Map32        ;TD_MOTOR          ($0009) ($00000200)
    dc.w    cmd_Seek32-.Map32       ;TD_SEEK           ($000A) ($00000400)
    dc.w    cmd_Write32-.Map32      ;TD_FORMAT         ($000B) ($00000800)
    dc.w    cmd_Remove-.Map32       ;TD_REMOVE         ($000C) ($00001000)
    dc.w    cmd_ChangeNum-.Map32    ;TD_CHANGENUM      ($000D) ($00002000)
    dc.w    cmd_ChangeState-.Map32  ;TD_CHANGESTATE    ($000E) ($00004000)
    dc.w    cmd_ProtStatus-.Map32   ;TD_PROTSTATUS     ($000F) ($00008000)
    dc.w    cmd_Invalid-.Map32      ;TD_RAWREAD        ($0010) ($00010000)
    dc.w    cmd_Invalid-.Map32      ;TD_RAWWRITE       ($0011) ($00020000)
    dc.w    cmd_GetDriveType-.Map32 ;TD_GETDRIVETYPE   ($0012) ($00040000)
    dc.w    cmd_GetNumTracks-.Map32 ;TD_GETNUMTRACKS   ($0013) ($00080000)
    dc.w    cmd_AddChangeInt-.Map32 ;TD_ADDCHANGEINT   ($0014) ($00100000)
    dc.w    cmd_RemChangeInt-.Map32 ;TD_REMCHANGEINT   ($0015) ($00200000)
    dc.w    cmd_GetGeometry-.Map32  ;TD_GETGEOMETRY    ($0016) ($00400000)
    dc.w    cmd_Eject-.Map32        ;TD_EJECT          ($0017) ($00800000)
    dc.w    cmd_Invalid-.Map32      ;     -            ($0018)      -
    dc.w    cmd_Invalid-.Map32      ;     -            ($0019)      -
    dc.w    cmd_Invalid-.Map32      ;     -            ($001A)      -
    dc.w    cmd_Invalid-.Map32      ;     -            ($001B)      -
    dc.w    cmd_ScsiDirect-.Map32   ;HD_SCSICMD        ($001C) ($10000000)
    dc.w    cmd_TestChanged-.Map32  ;APCMD_TESTCHANGED ($001D) ($20000000)
    dc.w    cmd_UnitParams-.Map32   ;APCMD_UNITPARAMS  ($001E) ($40000000)
;           cmd_DevQuery            ;NSCMD_DEVICEQUERY ($4000) ($80000000)

;******************************************************************************
;********                                                              ********
;********               AT-Apollo.device AbortIO() entry               ********
;********                                                              ********
;******************************************************************************

AbortIO
    moveq   #0,d0
    rts

;******************************************************************************
; -----------       BEGIN OF THE DRIVE LOW-LEVEL I/O ROUTINES       -----------
;******************************************************************************

;Parameters:
;-----------
;A1 : Standard I/O Request                 (must be saved)
;A3 : ApolloUnit base address
;A4 : TaskData structure                   (must be saved)
;A5 : ExecBase                             (must be saved)
;A6 : AT-Apollo.device base address        (must be saved)

;******************************************************************************
;********                                                              ********
;********                       Invalid command                        ********
;********                                                              ********
;******************************************************************************

cmd_Invalid
    move.b  #IOERR_NOCMD,IO_ERROR(a1)   ;Error : command is not supported
    rts

;******************************************************************************
;********                                                              ********
;********                        Reset command                         ********
;********                                                              ********
;******************************************************************************

cmd_Reset
    clr.l   IO_ACTUAL(a1)
    rts

;******************************************************************************
;********                                                              ********
;********                     64-bit read command                      ********
;********                                                              ********
;******************************************************************************

cmd_Read64
    move.b  au_SectShift(a3),d2         ;D2: Logical shift (9 or 11)
    move.l  IO_OFFSET(a1),d0            ;D0: Position [31..0]
    move.l  IO_ACTUAL(a1),d1            ;D1: Position [63..32]
    lsr.l   d2,d0
    ror.l   d2,d1
    or.l    d1,d0                       ;D0: Position / Block size = LBA
    bra.b   jmp_Read

;******************************************************************************
;********                                                              ********
;********                     32-bit read command                      ********
;********                                                              ********
;******************************************************************************

cmd_Read32
    move.b  au_SectShift(a3),d2         ;D2: Logical shift (9 or 11)
    move.l  IO_OFFSET(a1),d0            ;D0: Position [31..0]
    lsr.l   d2,d0                       ;D0: Position / Block size = LBA

jmp_Read
    move.l  IO_LENGTH(a1),d1
    lsr.l   d2,d1                       ;D1: Number of blocks

    movem.l a2/a4,-(sp)                 ;Save A2 & A4
    move.l  IO_DATA(a1),a0              ;A0: Buffer pointer
    move.l  au_WCacheTags(a3),a2        ;A2: Write cache tags
    move.l  au_WCacheFlags(a3),a4       ;A4: Write cache flags

;*************** Interrupts management ****************************************

    tst.b   au_IntDisable(a3)           ;Check the interrupts disable option
    beq.b   .IntEna1                    ;Not set: skip the next 2 lines
    move.w  #$4000,$DFF09A              ;Disable interrupts
    addq.b  #1,IDNestCnt(a5)            ;Increment Exec counter
.IntEna1

;*************** Read one block from the write cache **************************

    moveq   #1,d2
    cmp.l   d2,d1                       ;One block read ?
    bne.w   .NoReadCache                ;No, jump to ".NoReadCache"
    tst.b   au_WCacheOn(a3)             ;Write cache activated ?
    beq.b   .NoWriteCache               ;No, jump to ".NoWriteCache"

    move.w  d0,d2                       ;D2: Block's LBA
    and.w   au_WCacheSize(a3),d2        ;D2: Buffer index in the cache

    ;-------- Optimized code --------
    IFND CPU020
    add.l   d2,d2
    tst.b   cf_Valid(a4,d2.l)           ;Valid buffer ?
    ENDC

    IFD CPU020
    tst.b   cf_Valid(a4,d2.l*2)         ;Valid buffer ?
    ENDC

    beq.b   .NoWriteCache               ;No, the block is not in the cache

    ;-------- Optimized code --------
    IFND CPU020
    add.l   d2,d2
    add.l   d2,d2
    cmp.l   ct_Offset(a2,d2.l),d0       ;Same location on drive ?
    ENDC

    IFD CPU020
    cmp.l   ct_Offset(a2,d2.l*8),d0     ;Same location on drive ?
    ENDC

    bne.b   .NoWriteCache               ;No, the block is not in the cache
    move.l  a1,-(sp)                    ;Save A1
    move.l  a0,a1                       ;A1: Destination address

    ;-------- Optimized code --------
    IFND CPU020
    move.l  ct_Data(a2,d2.l),a0         ;A0: Source address
    ENDC

    IFD CPU020
    move.l  ct_Data(a2,d2.l*8),a0       ;A0: Source address
    ENDC

    bsr.w   CopyBlock                   ;Copy the block
    move.l  (sp)+,a1                    ;Restore A1
    move.l  au_SectSize(a3),IO_ACTUAL(a1) ;One block read
    bra.w   .End                        ;End
.NoWriteCache

;*************** Read one block from the read cache ***************************

    tst.b   au_RCacheOn(a3)             ;Read cache activated ?
    beq.b   .NoReadCache                ;No, jump to ".NoReadCache"

    move.l  au_RCacheBlock(a3),d2       ;D2: Cache location on disk
    cmp.l   d2,d0                       ;Data location > Cache location ?
    bcs.b   .OutCache                   ;No, start a new cache read
    add.l   au_RCacheSize(a3),d2        ;+ Cache size
    cmp.l   d2,d0                       ;Data location > End of cache ?
    bcc.b   .OutCache                   ;Yes, start a new cache read
    move.b  #1,au_RCacheCount(a3)       ;1 read before cache fetch
    sub.l   au_RCacheBlock(a3),d0
    move.b  au_SectShift(a3),d1
    lsl.l   d1,d0                       ;D0: Data offset in cache
    move.l  a1,-(sp)                    ;Save A1
    move.l  a0,a1                       ;A1: Destination address
    move.l  au_RCacheAddr(a3),a0        ;A0: Read cache address
    add.l   d0,a0                       ;A0: + Offset = Source address
    bsr.w   CopyBlock                   ;Copy one block
    move.l  (sp)+,a1                    ;Restore A1
    move.l  au_SectSize(a3),IO_ACTUAL(a1) ;One block read
    bra.b   .End                        ;End

;*************** Prepare cache read fetch *************************************

.OutCache
    cmp.l   au_RCacheNext(a3),d0        ;Data location = next read cache location ?
    beq.b   .ReadCache                  ;Yes, fetch the read cache
    move.l  d0,au_RCacheNext(a3)        ;Next read cache location:
    addq.l  #1,au_RCacheNext(a3)        ;Data location + 1
    move.b  #4,au_RCacheCount(a3)       ;4 reads before cache fetch

;*************** Read data from drive *****************************************

.NoReadCache
    movem.l d0/d1,-(sp)                 ;Save D0 & D1
    jsr     au_ReadJmp(a3)              ;Read the blocks
    move.b  d0,IO_ERROR(a1)             ;Error code
    move.l  d1,IO_ACTUAL(a1)            ;Number of bytes read
    movem.l (sp)+,d0/d1                 ;Restore D0 & D1

;*************** Take care of buffers not yet written *************************

    tst.b   au_WCacheUpd(a3)            ;Buffers already updated ?
    beq.b   .End                        ;Yes, exit

    move.l  a1,-(sp)                    ;Save A1
    move.w  au_WCacheSize(a3),d3        ;D3: Number of buffers - 1
    move.b  au_SectShift(a3),d4         ;D4: Block size (Log 2)
    move.l  a0,d5                       ;D5: Data address in memory
.Loop
    tst.b   (a4)                        ;Buffer not "dirty" ?
    beq.b   .NoCopy                     ;Yes, no copy
    move.l  (a2),d2                     ;D2: Buffer location on drive
    sub.l   d0,d2                       ;- Data location on drive
    bcs.b   .NoCopy                     ;Negative : no copy
    cmp.l   d1,d2                       ;>= Data size ? 
    bcc.b   .NoCopy                     ;Yes, no copy
    lsl.l   d4,d2
    add.l   d5,d2                       ;+ Data address in memory
    move.l  ct_Data(a2),a0              ;A0: Source address
    move.l  d2,a1                       ;A1: Destination address
    bsr.w   CopyBlock                   ;Copy the block
.NoCopy
    addq.l  #ct_SIZEOF,a2
    addq.l  #cf_SIZEOF,a4               ;Next buffer
    dbra    d3,.Loop                    ;Loop
    move.l  (sp)+,a1                    ;Restore A1

;*************** End of command : interrupts management ***********************

.End
    movem.l (sp)+,a2/a4                 ;Restore A2 & A4
    tst.b   au_IntDisable(a3)           ;Check the interrupts disable option
    beq.b   .IntEna2                    ;Not set: skip the next 3 lines
    subq.b  #1,IDNestCnt(a5)            ;Decrement Exec counter
    bge.b   .IntEna2                    ;> 0 : skip next instruction
    move.w  #$C000,$DFF09A              ;Enable interrupts
.IntEna2
    rts                                 ;End of the I/O command

;*************** Read cache fetch *********************************************

.ReadCache
    addq.l  #1,au_RCacheNext(a3)        ;+ 1 to the read cache location
    subq.b  #1,au_RCacheCount(a3)       ;Decrement the access count
    bne.b   .NoReadCache                ;Not null : no cache fetch yet
    movem.l d0/d1/a0,-(sp)              ;Save D0, D1 & A0
    move.l  au_RCacheSize(a3),d1        ;D1: Read cache size
    add.l   d1,d0
    move.l  d0,au_RCacheNext(a3)        ;Next read cache location
    move.l  au_RCacheAddr(a3),a0        ;A0: Read cache address
    move.l  (sp),d0                     ;D0: Current read cache location
    jsr     au_ReadJmp(a3)              ;Read cache fetch
    tst.b   d0                          ;Error code check
    movem.l (sp)+,d0/d1/a0              ;Restore D0, D1 & A0
    beq.b   .Copy                       ;No error : copy the block

    moveq   #-1,d2
    move.l  d2,au_RCacheBlock(a3)       ;Otherwise, invalid read cache
    jsr     au_ReadJmp(a3)              ;Read the blocks
    move.b  d0,IO_ERROR(a1)             ;Error code
    move.l  d1,IO_ACTUAL(a1)            ;Number of bytes read
    bra.b   .End                        ;End

;*************** Block copy after the read cache fetch ************************

.Copy
    move.l  d0,au_RCacheBlock(a3)       ;Valid read cache
    move.l  a1,-(sp)                    ;Save A1
    move.l  a0,a1                       ;A1: Destination address
    move.l  au_RCacheAddr(a3),a0        ;A0: Source address
    bsr.w   CopyBlock                   ;Copy one block
    move.l  (sp)+,a1                    ;Restore A1
    move.l  au_SectSize(a3),IO_ACTUAL(a1) ;One block read
    bra.b   .End                        ;End

;******************************************************************************
;********                                                              ********
;********                     64-bit write command                     ********
;********                                                              ********
;******************************************************************************

cmd_Write64
    tst.b   au_DevType(a3)              ;Direct access peripheral ?
    bne.b   err_WriteProt               ;No, error
    move.b  au_SectShift(a3),d2         ;D2: Logical shift (9 or 11)
    move.l  IO_OFFSET(a1),d0            ;D0: Position [31..0]
    move.l  IO_ACTUAL(a1),d1            ;D1: Position [63..32]
    lsr.l   d2,d0
    ror.l   d2,d1
    or.l    d1,d0                       ;D0: Position/Block size = LBA
    bra.b   jmp_Write

err_WriteProt
    move.b  #TDERR_WriteProt,IO_ERROR(a1)
    clr.l   IO_ACTUAL(a1)
    rts

;******************************************************************************
;********                                                              ********
;********                     32-bit write command                     ********
;********                                                              ********
;******************************************************************************

cmd_Write32
    tst.b   au_DevType(a3)              ;Direct access peripheral ?
    bne.b   err_WriteProt               ;No, error
    move.b  au_SectShift(a3),d2         ;D2: Logical shift (9 or 11)
    move.l  IO_OFFSET(a1),d0            ;D0: Position [31..0]
    lsr.l   d2,d0                       ;D0: Position/Block size = LBA

jmp_Write
    move.l  IO_LENGTH(a1),d1
    lsr.l   d2,d1                       ;D1: Number of blocks

    movem.l a2/a4,-(sp)                 ;Save A2 & A4
    move.l  IO_DATA(a1),a0              ;A0: Buffer address
    move.l  au_WCacheTags(a3),a2        ;A2: Write cache tags
    move.l  au_WCacheFlags(a3),a4       ;A4: Write cache flags

;*************** Interrupts management ****************************************

    tst.b   au_IntDisable(a3)           ;Check the interrupts disable option
    beq.b   .IntEna1                    ;Not set: skip the next 2 lines
    move.w  #$4000,$DFF09A              ;Disable interrupts
    addq.b  #1,IDNestCnt(a5)            ;Increment Exec counter
.IntEna1

;*************** Conflict management with the read cache **********************

    tst.b   au_RCacheOn(a3)             ;Read cache activated ?
    beq.b   .NoReadCache                ;No, jump to ".NoReadCache"

    move.l  au_RCacheBlock(a3),d2       ;D2: Cache location on disk
    sub.l   d0,d2                       ;- Data location on drive
    bcs.b   .Negative                   ;Negative : jump to ".Negative"
    cmp.l   d1,d2                       ;>= Data size ? 
    bcc.b   .NoReadCache                ;Yes, no conflict with the read cache
    bra.b   .DisRCache                  ;No, there is a conflict
.Negative
    neg.l   d2                          ;Positive number
    cmp.l   au_RCacheSize(a3),d2        ;>= Cache size ?
    bcc.b   .NoReadCache                ;Yes, no conflict with the read cache
.DisRCache
    moveq   #-1,d2
    move.l  d2,au_RCacheBlock(a3)       ;Conflict : invalidate the read cache

;*************** Conflict management with the write cache *********************

.NoReadCache
    tst.b   au_WCacheOn(a3)             ;Write cache activated ?
    beq.b   .NoWriteCache               ;No, jump to ".NoWriteCache"
    cmpi.l  #1,d1                       ;One block write ?
    beq.b   .WriteOne                   ;Yes, jump to ".WriteOne"

    move.w  au_WCacheSize(a3),d3        ;D3: Number of buffers - 1
.Loop
    tst.b   cf_Valid(a4)                ;Valid buffer ?
    beq.b   .Next                       ;No, next buffer
    move.l  (a2),d2                     ;D2: Buffer location on drive
    sub.l   d0,d2                       ;- Data location on drive
    bcs.b   .Next                       ;Negative : next buffer
    cmp.l   d1,d2                       ;>= Data size ? 
    bcc.b   .Next                       ;Yes, next buffer
    sf.b    (a4)                        ;Update done
    sf.b    cf_Valid(a4)                ;Invalidate the buffer
.Next
    addq.l  #ct_SIZEOF,a2
    addq.l  #cf_SIZEOF,a4               ;Next buffer
    dbra    d3,.Loop                    ;Loop

;*************** Write data to the drive **************************************

.NoWriteCache
    jsr     au_WriteJmp(a3)             ;Write data routine
    move.b  d0,IO_ERROR(a1)             ;Error code
    move.l  d1,IO_ACTUAL(a1)            ;Number of bytes written

;*************** End of command : interrupts management ***********************

.End
    movem.l (sp)+,a2/a4                 ;Restore A2 & A4
    tst.b   au_IntDisable(a3)           ;Check the interrupts disable option
    beq.b   .IntEna2                    ;Not set: skip the next 3 lines
    subq.b  #1,IDNestCnt(a5)            ;Decrement Exec counter
    bge.b   .IntEna2                    ;> 0 : skip next instruction
    move.w  #$C000,$DFF09A              ;Enable interrupts
.IntEna2
    rts                                 ;End of the I/O command

;*************** Write a block into the cache *********************************

.WriteOne
    move.l  d0,d2                       ;D2: Block's LBA
    and.w   au_WCacheSize(a3),d2        ;D2: Buffer index in the cache

    IFND CPU020
    add.w   d2,d2                       ;D2: N° x 2 -> Flags index
    move.w  d2,d3
    add.w   d3,d3
    add.w   d3,d3                       ;D3: N° x 8 -> Tags index
    ENDC

    ;-------- Optimized code --------
    IFND CPU020
    tst.b   cf_Update(a4,d2.w)          ;Update done ?
    ENDC

    IFD CPU020
    tst.b   cf_Update(a4,d2.w*2)        ;Update done ?
    ENDC

    beq.b   .NoUpdate                   ;Yes, do not write this buffer

    ;-------- Optimized code --------
    IFND CPU020
    cmp.l   ct_Offset(a2,d3.w),d0       ;Same location on drive ?
    ENDC

    IFD CPU020
    cmp.l   ct_Offset(a2,d2.w*8),d0     ;Same location on drive ?
    ENDC

    beq.b   .NoUpdate                   ;Yes, do not write this buffer
    movem.l d0/a0,-(sp)                 ;Save D0 & A0

    ;-------- Optimized code --------
    IFND CPU020
    move.l  ct_Data(a2,d3.w),a0         ;A0: Buffer address
    move.l  ct_Offset(a2,d3.w),d0       ;D0: Buffer location on drive
    ENDC

    IFD CPU020
    move.l  ct_Data(a2,d2.w*8),a0       ;A0: Buffer address
    move.l  ct_Offset(a2,d2.w*8),d0     ;D0: Buffer location on drive
    ENDC

    moveq   #1,d1                       ;D1: One block to write
    jsr     au_WriteJmp(a3)             ;Write the block
    movem.l (sp)+,d0/a0                 ;Restore D0 & A0
.NoUpdate

    move.l  a1,-(sp)                    ;Save A1

    ;-------- Optimized code --------
    IFND CPU020
    st.b    cf_Update(a4,d2.w)          ;Buffer is "dirty"
    st.b    cf_Valid(a4,d2.w)           ;Valid buffer
    move.l  d0,ct_Offset(a2,d3.w)       ;Buffer location on drive
    move.l  ct_Data(a2,d3.w),a1         ;A1: Destination address
    ENDC

    IFD CPU020
    st.b    cf_Update(a4,d2.w*2)        ;Buffer is "dirty"
    st.b    cf_Valid(a4,d2.w*2)         ;Valid buffer
    move.l  d0,ct_Offset(a2,d2.w*8)     ;Buffer location on drive
    move.l  ct_Data(a2,d2.w*8),a1       ;A1: Destination address
    ENDC

    bsr.w   CopyBlock                   ;Copy the block
    move.l  (sp)+,a1                    ;Restore A1
    st.b    au_WCacheUpd(a3)            ;Cache contains "dirty" buffers
    move.l  au_SectSize(a3),IO_ACTUAL(a1) ;One block written
    bra.b   .End                        ;End

;******************************************************************************
;********                                                              ********
;********                     Force buffers update                     ********
;********                                                              ********
;******************************************************************************

cmd_Update
    tst.b   au_WCacheUpd(a3)            ;Buffers up to date ?
    beq.b   .NoUpdate                   ;Yes, end of command

;*************** Update loop **************************************************

    move.l  a1,-(sp)                    ;Save A1
    move.l  au_WCacheTags(a3),a1        ;A1: Write cache tags
    move.l  au_WCacheFlags(a3),a2       ;A2: Write cache flags
    move.w  au_WCacheSize(a3),d2        ;D2: Number of buffers - 1
.Loop
    tst.b   (a2)                        ;"dirty"content in buffer ?
    beq.b   .NoWrite                    ;No, jump to ".NoWrite"
    movem.l (a1),d0/a0                  ;D0: Buffer location on drive
                                        ;A0: Data address in memory
    moveq   #1,d1                       ;D1: One block to write
    jsr     au_WriteJmp(a3)             ;Write the buffer
    tst.b   d0                          ;Error code check
    bne.b   .Error                      ;Error : exit
    sf.b    (a2)                        ;Buffer not "dirty" anymore
.NoWrite
    addq.l  #ct_SIZEOF,a1
    addq.l  #cf_SIZEOF,a2               ;Next buffer
    dbra    d2,.Loop                    ;Loop
    sf.b    au_WCacheUpd(a3)            ;Write cache up to date

;*************** End of command ***********************************************

.Error
    move.l  (sp)+,a1                    ;Restore A1

.NoUpdate
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                     64-bit seek command                      ********
;********                                                              ********
;******************************************************************************

cmd_Seek64
    move.b  au_SectShift(a3),d2         ;D2: Logical shift (9 or 11)
    move.l  IO_OFFSET(a1),d0            ;D0: Position [31..0]
    move.l  IO_ACTUAL(a1),d1            ;D1: Position [63..32]
    lsr.l   d2,d0
    ror.l   d2,d1
    or.l    d1,d0                       ;D0: Position / Block size = LBA
    bra.b   jmp_Seek

;******************************************************************************
;********                                                              ********
;********                     32-bit seek command                      ********
;********                                                              ********
;******************************************************************************

cmd_Seek32
    move.b  au_SectShift(a3),d2         ;D2: Logical shift (9 or 11)
    move.l  IO_OFFSET(a1),d0            ;D0: Position [31..0]
    lsr.l   d2,d0                       ;D0: Position/Block size = LBA

jmp_Seek
    jsr     au_SeekJmp(a3)              ;Head seek
    move.b  d0,IO_ERROR(a1)             ;Error code
    rts

;******************************************************************************
;********                                                              ********
;********                   Number of media changes                    ********
;********                                                              ********
;******************************************************************************

cmd_ChangeNum
    move.l  au_ChangeNum(a3),IO_ACTUAL(a1)
    rts

;******************************************************************************
;********                                                              ********
;********                        Media present                         ********
;********                                                              ********
;******************************************************************************

cmd_ChangeState
    moveq   #0,d0
    tst.b   au_DiskPresent(a3)
    bne.b   .End
    moveq   #1,d0
.End
    move.l  d0,IO_ACTUAL(a1)
    rts

;******************************************************************************
;********                                                              ********
;********   "DiskChange" software interrupts added by these commands   ********
;********                                                              ********
;******************************************************************************

cmd_Remove
    tst.l    au_RemoveInt(a3)
    beq.b      .Ok
    move.b   #TDERR_DriveInUse,IO_ERROR(a1)
    rts
.Ok
    move.l   IO_DATA(a1),au_RemoveInt(a3)
    rts

cmd_AddChangeInt
    move.l   a1,-(sp)

    exg      a5,a6
    jsr      _LVOForbid(a6)

    lea      au_SoftList(a3),a0
    move.l   (sp),a1
    move.l   (a0),d0
    move.l   a1,(a0)
    movem.l  d0/a0,(a1)
    move.l   d0,a0
    move.l   a1,LN_PRED(a0)

    jsr      _LVOPermit(a6)
    exg      a5,a6

    move.l   (sp)+,a1
    bclr     #IOB_QUICK,IO_FLAGS(a1)
    bclr     #UNITB_ACTIVE,UNIT_FLAGS(a4)
    addq.l   #4,sp
    movem.l  (sp)+,d0-d7/a0-a6
    rts

;******************************************************************************
;********                                                              ********
;********       "DiskChange" software interrupt removal command        ********
;********                                                              ********
;******************************************************************************

cmd_RemChangeInt
    move.l   a1,-(sp)

    exg      a5,a6
    jsr      _LVOForbid(a6)

    lea      au_SoftList(a3),a0
    move.l   (sp),a1
    move.l   (a1)+,a0
    move.l   (a1),a1
    move.l   a0,(a1)
    move.l   a1,LN_PRED(a0)

    jsr      _LVOPermit(a6)
    exg      a5,a6

    move.l   (sp)+,a1
    rts

;******************************************************************************
;********                                                              ********
;********                  Drive type identification                   ********
;********                                                              ********
;******************************************************************************

cmd_GetDriveType
    move.l  #1,IO_ACTUAL(a1)		    ;Type : 3"5 drive
    rts

;******************************************************************************
;********                                                              ********
;********                       Number of tracks                       ********
;********                                                              ********
;******************************************************************************

cmd_GetNumTracks
    moveq   #0,d0
    move.w  au_Cylinders(a3),d0         ;Number of tracks
    move.l  d0,IO_ACTUAL(a1)
    rts

;******************************************************************************
;********                                                              ********
;********                      I/O request flush                       ********
;********                                                              ********
;******************************************************************************

cmd_Flush
    move.l  a1,-(sp)                    ;Save A1
    exg     a5,a6                       ;A5: Device, A6: ExecBase
    jsr     _LVOForbid(a6)              ;Stop multi-tasking
.Loop
    move.l  a4,a0
    jsr     _LVOGetMsg(a6)              ;Get a message
    tst.l   d0
    beq.b   .End                        ;No more messages : exit
    move.l  d0,a1
    move.b  #IOERR_ABORTED,IO_ERROR(a1) ;Error : aborted command
    jsr     _LVOReplyMsg(a6)            ;Reply to message
    bra.b   .Loop                       ;Loop
.End
    jsr     _LVOPermit(a6)              ;Resume multi-tasking
    exg     a5,a6                       ;A5: ExecBase, A6: Device
    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                 Write protect status command                 ********
;********                                                              ********
;******************************************************************************

cmd_ProtStatus
    clr.l   IO_ACTUAL(a1)
    tst.b   au_DevType(a3)              ;Direct access peripheral ?
    beq.b   .End                        ;Yes, exit
    not.l   IO_ACTUAL(a1)               ;No, write protect (CD-ROM drive)
.End
    rts

;******************************************************************************
;********                                                              ********
;********                     Media eject command                      ********
;********                                                              ********
;******************************************************************************

cmd_Eject
    tst.b   au_Removable(a3)            ;Removable media ?
    beq.b   .End                        ;No, end of the command
    jsr     au_EjectJmp(a3)             ;Yes, eject media
    move.b  d0,IO_ERROR(a1)             ;Error code
.End
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                    Drive geometry command                    ********
;********                                                              ********
;******************************************************************************

cmd_GetGeometry
    move.l  IO_DATA(a1),a0
    move.l  IO_LENGTH(a1),d0            ;D0: Response length
    moveq   #dg_SIZEOF,d2
    cmpi.l  d2,d0                       ;= sizeof(DriveGeometry) ?
    beq.b   .Standard                   ;Yes, CBM defined info
    move.w  #BLOCK_SIZE,d2
    cmpi.l  d2,d0                       ;= BLOCK_SIZE ?
    beq.b   .Apollo                     ;Yes, Apollo-Install info
    addq.l  #2,d2
    cmpi.l  d2,d0                       ;= BLOCK_SIZE + 2 ?
    beq.b   .Ata                        ;Yes, ATA-3 auto-detect
.Error
    move.b  #TDERR_NotSpecified,IO_ERROR(a1) ;No, error
    rts                                 ;End 

.Ata
    bsr.w   ata_Identify                ;ATA-3 disk identify
    beq.b   .Error                      ;An error has occured
    move.l  d2,IO_ACTUAL(a1)            ;Returned data length
    rts                                 ;End

.Apollo
    lea     au_ModelID(a3),a2
    moveq   #7,d0                       ;8 long words (or 32 bytes) to copy
.Loop
    move.l  (a2)+,(a0)+                 ;Copy one long word
    dbra    d0,.Loop                    ;Loop
    move.l  au_Blocks(a3),d0
    move.b  au_SectShift(a3),d1
    lsl.l   d1,d0
    move.l  d0,(a0)+                    ;Number of bytes
    move.b  au_Heads(a3),(a0)+          ;Number of heads
    move.b  au_SectorsT(a3),(a0)+       ;Number of sectors per track
    move.w  au_Cylinders(a3),(a0)+      ;Number of cylinders
    move.w  au_SectSize+2(a3),(a0)      ;Sector size

    move.l  d2,IO_ACTUAL(a1)            ;Returned data length
    rts                                 ;End
    
.Standard
    move.l  au_SectSize(a3),(a0)+       ;Sector size
    move.l  au_Blocks(a3),(a0)+         ;Total number of blocks
    moveq   #0,d0
    move.w  au_Cylinders(a3),d0
    move.l  d0,(a0)+                    ;Number of cylinders
    move.w  au_SectorsC(a3),d0
    move.l  d0,(a0)+                    ;Number of sectors per cylinder
    moveq   #0,d0
    move.b  au_Heads(a3),d0
    move.l  d0,(a0)+                    ;Number of heads
    move.b  au_SectorsT(a3),d0
    move.l  d0,(a0)+                    ;Number of sectors per track
    move.l  #MEMF_PUBLIC,(a0)+          ;Memory type for the buffers
    move.b  au_DevType(a3),(a0)+        ;Peripheral type
    move.b  au_Removable(a3),d0
    andi.b  #DGF_REMOVABLE,d0
    move.b  d0,(a0)+                    ;Unit flags
    clr.w   (a0)
    move.l  d2,IO_ACTUAL(a1)            ;Returned data length
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********             Apollo parameters set/clear command              ********
;********                                                              ********
;******************************************************************************

cmd_UnitParams
    tst.l   IO_OFFSET(a1)               ;Reading parameters?
    bne.b   .Write                      ;No, writing parameters

    move.l  au_RCacheSize(a3),d0        ;D0 : Read cache size
    lsr.l   #3,d0                       ;/ 8
    lsl.l   #8,d0

    move.w  au_WCacheSize(a3),d1        ;D1 : Write cache size
.Loop
    addq.b  #1,d0
    lsr.w   #1,d1
    bne.b   .Loop                       ;Log 2 computation
    swap    d0

    move.b  au_Flags(a3),d0             ;Apollo flags

    tst.b   au_Swapped(a3)
    beq.b   .NoSwap
    bset    #AUB_SWAP,d0                ;Swapped data
.NoSwap

    tst.b   au_SlowDevice(a3)
    beq.b   .NoSlow
    bset    #AUB_SLOW,d0                ;Slow peripheral
.NoSlow

    rts                                 ;End

.Write
    bsr.w   cmd_Update                  ;Flush the write caches
    exg     a5,a6                       ;A5 : AT-Apollo.device, A6 : ExecBase
    bsr.w   ClrParams                   ;Clear the old Apollo parameters
    move.l  IO_ACTUAL(a1),d0            ;D0 : new Apollo parameters
    bsr.w   SetParams                   ;Set the new Apollo parameters
    exg     a5,a6                       ;A5 : ExecBase, A6 : AT-Apollo.device
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                  Media changed test command                  ********
;********                                                              ********
;******************************************************************************

cmd_TestChanged
    tst.b   au_AtapiDev(a3)             ;ATAPI protocol ?
    beq.b   .NoTest                     ;No, skip the test
    tst.b   au_Removable(a3)            ;Removable media ?
    beq.b   .NoTest                     ;No, skip the test
    tst.b   au_Used(a3)                 ;Unit used lately ?
    bne.b   .NoTest                     ;No, skip the test
    bsr.w   atapi_TestUnit              ;"Test Unit Ready" command
    tst.b   d0                          ;Not ready ?
    bne.b   .NotPresent                 ;Yes, media not present
    cmpi.b  #6,au_SenseKey(a3)          ;No, sense Key = 6 ? (Unit attention)
    beq.b   .Present                    ;Yes, media present

;*************** Media not present ********************************************

.NotPresent
    tst.b   au_DiskPresent(a3)          ;Media not present already detected ?
    beq.b   .NoTest                     ;Yes, do nothing
    sf.b    au_DiskPresent(a3)          ;No, clear the flag
    bra.b   .Changed                    ;Software interrupts generation

;*************** Media present ************************************************

.Present
    tst.b   au_DiskPresent(a3)          ;Media present already detected ?
    bne.b   .NoTest                     ;Yes, do nothing
    st.b    au_DiskPresent(a3)          ;No, set the flag

;*************** Media changed ************************************************

.Changed
    moveq   #-1,d0
    move.l  d0,au_RCacheBlock(a3)       ;Invalidate caches
    addq.l  #1,au_ChangeNum(a3)         ;Increment the counter

    movem.l a1/a2,-(sp)
    exg     a5,a6
    jsr     _LVOForbid(a6)              ;Stop multi-tasking

    move.l  au_RemoveInt(a3),d0
    beq.b   .NoSoft
    move.l  d0,a1
    jsr     _LVOCause(a6)               ;Trigger a software interrupt
.NoSoft

    move.l  au_SoftList(a3),a2          ;List of software interrupts
.SoftLoop
    move.l  (a2),d0
    beq.b   .SoftEnd
    move.l  IO_DATA(a2),a1
    move.l  d0,a2
    jsr     _LVOCause(a6)               ;Trigger a software interrupt
    bra.b   .SoftLoop
.SoftEnd

    jsr     _LVOPermit(a6)              ;Resume multi-tasking
    exg     a5,a6
    movem.l (sp)+,a1/a2

.NoTest
    sf.b    au_Used(a3)                 ;Clear the flag
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                       SCSI-2 commands                        ********
;********                                                              ********
;******************************************************************************

;A1.l : Standard I/O Request
;A3.l : ApolloUnit base address

cmd_ScsiDirect
    moveq   #scsi_SIZEOF,d0
    move.l  d0,IO_ACTUAL(a1)
    move.l  IO_DATA(a1),a2              ;A2: SCSICmd structure

;*************** PowerVisor v1.43 debugging ***********************************

    IF PVDBG=1
    movem.l d0-d2/a0-a6,-(sp)
    move.l  au_Device(a3),a5
    tst.l   ad_PVBase(a5)
    beq.w   .NoDebug1
    tst.l   ad_PVPort(a5)
    beq.w   .NoDebug1

    lea     CommandString(pc),a0
    lea     Digit(pc),a1
    move.l  scsi_Command(a2),a4
    bsr.w   IdentifyCmd
    move.w  scsi_CmdLength(a2),d0
    subq.w  #1,d0
    moveq   #0,d1
.CmdLoop
    move.b  #"$",(a0)+
    move.b  (a4)+,d1
    move.w  d1,d2
    lsr.b   #4,d1
    andi.b  #%00001111,d2
    move.b  (a1,d1.w),(a0)+
    move.b  (a1,d2.w),(a0)+
    move.b  #",",(a0)+
    dbra    d0,.CmdLoop
    clr.b   -(a0)

    move.w  scsi_SenseLength(a2),-(sp)
    move.l  scsi_SenseData(a2),-(sp)
    moveq   #0,d0
    move.b  scsi_Flags(a2),d0
    move.w  d0,-(sp)
    move.w  scsi_CmdLength(a2),-(sp)
    pea     CommandString(pc)
    move.l  scsi_Length(a2),-(sp)
    move.l  scsi_Data(a2),-(sp)
    move.l  ad_CmdStr(a5),-(sp)

    move.l  ad_SysLib(a5),a6
    lea     FormatString1(pc),a0
    move.l  sp,a1
    lea     PutChProc(pc),a2
    lea     OutputString(pc),a3
    jsr     _LVORawDoFmt(a6)
    lea     26(sp),sp
    move.l  ad_PVBase(a5),a6
    move.l  ad_PVPort(a5),a0
    lea     OutputString(pc),a1
    jsr     _LVOPP_Print(a6)

.NoDebug1
    movem.l (sp)+,d0-d2/a0-a6
    ENDIF

    jsr     au_ScsiJmp(a3)

;*************** PowerVisor v1.43 debugging ***********************************

    IF PVDBG=1
    movem.l d0-d2/a0-a6,-(sp)
    move.l  au_Device(a3),a5
    tst.l   ad_PVBase(a5)
    beq.w   .NoDebug2
    tst.l   ad_PVPort(a5)
    beq.w   .NoDebug2

    move.w  scsi_SenseActual(a2),d2
    move.l  scsi_SenseData(a2),a4

    moveq   #0,d0
    move.b  scsi_Status(a2),d0
    move.w  d0,-(sp)
    move.w  d2,-(sp)
    move.w  scsi_CmdActual(a2),-(sp)
    move.l  scsi_Actual(a2),-(sp)

    move.l  ad_SysLib(a5),a6
    lea     FormatString2(pc),a0
    move.l  sp,a1
    lea     PutChProc(pc),a2
    lea     OutputString(pc),a3
    jsr     _LVORawDoFmt(a6)
    lea     10(sp),sp
    move.l  ad_PVBase(a5),a6
    move.l  ad_PVPort(a5),a0
    lea     OutputString(pc),a1
    jsr     _LVOPP_Print(a6)

.DataLoop1
    tst.w   d2
    beq.b   .NoDebug2
    moveq   #15,d1
    moveq   #0,d0
    lea     Digit(pc),a1
    lea     OutputString(pc),a0
.DataLoop2
    move.b  #"$",(a0)+
    move.b  (a4),d0
    lsr.b   #4,d0
    move.b  (a1,d0.w),(a0)+
    move.b  (a4)+,d0
    andi.b  #%00001111,d0
    move.b  (a1,d0.w),(a0)+
    move.b  #",",(a0)+
    subq.w  #1,d2
    beq.b   .EndLoop
    dbra    d1,.DataLoop2
.EndLoop
    move.b  #10,-1(a0)
    clr.b   (a0)

    move.l  ad_PVBase(a5),a6
    move.l  ad_PVPort(a5),a0
    lea     OutputString(pc),a1
    jsr     _LVOPP_Print(a6)
    bra.b   .DataLoop1

.NoDebug2
    movem.l (sp)+,d0-d2/a0-a6
    ENDIF

    rts

;******************************************************************************
;********                                                              ********
;********                  List of supported commands                  ********
;********                                                              ********
;******************************************************************************

cmd_DevQuery
    move.l  IO_DATA(a1),a0
    lea     .Support(pc),a2
    move.l  #nsdqr_SIZEOF,d0
    clr.l   (a0)+                      ;DevQueryFormat   = 0
    move.l  d0,(a0)+                   ;SizeAvailable    = nsdqr_SIZEOF
    move.w  #NSDEVTYPE_TRACKDISK,(a0)+ ;DeviceType       = NSDEVTYPE_TRACKDISK
    clr.w   (a0)+                      ;DeviceSubType    = 0
    move.l  a2,(a0)+
    move.l  d0,IO_ACTUAL(a1)
    rts

.Support
    dc.w    CMD_RESET
    dc.w    CMD_READ
    dc.w    CMD_WRITE
    dc.w    CMD_UPDATE
    dc.w    CMD_CLEAR
    dc.w    CMD_STOP
    dc.w    CMD_START
    dc.w    CMD_FLUSH
    dc.w    TD_MOTOR
    dc.w    TD_SEEK
    dc.w    TD_FORMAT
    dc.w    TD_REMOVE
    dc.w    TD_CHANGENUM
    dc.w    TD_CHANGESTATE
    dc.w    TD_PROTSTATUS
    dc.w    TD_GETDRIVETYPE
    dc.w    TD_GETNUMTRACKS
    dc.w    TD_ADDCHANGEINT
    dc.w    TD_REMCHANGEINT
    dc.w    TD_GETGEOMETRY
    dc.w    TD_EJECT
    dc.w    HD_SCSICMD
    dc.w    NSCMD_DEVICEQUERY
    dc.w    NSCMD_TD_READ64
    dc.w    NSCMD_TD_WRITE64
    dc.w    NSCMD_TD_SEEK64
    dc.w    NSCMD_TD_FORMAT64
    dc.w    0

;******************************************************************************
; -----------        END OF THE DRIVE LOW-LEVEL I/O ROUTINES        -----------
;******************************************************************************

;******************************************************************************
;********                                                              ********
;********        Tâche attendant les messages envoyés au device        ********
;********                                                              ********
;******************************************************************************

    cnop    0,4                         ;Long word alignment
    dc.l    16                          ;Segment size
    dc.l    0                           ;Next segment pointer
TaskCode
    move.l  4(sp),a5                    ;A5 : AT-Apollo.device base address
    move.l  ad_SysLib(a5),a6            ;A6 : ExecBase
    move.l  ad_TaskData(a5),a4          ;A4 : "TaskData" structure 

;*************** Debugging with PowerVisor v1.42 ******************************

    IF PVDBG=1
    lea     PVName(pc),a1               ;A1 : "powervisor.library"
    moveq   #1,d0                       ;D0 : Version = 1
    jsr     _LVOOpenLibrary(a6)         ;Open the library
    move.l  d0,ad_PVBase(a5)            ;Save the base address
    beq.b   .NoDebug                    ;Null : no debugging
    move.l  d0,a6                       ;A6 : PVBase
    jsr     _LVOPP_InitPortPrint(a6)    ;MessagePort initialization
    move.l  d0,ad_PVPort(a5)            ;Save its address
    move.l  ad_SysLib(a5),a6            ;A6 : ExecBase
.NoDebug
    ENDIF

    bsr.w   CreateMsgPort
    move.l  d0,ad_TimerMP(a5)           ;MessagePort for the "timer.device"

    move.l  d0,a0
    moveq   #IOTV_SIZE,d0
    bsr.w   CreateIORequest
    move.l  d0,ad_TimerIO(a5)

    lea     TimerName(pc),a0            ;A0: "timer.device"
    move.l  d0,a1                       ;A1: timerequest
    moveq   #UNIT_MICROHZ,d0            ;D0: Accuracy: 1/1000000th of a second
    moveq   #0,d1                       ;D1: Flags
    jsr     _LVOOpenDevice(a6)

    moveq   #-1,d0
    jsr     _LVOAllocSignal(a6)         ;Signal allocation
    move.b  d0,MP_SIGBIT(a4)            ;Used for messages receipt
    clr.b   MP_FLAGS(a4)
    moveq   #0,d7
    bset    d0,d7                       ;Mask for Wait()
    bra.b   .Jump
.NoMessage
    andi.b  #$FF&~(UNITF_INTASK!UNITF_ACTIVE),UNIT_FLAGS(a4)
.Wait
    move.l  d7,d0
    jsr     _LVOWait(a6)                ;Wait for a signal
.Jump
    bset    #UNITB_ACTIVE,UNIT_FLAGS(a4)
    bne.b   .Wait
.Loop
    move.l  a4,a0
    jsr     _LVOGetMsg(a6)              ;Get a message (Standard I/O Request)
    tst.l   d0                          ;Null pointer ?
    beq.b   .NoMessage                  ;Yes, no more message
    move.l  d0,a1                       ;A1 : I/O structure
    exg     a6,a5                       ;Swap A5 & A6
    move.l  IO_UNIT(a1),a3              ;A3 : ApolloUnit base address
    bsr.w   PerformIO                   ;Process the I/O request
    exg     a6,a5                       ;Swap A5 & A6
    jsr     _LVOReplyMsg(a6)            ;Reply to the message
    bra.b   .Loop                       ;Loop

;******************************************************************************
;********                                                              ********
;********                   Disk change deamon task                    ********
;********                                                              ********
;******************************************************************************

    cnop    0,4                         ;Long word alignment
    dc.l    16                          ;Segment size
    dc.l    0                           ;Next segment pointer
DaemonCode
    move.l  4(sp),a5                    ;A5 : AT-Apollo.device base address
    move.l  ad_SysLib(a5),a6            ;A6 : ExecBase
    move.l  ad_DaemonData(a5),a4        ;A4 : "DaemonData" structure 

    bsr.w   CreateMsgPort
    move.l  d0,dd_TimerMP(a4)           ;Message-Port for the "timer.device"

    move.l  d0,a0
    moveq   #IOTV_SIZE,d0
    bsr.b   CreateIORequest
    move.l  d0,dd_TimerIO(a4)           ;IoRequest for the "timer.device"

    lea     TimerName(pc),a0            ;A0 : "timer.device"
    move.l  d0,a1                       ;A1 : IoRequest
    moveq   #UNIT_VBLANK,d0             ;D0 : Accuracy: vertical blank
    moveq   #0,d1                       ;D1 : Flags
    jsr     _LVOOpenDevice(a6)          ;Open the "timer.device"

    bsr.w   CreateMsgPort
    move.l  d0,dd_DevMP(a4)             ;Message-Port for the "AT-Apollo.device"

    moveq   #0,d2
    lea     dd_DevIO(a4),a3
.InitLoop
    move.l  dd_DevMP(a4),a0
    moveq   #IOSTD_SIZE,d0
    bsr.b   CreateIORequest
    move.l  d0,(a3)+

    move.l  d0,a1                       ;A1 : "StdIoRequest" structure 
    move.w  #APCMD_TESTCHANGED,IO_COMMAND(a1) ;"Test Changed" command
    move.l  d2,d0                       ;D0 : Unit number
    moveq   #0,d1                       ;D1 : Flags
    exg     a5,a6
    bsr.w   Open                        ;Open the unit
    exg     a5,a6

    addq.w  #1,d2                       ;Next unit
    cmp.w   ad_NumUnits(a5),d2          ;All units open ?
    bne.b   .InitLoop                   ;No, loop

.WaitLoop
    move.l  dd_TimerIO(a4),a1
    move.w  #TR_ADDREQUEST,IO_COMMAND(a1)
    move.l  #3,IOTV_TIME+TV_SECS(a1)    ;3-second wait
    clr.l   IOTV_TIME+TV_MICRO(a1)
    jsr     _LVODoIO(a6)                ;Start waiting

    moveq   #0,d2
    lea     dd_DevIO(a4),a3
.TestLoop
    move.l  (a3)+,a1
    jsr     _LVODoIO(a6)
    addq.w  #1,d2                       ;Next unit
    cmp.w   ad_NumUnits(a5),d2          ;All units tested ?
    bne.b   .TestLoop                   ;No, loop
    bra.b   .WaitLoop                   ;Go back to the 3-second wait

CreateIORequest
    movem.l d2/d3,-(sp)
    move.l  d0,d2
    move.l  a0,d3
    beq.b   .End
    move.l  #MEMF_CLEAR!MEMF_PUBLIC,d1
    jsr	    _LVOAllocMem(a6)
    move.l  d0,a0
    tst.l   d0
    beq.b   .End
    move.b  #NT_REPLYMSG,LN_TYPE(a0)
    move.l  d3,MN_REPLYPORT(a0)
    move.w  d2,MN_LENGTH(a0)
.End
    move.l  a0,d0
    movem.l (sp)+,d2/d3
    rts	

CreateMsgPort
    moveq   #MP_SIZE,d0
    move.l  #MEMF_CLEAR!MEMF_PUBLIC,d1
    jsr     _LVOAllocMem(a6)
    move.l  d0,-(sp)
    beq.b   .End
    moveq   #-1,d0
    jsr     _LVOAllocSignal(a6)
    move.l  (sp),a0
    move.b  #NT_MSGPORT,LN_TYPE(a0)
    clr.b   MP_FLAGS(a0)
    move.b  d0,MP_SIGBIT(a0)
    bmi.b   .NoSig
    move.l  ThisTask(a6),MP_SIGTASK(a0)
    lea     MP_MSGLIST(a0),a1
    move.l  a1,MLH_TAILPRED(a1)
    addq.l  #MLH_TAIL,a1
    clr.l   (a1)
    move.l  a1,-(a1)
.End
    move.l  (sp)+,d0
    rts
.NoSig
    moveq   #MP_SIZE,d0
    move.l  a0,a1
    jsr     _LVOFreeMem(a6)
    clr.l   (sp)
    bra.b   .End

;******************************************************************************
;********                                                              ********
;********              CMD_READ command for ATAPI drives               ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;D0.l : Logical Block Address (LBA)
;D1.w : Number of blocks to read
;A0.l : Destination buffer
;A3.l : ApolloUnit base address

;Return values:
;--------------
;D0.b : Error code
;D1.l : Number of bytes read

atapi_Read
    movem.l d2-d6/a0-a6,-(sp)

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    clr.w   -(sp)
    lsl.l   #8,d1
    movem.l d0/d1,-(sp)                 ;LBA / Number of blocks
    move.w  #SCSI_READ10<<8,-(sp)       ;ATAPI READ(10) command
    move.l  sp,a4                       ;A4 : CDB for the READ command

    moveq   #0,d6                       ;D6: Byte counter
    bsr.w   SendPacket                  ;Send CDB's 12 bytes
    beq.w   atapi_ErrCmd                ;An error has occured

.Loop
    bsr.w   WaitBusySlow                ;Wait for BUSY == 0
    beq.w   atapi_ErrCmd                ;Time-out elapsed : error
    btst    #ATAPIB_DATAREQ,d0          ;Some data to transfer ?
    beq.w   atapi_EndCmd                ;No, skip
    move.b  atapi_Reason(a5),d0         ;Interrupt Reason Register
    andi.b  #ATAPIF_MASK,d0             ;Bits IO & CoD
    cmpi.b  #ATAPIF_READ,d0             ;Ready to read data ?
    bne.w   atapi_ErrCmd                ;No, error
    move.b  atapi_ByteCntH(a5),d5
    lsl.w   #8,d5
    move.b  atapi_ByteCntL(a5),d5       ;D5.w : Number of bytes to read
    move.l  d5,d4
    lsr.w   #3,d5
    subq.w  #1,d5
.ReadLoop
    movem.w (a5),d0-d3                  ;Reading two long words from the ATA bus
    rol.w   #8,d0
    rol.w   #8,d1
    rol.w   #8,d2
    rol.w   #8,d3                       ;Swap LSBs <-> MSBs
    movem.w d0-d3,(a0)                  ;Writing the two long words into memory
    addq.l  #8,a0
    dbra    d5,.ReadLoop                ;Loop
    btst    #2,d4                       ;One more double long word to read ?
    beq.b   .NoLong                     ;No, skip
    move.l  (a5),d0                     ;Reading one long word from the ATA bus
    rol.w   #8,d0
    swap    d0
    rol.w   #8,d0
    swap    d0                          ;Swap LSBs <-> MSBs
    move.l  d0,(a0)+                    ;Writing one long word into memory
.NoLong
    btst    #1,d4                       ;One more long word to read ?
    beq.b   .NoWord                     ;No, skip
    move.w  (a5),d0                     ;Reading one word from the ATA bus
    rol.w   #8,d0                       ;Swap LSB <-> MSB
    move.w  d0,(a0)+                    ;Writing one word into memory
.NoWord
    add.l   d4,d6                       ;Number of bytes already read
    bra.b   .Loop                       ;Loop

;******************************************************************************
;********                                                              ********
;********              CMD_WRITE command for ATAPI drives              ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;D0.l : Logical Block Address (LBA)
;D1.w : Number of blocks to write
;A0.l : Source buffer
;A3.l : ApolloUnit base address

;Return values:
;--------------
;D0.b : Error code
;D1.l : Number of bytes written

atapi_Write
    movem.l d2-d6/a0-a6,-(sp)

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    clr.w   -(sp)
    lsl.l   #8,d1
    movem.l d0/d1,-(sp)                 ;LBA / Number of blocks
    move.w  #SCSI_WRITE10<<8,-(sp)      ;ATAPI command WRITE(10)
    move.l  sp,a4                       ;A4 : CDB for the WRITE command

    moveq   #0,d6                       ;D6: Byte counter
    bsr.w   SendPacket                  ;Send CDB's 12 bytes
    beq.w   atapi_ErrCmd                ;An error has occured

.Loop
    bsr.w   WaitBusySlow                ;Wait for BUSY == 0
    beq.w   atapi_ErrCmd                ;Time-out elapsed : error
    btst    #ATAPIB_DATAREQ,d0          ;Some data to transfer ?
    beq.w   atapi_EndCmd                ;No, skip
    move.b  atapi_Reason(a5),d0         ;Interrupt Reason Register
    andi.b  #ATAPIF_MASK,d0             ;Bits IO & CoD
    cmpi.b  #ATAPIF_WRITE,d0            ;Ready to write data ?
    bne.w   atapi_ErrCmd                ;No, error
    move.b  atapi_ByteCntH(a5),d5
    lsl.w   #8,d5
    move.b  atapi_ByteCntL(a5),d5       ;D5.w : Number of bytes to write
    move.l  d5,d4
    lsr.w   #3,d5
    subq.w  #1,d5
.WriteLoop
    movem.w (a0),d0-d3                  ;Reading two long words from memory
    rol.w   #8,d0
    rol.w   #8,d1
    rol.w   #8,d2
    rol.w   #8,d3                       ;Swap LSBs <-> MSBs
    movem.w d0-d3,(a5)                  ;Writing the two long words to the ATA bus
    addq.l  #8,a0
    dbra    d5,.WriteLoop               ;Loop
    btst    #2,d4                       ;One more double long word to write ?
    beq.b   .NoLong                     ;No, skip
    move.l  (a0)+,d0                    ;Reading one long word from memory
    rol.w   #8,d0
    swap    d0
    rol.w   #8,d0
    swap    d0                          ;Swap LSBs <-> MSBs
    move.l  d0,(a5)                     ;Writing one long word to the ATA bus
.NoLong
    btst    #1,d4                       ;One more long word to write ?
    beq.b   .NoWord                     ;No, skip
    move.w  (a0)+,d0                    ;Reading one word from memory
    rol.w   #8,d0                       ;Swap LSB <-> MSB
    move.w  d0,(a5)                     ;Writing one word to the ATA bus
.NoWord
    add.l   d4,d6                       ;Number of bytes already written
    bra.b   .Loop                       ;Loop

;******************************************************************************
;********                                                              ********
;********          "Test Unit Ready" command for ATAPI drives          ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address

;Return value:
;-------------
;D0.b : Sense Key

atapi_TestUnit
    movem.l d2-d6/a0-a6,-(sp)

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    clr.l   -(sp)
    clr.l   -(sp)
    clr.l   -(sp)                       ;ATAPI command "Test Unit Ready"
    move.l  sp,a4                       ;A4 : CDB for the TEST UNIT READY command

    bsr.w   SendPacket                  ;Send CDB's 12 bytes
    beq.b   atapi_ErrCmd                ;An error has occured

    bsr.w   WaitBusySlow                ;Wait for BUSY == 0
    beq.b   atapi_ErrCmd                ;Time-out elapsed : error

    move.b  atapi_Error(a5),d0
    lsr.b   #4,d0                       ;D0: Sense key
    beq.b   .NoSense
    move.b  d0,au_SenseKey(a3)
.NoSense

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    lea     12(sp),sp                   ;Restore stack
    movem.l (sp)+,d2-d6/a0-a6           ;Restore registers
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********               TD_SEEK command for ATAPI drive                ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;D0.l : Logical Block Address (LBA)
;A3.l : ApolloUnit base address

;Return value:
;-------------
;D0.b : Error code

atapi_Seek
    movem.l d2-d6/a0-a6,-(sp)

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    clr.l   -(sp)
    clr.w   -(sp)
    move.l  d0,-(sp)                    ;LBA
    move.w  #SCSI_SEEK10<<8,-(sp)       ;ATAPI command SEEK(10)
    move.l  sp,a4                       ;A4 : CDB for the SEEK command

    move.l  d1,d6                       ;Save D1 into D6 !
    bsr.w   SendPacket                  ;Send CDB's 12 bytes
    beq.b   atapi_ErrCmd                ;An error has occured

    bsr.w   WaitBusySlow                ;Wait for BUSY == 0
    beq.b   atapi_ErrCmd                ;Time-out elapsed : error

    bra.b   atapi_EndCmd                ;End of the command

;******************************************************************************
;********                                                              ********
;********               TD_EJECT command for ATAPI drive               ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address

;Return value:
;-------------
;D0.b : Error code

atapi_Eject
    movem.l d2-d6/a0-a6,-(sp)

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    clr.l   -(sp)
    clr.w   -(sp)
    move.w  #$0200,-(sp)                ;Flags : eject
    clr.w   -(sp)
    move.w  #SCSI_STARTSTOP<<8!1,-(sp)  ;ATAPI command START/STOP UNIT
    move.l  sp,a4                       ;A4 : CDB for the START/STOP UNIT command

    move.l  d1,d6                       ;Save D1 into D6 !
    bsr.w   SendPacket                  ;Send CDB's 12 bytes
    beq.b   atapi_ErrCmd                ;An error has occured

    bsr.w   WaitBusySlow                ;Wait for BUSY == 0
    beq.b   atapi_ErrCmd                ;Time-out elapsed : error

    bra.b   atapi_EndCmd                ;End of the command

;******************************************************************************
;********                                                              ********
;********                     End of ATAPI commands                    ********
;********                                                              ********
;******************************************************************************

atapi_ErrCmd
    lea     12(sp),sp                   ;Restore stack

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #CDERR_ABORTED,d0           ;D0: Error code
    move.l  d6,d1                       ;D1: Number of bytes read
    movem.l (sp)+,d2-d6/a0-a6           ;Restore registers
    rts                                 ;End

atapi_EndCmd
    st.b    au_Used(a3)                 ;Unit has been used

    moveq   #0,d0
    btst    #ATAPIB_CHECK,atapi_Status(a5) ;An error has occured ?
    beq.b   .End                        ;No, exit

    move.b  atapi_Error(a5),d0
    lsr.b   #4,d0                       ;D0: Sense key
    move.b  .ErrorMap(pc,d0.w),d0       ;D0: Error code

.End
    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    move.l  d6,d1                       ;D1: Number of bytes read
    lea     12(sp),sp                   ;Restore stack
    movem.l (sp)+,d2-d6/a0-a6           ;Restore registers
    rts                                 ;End

.ErrorMap
    dc.b    CDERR_NotSpecified ;NO SENSE
    dc.b    CDERR_NoSecHdr     ;RECOVERED ERROR
    dc.b    CDERR_NoDisk       ;NOT READY
    dc.b    CDERR_NoSecHdr     ;MEDIUM ERROR
    dc.b    CDERR_NoSecHdr     ;HARDWARE ERROR
    dc.b    CDERR_NOCMD        ;ILLEGAL REQUEST
    dc.b    CDERR_NoDisk       ;UNIT ATTENTION
    dc.b    CDERR_WriteProt    ;DATA PROTECT
    dc.b    CDERR_NotSpecified ;Reserved
    dc.b    CDERR_NotSpecified ;Reserved
    dc.b    CDERR_NotSpecified ;Reserved
    dc.b    CDERR_ABORTED      ;ABORTED COMMAND
    dc.b    CDERR_NotSpecified ;Reserved
    dc.b    CDERR_NotSpecified ;Reserved
    dc.b    CDERR_NoSecHdr     ;MISCOMPARE
    dc.b    CDERR_NotSpecified ;Reserved

;******************************************************************************
;********                                                              ********
;********               CMD_READ command for ATA drives                ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;D0.l : Logical Block Address (LBA)
;D1.l : Number of blocks to read
;A0.l : Destination buffer
;A3.l : ApolloUnit base address

;Return values:
;--------------
;D0.b : Error code
;D1.l : Number of blocks lus

;*************** Normal slow read *********************************************

ata_SlowReadNorm
    movem.l d1/d2/a0/a5/a6,-(sp)

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    cmp.l   au_Blocks(a3),d0            ;LBA >= Total number of blocks ?
    bcc.b   .Error                      ;Yes, error
    tst.l   d1                          ;Is number of blocks to read null ?
    beq.b   .EndLoop                    ;Yes, exit

    bsr.w   CalcBlockAddr               ;Compute block address
    beq.b   .Error                      ;Error : exit

.SectLoop
    move.b  d1,ata_SectorCnt(a5)        ;Number of sectors to read
    move.b  #ATA_READ,ata_Command(a5)   ;ATA read command ($20)

.ReadLoop
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    btst    #ATAB_DATAREQ,d0            ;DREQ = 1 ?
    beq.b   .Error                      ;No, error
    move.b  d0,d2                       ;"ata_Status" into D2

    moveq   #BLOCK_SIZE/4-1,d0          ;Number of long words to read (minus 1)
.Loop
    move.w  (a5),(a0)+                  ;One word transfer
    move.w  (a5),(a0)+                  ;One word transfer
    dbra    d0,.Loop                    ;Loop

    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    btst    #ATAB_ERROR,d2              ;Check ATA error bit
    bne.b   .Error                      ;Set : exit with an error
    subq.l  #1,d1                       ;One sector read
    tst.b   d1                          ;Null LSB ?
    bne.b   .ReadLoop                   ;No, loop

    tst.l    d1                         ;No more sector to read ?
    beq.b   .EndLoop                    ;Yes, exit
    bsr.w   IncrBlockAddr               ;No, CHS/LBA address increment
    bra.b   .SectLoop                   ;Loop

.EndLoop
    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #0,d0                       ;No error
.End
    move.l  (sp)+,d1                    ;Number of blocks read
    move.b  au_SectShift(a3),d2         ;Logical shift (9 or 11)
    lsl.l   d2,d1                       ;Number of bytes read
    movem.l (sp)+,d2/a0/a5/a6           ;Restore registers
    rts                                 ;End

.Error
    sub.l   d1,(sp)                     ;Number of blocks already read
    bsr.w   ResumeError                 ;Drive reset

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #TDERR_NotSpecified,d0      ;Error code
    bra.b   .End                        ;End

;*************** Swapped slow read ********************************************

ata_SlowReadSwap
    movem.l d1-d3/a0/a5/a6,-(sp)

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    cmp.l   au_Blocks(a3),d0            ;LBA >= Total number of blocks ?
    bcc.w   .Error                      ;Yes, error
    tst.l   d1                          ;Is number of blocks to read null ?
    beq.b   .EndLoop                    ;Yes, exit

    bsr.w   CalcBlockAddr               ;Compute block address
    beq.b   .Error                      ;Error : exit

.SectLoop
    move.b  d1,ata_SectorCnt(a5)        ;Number of sectors to read
    move.b  #ATA_READ,ata_Command(a5)   ;ATA read command ($20)

.ReadLoop
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    btst    #ATAB_DATAREQ,d0            ;DREQ = 1 ?
    beq.b   .Error                      ;No, error
    move.b  d0,d2                       ;"ata_Status" into D2

    moveq   #BLOCK_SIZE/4-1,d0          ;Number of long words to read (minus 1)
.Loop
    move.w  (a5),d3
    rol.w   #8,d3
    move.w  d3,(a0)+                    ;Swapped word read
    move.w  (a5),d3
    rol.w   #8,d3
    move.w  d3,(a0)+                    ;Swapped word read
    dbra    d0,.Loop                    ;Loop

    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    btst    #ATAB_ERROR,d2              ;Check ATA error bit
    bne.b   .Error                      ;Set : exit with an error
    subq.l  #1,d1                       ;One sector read
    tst.b   d1                          ;Null LSB ?
    bne.b   .ReadLoop                   ;No, loop

    tst.l   d1                          ;No more sector to read ?
    beq.b   .EndLoop                    ;Yes, exit
    bsr.w   IncrBlockAddr               ;No, CHS/LBA address increment
    bra.b   .SectLoop                   ;Loop

.EndLoop
    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #0,d0                       ;No error
.End
    move.l  (sp)+,d1                    ;Number of blocks read
    move.b  au_SectShift(a3),d2         ;Logical shift (9 or 11)
    lsl.l   d2,d1                       ;Number of bytes read
    movem.l (sp)+,d2/d3/a0/a5/a6        ;Restore registers
    rts                                 ;End

.Error
    sub.l   d1,(sp)                     ;Number of blocks already read
    bsr.w   ResumeError                 ;Drive reset

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #TDERR_NotSpecified,d0      ;Error code
    bra.b   .End                        ;End

;*************** Normal fast read *********************************************

ata_FastReadNorm
    movem.l d1-d7/a0-a6,-(sp)

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    cmp.l   au_Blocks(a3),d0            ;LBA >= Total number of blocks ?
    bcc.w   .Error1                     ;Yes, error
    tst.l   d1                          ;Is number of blocks to read null ?
    beq.w   .EndLoop                    ;Yes, exit

    bsr.w   CalcBlockAddr               ;Compute block address
    beq.w   .Error1                     ;Error : exit

    lea     $3D0(a5),a5                 ;A5 : Source
    moveq   #$30,d7                     ;D7 : Incrément

.SectLoop
    move.b  d1,ata_SectorCnt(a5)        ;Number of sectors to read
    move.b  #ATA_READ,ata_Command(a5)   ;ATA read command ($20)
    movem.l d1/a3/a6,-(sp)              ;Save D1, A3 & A6

.ReadLoop
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.w   .Error2                     ;Time-out elapsed : error
    btst    #ATAB_DATAREQ,d0            ;DREQ = 1 ?
    beq.w   .Error2                     ;No, error
    move.w  d0,-(sp)                    ;Save "ata_Status"

    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;1st 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;2nd 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;3rd 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;4th 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;5th 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;6th 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;7th 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;8th 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;9th 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;10th 12-long-word transfer
    add.l   d7,a0
    movem.l $10(a5),d0-d6/a1
    movem.l d0-d6/a1,(a0)               ;Last 8-long-word transfer
    lea     $20(a0),a0                  ;512 bytes : 12*10+8 long words

    move.w  (sp)+,d1                    ;D1 : ata_Status
    move.l  4(sp),a3                    ;Restore A3

    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error2                     ;Time-out elapsed : error
    btst    #ATAB_ERROR,d1              ;Check ATA error bit
    bne.b   .Error2                     ;Set : exit with an error
    subq.l  #1,(sp)                     ;One sector read
    tst.b   3(sp)                       ;Null LSB ?
    bne.w   .ReadLoop                   ;No, loop

    movem.l (sp)+,d1/a3/a6              ;Restore D1, A3 & A6
    tst.l   d1                          ;No more sector to read ?
    beq.b   .EndLoop                    ;Yes, exit
    bsr.w   IncrBlockAddr               ;No, CHS/LBA address incremement
    bra.w   .SectLoop                   ;Loop

.EndLoop
    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #0,d0                       ;No error
.End
    move.l  (sp)+,d1                    ;Number of blocks read
    move.b  au_SectShift(a3),d2         ;Logical shift (9 or 11)
    lsl.l   d2,d1                       ;Number of bytes read
    movem.l (sp)+,d2-d7/a0-a6           ;Restore registers
    rts                                 ;End

.Error2
    movem.l (sp)+,d1/a3/a6              ;Restore D1, A3 & A6

.Error1
    sub.l   d1,(sp)                     ;Number of blocks already read
    bsr.w   ResumeError                 ;Drive reset

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #TDERR_NotSpecified,d0      ;Error code
    bra.b   .End                        ;End

;*************** Swapped fast read ********************************************

ata_FastReadSwap
    movem.l d1-d7/a0-a6,-(sp)

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    cmp.l   au_Blocks(a3),d0            ;LBA >= Total number of blocks ?
    bcc.w   .Error1                     ;Yes, error
    tst.l   d1                          ;Is number of blocks to read null ?
    beq.w   .EndLoop                    ;Yes, exit

    bsr.w   CalcBlockAddr               ;Compute block address
    beq.w   .Error1                     ;Error : exit

    lea     $3D0(a5),a5                 ;A5 : Source
    moveq   #$30,d7                     ;D7 : Increment
.SectLoop
    move.b  d1,ata_SectorCnt(a5)        ;Number of sectors to read
    move.b  #ATA_READ,ata_Command(a5)   ;ATA read command ($20)
    movem.l d1/a3/a6,-(sp)              ;Save D1, A3 & A6


;*************** Fast read, followed by fast swap *****************************

.Loop
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.w   .Error2                     ;Time-out elapsed : error
    btst    #ATAB_DATAREQ,d0            ;DREQ = 1 ?
    beq.w   .Error2                     ;No, error
    move.w  d0,-(sp)                    ;Save "ata_Status"

    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;1st 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;2nd 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;3rd 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;4th 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;5th 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;6th 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;7th 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;8th 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;9th 12-long-word transfer
    add.l   d7,a0
    movem.l (a5),d0-d6/a1-a4/a6
    movem.l d0-d6/a1-a4/a6,(a0)         ;10th 12-long-word transfer
    add.l   d7,a0
    movem.l $10(a5),d0-d6/a1
    movem.l d0-d6/a1,(a0)               ;Last 8-long-word transfer
    lea     $20(a0),a0                  ;512 bytes : 12*10+8 long words

    lea     -BLOCK_SIZE(a0),a0
    moveq   #BLOCK_SIZE/8-1,d0          ;Nomber of 8-byte bursts
.SwapLoop
    movem.w (a0)+,d2-d5                 ;Read 8 bytes from memory
    rol.w   #8,d2
    rol.w   #8,d3
    rol.w   #8,d4
    rol.w   #8,d5                       ;Swap LSBs <-> MSBs
    movem.w d2-d5,-8(a0)                ;Write 8 bytes to memory
    dbra    d0,.SwapLoop                ;Loop

    move.w  (sp)+,d1                    ;D1 : ata_Status
    move.l  4(sp),a3                    ;Restore A3

    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error2                     ;Time-out elapsed : error
    btst    #ATAB_ERROR,d1              ;Check ATA error bit
    bne.b   .Error2                     ;Set : exit with an error
    subq.l  #1,(sp)                     ;One sector read
    tst.b   3(sp)                       ;Null LSB ?
    bne.w   .Loop                       ;No, loop

    movem.l (sp)+,d1/a3/a6              ;Restore D1, A3 & A6
    tst.l   d1                          ;No more sector to read ?
    beq.b   .EndLoop                    ;Yes, exit
    bsr.w   IncrBlockAddr               ;No, CHS/LBA address increment
    bra.w   .SectLoop                   ;Loop

.EndLoop
    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #0,d0                       ;No error
.End
    move.l  (sp)+,d1                    ;Number of blocks read
    move.b  au_SectShift(a3),d2         ;Logical shift (9 or 11)
    lsl.l   d2,d1                       ;Number of bytes read
    movem.l (sp)+,d2-d7/a0-a6           ;Restore registers
    rts                                 ;End

.Error2
    movem.l (sp)+,d1/a3/a6              ;Restore D1, A3 & A6

.Error1
    sub.l   d1,(sp)                     ;Number of blocks already read
    bsr.w   ResumeError                 ;Drive reset

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #TDERR_NotSpecified,d0      ;Error code
    bra.b   .End                        ;End

;******************************************************************************
;********                                                              ********
;********               CMD_WRITE command for ATA drives               ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;D0.l : Logical Block Address (LBA)
;D1.l : Number of blocks to write
;A0.l : Source buffer
;A3.l : ApolloUnit base address

;Return values:
;--------------
;D0.b : Error code
;D1.l : Number of bytes written

;*************** Normal slow write ********************************************

ata_SlowWriteNorm
    movem.l d0-d2/a0/a5/a6,-(sp)

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    cmp.l   au_Blocks(a3),d0            ;LBA >= Total number of blocks ?
    bcc.b   .Error                      ;Yes, error
    tst.l   d1                          ;Number of blocks to write is null ?
    beq.b   .EndLoop                    ;Yes, exit

    bsr.w   CalcBlockAddr               ;Compute block address
    beq.b   .Error                      ;Error : exit

.SectLoop
    move.b  d1,ata_SectorCnt(a5)        ;Number of sectors to write
    move.b  #ATA_WRITE,ata_Command(a5)  ;ATA write command ($30)

.WriteLoop
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    btst    #ATAB_ERROR,d0              ;Check ATA error bit
    bne.b   .Error                      ;Set : exit with an error
    btst    #ATAB_DATAREQ,d0            ;DREQ = 1 ?
    beq.b   .Error                      ;No, error

    moveq   #BLOCK_SIZE/4-1,d0          ;Number of long words to write (minus 1)
.Loop
    move.w  (a0)+,(a5)                  ;One word transfer
    move.w  (a0)+,(a5)                  ;One word transfer
    dbra    d0,.Loop                    ;Loop

    subq.l  #1,d1                       ;One sector written
    tst.b   d1                          ;Null LSB ?
    bne.b   .WriteLoop                  ;No, loop

    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    tst.l   d1                          ;More sectors to write ?
    bne.b   .Continue                   ;Yes, continue
    btst    #ATAB_ERROR,d0              ;Check ATA error bit
    bne.b   .Error                      ;Set : exit with an error

.EndLoop
    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #0,d0                       ;No error
.End
    addq.l  #4,sp
    move.l  (sp)+,d1                    ;Number of blocks written
    move.b  au_SectShift(a3),d2         ;Logical shift (9 or 11)
    lsl.l   d2,d1                       ;Number of bytes written
    movem.l (sp)+,d2/a0/a5/a6           ;Restore registers
    rts                                 ;End

.Continue
    move.l  (sp),d0                     ;Logical block number (LBA)
    add.l   4(sp),d0                    ;+ Number of blocks to write
    sub.l   d1,d0                       ;- Number of remaining blocks to write
    bsr.w   CalcBlockAddr               ;Compute block address
    beq.b   .Error
    bra.b   .SectLoop                   ;Loop

.Error
    sub.l   d1,4(sp)                    ;Number of blocks already written
    bsr.w   ResumeError                 ;Drive reset

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #TDERR_NotSpecified,d0      ;Error code
    bra.b   .End                        ;End

;*************** Swapped slow write *******************************************

ata_SlowWriteSwap
    movem.l d0-d2/a0/a5/a6,-(sp)

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    cmp.l   au_Blocks(a3),d0            ;LBA >= Total number of blocks ?
    bcc.b   .Error                      ;Yes, error
    tst.l   d1                          ;Is number of blocks to write null ?
    beq.b   .EndLoop                    ;Yes, exit

    bsr.w   CalcBlockAddr               ;Compute block address
    beq.b   .Error                      ;Error : exit

.SectLoop
    move.b  d1,ata_SectorCnt(a5)        ;Number of sectors to write
    move.b  #ATA_WRITE,ata_Command(a5)  ;ATA write command ($30)

.WriteLoop
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    btst    #ATAB_ERROR,d0              ;Check ATA error bit
    bne.b   .Error                      ;Set : exit with an error
    btst    #ATAB_DATAREQ,d0            ;DREQ = 1 ?
    beq.b   .Error                      ;No, error

    moveq   #BLOCK_SIZE/4-1,d0          ;Number of long words to write (minus 1)
.Loop
    move.w  (a0)+,d2
    rol.w   #8,d2
    move.w  d2,(a5)                     ;Swapped word write
    move.w  (a0)+,d2
    rol.w   #8,d2
    move.w  d2,(a5)                     ;Swapped word write
    dbra    d0,.Loop                    ;Loop

    subq.l  #1,d1                       ;One sector written
    tst.b   d1                          ;Null LSB ?
    bne.b   .WriteLoop                  ;No, loop

    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    tst.l   d1                          ;More sectors to write ?
    bne.b   .Continue                   ;Yes, continue
    btst    #ATAB_ERROR,d0              ;Check ATA error bit
    bne.b   .Error                      ;Set : exit with an error

.EndLoop
    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #0,d0                       ;No error
.End
    addq.l  #4,sp
    move.l  (sp)+,d1                    ;Number of blocks written
    move.b  au_SectShift(a3),d2         ;Logical shift (9 or 11)
    lsl.l   d2,d1                       ;Number of bytes written
    movem.l (sp)+,d2/a0/a5/a6           ;Restore registers
    rts                                 ;End

.Continue
    move.l  (sp),d0                     ;Logical block number (LBA)
    add.l   4(sp),d0                    ;+ Number of blocks to write
    sub.l   d1,d0                       ;- Number of remaining blocks to write
    bsr.w   CalcBlockAddr               ;Compute block address
    beq.b   .Error
    bra.w   .SectLoop                   ;Loop

.Error
    sub.l   d1,4(sp)                    ;Number of blocks already written
    bsr.w   ResumeError                 ;Drive reset

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #TDERR_NotSpecified,d0      ;Error code
    bra.b   .End                        ;End

;*************** Normal fast write ********************************************

ata_FastWriteNorm
    movem.l d0-d7/a0-a6,-(sp)

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    cmp.l   au_Blocks(a3),d0            ;LBA >= Total number of blocks ?
    bcc.w   .Error1                     ;Yes, error
    tst.l   d1                          ;Is number of blocks to write null ?
    beq.w   .EndLoop                    ;Yes, exit

    bsr.w   CalcBlockAddr               ;Compute block address
    beq.w   .Error1                     ;Error : exit

.SectLoop
    move.b  d1,ata_SectorCnt(a5)        ;Number of sectors to write
    move.b  #ATA_WRITE,ata_Command(a5)  ;ATA write command ($30)
    movem.l a3/a6,-(sp)                 ;Save A3 & A6

.WriteLoop
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.w   .Error2                     ;Time-out elapsed : error
    btst    #ATAB_ERROR,d0              ;Check ATA error bit
    bne.w   .Error2                     ;Set : exit with an error
    btst    #ATAB_DATAREQ,d0            ;DREQ = 1 ?
    beq.w   .Error2                     ;No, error

    movem.l (a0)+,d0/d2-d7/a1-a4/a6
    movem.l d0/d2-d7/a1-a4/a6,(a5)      ;1st 12-long-word transfer
    movem.l (a0)+,d0/d2-d7/a1-a4/a6
    movem.l d0/d2-d7/a1-a4/a6,(a5)      ;2nd 12-long-word transfer
    movem.l (a0)+,d0/d2-d7/a1-a4/a6
    movem.l d0/d2-d7/a1-a4/a6,(a5)      ;3rd 12-long-word transfer
    movem.l (a0)+,d0/d2-d7/a1-a4/a6
    movem.l d0/d2-d7/a1-a4/a6,(a5)      ;4th 12-long-word transfer
    movem.l (a0)+,d0/d2-d7/a1-a4/a6
    movem.l d0/d2-d7/a1-a4/a6,(a5)      ;5th 12-long-word transfer
    movem.l (a0)+,d0/d2-d7/a1-a4/a6
    movem.l d0/d2-d7/a1-a4/a6,(a5)      ;6th 12-long-word transfer
    movem.l (a0)+,d0/d2-d7/a1-a4/a6
    movem.l d0/d2-d7/a1-a4/a6,(a5)      ;7th 12-long-word transfer
    movem.l (a0)+,d0/d2-d7/a1-a4/a6
    movem.l d0/d2-d7/a1-a4/a6,(a5)      ;8th 12-long-word transfer
    movem.l (a0)+,d0/d2-d7/a1-a4/a6
    movem.l d0/d2-d7/a1-a4/a6,(a5)      ;9th 12-long-word transfer
    movem.l (a0)+,d0/d2-d7/a1-a4/a6
    movem.l d0/d2-d7/a1-a4/a6,(a5)      ;10th 12-long-word transfer
    movem.l (a0)+,d0/d2-d7/a1
    movem.l d0/d2-d7/a1,(a5)            ;Last 8-long-word transfer
                                        ;512 bytes : 12*10+8 long words
    movem.l (sp),a3/a6                  ;Restore A3 & A6
    subq.l  #1,d1                       ;One sector written
    tst.b   d1                          ;Null LSB ?
    bne.b   .WriteLoop                  ;No, loop

    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error2                     ;Time-out elapsed : error
    movem.l (sp)+,a3/a6                 ;Restore A3 & A6
    tst.l   d1                          ;More sectors to write ?
    bne.b   .Continue                   ;Yes, continue
    btst    #ATAB_ERROR,d0              ;Check ATA error bit
    bne.b   .Error1                     ;Set : exit with an error

.EndLoop
    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #0,d0                       ;No error
.End
    addq.l  #4,sp
    move.l  (sp)+,d1                    ;Number of blocks written
    move.b  au_SectShift(a3),d2         ;Logical shift (9 or 11)
    lsl.l   d2,d1                       ;Number of bytes written
    movem.l (sp)+,d2-d7/a0-a6           ;Restore registers
    rts                                 ;End

.Continue
    move.l  (sp),d0                     ;Logical block number (LBA)
    add.l   4(sp),d0                    ;+ Number of blocks to write
    sub.l   d1,d0                       ;- Number of remaining blocks to write
    bsr.w   CalcBlockAddr               ;Compute block address
    beq.b   .Error1
    bra.w   .SectLoop                   ;Loop

.Error2
    movem.l (sp)+,a3/a6                 ;Restore A3 & A6

.Error1
    sub.l   d1,4(sp)                    ;Number of blocks already written
    bsr.w   ResumeError                 ;Drive reset

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #TDERR_NotSpecified,d0      ;Error code
    bra.b   .End                        ;End

;*************** Swapped fast write *******************************************

ata_FastWriteSwap
    movem.l d0-d7/a0/a5/a6,-(sp)

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    cmp.l   au_Blocks(a3),d0            ;LBA >= Total number of blocks ?
    bcc.w   .Error                      ;Yes, error
    tst.l   d1                          ;Is number of blocks to write null ?
    beq.b   .EndLoop                    ;Yes, exit

    bsr.w   CalcBlockAddr               ;Compute block address
    beq.w   .Error                      ;Error : exit

.SectLoop
    move.b  d1,ata_SectorCnt(a5)        ;Number of sectors to write
    move.b  #ATA_WRITE,ata_Command(a5)  ;ATA write command ($30)

.WriteLoop
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.w   .Error                      ;Time-out elapsed : error
    btst    #ATAB_ERROR,d0              ;Check ATA error bit
    bne.w   .Error                      ;Set : exit with an error
    btst    #ATAB_DATAREQ,d0            ;DREQ = 1 ?
    beq.b   .Error                      ;No, error

    moveq   #BLOCK_SIZE/32-1,d0         ;Number of 32-byte bursts (minus 1)
.Loop
    movem.w (a0)+,d2-d7
    rol.w   #8,d2
    rol.w   #8,d3
    rol.w   #8,d4
    rol.w   #8,d5
    rol.w   #8,d6
    rol.w   #8,d7
    movem.w d2-d7,(a5)                  ;6-word transfer
    movem.w (a0)+,d2-d7
    rol.w   #8,d2
    rol.w   #8,d3
    rol.w   #8,d4
    rol.w   #8,d5
    rol.w   #8,d6
    rol.w   #8,d7
    movem.w d2-d7,(a5)                  ;6-word transfer
    movem.w (a0)+,d2-d5
    rol.w   #8,d2
    rol.w   #8,d3
    rol.w   #8,d4
    rol.w   #8,d5
    movem.w d2-d5,(a5)                  ;4-word transfer
    dbra    d0,.Loop                    ;Loop

    subq.l  #1,d1                       ;One secteur written
    tst.b   d1                          ;Null LSB ?
    bne.b   .WriteLoop                  ;No, loop

    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    tst.l   d1                          ;More sectors to write ?
    bne.b   .Continue                   ;Yes, continue
    btst    #ATAB_ERROR,d0              ;Check ATA error bit
    bne.b   .Error                      ;Set : exit with an error

.EndLoop
    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #0,d0                       ;No error
.End
    addq.l  #4,sp
    move.l  (sp)+,d1                    ;Number of blocks written
    move.b  au_SectShift(a3),d2         ;Logical shift (9)
    lsl.l   d2,d1                       ;Number of bytes written
    movem.l (sp)+,d2-d7/a0/a5/a6        ;Restore registers
    rts                                 ;End

.Continue
    move.l  (sp),d0                     ;Logical block number (LBA)
    add.l   4(sp),d0                    ;+ Number of blocks to write
    sub.l   d1,d0                       ;- Number of remaining blocks to write
    bsr.w   CalcBlockAddr               ;Compute block address
    beq.b   .Error
    bra.w   .SectLoop                   ;Loop

.Error
    sub.l   d1,4(sp)                    ;Number of blocks already written
    bsr.w   ResumeError                 ;Drive reset

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #TDERR_NotSpecified,d0      ;Error code
    bra.b   .End                        ;End

;******************************************************************************
;********                                                              ********
;********                TD_SEEK command for ATA drives                ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;D0.l : Logical Block Address (LBA)
;A3.l : ApolloUnit base address

;Return value:
;-------------
;D0.b : Error code

ata_Seek
    movem.l a5/a6,-(sp)                 ;Save A5 & A6

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    cmp.l   au_Blocks(a3),d0            ;LBA >= Total number of blocks ?
    bcc.b   .Error1                     ;Yes, error

    bsr.w   CalcBlockAddr               ;Otherwise, compute block address
    beq.b   .Error2                     ;Error : exit

    move.b  #ATA_SEEK,ata_Command(a5)   ;ATA seek command ($70)
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error3                     ;Time-out elapsed : error
    btst    #ATAB_ERROR,d0              ;Check ATA error bit
    bne.b   .Error3                     ;Set : exit with an error

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #0,d0                       ;No error
    movem.l (sp)+,a5/a6                 ;Restore A5 & A6
    rts                                 ;End

.Error1
    move.w  #$0521,d1                   ;Illegal request + LBA out of range
    bra.b   .EndErr

.Error2
    move.w  #$0205,d1                   ;Not ready + Logical unit not respond
    bra.b   .EndErr

.Error3
    bsr.w   CurrBlockAddr
    move.w  #$0B02,d1                   ;Aborted command + No seek complete

.EndErr
    move.l  d0,au_LBASense(a3)
    move.w  d1,au_SenseKey(a3)

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #TDERR_NotSpecified,d0      ;Error code
    movem.l (sp)+,a5/a6                 ;Restore A5 & A6
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********               TD_EJECT command for ATA drives                ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address

;Return value:
;-------------
;D0.b : Error code

ata_Eject
    movem.l a5/a6,-(sp)                 ;Save A5 & A6

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

    move.b  au_DevMask,ata_DevHead(a5)  ;Select the drive
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    move.b  #ATA_MEDIAEJECT,ata_Command(a5) ;Send the EJECT command
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    btst    #ATAB_ERROR,d0              ;Check ATA error bit
    bne.b   .Error                      ;Set : exit with an error

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #0,d0                       ;No error
    movem.l (sp)+,a5/a6                 ;Restore A5 & A6
    rts                                 ;End

.Error
    move.w  #$0205,au_SenseKey(a3)      ;Not ready + Logical unit not respond
    clr.l   au_LBASense(a3)

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #TDERR_NotSpecified,d0      ;Error code
    movem.l (sp)+,a5/a6                 ;Restore A5 & A6
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********           "AutoDetect" command for an ATA drive (3)          ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A0.l : Destination buffer
;A3.l : ApolloUnit base address

;Return value:
;-------------
;Z Flag (0:Ok, 1:Error)

ata_Identify
    movem.l d0/d1/a5/a6,-(sp)           ;Save D0, D1, A5 & A6

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

;*************** Sending the command to the drive *****************************

    move.b  #ATA_IDENTDEV,d1            ;ATA command
    tst.b   au_AtapiDev(a3)
    beq.b   .NoAtapi
    move.b  #ATAPI_IDENTDEV,d1          ;ATAPI command
.NoAtapi
  
    move.b  au_DevMask(a3),ata_DevHead(a5) ;Drive select
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.w   .Error                      ;Time-out elapsed : error
    move.b  d1,ata_Command(a5)          ;IDENTIFY DEVICE command
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.w   .Error                      ;Time-out elapsed : error
    btst    #ATAB_DATAREQ,d0            ;DREQ = 1 ?
    beq.w   .Error                      ;No, error

;*************** Reading parameters *******************************************

    moveq   #idev_SIZEOF/4-1,d0         ;D0: Long words to read minus 1
.Loop1
    move.l  (a5),(a0)+                  ;One long word transfered
    dbra    d0,.Loop1                   ;Loop
    lea     -idev_SIZEOF(a0),a0         ;Restore A0

    btst    #ATAB_ERROR,ata_Status(a5)  ;Check ATA error bit
    bne.w   .Error                      ;Set : exit with an error

    tst.b   au_AtapiDev(a3)             ;ATAPI protocol ?
    beq.w   .Ata                        ;No, skip

;*************** Dummy geometry for ATAPI drive *******************************

    move.b  (a0),d0
    andi.b  #%00001111,d0               ;D0 : Drive type

    cmpi.b  #DG_CDROM,d0
    beq.b   .CdRom
    cmpi.b  #DG_WORM,d0
    beq.b   .CdRom
    cmpi.b  #DG_OPTICAL_DISK,d0
    beq.b   .CdRom
    cmpi.b  #DG_DIRECT_ACCESS,d0
    beq.b   .Direct
    bra.w   .End

.Direct
    cmpi.l  #"LS-1",idev_ModelNumber(a0)
    bne.b   .NoLS
    cmpi.w  #"20",idev_ModelNumber+4(a0)
    bne.b   .NoLS

    ;LS-120 drive geometry
    move.w  #2,idev_Heads(a0)           ;2 heads
    move.w  #18,idev_Sectors(a0)        ;18 sectors
    move.w  #6848,idev_Cylinders(a0)    ;6848 cylinders
    st.b    au_SlowDevice(a3)           ;Slow peripheral
    bra.w   .End

.NoLS
    cmpi.l  #"ZIP ",idev_ModelNumber+8(a0)
    bne.w   .End
    cmpi.l  #"100 ",idev_ModelNumber+12(a0)
    bne.w   .End

    ;ZIP 100 drive geometry
    move.w  #1,idev_Heads(a0)           ;1 head
    move.w  #64,idev_Sectors(a0)        ;64 sectors
    move.w  #3072,idev_Cylinders(a0)    ;3072 cylinders
    sf.b    au_SlowDevice(a3)           ;Fast peripheral
    bra.b   .End

.CdRom
    ;CD-ROM drive geometry
    move.w  #1,idev_Heads(a0)           ;1 head
    move.w  #75,idev_Sectors(a0)        ;75 sectors
    move.w  #4440,idev_Cylinders(a0)    ;4440 cylinders
    st.b    au_SlowDevice(a3)           ;Slow peripheral
    bra.b   .End

;*************** Special geometry for ATA drives > 8 GB ***********************

.Ata
    cmpi.w  #16,idev_Heads(a0)          ;16 heads ?
    bne.b   .End                        ;No, skip
    cmpi.w  #63,idev_Sectors(a0)        ;63 sectors ?
    bne.b   .End                        ;No, skip
    cmpi.w  #16383,idev_Cylinders(a0)   ;16383 cylindres ?
    bne.b   .End                        ;No, skip

    move.l  idev_LbaCapacity(a0),d0     ;Real number of blocks
    swap    d0
    cmpi.l  #(63*16*65535),d0           ;Drive capacity > 32 GB ?
    bhi.b   .More32GB                   ;Yes, special computation

    divu    #(63*16),d0
    move.w  d0,idev_Cylinders(a0)       ;New cylinders numbers
    bra.b   .End

.More32GB
    move.l  d2,-(sp)                    ;Save D2
    lsr.l   #4,d0                       ;/ 16 heads
    move.w  #255,d1                     ;Start with 255 sectors
.Loop2
    move.l  d0,d2
    divu    d1,d2
    bvs.b   .OvlLoop2                   ;Overflow : end computation
    swap    d2
    tst.w   d2                          ;Null remainder ?
    beq.b   .EndLoop2                   ;Yes, exit
    subq.w  #1,d1                       ;No, decrease the number of sectors
    bra.b   .Loop2
.OvlLoop2
    addq.w  #1,d1                       ;Increase the number of sectors
.EndLoop2
    divu    d1,d0
    move.w  d0,idev_Cylinders(a0)       ;New number of cylinders
    move.w  d1,idev_Sectors(a0)         ;New number of sectors
    move.l  (sp)+,d2                    ;Restore D2

;*************** End of routine ***********************************************

.End
    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #1,d0                       ;Flag Z = 0 : Ok
    movem.l (sp)+,d0/d1/a5/a6           ;Restore D0, D1, A5 & A6
    rts                                 ;End

;*************** An error has occured *****************************************

.Error
    bsr.w   ResumeError                 ;Re-initialize the drive

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #0,d0                       ;Flag Z = 1 : Error
    movem.l (sp)+,d0/d1/a5/a6           ;Restore D0, D1, A5 & A6
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********    Increase the CHS/LBA address of the last accessed block   ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address
;A5.l : Apollo card base address

IncrBlockAddr
    tst.b   au_LBAMode(a3)
    beq.b   .CHSMode

;*************** LBA addressing of blocks *************************************

    addq.b  #1,ata_SectorNum(a5)
    bne.b   .EndLBA
    addq.b  #1,ata_CylinderL(a5)
    bne.b   .EndLBA
    addq.b  #1,ata_CylinderH(a5)
    bne.b   .EndLBA
    addq.b  #1,ata_DevHead(a5)
.EndLBA
    rts

;*************** CHS addressing of blocks *************************************

.CHSMode
    move.b  ata_SectorNum(a5),d0        ;Current sector number
    cmp.b   au_SectorsT(a3),d0          ;== Number of sectors ?
    beq.b   .NextHead                   ;Yes, increase the head number
    addq.b  #1,ata_SectorNum(a5)        ;No, increase the sector number
    rts                                 ;End

.NextHead
    move.b  #1,ata_SectorNum(a5)        ;Sector number = 1
    move.b  ata_DevHead(a5),d0
    and.b   #ATAF_HEADS,d0              ;Head number
    addq.b  #1,d0                       ;+1
    cmp.b   au_Heads(a3),d0             ;== Number of heads ?
    beq.b   .NextCylinder               ;Yes, increase the cylinder number
    addq.b  #1,ata_DevHead(a5)          ;No, increase the head number
    rts                                 ;End

.NextCylinder
    and.b   #ATAF_SELECT,ata_DevHead(a5) ;Head number = 0
    addq.b  #1,ata_CylinderL(a5)        ;Increase the LSB
    bne.b   .EndCHS                     ;Not null : end
    addq.b  #1,ata_CylinderH(a5)        ;Null : increase the MSB
.EndCHS
    rts                                 ;End
  
;******************************************************************************
;********                                                              ********
;********             Block address computing (CHS or LBA)             ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;D0.l : Logical block number
;A3.l : ApolloUnit base address
;A5.l : IDE interface base address
;A6.l : AT-Apollo.device base address

;Return value:
;-------------
;Z Flag (0:Ok, 1:Error)

CalcBlockAddr
    movem.l d0-d2,-(sp)                 ;Save D0, D1 & D2
    tst.b   au_LBAMode(a3)              ;LBA mode ?
    beq.b   .CHSMode                    ;No, CHS mode

;*************** LBA mode (max capacity : 128 GB) *****************************

    move.w  d0,d2                       ;D2.w : LBA[15..0]
    swap    d0                          ;D0.w : LBA[27..16]
    move.b  d0,d1                       ;D1.b : LBA[23..16]
    lsr.w   #8,d0                       ;D0.b : LBA[27..24]
    or.b    au_DevMask(a3),d0           ; + Drive select

    move.b  d0,ata_DevHead(a5)          ;Write the drive select + LBA[27..24]
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    move.b  d1,ata_CylinderH(a5)        ;Write LBA[23..16]
    move.b  d2,ata_SectorNum(a5)        ;Write LBA[7..0]
    lsr.w   #8,d2
    move.b  d2,ata_CylinderL(a5)        ;Write LBA[15..8]

    moveq   #1,d0                       ;Flag Z = 0 : Ok
    movem.l (sp)+,d0-d2                 ;Restore D0, D1 & D2
    rts                                 ;End

;*************** CHS mode (max capacity : 8 GB) *******************************

.CHSMode
    move.w  au_SectorsC(a3),d1          ;D1.w : Number of sectors per cylinder
    divu    d1,d0                       ;Block number/Number of sectors
    move.w  d0,d1                       ;D1.w : Cylinder number
    clr.w   d0
    swap    d0                          ;D0.l : Remainder
    moveq   #0,d2
    move.b  au_SectorsT(a3),d2          ;D2.w : Number of sectors per track
    divu    d2,d0
    or.b    au_DevMask(a3),d0           ;D0.b : Head number + drive select
    move.b  d0,ata_DevHead(a5)          ;Write the head number + drive select
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    swap    d0
    addq.b  #1,d0                       ;D0.b : Sector number
    move.b  d0,ata_SectorNum(a5)        ;Write the sector number
    move.b  d1,ata_CylinderL(a5)        ;Write the cylinder number (LSB)
    lsr.w   #8,d1
    move.b  d1,ata_CylinderH(a5)        ;Write the cylinder number (MSB)

    moveq   #1,d0                       ;Flag Z = 0 : Ok
    movem.l (sp)+,d0-d2                 ;Restore D0, D1 & D2
    rts                                 ;End

.Error
    moveq   #0,d0                       ;Flag Z = 1 : Error
    movem.l (sp)+,d0-d2                 ;Restore D0, D1 & D2
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********       Get the current position from the ATA registers        ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address
;A5.l : IDE interface base address

;Return value:
;-------------
;D0.l : Block number

CurrBlockAddr
    tst.b   au_LBAMode(a3)
    bne.b   .LBA

;*************** CHS mode *****************************************************

    movem.l d1/d2,-(sp)
    moveq   #0,d1
    move.b  au_SectorsT(a3),d1          ;D1 : Number of sectors per track
    move.w  au_SectorsC(a3),d2          ;D2 : Number of sectors per cylinder
    move.b  ata_CylinderH(a5),d0
    lsl.w   #8,d0
    move.b  ata_CylinderL(a5),d0        ;D0 : Cylinder number
    mulu    d2,d0
    move.b  ata_DevHead(a5),d2
    andi.w  #ATAF_HEADS,d2              ;D2 : Head number
    mulu    d1,d2
    add.l   d2,d0
    move.b  ata_SectorNum(a5),d1        ;D1 : Sector number
    subq.l  #1,d1                       ;minus 1
    add.l   d1,d0                       ;D0 : LBA address
    movem.l (sp)+,d1/d2
    rts

;*************** LBA mode *****************************************************

.LBA
    move.b  ata_DevHead(a5),d0
    andi.b  #ATAF_HEADS,d0              ;LBA[27..24]
    lsl.w   #8,d0
    move.b  ata_CylinderH(a5),d0        ;LBA[23..16]
    swap    d0
    move.b  ata_CylinderL(a5),d0        ;LBA[15..8]
    lsl.w   #8,d0
    move.b  ata_SectorNum(a5),d0        ;LBA[7..0]
    rts

;******************************************************************************
;********                                                              ********
;********          Drive geometry for Apollo-Install tool (2)          ********
;********                                                              ********
;******************************************************************************

;*************** Special information for the Apollo-Install tool **************

DG_Apollo
    lea     au_ModelID(a3),a0
    moveq   #7,d0                       ;8 long words (or 32 bytes) to copy
.Loop
    move.l  (a0)+,(a2)+                 ;One long word copy
    dbra    d0,.Loop                    ;Loop
    move.l  au_Blocks(a3),d0
    move.b  au_SectShift(a3),d1
    lsl.l   d1,d0
    move.l  d0,(a2)+                    ;Number of bytes
    move.b  au_Heads(a3),(a2)+          ;Number of heads
    move.b  au_SectorsT(a3),(a2)+       ;Number of sectors per track
    move.w  au_Cylinders(a3),(a2)+      ;Number of cylinders
    move.w  au_SectSize+2(a3),(a2)      ;Sector size
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                 Detect and test an ATA drive                 ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A0.l : "ConfigDev" structure address
;A1.l : IDE interface base address
;A2.l : 16-byte array of device selection masks
;A3.l : 16-pointer array of board base addresses
;A4.l : 16-pointer array of "ConfigDev" structures
;A5.l : AT-Apollo.device base address
;D5.b : Controller number (0 to 7)
;D6.b : Drive select mask (0: $00, 1: $10)
;D7.b : Unit number (0 to 15)

;Return values:
;--------------
;D7.b : Next unit number
;Z Flag (0:Ok, 1:Error)

TestDevice
    movem.l d0-d6/a0-a6,-(sp)           ;Save registers

    move.l  a5,a6                       ;A6: AT-Apollo.device base address
    move.l  a1,a5                       ;A5: Apollo board base address
    move.l  a0,d3                       ;D3: "ConfigDev" structure address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

;*************** Test the presence of drives on the ATA bus *******************

    move.b  d6,ata_DevHead(a5)          ;Select the drive
    moveq   #7,d1                       ;8 registers to test
    moveq   #-1,d0                      ;D0 : $FFFFFFFF
.BusLoop
    cmp.l   (a1),d0                     ;$FFFFFFFF present everywhere ?
    bne.b   .BusFound                   ;No, there is something
    lea     ata_NextReg(a1),a1          ;Yes, next register
    dbra    d1,.BusLoop                 ;Loop
    bra.b   .Error                      ;No drive: error
.BusFound

    IFD SERDBG
    movem.l a0-a3/a6/d0/d1,-(sp)
    move.l  ad_SysLib(a6),a6
    lea     DbgBusOkMess(pc),a0
    sub.l   a1,a1
    lea     _LVORawPutChar(a6),a2
    sub.l   a3,a3
    jsr     _LVORawDoFmt(a6)
    movem.l (sp)+,a0-a3/a6/d0/d1
    ENDC

;*************** ATA drive detection ******************************************

    moveq   #99,d2                      ;100 retries
    move.b  d6,d0
    andi.b  #ATAF_DEV,d0                ;We keep the master/slave bit
.DevLoop
    move.b  d6,ata_DevHead(a5)          ;Select the drive
    move.b  ata_DevHead(a5),d1          ;Read back the register
    andi.b  #ATAF_DEV,d1                ;We keep the master/slave bit
    cmp.b   d0,d1                       ;Drive select done ?
    beq.b   .DevFound                   ;Yes, we have an ATA/ATAPI drive
    dbra    d2,.DevLoop                 ;No, new try
    bra.b   .Error                      ;Nothing found: error
.DevFound

    IFD SERDBG
    movem.l a0-a3/a6/d0/d1,-(sp)
    move.l  ad_SysLib(a6),a6
    lea     DbgSelectMess(pc),a0
    sub.l   a1,a1
    lea     _LVORawPutChar(a6),a2
    sub.l   a3,a3
    jsr     _LVORawDoFmt(a6)
    movem.l (sp)+,a0-a3/a6/d0/d1
    ENDC

;*************** Wait for the drive initialization (max. 15s) *****************

    move.l  a6,-(sp)                    ;Save A6
    move.l  ad_TimerIO(a6),a1           ;A1: timerequest structure 
    lea     IOTV_TIME(a1),a0            ;A0: timeval structure
    move.l  IO_DEVICE(a1),a6            ;A6: TimerBase
    jsr     _LVOGetSysTime(a6)          ;Read the system clock
    moveq   #15,d2                      ;15 seconds
    add.l   (a0),d2                     ;D2: + number of seconds

.WaitReset
    move.b  ata_Status(a5),d0           ;Read the ATA status register
    beq.b   .TestMaster                 ;Null : check if it is the master
    btst    #ATAB_BUSY,d0               ;Wait for BUSY=0 (end of Reset)
    bne.b   .TestTime                   ;BUSY=1, check the elapsed time
    btst    #ATAB_DEVREADY,d0           ;Wait for READY=1 (drive ready)
    bne.b   .AutoDetect                 ;READY=1, try an auto-detect
.TestTime
    jsr     _LVOGetSysTime(a6)          ;Read the system clock
    cmp.l   (a0),d2                     ;Time elapsed ?
    bne.b   .WaitReset                  ;No, still waiting

;*************** An error has occured *****************************************

    move.l  (sp)+,a6                    ;A6: AT-Apollo.device base address
.Error
    moveq   #99,d0                      ;100 retries
.DesLoop
    move.b  #0,ata_DevHead(a5)          ;Deselect the drive
    tst.b   ata_DevHead(a5)             ;Deselect done ?
    beq.b   .EndLoop                    ;Yes, exit
    dbra    d0,.DesLoop                 ;No, try again

.EndLoop
    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #0,d0
    movem.l (sp)+,d0-d6/a0-a6           ;Restore registers
    rts                                 ;End

;*************** Check if the drive is master *********************************

.TestMaster
    btst    #ATAB_DEV,d6                ;Master drive ?
    beq.b   .TestTime                   ;Yes, continue

;*************** Auto-detect of an ATA/ATAPI drive ****************************

.AutoDetect
    move.l  (sp)+,a6                    ;A6: AT-Apollo.device base address

    IFD SERDBG
    movem.l a0-a3/a6/d0/d1,-(sp)
    move.l  ad_SysLib(a6),a6
    lea     DbgReadyMess(pc),a0
    sub.l   a1,a1
    lea     _LVORawPutChar(a6),a2
    sub.l   a3,a3
    jsr     _LVORawDoFmt(a6)
    movem.l (sp)+,a0-a3/a6/d0/d1
    ENDC

    bclr    #ATAB_ATAPI,d6              ;ATA protocol : clear bit #7
    move.b  d6,ata_DevHead(a5)          ;Select the drive
    move.b  #ATA_IDENTDEV,ata_Command(a5) ;Auto-Detect ATA

    IFND CPU020
    move.l  #ATA_TimeOut,d0             ;Number of loops
    ENDC

    IFD CPU020
    move.l  #ATA_TimeOut*8,d0           ;Number of loops x 8
    ENDC

.BusyLoop1
    btst    #ATAB_BUSY,ata_Status(a5)   ;Check the BUSY bit
    beq.b   .BusyOk1                    ;BUSY == 0 : continue
    subq.l  #1,d0                       ;i--
    bne.b   .BusyLoop1                  ;i != 0, loop
    bra.b   .Error                      ;Time-out elapsed : error
.BusyOk1
    btst    #ATAB_ERROR,ata_Status(a5)  ;Check ATA error bit
    beq.b   .DevOk                      ;Clear : ATA drive found

    bset    #ATAB_ATAPI,d6              ;ATAPI protocol : set bit #7
    move.b  d6,atapi_DriveSel(a5)       ;Select the drive
    move.b  #ATAPI_IDENTDEV,atapi_Command(a5) ;Auto-Detect ATAPI

    IFND CPU020
    move.l  #ATAPI_TimeOut,d0           ;Number of loops
    ENDC

    IFD CPU020
    move.l  #ATAPI_TimeOut*8,d0         ;Number of loops x 8
    ENDC

.BusyLoop2
    btst    #ATAB_BUSY,ata_Status(a5)   ;Check the BUSY bit
    beq.b   .BusyOk2                    ;BUSY == 0 : continue
    subq.l  #1,d0                       ;i--
    bne.b   .BusyLoop2                  ;i != 0, loop
    bra.b   .Error                      ;Time-out elapsed : error
.BusyOk2
    btst    #ATAPIB_CHECK,atapi_Status(a5) ;An error has occured ?
    beq.b   .DevOk                      ;No, we found an ATAPI drive

    andi.b  #ATAF_DEV,d6                ;Yes, switch back to ATA mode (old ATA drives ?)
    bra.b   .InitArray                  ;Initialize the arrays

.DevOk
    IFD SERDBG
    movem.l a0-a3/a6/d0/d1,-(sp)
    move.l  ad_SysLib(a6),a6
    lea     DbgDetectMess(pc),a0
    sub.l   a1,a1
    lea     _LVORawPutChar(a6),a2
    sub.l   a3,a3
    jsr     _LVORawDoFmt(a6)
    movem.l (sp)+,a0-a3/a6/d0/d1
    ENDC

    moveq   #idev_SIZEOF/4-1,d1         ;D1: Long words to read minus 1
.Loop
    move.l  (a5),d0                     ;Reading one long word
    dbra    d1,.Loop                    ;Loop

.InitArray
    tst.b   d6                          ;ATAPI drive ?
    bmi.b   .AtapiDev                   ;Yes, skip next line
    bsr.b   TestLBA                     ;Check LBA addressing

.AtapiDev
    move.b  d6,d0                       ;Drive select mask
    or.b    d5,d0                       ;Controller number
    move.b  d0,(a2,d7.w)

    ;-------- Optimized code --------
    IFND CPU020
    move.l  d7,d0
    add.l   d0,d0
    add.l   d0,d0
    move.l  d3,(a4,d0.w)                ;"ConfigDev" structure
    move.l  a5,(a3,d0.w)                ;Apollo card base address
    ENDC

    IFD CPU020
    move.l  d3,(a4,d7.w*4)              ;"ConfigDev" structure
    move.l  a5,(a3,d7.w*4)              ;Apollo card base address
    ENDC

    addq.l  #1,d7                       ;Increase the unit number

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #-1,d0
    movem.l (sp)+,d0-d6/a0-a6           ;Restore registers
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********             Check if the drive supports LBA mode             ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A5.l : IDE interface base address
;A6.l : AT-Apollo.device base address
;D6.b : Drive select mask

;Return value:
;-------------
;D6.b : Updated drive select mask

TestLBA
    movem.l d0/d1,-(sp)                 ;Save D0 & D1
    moveq   #0,d0
    bset    #ATAB_LBA,d6                ;LBA mode activated
    move.b  d6,ata_DevHead(a5)          ;Drive selected
    move.b  d0,ata_SectorNum(a5)
    move.b  d0,ata_CylinderL(a5)
    move.b  d0,ata_CylinderH(a5)        ;Block number : 0
    move.b  #1,ata_SectorCnt(a5)        ;Only one sector
    move.b  #ATA_READ,ata_Command(a5)   ;ATA read command ($20)

    IFND CPU020
    move.l  #ATA_TimeOut,d0             ;Number of loops
    ENDC

    IFD CPU020
    move.l  #ATA_TimeOut*8,d0           ;Number of loops x 8
    ENDC
.BusyLoop1
    btst    #ATAB_BUSY,ata_Status(a5)   ;Check the BUSY bit
    beq.b   .BusyOk1                    ;BUSY == 0 : continue
    subq.l  #1,d0                       ;i--
    bne.b   .BusyLoop1                  ;i != 0, loop
    bra.b   .NoLBA                      ;Waiting too long : LBA mode not supported
.BusyOk1
    btst    #ATAB_DATAREQ,ata_Status(a5) ;Check DREQ bit
    beq.b   .NoLBA                      ;DREQ=0 : LBA mode not supported

    move.b  ata_Status(a5),-(sp)        ;Save "ata_Status"

    moveq   #BLOCK_SIZE/4-1,d1          ;Number of long words to read (minus 1)
.Loop
    move.l  (a5),d0                     ;Reading one long word
    dbra    d1,.Loop                    ;Loop
    
    move.b  (sp)+,d1                    ;D1 : ata_Status
    btst    #ATAB_ERROR,d1              ;Check ATA error bit
    bne.b   .NoLBA                      ;Set : LBA mode not supported

    IFND CPU020
    move.l  #ATA_TimeOut,d0             ;Number of loops
    ENDC

    IFD CPU020
    move.l  #ATA_TimeOut*8,d0           ;Number of loops x 8
    ENDC
.BusyLoop2
    btst    #ATAB_BUSY,ata_Status(a5)   ;Check the BUSY bit
    beq.b   .End                        ;BUSY == 0 : exit
    subq.l  #1,d0                       ;i--
    bne.b   .BusyLoop2                  ;i != 0, loop

.NoLBA
    bclr    #ATAB_LBA,d6                ;Deactivate LBA mode
.End
    movem.l (sp)+,d0/d1                 ;Restore registers
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********            Check if address decoding is incomplete           ********
;********                                                              ********
;******************************************************************************

;A1.l : IDE interface base address

;Return value:
;-------------
;Z Flag : 0=Decoding OK, 1=Decoding incomplete

TestMirror
    movem.l d0/a5/a6,-(sp)
    move.l  a5,a6
    move.l  a1,a5
    move.b  #ATAF_MASTER,ata_DevHead(a5)
    move.b  #ATA_NOP,ata_Command(a5)

    IFND CPU020
    move.l  #ATA_TimeOut,d0             ;Number of loops
    ENDC

    IFD CPU020
    move.l  #ATA_TimeOut*8,d0           ;Number of loops x 8
    ENDC
.BusyLoop
    btst    #ATAB_BUSY,ata_Status(a5)   ;Check the BUSY bit
    beq.b   .BusyOk                     ;BUSY == 0 : exit
    subq.l  #1,d0                       ;i--
    bne.b   .BusyLoop                   ;i != 0, loop
    bra.b   .DecOk
.BusyOk

    move.b  ata_Status(a5),d0
    move.b  #ATAF_SLAVE,ata_DevHead(a5)
    cmp.b   ata_Status(a5),d0           ;Incomplete address decoding ?
    bne.b   .DecOk                      ;No, exit

    moveq   #0,d0
    movem.l (sp)+,d0/a5/a6
    rts

.DecOk
    moveq   #-1,d0
    movem.l (sp)+,d0/a5/a6
    rts

;******************************************************************************
;********                                                              ********
;********                 IDE-Mux board presence check                 ********
;********                                                              ********
;******************************************************************************

;A1.l : IDE interface base address

;Return value:
;-------------
; D0 : 0=Present, -1=Not present

TestPort2
    movem.l d1/a5,-(sp)
    lea     ata_NextPort(a1),a5         ;A5 : Second port address

    moveq   #$55,d0
    move.b  d0,ata_SectorCnt(a1)        ;Sector Count = $55
    cmp.b   ata_SectorCnt(a5),d0        ;Incomplete address decoding ?
    bne.b   .NoMirror                   ;No, skip

    add.b   d0,d0
    move.b  d0,ata_SectorCnt(a1)        ;Sector Count = $AA
    cmp.b   ata_SectorCnt(a5),d0        ;Incomplete address decoding ?
    bne.b   .NoMirror                   ;No, skip

    bra.b   .Mirror                     ;Yes

.NoMirror
    moveq   #5,d1                       ;6 registers to test
    moveq   #-1,d0                      ;D0 : $FFFFFFFF
.TestLoop
    cmp.l   (a5),d0                     ;We found $FFFFFFFF everywhere ?
    bne.b   .Found                      ;No, IDE-Mux board present
    lea     ata_NextReg(a5),a5          ;Yes, next register
    dbra    d1,.TestLoop                ;Loop

.Mirror
    move.b  ata_AltStatus(a1),d0
    cmp.b   ata_Status(a1),d0           ;Status = Alternate Status ?
    bne.b   .Found                      ;No, IDE-Mux board present

    movem.l (sp)+,d1/a5                 ;Yes, no IDE-Mux board
    moveq   #-1,d0
    rts

.Found
    movem.l (sp)+,d1/a5                 ;IDE-Mux board found
    moveq   #0,d0
    rts

;******************************************************************************
;********                                                              ********
;********             ApolloUnit structure initialization              ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address
;A6.l : ExecBase

;Return value:
;-------------
;Z Flag (0:Ok, 1:Error)

UnitInfo
    movem.l d0-d3/a0-a2,-(sp)           ;Save D0 - D3, A0 - A2

    lea     -BLOCK_SIZE(sp),sp          ;Allocate one block on the stack
    move.l  sp,a0                       ;A0 : buffer's address

;******** Allocate memory *****************************************************

;    move.l  #BLOCK_SIZE,d0              ;Sector size
;    moveq   #0,d1                       ;Any memory
;    jsr     _LVOAllocMem(a6)            ;Allocate one buffer
;    tst.l   d0                          ;No more memory ?
;    beq.w   .Error                      ;Yes, error
;    move.l  d0,a0                       ;A0 : buffer's address

;******** Device identification ***********************************************

    moveq   #-1,d0
    move.l  d0,au_RDBSector(a3)         ;Invalidate RDB's LBA

    bsr.w   ata_Identify                ;ATA-3 disk identify
    beq.w   .Search                     ;Error : search by trial/error

    lea     idev_ModelNumber(a0),a1     ;A1: Source
    lea     au_ModelID(a3),a2           ;A2: Destination
    moveq   #7,d0                       ;8 long words to copy
.CopyLoop
    move.l  (a1)+,(a2)+                 ;Copy one long word
    dbra    d0,.CopyLoop                ;Loop

    move.l  idev_RevisionNumber(a0),(a2)+ ;Firmware version

    movem.l idev_SerialNumber(a0),d0-d2
    movem.l d0-d2,(a2)                  ;Serial number

;******** Drive geometry ******************************************************

    move.w  idev_Heads(a0),d0
    move.b  d0,au_Heads(a3)             ;D0: Number of heads
    move.w  idev_Sectors(a0),d1
    move.b  d1,au_SectorsT(a3)          ;D1: Number of sectors per track
    move.w  idev_Cylinders(a0),d2
    move.w  d2,au_Cylinders(a3)         ;D2: Number of cylinders
    mulu    d1,d0                       ;D0 x D1 =
    move.w  d0,au_SectorsC(a3)          ;Number of sectors per cylinder
    mulu    d2,d0                       ; x D2 =
    move.l  d0,au_Blocks(a3)            ;Number of blocks

    tst.b   1(a0)                       ;Removable media ?
    bpl.b   .NoRemove                   ;No, skip
    st.b    au_Removable(a3)            ;Yes, set the removable flag
    move.b  #6,au_SenseKey(a3)          ;Sense key = 6 (Unit attention)
.NoRemove
    st.b    au_DiskPresent(a3)          ;Default : media present

    moveq   #9,d1                       ;2^9 bytes block
    move.b  (a0),d2
    andi.b  #%00001111,d2               ;Device type
    tst.b   au_AtapiDev(a3)             ;ATAPI device ?
    bne.b   .AtapiDev                   ;Yes, skip next line
    moveq   #DG_DIRECT_ACCESS,d2        ;No, device type = hard drive
.AtapiDev
    move.b  d2,au_DevType(a3)           ;Save the device type
    beq.b   .Direct                     ;Hard drive : skip next line
    moveq   #11,d1                      ;2^11 bytes block
.Direct
    moveq   #0,d2
    bset    d1,d2
    move.b  d1,au_SectShift(a3)         ;Block size (Log 2)
    move.l  d2,au_SectSize(a3)          ;Block size

;******** Drive geometry search ***********************************************

    tst.b   au_Removable(a3)            ;Removable media ?
    bne.b   .LastOk                     ;Yes, skip the search
    subq.l  #1,d0                       ;D0: last sector's LBA address
    moveq   #1,d1                       ;D1: one sector to read
    jsr     au_ReadJmp(a3)              ;Read the media's last sector
    tst.b   d0                          ;Check the error code
    beq.b   .LastOk                     ;No error : next step
.Search
    tst.b   au_AtapiDev(a3)             ;Error : ATAPI peripheral ?
    bne.b   .LastOk                     ;Yes, skip the CHS search
    bsr.w   SearchCHS                   ;No, search by trials and errors
.LastOk

;******** Rigid Disk Block (RDB) read *****************************************

    tst.b   au_DevType(a3)              ;Hard drive ?
    bne.b   .NoRDB                      ;No, skip
    bsr.b   RDBInfo                     ;Yes, retrieve info from the RDB
.NoRDB

;******** End : free up the memory ********************************************

;.Continue
;    move.l  a0,a1
;    move.l  #BLOCK_SIZE,d0
;    jsr     _LVOFreeMem(a6)
    lea     BLOCK_SIZE(sp),sp           ;Restore the stack

    moveq   #1,d0                       ;Flag Z = 0 : Ok
    movem.l (sp)+,d0-d3/a0-a2           ;Restore D0 to D3 & A0 to A2
    rts                                 ;End

;******** Error : exit ********************************************************

.Error
    moveq   #0,d0                       ;Flag Z = 1 : Error
    movem.l (sp)+,d0-d3/a0-a2           ;Restore D0 to D3 & A0 to A2
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********             Rigid Disk Block search on the disk              ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address
;A6.l : ExecBase

RDBInfo
    moveq   #0,d3                       ;D3 : point to the non-swapped routines

;******** Rigid Disk Block search loop ****************************************

    moveq   #0,d2                       ;D2 : block's LBA = 0
.RDBLoop
    sf.b    au_Swapped(a3)              ;Clear the byte swapped flag
    move.l  d2,d0                       ;Block's LBA
    moveq   #1,d1                       ;One block to read
    jsr     au_ReadJmp(a3)              ;Read the block
    tst.b   d0                          ;Error code check
    bne.b   .End                        ;Error : exit
    cmpi.l  #"RDSK",rdb_ID(a0)          ;Valid RDB identifier ?
    beq.b   .RDBFound                   ;Yes, Apollo RDB found
    cmpi.l  #"DRKS",rdb_ID(a0)          ;Swapped RDB identifier ?
    beq.b   .InvRDBFound                ;Yes, A600/1200/4000 RDB found
.NextRDB
    addq.b  #1,d2                       ;Next block
    cmp.b   #RDB_LOCATION_LIMIT,d2      ;RDB reserved area scanned ?
    bne.b   .RDBLoop                    ;No, resume RDB search
.End
    rts                                 ;Yes, exit

;******** Swapped RDB found ***************************************************

.InvRDBFound
    moveq   #BLOCK_SIZE/4-1,d3          ;Number of long words to swap (minus 1)
.InvLoop
    movem.w (a0)+,d0/d1                 ;Reading one word long
    rol.w   #8,d0
    rol.w   #8,d1                       ;Swap LSBs <-> MSBs
    movem.w d0/d1,-4(a0)                ;Swapped long word write
    dbra    d3,.InvLoop                 ;Loop
    lea     -BLOCK_SIZE(a0),a0          ;Restore A0
    st.b    au_Swapped(a3)              ;Set the byte swapped flag
    moveq   #4,d3                       ;D3 : point to the swapped routines

;******** Regular RDB found ***************************************************

.RDBFound
    move.l  a0,-(sp)                    ;Save A0
    move.l  rdb_SummedLongs(a0),d1      ;RDB size (in long words)
    subq.w  #1,d1                       ;-1 : for DBRA
    moveq   #0,d0
.SumLoop
    add.l   (a0)+,d0                    ;Long words summing
    dbra    d1,.SumLoop                 ;Loop
    move.l  (sp)+,a0                    ;Restore A0
    tst.l   d0                          ;Valid checksum ?
    bne.b   .NextRDB                    ;No, resume RDB search

;*************** Valid RDB : update ApolloUnit ********************************

    move.l  d2,au_RDBSector(a3)         ;Yes, save the RDB's LBA

    cmpi.l  #'Apol',rdb_ControllerProduct(a0) ;Apollo controller ?
    bne.b   .End                        ;No, exit

    move.l  rdb_ControllerRevision(a0),d0 ;Yes, set the Apollo parameters
    bra.b   SetParams2

;******************************************************************************
;********                                                              ********
;********              Set the Apollo specific parameters              ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;D0.l : Apollo specific parameters (rdb_ControllerRevision)
;A3.l : ApolloUnit base address
;A6.l : ExecBase

SetParams
    moveq   #0,d3
    btst    #AUB_SWAP,d0                ;Swapped mode ?
    beq.b   .Swap                       ;No, skip
    st.b    au_Swapped(a3)              ;Yes
    moveq   #4,d3
.Swap

    btst    #AUB_SLOW,d0                ;Slow peripheral ?
    sne.b   au_SlowDevice(a3)           ;Yes

;******** Second entry point for "RDBInfo" ************************************

SetParams2
    move.l  a0,-(sp)
    move.l  d3,d2

    btst    #AUB_FREAD,d0               ;Read-mode = Safe ?
    bne.b   .NoFRead                    ;Yes, disable fast read
    st.b    au_ReadMode(a3)             ;No, enable fast read
    addq.l  #2,d2
.NoFRead

    btst    #AUB_FWRITE,d0              ;Write-mode = Safe ?
    bne.b   .NoFWrite                   ;Yes, disable fast write
    st.b    au_WriteMode(a3)            ;No, enable fast write
    addq.l  #2,d3
.NoFWrite

    tst.b   au_AtapiDev(a3)
    bne.b   .NoAtaFunc
    lea     .FuncMap(pc),a0
    move.w  0(a0,d2.l),d2
    move.w  8(a0,d3.l),d3
    ext.l   d2
    ext.l   d3
    add.l   a0,d2
    add.l   a0,d3
    move.l  d2,au_ReadSub(a3)
    move.l  d3,au_WriteSub(a3)
    move.l  d3,au_FormatSub(a3)
.NoAtaFunc

    btst    #AUB_INTDIS,d0              ;Interrupts disabled option ?
    sne.b   au_IntDisable(a3)           ;Yes

    btst    #AUB_RCACHE,d0              ;Read cache activated option ?
    sne.b   au_RCacheOn(a3)             ;Yes

    btst    #AUB_WCACHE,d0              ;Write cache activated option ?
    sne.b   au_WCacheOn(a3)             ;Yes

    swap    d0                          ;Caches sizes
    cmpi.b  #3,d0
    bcs.b   .WCSizeNOk
    cmpi.b  #8,d0
    bhi.b   .WCSizeNOk                  ;Boundaries check
    bra.b   .WCSizeOk
.WCSizeNOk
    move.b  #6,d0                       ;Default size : 2^6 (64) blocks
.WCSizeOk
    moveq   #0,d1
    bset    d0,d1
    subq.w  #1,d1
    move.w  d1,au_WCacheSize(a3)        ;Write cache size - 1

    lsr.w   #8,d0
    beq.b   .RCSizeNOk
    cmpi.b  #32,d0
    bhi.b   .RCSizeNOk                  ;Boundaries check
    bra.b   .RCSizeOk
.RCSizeNOk
    moveq   #4,d0                       ;Default size : 4 x 8 (32) blocks
.RCSizeOk
    lsl.w   #3,d0                       ; x 8
    ext.l   d0
    move.l  d0,au_RCacheSize(a3)        ;Read-Prefetch cache size

    bsr.w   AllocCache                  ;Cache memory allocation
    bne.b   .End                        ;No error : end

    bsr.w   FreeCache                   ;Error : free cache memory
.End
    move.l  (sp)+,a0
    rts                                 ;End

.FuncMap
    dc.w    ata_SlowReadNorm-.FuncMap
    dc.w    ata_FastReadNorm-.FuncMap
    dc.w    ata_SlowReadSwap-.FuncMap
    dc.w    ata_FastReadSwap-.FuncMap
    dc.w    ata_SlowWriteNorm-.FuncMap
    dc.w    ata_FastWriteNorm-.FuncMap
    dc.w    ata_SlowWriteSwap-.FuncMap
    dc.w    ata_FastWriteSwap-.FuncMap


;******************************************************************************
;********                                                              ********
;********             Clear the Apollo specific parameters             ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address
;A6.l : ExecBase

ClrParams
    sf.b    au_Swapped(a3)
    sf.b    au_SlowDevice(a3)
    sf.b    au_ReadMode(a3)
    sf.b    au_WriteMode(a3)
    sf.b    au_SlowDevice(a3)           ;Clear the flags
    bra.w   FreeCache                   ;Free the caches

;******************************************************************************
;********                                                              ********
;********            Find drive geometry by trial and error            ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A0.l : Buffer adddress
;A3.l : ApolloUnit base address

SearchCHS

;*************** Find the number of sectors ***********************************

    moveq   #0,d0                       ;D0: Head number     = 0
    moveq   #1,d1                       ;D1: Sector number   = 1
    moveq   #0,d2                       ;D2: Cylinder number = 0
.SearchSec
    bsr.b   ata_ReadSectorCHS           ;Read one sector
    beq.b   .SecFound                   ;Error : max sector found
    addq.b  #1,d1                       ;Otherwise, increment the sector number
    cmpi.b  #65,d1                      ;Is sector number == 65 ?
    bne.b   .SearchSec                  ;No, go on looping
    moveq   #36,d1                      ;Yes, sector number = 36
.SecFound
    subq.b  #1,d1
    move.b  d1,au_SectorsT(a3)          ;Number of sectors per track

;*************** Find the number of heads *************************************

    moveq   #0,d0                       ;D0: Head number     = 0
    moveq   #1,d1                       ;D1: Sector number   = 1
    moveq   #0,d2                       ;D2: Cylinder number = 0
.SearchHead
    bsr.b   ata_ReadSectorCHS           ;Read one sector
    beq.b   .HeadFound                  ;Error : max head found
    addq.b  #1,d0                       ;Otherwise, increment the head number
    cmpi.b  #16,d0                      ;Is head number = 16 ?
    bne.b   .SearchHead                 ;No, go on looping
.HeadFound
    move.b  d0,au_Heads(a3)             ;Number of heads

;*************** Find the number of cylinders (binary search) *****************

    moveq   #0,d0                       ;D0: Head number     = 0
    moveq   #1,d1                       ;D1: Sector number   = 1
    move.w  #32768,d2                   ;D2: Cylinder number = 32768
    move.w  d2,d3                       ;D3: Cylinder increment = 32768
.SearchCyl
    lsr.w   #1,d3                       ;Increment / 2
    beq.b   .CylFound                   ;Null increment : end of search
    bsr.b   ata_ReadSectorCHS           ;Read one sector
    beq.b   .Dec                        ;Error : jump to ".Dec"
    add.w   d3,d2                       ;No error : increment the cylinder number
    bra.b   .SearchCyl                  ;Loop
.Dec
    sub.l   d3,d2                       ;Decrement the cylinder number
    bra.b   .SearchCyl                  ;Loop
.CylFound
    bsr.b   ata_ReadSectorCHS           ;Read the drive's last sector
    beq.b   .Jump                       ;Error : jump to ".Jump"
    addq.l  #1,d2                       ;No error : increase the cylinder number
.Jump
    move.w  d2,au_Cylinders(a3)         ;Number of cylinders

;*************** Additional geometry data *************************************

    move.b  au_Heads(a3),d0             ;Number of heads
    move.b  au_SectorsT(a3),d1          ;Number of sectors per track
    mulu    d1,d0
    move.w  d0,au_SectorsC(a3)          ;Number of sectors per cylinder
    mulu    d2,d0
    move.l  d0,au_Blocks(a3)            ;Total number of blocks

    moveq   #DG_DIRECT_ACCESS,d0        ;Type : hard drive
    move.b  d0,au_DevType(a3)
    moveq   #9,d1                       ;Block size : 2^9 bytes
    bset    d1,d0
    move.b  d1,au_SectShift(a3)         ;Size (log 2)
    move.l  d0,au_SectSize(a3)          ;Size (in bytes)

    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********            Read one sector, using CHS addressing             ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;D0.b : Head number
;D1.b : Sector number
;D2.w : Cylinder number
;A0.l : Buffer address
;A3.l : ApolloUnit base address

;Return value:
;-------------
;Z Flag (0:Ok, 1:Error)

ata_ReadSectorCHS
    movem.l d0-d2/a5/a6,-(sp)           ;Save D0, D1, D2, A5 & A6

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC
    
    or.b    au_OldDevMask(a3),d0        ;Head number ORed with old selection mask
    move.b  d0,ata_DevHead(a5)
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    move.b  d1,ata_SectorNum(a5)        ;Sector number
    move.b  d2,ata_CylinderL(a5)        ;Cylinder number (LSB)
    lsr.w   #8,d2
    move.b  d2,ata_CylinderH(a5)        ;Cylinder number (MSB)
    move.b  #1,ata_SectorCnt(a5)        ;Only one sector
    move.b  #ATA_READ,ata_Command(a5)   ;ATA read command ($20)
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error

    moveq   #BLOCK_SIZE/4-1,d1          ;Number of long words to read (minus 1)
.Loop
    move.l  (a5),(a0)+                  ;Reading one word long
    dbra    d1,.Loop                    ;Loop
    lea     -BLOCK_SIZE(a0),a0          ;Restore A0

    btst    #ATAB_ERROR,d0              ;Check ATA error bit
    bne.b   .Error                      ;Set : exit with an error
    btst    #ATAB_DATAREQ,ata_Status(a5) ;It remains some data to read ?
    bne.b   .Error                      ;Yes, error

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #1,d0                       ;Flag Z = 0 : Ok
    movem.l (sp)+,d0-d2/a5/a6           ;Restore D0, D1, D2, A5 & A6
    rts                                 ;End

.Error
    bsr.w   ResumeError                 ;Drive reset

    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    moveq   #0,d0                       ;Flag Z = 1 : Error
    movem.l (sp)+,d0-d2/a5/a6           ;Restore D0, D1, D2, A5 & A6
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                     Send an ATAPI packet                     ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address
;A4.l : SCSI CDB address
;A5.l : IDE interface base address
;A6.l : AT-Apollo.device base address

;Return value:
;-------------
;Z Flag (0:Ok, 1:Error)

SendPacket
    movem.l d0/d1,-(sp)                 ;Save D0 & D1

    move.b  au_DevMask(a3),atapi_DriveSel(a5) ;Drive select
    bsr.b   WaitBusy                    ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    moveq   #0,d0
    move.b  d0,atapi_Features(a5)
    move.b  d0,atapi_ByteCntH(a5)
    move.b  d0,atapi_ByteCntL(a5)
    move.b  #ATAPI_PACKET,atapi_Command(a5) ;Send the CDB
    bsr.b   WaitBusySlow                ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    btst    #ATAB_DATAREQ,d0            ;DREQ = 1 ?
    beq.b   .Error                      ;No, error

    move.b  atapi_Reason(a5),d0         ;Interrupt Reason Register
    andi.b  #ATAPIF_MASK,d0             ;Bits IO & CoD
    cmpi.b  #ATAPIF_COMMAND,d0          ;Ready to accept the command ?
    bne.b   .Error                      ;No, error

    moveq   #5,d1                       ;6 words to send
.SendLoop
    move.w  (a4)+,d0
    rol.w   #8,d0
    move.w  d0,(a5)                     ;Send the CDB
    dbra    d1,.SendLoop
    lea     -12(a4),a4                  ;Restore A4

    moveq   #1,d0                       ;Flag Z = 0 : Ok
    movem.l (sp)+,d0/d1                 ;Restore D0 & D1
    rts                                 ;End

.Error
    moveq   #0,d0                       ;Flag Z = 1 : Error
    movem.l (sp)+,d0/d1                 ;Restore D0 & D1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********               Wait for BUSY flag being cleared               ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address
;A5.l : IDE interface base address

;Return values:
;--------------
;Z Flag (0:Ok, 1:Error)
;D0.b : ata_Status

WaitBusy
    movem.l d1,-(sp)                    ;Save D1
    move.l  au_NumLoop(a3),d1           ;i = NumLoop
.Wait
    move.b  ata_Status(a5),d0           ;Read the ata_Status register
    btst    #ATAB_BUSY,d0               ;Check the BUSY bit
    beq.b   .Ok                         ;BUSY == 0 : exit
    subq.l  #1,d1                       ;i--
    bne.b   .Wait                       ;i != 0 : loop
.Ok
    tst.l   d1                          ;Update the Z flag
    movem.l (sp)+,d1                    ;Restore D1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********     Wait for BUSY flag being cleared (using timer.device)    ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address
;A5.l : IDE interface base address
;A6.l : AT-Apollo.device base address

;Return values:
;--------------
;Z Flag (0:Ok, 1:Error)
;D0.b : ata_Status

WaitBusySlow
    tst.b   au_SlowDevice(a3)           ;Slow peripheral ?
    beq.b   WaitBusy                    ;No, regular wait

    movem.l d1-d3/a0-a2,-(sp)           ;Save the registers

    move.w  #1000,d3                    ;1000 retries
.Wait1
    move.b  ata_Status(a5),d0           ;Read the ata_Status register
    btst    #ATAB_BUSY,d0               ;Check the BUSY bit
    beq.b   .End                        ;BUSY == 0 : exit
    subq.w  #1,d3
    bne.b   .Wait1                      ;Loop

    lea     .WaitTable(pc),a2
.Wait2
    move.l  (a2)+,d3                    ;Number of micro-seconds
    beq.b   .End                        ;Null : end
    move.w  (a2)+,d2                    ;Number of tests
.Wait3
    move.l  ad_TimerIO(a6),a1
    move.w  #TR_ADDREQUEST,IO_COMMAND(a1)
    clr.l   IOTV_TIME+TV_SECS(a1)
    move.l  d3,IOTV_TIME+TV_MICRO(a1)
    move.l  ad_SysLib(a6),a6
    jsr     _LVODoIO(a6)
    move.l  au_Device(a3),a6

    move.b  ata_Status(a5),d0           ;Read the ata_Status register
    btst    #ATAB_BUSY,d0               ;Check the BUSY bit
    beq.b   .End                        ;BUSY == 0 : exit

    dbra    d2,.Wait3
    bra.b   .Wait2                      ;Loop
.End
    tst.l   d3                          ;Set/Clear the Z flag
    movem.l (sp)+,d1-d3/a0-a2           ;Restore the registers
    rts                                 ;End

.WaitTable
    dc.l    1000                        ;    1 ms
    dc.w    19                          ;x  20
    dc.l    5000                        ;    5 ms
    dc.w    15                          ;x  16
    dc.l    10000                       ;   10 ms
    dc.w    19                          ;x  20
    dc.l    20000                       ;   20 ms
    dc.w    9                           ;x  10
    dc.l    50000                       ;   50 ms
    dc.w    9                           ;x  10
    dc.l    100000                      ;  100 ms
    dc.w    89                          ;x  90
    dc.l    0                           ;--------
                                        ;10000 ms

;******************************************************************************
;********                                                              ********
;********      Wait for BUSY flag being cleared (4 times longer)       ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address
;A5.l : IDE interface base address

;Return values:
;--------------
;Z Flag (0:Ok, 1:Error)
;D0.b : ata_Status

WaitBusyLong
    movem.l d1,-(sp)                    ;Save D0
    move.l  au_NumLoop(a3),d1
    lsl.l   #2,d1                       ;i = NumLoop x 4
.Wait
    move.b  ata_Status(a5),d0           ;Read the ata_Status register
    btst    #ATAB_BUSY,d0               ;Check the BUSY bit
    beq.b   .Ok                         ;BUSY == 0 : exit
    subq.l  #1,d1                       ;i--
    bne.b   .Wait                       ;i != 0 : loop
.Ok
    tst.l   d1                          ;Update the Z flag
    movem.l (sp)+,d1                    ;Restore D0
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                  Reset drive after an error                  ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A3.l : ApolloUnit base address
;A5.l : IDE interface base address
;A6.l : AT-Apollo.device base address

;Return values:
;--------------
;Z Flag (0:Ok, 1:Error)

ResumeError
    tst.b   au_AtapiDev(a3)                ;Check protocol used
    beq.b   .Ata
    move.b  #ATAPI_RESET,atapi_Command(a5) ;ATAPI drive reset
    bra.b   WaitBusyLong                   ;Wait for BUSY == 0

.Ata
    move.b  #ATA_RECALIBRATE,ata_Command(a5) ;ATA drive recalibrate
    bra.b   WaitBusyLong                     ;Wait for BUSY == 0

;******************************************************************************
;********                                                              ********
;********             Freeze CPU 68030/040/060 data cache              ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A6.l : AT-Apollo.device base address

    IFD CPU020
FreezeCache
    movem.l d0/d1/a0/a5/a6,-(sp)

    move.l  ad_SysLib(a6),a6            ;A6 : ExecBase
    cmpi.w  #33,LIB_VERSION(a6)         ;Version > 33 ?
    bls.b   .Kick1x                     ;No, use our own routine

    move.l  #CACRF_FreezeD,d0           ;Yes, use CacheControl()
    move.l  #CACRF_FreezeD,d1
    jsr     _LVOCacheControl(a6)        ;Freeze CPU data cache

.End
    movem.l (sp)+,d0/d1/a0/a5/a6
    rts

.Kick1x
    move.w  AttnFlags(a6),d0
    btst    #AFB_68030,d0               ;030+ CPU ?
    beq.b   .End                        ;No, exit
    lea     .Super(pc),a5
    jsr     _LVOSupervisor(a6)
    bra.b   .End

.Super
    movec   cacr,d0
    bset    #CACRB_FreezeD,d0
    movec   d0,cacr
    rte
    ENDC

;******************************************************************************
;********                                                              ********
;********            Unfreeze CPU 68030/040/060 data cache             ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A6.l : AT-Apollo.device base address

    IFD CPU020
UnFreezeCache
    movem.l d0/d1/a0/a5/a6,-(sp)

    move.l  ad_SysLib(a6),a6            ;A6 : ExecBase
    cmpi.w  #33,LIB_VERSION(a6)         ;Version > 33 ?
    bls.b   .Kick1x                     ;No, use our own routine

    moveq   #0,d0                       ;Yes, use CacheControl()
    move.l  #CACRF_FreezeD,d1
    jsr     _LVOCacheControl(a6)        ;Unfreeze CPU data cache

.End    
    movem.l (sp)+,d0/d1/a0/a5/a6
    rts

.Kick1x
    move.w  AttnFlags(a6),d0
    btst    #AFB_68030,d0               ;030+ CPU ?
    beq.b   .End                        ;No, exit
    lea     .Super(pc),a5
    jsr     _LVOSupervisor(a6)
    bra.b   .End

.Super
    movec   cacr,d0
    bclr    #CACRB_FreezeD,d0
    movec   d0,cacr
    rte
    ENDC

;******************************************************************************
; ----------   "SCSI DIRECT" IMPLEMENTATION FOR ATA & ATAPI DRIVES   ----------
;******************************************************************************

;******************************************************************************
;********                                                              ********
;********                SCSI-2 commands for ATA drives                ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : Standard I/O Request
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

ata_ScsiCmd
    move.l  a1,-(sp)                    ;Save A1

    clr.l   scsi_Actual(a2)
    clr.w   scsi_CmdActual(a2)
    clr.w   scsi_SenseActual(a2)        ;We clear the command's
    clr.b   scsi_Status(a2)             ;sizes and states

    move.l  scsi_Command(a2),a1
    move.b  (a1),d0                     ;D0: Command byte
    cmpi.b  #SCSI_REQUESTSENSE,d0       ;$03: REQUEST SENSE command
    beq.w   scsi_RequestSense
    clr.w   au_SenseKey(a3)             ;No, clear the errors
    clr.l   au_LBASense(a3)

    tst.b   d0                          ;$00: TEST UNIT READY command
    beq.w   scsi_TestUnitReady
    subq.b  #1,d0                       ;$01: RE-ZERO UNIT command
;    beq.w   scsi_RezeroUnit
    subq.b  #3,d0                       ;$04: FORMAT UNIT command
;    beq.b   scsi_FormatUnit
    subq.b  #4,d0                       ;$08: READ(6) command
    beq.w   scsi_Read6
    subq.b  #2,d0                       ;$0A: WRITE(6) command
    beq.w   scsi_Write6
    subq.b  #1,d0                       ;$0B: SEEK(6) command
    beq.w   scsi_Seek6
    subq.b  #7,d0                       ;$12: INQUIRY command
    beq.w   scsi_Inquiry
    subq.b  #1,d0                       ;$13: VERIFY(6) command
;    beq.w   scsi_Verify6
    subq.b  #3,d0                       ;$16: RESERVE(6) command
;    beq.b   scsi_Reserve6
    subq.b  #1,d0                       ;$17: RELEASE(6) command
;    beq.b   scsi_Release6
    subq.b  #3,d0                       ;$1A: MODE SENSE(6) command
    beq.w   scsi_ModeSense6
    subq.b  #3,d0                       ;$1D: SEND DIAGNOSTIC command
;    beq.b   scsi_SendDiagnostic
    subq.b  #8,d0                       ;$25: READ CAPACITY command
    beq.w   scsi_ReadCapacity
    subq.b  #3,d0                       ;$28: READ(10) command
    beq.w   scsi_Read10
    subq.b  #2,d0                       ;$2A: WRITE(10) command
    beq.w   scsi_Write10
    subq.b  #1,d0                       ;$2B: SEEK(10) command
    beq.w   scsi_Seek10
    subq.b  #4,d0                       ;$2F: VERIFY(10) command
    beq.w   scsi_Verify10
    subi.b  #$26,d0                     ;$55: MODE SELECT(10) command
;    beq.w   scsi_ModeSelect10
    subq.b  #1,d0                       ;$56: RESERVE(10) command
;    beq.b   scsi_Reserve10
    subq.b  #1,d0                       ;$57: RELEASE(10) command
;    beq.b   scsi_Release10
    subq.b  #3,d0                       ;$5A: MODE SENSE(10) command
;    beq.b   scsi_ModeSense10
    subi.b  #$4E,d0                     ;$A8: READ(12) command
    beq.w   scsi_Read12
    subq.b  #2,d0                       ;$AA: WRITE(12) command
    beq.w   scsi_Write12
    subq.b  #5,d0                       ;$AF: VERIFY(12) command
    beq.w   scsi_Verify12

ScsiInvCmd
    move.w  #$0520,au_SenseKey(a3)      ;Illegal request + Invalid cmd opcode

ScsiError
    btst    #SCSIB_AUTOSENSE,scsi_Flags(a2) ;Auto-Sense mode ?
    beq.b   .Error1                     ;No, exit

    lea     -18(sp),sp

    moveq   #0,d1
    move.w  au_SenseKey(a3),d0
    move.b  d0,d1
    clr.b   d0

    move.l  sp,a0
    move.b  #$70,(a0)+                  ;Current error
    move.w  d1,(a0)+                    ;Sense key
    move.l  au_LBASense(a3),(a0)+       ;LBA where the error occured
    move.b  #10,(a0)+                   ;Additional size
    clr.l   (a0)+
    move.w  d0,(a0)+                    ;Additional sense code
    clr.l   (a0)+

    moveq   #4,d0                       ;4 bytes for the "Old Auto-Sense"
    btst    #SCSIB_OLDAUTOSENSE,scsi_Flags(a2) ;Old Auto-Sense mode ?
    bne.b   .OldAS                      ;Yes, skip next line
    move.w  scsi_SenseLength(a2),d0     ;No, keep the size into account
.OldAS
    cmpi.w  #18,d0                      ;Greater than 18 ?
    bls.b   .Lower                      ;No, skip
    moveq   #18,d0                      ;Yes, limit to 18
.Lower
    move.w  d0,scsi_SenseActual(a2)
    subq.w  #1,d0
    bcs.b   .Error2

    move.l  sp,a0                       ;A0: Source
    move.l  scsi_SenseData(a2),a1       ;A1: Destination
.SenseLoop
    move.b  (a0)+,(a1)+                 ;Copy one byte
    dbra    d0,.SenseLoop               ;Loop

.Error2
    lea     18(sp),sp                   ;Restore stack
.Error1
    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********               SCSI-2 commands for ATAPI drives               ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : Standard I/O Request
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

atapi_ScsiCmd
    movem.l a1/a4-a6,-(sp)              ;Save A1, A4, A5 & A6

    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address

    clr.l   -(sp)
    clr.l   -(sp)
    clr.l   -(sp)                       ;Allocate CDB size on the stack

;*************** CPU data cache managemnt *************************************

    IFD CPU020
    bsr.w   FreezeCache                 ;Freeze CPU data cache
    ENDC

;*************** Initialize various variables *********************************

    clr.w   scsi_SenseActual(a2)        ;No sense key
    clr.b   scsi_Status(a2)             ;No error
    clr.l   scsi_Actual(a2)             ;No data transfered
    move.w  scsi_CmdLength(a2),d0       ;D0: Command length
    cmpi.w  #12,d0                      ;CDB size greater than 12 bytes ?
    bhi.w   .Error                      ;Yes, error
    cmpi.w  #6,d0                       ;CDB size less than 6 bytes ?
    bcs.w   .Error                      ;Yes, error
    move.w  d0,scsi_CmdActual(a2)       ;Otherwise, write the size into CmdActual
    lsr.w   #1,d0
    subq.w  #1,d0

;*************** CDB copy *****************************************************

    move.l  scsi_Command(a2),a0
    move.l  sp,a1
.CopyLoop
    move.w  (a0)+,(a1)+                 ;CDB copy loop
    dbra    d0,.CopyLoop

;*************** SCSI-1 compatibility *****************************************

    move.l  sp,a4
    move.b  (a4),d0
    cmpi.b  #$20,d0                     ;SCSI-2 commands ?
    bcc.b   .SendCDB                    ;Yes, no conversion
    cmpi.b  #SCSI_READ6,d0              ;READ(6) command ?
    beq.b   .BlkCmd                     ;Yes, convert it
    cmpi.b  #SCSI_WRITE6,d0             ;WRITE(6) command ?
    beq.b   .BlkCmd                     ;Yes, convert it
    cmpi.b  #SCSI_SEEK6,d0              ;SEEK(6) command ?
    beq.b   .BlkCmd                     ;Yes, convert it
    cmpi.b  #SCSI_MODESELECT6,d0        ;MODE SELECT(6) command ?
    beq.b   .ModeCmd                    ;Yes, convert it
    cmpi.b  #SCSI_MODESENSE6,d0         ;MODE SENSE(6) command ?
    beq.b   .ModeCmd                    ;Yes, convert it
    bra.b   .SendCDB                    ;No conversion
.BlkCmd
    ori.b   #$20,d0
    move.b  d0,(a4)                     ;SCSI-2 command
    move.w  4(a4),8(a4)                 ;16-bit length + control
    move.l  (a4),d0
    andi.l  #$001FFFFF,d0
    move.l  d0,2(a4)                    ;32-bit LBA
    clr.b   1(a4)
    bra.b   .SendCDB
.ModeCmd
    ori.b   #$40,d0
    move.b  d0,(a4)                     ;SCSI-2 command
    move.w  4(a4),8(a4)                 ;16-bit length + control
    clr.w   4(a4)

;*************** Send the CDB *************************************************

.SendCDB
    bsr.w   SendPacket                  ;Send CDB's 12 bytes
    beq.w   .Error                      ;An error has occured

    move.l  scsi_Data(a2),a0            ;A0: data address
    moveq   #0,d1

;*************** Initialize the data transfer *********************************

.Loop
    bsr.w   WaitBusySlow                ;Wait for BUSY == 0
    beq.w   .Error                      ;Time-out elapsed : error
    btst    #ATAPIB_DATAREQ,d0          ;Some data to transfer ?
    beq.b   .NoData                     ;No, skip
    move.b  atapi_Reason(a5),d0         ;"Interrupt Reason Register"
    btst    #ATAPIB_COD,d0              ;Ready to transfer data ?
    bne.w   .Error                      ;No, error
    move.b  atapi_ByteCntH(a5),d1
    lsl.w   #8,d1
    move.b  atapi_ByteCntL(a5),d1       ;D1.w : Number of bytes to transfer
    move.l  d1,d2
    addq.l  #1,d1
    lsr.l   #1,d1
    subq.w  #1,d1
    btst    #ATAPIB_IO,d0               ;Transfer direction
    bne.b   .ReadLoop                   ;Bit set : read

;*************** Write data to the ATA bus ************************************

.WriteLoop
    move.w  (a0)+,d0                    ;Reading one word from memory
    rol.w   #8,d0                       ;Swap LSB <-> MSB
    move.w  d0,(a5)                     ;Writing one word to the ATA bus
    dbra    d1,.WriteLoop               ;Loop
    add.l   d2,scsi_Actual(a2)
    bra.b   .Loop                       ;Loop

;*************** Read data from the ATA bus ***********************************

.ReadLoop
    move.w  (a5),d0                     ;Reading one word from the ATA bus
    rol.w   #8,d0                       ;Swap LSB <-> MSB
    move.w  d0,(a0)+                    ;Writing one word to memory
    dbra    d1,.ReadLoop                ;Loop
    add.l   d2,scsi_Actual(a2)
    bra.b   .Loop                       ;Loop

;*************** End of the command *******************************************

.NoData
    btst    #ATAPIB_CHECK,atapi_Status(a5) ;Check condition ?
    beq.w   .End                        ;No, exit
    move.b  #2,scsi_Status(a2)          ;Yes, set the bit

    move.w  #SCSI_REQUESTSENSE<<8,(a4)+ ;ATAPI command "Request Sense"
    clr.w   (a4)+
    clr.l   (a4)+
    clr.l   (a4)                        ;We clear the CDB
    subq.l  #8,a4                       ;Restore A4

    move.l  scsi_SenseData(a2),a0       ;A0: data address
    move.b  scsi_Flags(a2),d0           ;D0: Flags
    btst    #SCSIB_AUTOSENSE,d0         ;Extended auto-sense ?
    bne.b   .ExtSense                   ;Yes
    btst    #SCSIB_OLDAUTOSENSE,d0      ;Old auto-sense ?
    bne.b   .OldSense                   ;Yes
    bra.b   .NoSense                    ;No auto-sense

;*************** Old Auto-Sense ***********************************************

.OldSense
    move.w  #$7000,(a0)+
    move.b  atapi_Error(a5),d0
    lsr.b   #4,d0
    move.b  d0,(a0)+
    clr.b   (a0)+
    move.w  #4,scsi_SenseActual(a2)
;    cmpi.b  #6,d0
;    bne.b   .End

;*************** No Auto-Sense : re-initialize everything *********************

.NoSense
    clr.b   4(a4)                       ;No information returned
    bra.b   .SendSense

;*************** Extended Auto-Sense ******************************************

.ExtSense
    move.b  scsi_SenseLength+1(a2),4(a4) ;Returned information's length

.SendSense
    bsr.w   SendPacket                  ;Send CDB's 12 bytes
    beq.b   .Error                      ;An error has occured

.SenseLoop1
    bsr.w   WaitBusySlow                ;Wait for BUSY == 0
    beq.b   .Error                      ;Time-out elapsed : error
    btst    #ATAPIB_DATAREQ,d0          ;Data to transfer ?
    beq.b   .End                        ;No, exit
    move.b  atapi_Reason(a5),d0
    btst    #ATAPIB_COD,d0
    bne.b   .Error
    btst    #ATAPIB_IO,d0
    beq.b   .Error

    moveq   #0,d1
    move.b  atapi_ByteCntL(a5),d1       ;D1.w: Number of bytes to read
    beq.b   .End                        ;Nothing to read : exit
    move.w  d1,scsi_SenseActual(a2)
    addq.w  #1,d1
    lsr.w   #1,d1
    subq.w  #1,d1
.SenseLoop2
    move.w  (a5),d0                     ;Reading one word
    rol.w   #8,d0                       ;Swap LSB <-> MSB
    move.w  d0,(a0)+                    ;Writing one word to memory
    dbra    d1,.SenseLoop2              ;Loop
    bra.b   .SenseLoop1

;*************** End of SCSI-2 commands for ATAPI drives **********************

.End
    IFD CPU020
    bsr.w   UnFreezeCache               ;Unfreeze CPU data cache
    ENDC

    lea     12(sp),sp                   ;Restore stack
    movem.l (sp)+,a1/a4-a6              ;Restore A1, A4, A5 & A6
    rts                                 ;End

.Error
    move.b  #5,scsi_Status(a2)
    clr.l   scsi_Actual(a2)
    clr.w   scsi_SenseActual(a2)
    clr.w   scsi_CmdActual(a2)
    bra.b   .End

;******************************************************************************
;********                                                              ********
;********                 SCSI-1 command : blocks read                 ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_Read6
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #6,d0                       ;6-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes

    move.l  (a1)+,d0
    andi.l  #$001FFFFF,d0               ;D0: LBA (21 bits)
    moveq   #0,d1
    move.b  (a1),d1                     ;D1: Length (8 bits)
    bne.b   .NotNull
    move.w  #256,d1                     ;Null size : 256 blocks
.NotNull
    move.l  scsi_Data(a2),a0            ;A0: Buffer
    jsr     au_ReadJmp(a3)              ;Reading blocks
    move.l  d1,scsi_Actual(a2)          ;D1: Transfer length in bytes
    tst.b   d0
    bne.w   ScsiError                   ;SCSI error management

    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                 SCSI-2 command : blocks read                 ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_Read10
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #10,d0                      ;10-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes

    movem.l 2(a1),d0/d1                 ;D0: LBA (32 bits),D1: Length (16 bits)
    lsl.l   #8,d1
    clr.w   d1
    swap    d1
    move.l  scsi_Data(a2),a0            ;A0: Buffer
    jsr     au_ReadJmp(a3)              ;Reading blocks
    move.l  d1,scsi_Actual(a2)          ;D1: Transfer length in bytes
    tst.b   d0
    bne.w   ScsiError                   ;SCSI error management

    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                 SCSI-3 command : blocks read                 ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_Read12
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #12,d0                      ;12-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes

    movem.l 2(a1),d0/d1                 ;D0: LBA (32 bits),D1: Length (32 bits)
    move.l  scsi_Data(a2),a0            ;A0: Buffer
    jsr     au_ReadJmp(a3)              ;Reading blocks
    move.l  d1,scsi_Actual(a2)          ;D1: Transfer length in bytes
    tst.b   d0
    bne.w   ScsiError                   ;SCSI error management

    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                SCSI-2 command : blocks verify                ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_Verify10
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #10,d0                      ;10-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes

    movem.l 2(a1),d0/d1                 ;D0: LBA (32 bits),D1: Length (16 bits)
    lsl.l   #8,d1
    clr.w   d1
    swap    d1
;    bsr.w   ata_Verify                  ;Verifying blocks
    beq.w   ScsiError                   ;SCSI error management

    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                SCSI-3 command : blocks verify                ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_Verify12
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #12,d0                      ;12-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes

    movem.l 2(a1),d0/d1                 ;D0: LBA (32 bits),D1: Length (32 bits)
;    bsr.w   ata_Verify                  ;Verifying blocks
    beq.w   ScsiError                   ;SCSI error management

    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                SCSI-1 command : blocks write                 ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_Write6
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #6,d0                       ;6-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes

    move.l  (a1)+,d0
    andi.l  #$001FFFFF,d0               ;D0: LBA (21 bits)
    moveq   #0,d1
    move.b  (a1),d1                     ;D1: Length (8 bits)
    bne.b   .NotNull
    move.w  #256,d1                     ;Null length case : 256 blocks
.NotNull
    move.l  scsi_Data(a2),a0            ;A0: Buffer
    jsr     au_WriteJmp(a3)             ;Writing blocks
    move.l  d1,scsi_Actual(a2)          ;D1: Transfer length in bytes
    tst.b   d0
    bne.w   ScsiError                   ;SCSI error management

    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                SCSI-2 command : blocks write                 ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_Write10
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #10,d0                      ;10-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes

    movem.l 2(a1),d0/d1                 ;D0: LBA (32 bits),D1: Length (16 bits)
    lsl.l   #8,d1
    clr.w   d1
    swap    d1
    move.l  scsi_Data(a2),a0            ;A0: Buffer
    jsr     au_WriteJmp(a3)             ;Writing blocks
    move.l  d1,scsi_Actual(a2)          ;D1: Transfer length in bytes
    tst.b   d0
    bne.w   ScsiError                   ;SCSI error management

    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                SCSI-3 command : blocks write                 ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_Write12
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #12,d0                      ;12-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes

    movem.l 2(a1),d0/d1                 ;D0: LBA (32 bits),D1: Length (32 bits)
    move.l  scsi_Data(a2),a0            ;A0: Buffer
    jsr     au_WriteJmp(a3)             ;Writing blocks
    move.l  d1,scsi_Actual(a2)          ;D1: Transfer length in bytes
    tst.b   d0
    bne.w   ScsiError                   ;SCSI error management

    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                  SCSI-1 command : head seek                  ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_Seek6
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #6,d0                       ;6-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes

    move.l  (a1),d0
    andi.l  #$001FFFFF,d0               ;D0: LBA (21 bits)
    bsr.w   ata_Seek                    ;Heads movement
    beq.w   ScsiError                   ;SCSI error management

    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                  SCSI-2 command : head seek                  ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_Seek10
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #10,d0                      ;10-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes

    move.l  2(a1),d0                    ;D0: LBA (32 bits)
    bsr.w   ata_Seek                    ;Heads movement
    beq.w   ScsiError                   ;SCSI error management

    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********            SCSI-2 command : disk capacity reading            ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_ReadCapacity
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #10,d0                      ;10-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes, continue

    btst    #0,8(a1)                    ;PMI bit set ?
    bne.b   .Pmi                        ;Yes, skip
    tst.l   2(a1)                       ;LBA not null ?
    bne.b   .Error                      ;Yes, error
    move.l  au_Blocks(a3),d0            ;No, D0 : total number of blocks
    bra.b   .Cont                       ;We continue
.Pmi
    move.l  2(a1),d0                    ;D0 : 32-bit LBA
    divu    au_SectorsC(a3),d0
    addq.w  #1,d0
    mulu    au_SectorsC(a3),d0          ;D0 : Next cylinder's LBA
.Cont
    subq.l  #1,d0
    move.l  au_SectSize(a3),d1          ;D1 : Block size

    movem.l d0/d1,-(sp)
    move.l  sp,a0                       ;A0 : source
    moveq   #8,d0                       ;8 bytes to copy
    bsr.w   CopyScsiResult              ;Copy the result
    addq.l  #8,sp                       ;Restore the stack

    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

.Error
    move.w  #$0524,au_SenseKey(a3)      ;Invalid field in CDB + Illegal request
    bra.w   ScsiError                   ;SCSI error management

;******************************************************************************
;********                                                              ********
;********        SCSI-1 command : Inquiry (auto-detect drives)         ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_Inquiry
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #6,d0                       ;6-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes

    lea     -56(sp),sp                  ;56 bytes allocated on the stack
    move.l  sp,a0
    move.b  au_DevType(a3),(a0)+        ;Device type
    moveq   #0,d0
    tst.b   au_Removable(a3)            ;Removable media ?
    beq.b   .NoRemove                   ;No, skip next line
    bset    #7,d0                       ;Yes, set bit #7
.NoRemove
    move.b  d0,(a0)+
    moveq   #2,d0
    move.b  d0,(a0)+                    ;SCSI-2 compatible 
    move.b  d0,(a0)+                    ;Normal Inquiry response
    move.b  4(a1),d0
    subq.b  #4,d0
    move.b  d0,(a0)+                    ;Additional size
    clr.b   (a0)+
    clr.b   (a0)+
    move.b  #$88,(a0)+                  ;Relative mode & linked commands

    lea     au_ModelID(a3),a1
    moveq   #5,d0                       ;6 long words to copy
.IDLoop
    move.l  (a1)+,(a0)+
    dbra    d0,.IDLoop                  ;Model identification

    addq.l  #8,a1
    move.l  (a1)+,(a0)+                 ;Firmware version

    clr.l   (a0)+
    clr.l   (a0)+
    movem.l (a1),d0-d2
    movem.l d0-d2,(a0)                  ;Serial number

    move.l  sp,a0                       ;A0 : source
    moveq   #56,d0                      ;56 bytes to copy
    bsr.w   CopyScsiResult              ;Copy the result
    lea     56(sp),sp                   ;Restore the stack

    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********               SCSI-1 command : Test unit ready               ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_TestUnitReady
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #6,d0                       ;6-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes

    movem.l a5/a6,-(sp)                 ;Save A5 & A6
    move.l  au_PortAddr(a3),a5          ;A5: IDE interface base address
    move.l  au_Device(a3),a6            ;A6: AT-Apollo.device base address
    move.b  au_DevMask(a3),ata_DevHead(a5) ;Select the drive
    bsr.w   WaitBusy                    ;Wait for BUSY == 0
    bne.b   .Error1                     ;Time-out elapsed : error
    btst    #ATAB_DEVREADY,ata_Status(a5) ;Check if the drive is ready
    beq.b   .Error2                     ;Not ready : error
    movem.l (sp)+,a5/a6                 ;Restore A5 & A6

    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

.Error1
    move.w  #$0205,au_SenseKey(a3)      ;Not ready + Logical unit does not respond
    movem.l (sp)+,a5/a6                 ;Restore A5 & A6
    bra.w   ScsiError                   ;SCSI error management

.Error2
    move.w  #$0204,au_SenseKey(a3)      ;Not ready + Logical unit not ready
    movem.l (sp)+,a5/a6                 ;Restore A5 & A6
    bra.w   ScsiError                   ;SCSI error management

;******************************************************************************
;********                                                              ********
;********                SCSI-1 command : Request sense                ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_RequestSense
    move.w  #6,scsi_CmdActual(a2)       ;6-byte CDB
    move.l  scsi_Length(a2),scsi_Actual(a2) ;Size of the returned data

    lea     -18(sp),sp                  ;18 bytes allocated on the stack

    moveq   #0,d1
    move.w  au_SenseKey(a3),d0
    move.b  d0,d1
    clr.b   d0

    move.l  sp,a0
    move.b  #$70,(a0)+                  ;Current error
    move.w  d1,(a0)+                    ;Sense key
    move.l  au_LBASense(a3),(a0)+       ;LBA where the error occured
    move.b  #10,(a0)+                   ;Extra size
    clr.l   (a0)+
    move.w  d0,(a0)+                    ;Additional sense code
    clr.l   (a0)+

    move.l  sp,a0                       ;A0 : source address
    moveq   #18,d0                      ;18 bytes to copy
    bsr.w   CopyScsiResult              ;Copy the result

    lea     18(sp),sp                   ;Restore the stack
    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

;******************************************************************************
;********                                                              ********
;********                 SCSI-2 command : Mode Sense                  ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_ModeSense10
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #10,d0                      ;10-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes

    lea     -104(sp),sp                 ;104 bytes allocated on the stack
    move.l  sp,a0
    move.w  #13,(a0)+                   ;Page size : 13 bytes
    clr.l   (a0)+                       ;Media type, specific parameters
    move.w  #8,(a0)+                    ;Block descriptor size
    move.l  au_Blocks(a3),(a0)+         ;Number of blocks
    move.l  au_SectSize(a3),(a0)+       ;Sector size
    move.b  2(a1),d0
    lea     1(sp),a1
    bra.b   scsi_MS_Jump

;******************************************************************************
;********                                                              ********
;********                 SCSI-1 command : Mode Sense                  ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;A1.l : SCSI CDB address
;A2.l : SCSICmd structure 
;A3.l : ApolloUnit base address

scsi_ModeSense6
    move.w  scsi_CmdLength(a2),d0       ;CDB size
    cmpi.w  #6,d0                       ;6-byte CDB ?
    bne.w   ScsiInvCmd                  ;No, invalid command
    move.w  d0,scsi_CmdActual(a2)       ;Yes

    lea     -104(sp),sp                 ;104 bytes allocated on the stack
    move.l  sp,a0
    move.b  #13,(a0)+                   ;Page size : 13 bytes
    clr.b   (a0)+                       ;Media type, specific parameters
    clr.b   (a0)+                       ;Specific parameters
    move.b  #8,(a0)+                    ;Block descriptor size
    move.l  au_Blocks(a3),(a0)+         ;Number of blocks
    move.l  au_SectSize(a3),(a0)+       ;Sector size
    move.b  2(a1),d0
    move.l  sp,a1

scsi_MS_Jump
    andi.b  #%00111111,d0               ;"Page Code" field

    subq.b  #3,d0                       ;$03 : Format device page
    beq.b   .Format

    subq.b  #1,d0                       ;$04 : Rigid disk geometry page
    beq.b   .Geometry

    subq.b  #4,d0                       ;$08 : Caching page
;    beq.b   .Cache

    subq.b  #1,d0                       ;$09 : Peripheral device page
    beq.b   .Periph

    subq.b  #4,d0                       ;$0D : Power condition page
    beq.b   .Power

    cmpi.b  #$32,d0                     ;$3F : All pages
    beq.b   .All

    bra.w   ScsiInvCmd                  ;Invalid command

.Format
    bsr.b   scsi_MS_Format
    bra.b   .End

.Geometry
    bsr.b   scsi_MS_Geometry
    bra.b   .End

.Cache
    bsr.b   scsi_MS_Cache
    bra.b   .End

.Periph
    bsr.b   scsi_MS_Periph
    bra.b   .End

.Power
    bsr.w   scsi_MS_Power
    bra.b   .End

.All
    bsr.b   scsi_MS_Format
    bsr.b   scsi_MS_Geometry
;    bsr.b   scsi_MS_Cache
    bsr.b   scsi_MS_Periph
    bsr.b   scsi_MS_Power

.End
    moveq   #1,d0
    add.b   (a1),d0                     ;Number of bytes to copy
    move.l  sp,a0
    bsr.w   CopyScsiResult              ;Copy the result
    lea     104(sp),sp                  ;Restore the stack
    move.l  (sp)+,a1                    ;Restore A1
    rts                                 ;End

scsi_MS_Format
    move.b  #$03,(a0)+
    moveq   #22,d0                      ;22 bytes in the page
    add.b   d0,(a1)
    move.b  d0,(a0)+
    clr.l   (a0)+
    clr.l   (a0)+
    clr.b   (a0)+
    move.b  au_SectorsT(a3),(a0)+       ;Number of sectors per track
    move.w  au_SectSize+2(a3),(a0)+     ;Sector size
    move.w  #1,(a0)+                    ;Interleave
    clr.l   (a0)+
    move.b  #%10000000,(a0)+            ;Soft format
    clr.b   (a0)+
    clr.w   (a0)+
    rts

scsi_MS_Geometry
    move.b  #$04,(a0)+
    moveq   #22,d0                      ;22 bytes in the page
    add.b   d0,(a1)
    move.b  d0,(a0)+
    move.w  au_Cylinders(a3),d0         ;Number of cylinders
    lsl.l   #8,d0
    move.b  au_Heads(a3),d0             ;Number of heads
    move.l  d0,(a0)+
    clr.w   (a0)+
    clr.l   (a0)+
    clr.l   (a0)+
    clr.l   (a0)+
    clr.l   (a0)+
    rts

scsi_MS_Cache
    move.b  #$08,(a0)+
    moveq   #18,d0                      ;18 bytes in the page
    add.b   d0,(a1)
    move.b  d0,(a0)+
    rts

scsi_MS_Periph
    move.b  #$09,(a0)+
    moveq   #6,d0                       ;6 bytes in the page
    add.b   d0,(a1)
    move.b  d0,(a0)+
    move.w  #3,(a0)+                    ;SCSI-2 interface 
    clr.l   (a0)+
    rts

scsi_MS_Power
    move.b  #$0D,(a0)+
    moveq   #10,d0                      ;10 bytes in the page
    add.b   d0,(a1)
    move.b  d0,(a0)+
    clr.w   (a0)+                       ;Timers disabled
    clr.l   (a0)+                       ;Idle timer
    clr.l   (a0)+                       ;Standby timer
    rts

;******************************************************************************
;********                                                              ********
;********              Copy the result of a SCSI command               ********
;********                                                              ********
;******************************************************************************

;Parameters:
;-----------
;D0.l : Copy size
;A0.l : Source address
;A2.l : SCSICmd structure 

CopyScsiResult
    cmp.l   scsi_Length(a2),d0          ;Greater than the expected size ?
    bls.b   .Lower                      ;No, skip next instruction
    move.l  scsi_Length(a2),d0          ;Yes, limit the size

.Lower
    move.l  d0,scsi_Actual(a2)
    subq.w  #1,d0                       ;-1 for DBRA
    bcs.b   .End                        ;Null size : exit
    move.l  scsi_Data(a2),a1            ;A1 : destination address

.CopyLoop
    move.b  (a0)+,(a1)+                 ;Copy one byte
    dbra    d0,.CopyLoop                ;Loop

.End
    rts

;******************************************************************************
;********                                                              ********
;********           Debugging routine under PowerVisor v1.43           ********
;********                                                              ********
;******************************************************************************

    IF PVDBG>0

PutChProc
    move.b  d0,(a3)+
    rts

IdentifyCmd
    moveq   #0,d0
    move.b  (a4),d0
    cmpi.b  #$C0,d0
    bcc.b   .Unknown
    add.w   d0,d0
    add.w   d0,d0
    move.l  .Map(pc,d0.w),ad_CmdStr(a5)
    rts
.Unknown
    move.l  #CmdXX,ad_CmdStr(a5)
    rts
.Map
    dc.l    Cmd00,Cmd01,CmdXX,Cmd03,CmdXX,CmdXX,CmdXX,CmdXX
    dc.l    Cmd08,CmdXX,CmdXX,Cmd0B,CmdXX,CmdXX,CmdXX,CmdXX

    dc.l    CmdXX,CmdXX,Cmd12,CmdXX,CmdXX,Cmd15,Cmd16,Cmd17
    dc.l    Cmd18,CmdXX,Cmd1A,Cmd1B,Cmd1C,Cmd1D,Cmd1E,CmdXX

    dc.l    CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,Cmd25,CmdXX,CmdXX
    dc.l    Cmd28,CmdXX,CmdXX,Cmd2B,CmdXX,CmdXX,CmdXX,Cmd2F

    dc.l    Cmd30,Cmd31,Cmd32,Cmd33,Cmd34,Cmd35,Cmd36,CmdXX
    dc.l    CmdXX,Cmd39,Cmd3A,Cmd3B,Cmd3C,CmdXX,Cmd3E,CmdXX

    dc.l    Cmd40,CmdXX,Cmd42,Cmd43,Cmd44,Cmd45,CmdXX,Cmd47
    dc.l    Cmd48,Cmd49,CmdXX,Cmd4B,Cmd4C,Cmd4D,Cmd4E,CmdXX

    dc.l    CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,Cmd55,Cmd56,Cmd57
    dc.l    CmdXX,CmdXX,Cmd5A,CmdXX,CmdXX,CmdXX,Cmd5E,Cmd5F

    dc.l    CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX
    dc.l    CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX

    dc.l    CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX
    dc.l    CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX

    dc.l    CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX
    dc.l    CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX

    dc.l    CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX
    dc.l    CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX,CmdXX

    dc.l    CmdA0,CmdXX,CmdXX,CmdXX,CmdXX,CmdA5,CmdXX,CmdXX
    dc.l    CmdA8,CmdA9,CmdXX,Cmd03,CmdXX,CmdXX,CmdXX,CmdAF

    dc.l    CmdB0,CmdB1,CmdB2,CmdB3,CmdXX,CmdXX,CmdXX,CmdXX
    dc.l    CmdXX,CmdB9,CmdBA,CmdBB,CmdBC,CmdBD,CmdBE,CmdXX
PVName
    dc.b    "powervisor.library",0
Digit
    dc.b    "0123456789ABCDEF"
FormatString1
    dc.b    10,"---- SCSI-2 command : %s ----",10
    dc.b    "scsi_Data        = $%08lx",10
    dc.b    "scsi_Length      = %ld",10
    dc.b    "scsi_Command     = %s",10
    dc.b    "scsi_CmdLength   = %d",10
    dc.b    "scsi_Flags       = $%02x",10
    dc.b    "scsi_SenseData   = $%08lx",10
    dc.b    "scsi_SenseLength = %d",10,0
FormatString2
    dc.b    "---- After execution : ----",10
    dc.b    "scsi_Actual      = %ld",10
    dc.b    "scsi_CmdActual   = %d",10
    dc.b    "scsi_SenseActual = %d",10
    dc.b    "scsi_Status      = $%02x",10
    dc.b    "---- scsi_Data content : ----",10,0
FormatString3
    dc.b    "---- Unit %d ----",10
    dc.b    "Old sense : $%02x",10
    dc.b    "New sense : $%02x",10
    dc.b    "Old change state  : %d",10
    dc.b    "Old change number : %ld",10,0
FormatString4
    dc.b    "---- Unit %d ----",10
    dc.b    "New change state  : %d",10
    dc.b    "New change number : %ld",10,0
OutputString
    blk.b   352,0
CommandString
    blk.b   64,0
CmdXX
    dc.b    "Unknown",0
Cmd00
    dc.b    "Test Unit Ready",0
Cmd01
    dc.b    "Rezero Unit",0
Cmd03
    dc.b    "Request Sense",0
Cmd08
    dc.b    "Read(6)",0
Cmd0B
    dc.b    "Seek(6)",0
Cmd12
    dc.b    "Inquiry",0
Cmd15
    dc.b    "Mode Select(6)",0
Cmd16
    dc.b    "Reserve(6)",0
Cmd17
    dc.b    "Release(6)",0
Cmd18
    dc.b    "Copy",0
Cmd1A
    dc.b    "Mode Sense(6)",0
Cmd1B
    dc.b    "Stop/Start Unit",0
Cmd1C
    dc.b    "Receive Diagnostic Results",0
Cmd1D
    dc.b    "Send Diagnostic",0
Cmd1E
    dc.b    "Prevent/Allow Medium Removal",0
Cmd25
    dc.b    "Read CD-Rom Capacity",0
Cmd28
    dc.b    "Read(10)",0
Cmd2B
    dc.b    "Seek(10)",0
Cmd2F
    dc.b    "Verify(10)",0
Cmd30
    dc.b    "Search Data High(10)",0
Cmd31
    dc.b    "Search Data Equal(10)",0
Cmd32
    dc.b    "Search Data Low(10)",0
Cmd33
    dc.b    "Set Limits(10)",0
Cmd34
    dc.b    "Pre-Fetch",0
Cmd35
    dc.b    "Synchronize Cache",0
Cmd36
    dc.b    "Lock/Unlock Cache",0
Cmd39
    dc.b    "Compare",0
Cmd3A
    dc.b    "Copy And Verify",0
Cmd3B
    dc.b    "Write Buffer",0
Cmd3C
    dc.b    "Read Buffer",0
Cmd3E
    dc.b    "Read Long",0
Cmd40
    dc.b    "Change Definition",0
Cmd42
    dc.b    "Read Sub-channel",0
Cmd43
    dc.b    "Read TOC",0
Cmd44
    dc.b    "Read Header",0
Cmd45
    dc.b    "Play Audio(10)",0
Cmd47
    dc.b    "Play Audio MSF",0
Cmd48
    dc.b    "Play Audio Track Index",0
Cmd49
    dc.b    "Play Track Relative(10)",0
Cmd4B
    dc.b    "Pause/Resume",0
Cmd4C
    dc.b    "Log Select",0
Cmd4D
    dc.b    "Log Sense",0
Cmd4E
    dc.b    "Stop Play/Scan",0
Cmd55
    dc.b    "Mode Select(10)",0
Cmd56
    dc.b    "Reserve(10)",0
Cmd57
    dc.b    "Release(10)",0
Cmd5A
    dc.b    "Mode Sense(10)",0
Cmd5E
    dc.b    "Prin",0
Cmd5F
    dc.b    "Prout",0
CmdA0
    dc.b    "Report LUNs",0
CmdA5
    dc.b    "Play Audio(12)",0
CmdA8
    dc.b    "Read(12)",0
CmdA9
    dc.b    "Play Track Relative(12)",0
CmdAF
    dc.b    "Verify(12)",0
CmdB0
    dc.b    "Search Data High(12)",0
CmdB1
    dc.b    "Search Data Equal(12)",0
CmdB2
    dc.b    "Search Data Low(12)",0
CmdB3
    dc.b    "Set Limits(12)",0
CmdB9
    dc.b    "Read CD MSF",0
CmdBA
    dc.b    "Audio Scan",0
CmdBB
    dc.b    "Set CD-Rom Speed",0
CmdBC
    dc.b    "Play CD",0
CmdBD
    dc.b    "CD Mechanism States",0
CmdBE
    dc.b    "Read CD",0
    even
CmdPtr
    dc.l    0
    ENDIF

EndRomTag
