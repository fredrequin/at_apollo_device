	IFND	DOS_DOS_LIB_I
DOS_DOS_LIB_I	SET	1
**
**	$VER: dos_lib.i 36.1 (4.11.90)
**	Includes Release 40.15
**
**	Library interface offsets for DOS library
**
**	(C) Copyright 1985-1993 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

;---- Public
_LVOOpen               = -30
_LVOClose              = -36
_LVORead               = -42
_LVOWrite              = -48
_LVOInput              = -54
_LVOOutput             = -60
_LVOSeek               = -66
_LVODeleteFile         = -72
_LVORename             = -78
_LVOLock               = -84
_LVOUnLock             = -90
_LVODupLock            = -96
_LVOExamine            = -102
_LVOExNext             = -108
_LVOInfo               = -114
_LVOCreateDir          = -120
_LVOCurrentDir         = -126
_LVOIoErr              = -132
_LVOCreateProc         = -138
_LVOExit               = -144
_LVOLoadSeg            = -150
_LVOUnLoadSeg          = -156
;---- Private
_LVOClearVec           = -162
_LVONoReqLoadSeg       = -168
;---- Public
_LVODeviceProc         = -174
_LVOSetComment         = -180
_LVOSetProtection      = -186
_LVODateStamp          = -192
_LVODelay              = -198
_LVOWaitForChar        = -204
_LVOParentDir          = -210
_LVOIsInteractive      = -216
_LVOExecute            = -222
;---- V36: DOS Object creation/deletion
_LVOAllocDosObject     = -228
_LVOFreeDosObject      = -234
;---- V36: Packet Level routines
_LVODoPkt              = -240
_LVOSendPkt            = -246
_LVOWaitPkt            = -252
_LVOReplyPkt           = -258
_LVOAbortPkt           = -264
;---- V36: Record Locking
_LVOLockRecord         = -270
_LVOLockRecords        = -276
_LVOUnLockRecord       = -282
_LVOUnLockRecords      = -288
;---- V36: Buffered File I/O
_LVOSelectInput        = -294
_LVOSelectOutput       = -300
_LVOFGetC              = -306
_LVOFPutC              = -312
_LVOUnGetC             = -318
_LVOFRead              = -324
_LVOFWrite             = -330
_LVOFGets              = -336
_LVOFPuts              = -342
_LVOVFWritef           = -348
_LVOVFPrintf           = -354
_LVOFlush              = -360
_LVOSetVBuf            = -366
;---- V36: DOS Object management
_LVODupLockFromFH      = -372
_LVOOpenFromLock       = -378
_LVOParentOfFH         = -384
_LVOExamineFH          = -390
_LVOSetFileDate        = -396
_LVONameFromLock       = -402
_LVONameFromFH         = -408
_LVOSplitName          = -414
_LVOSameLock           = -420
_LVOSetMode            = -426
_LVOExAll              = -432
_LVOReadLink           = -438
_LVOMakeLink           = -444
_LVOChangeMode         = -450
_LVOSetFileSize        = -456
;---- V36: Error handling
_LVOSetIOErr           = -462
_LVOFault              = -468
_LVOPrintFault         = -474
_LVOErrorReport        = -480
;---- V36: Process management
_LVOCli                = -492
_LVOCreateNewProc      = -498
_LVORunCommand         = -504
_LVOGetConsoleTask     = -510
_LVOSetConsoleTask     = -516
_LVOGetFileSysTask     = -522
_LVOSetFileSysTask     = -528
_LVOGetArgStr          = -534
_LVOSetArgStr          = -540
_LVOFindCliProc        = -546
_LVOMaxCli             = -552
_LVOSetCurrentDirName  = -558
_LVOGetCurrentDirName  = -564
_LVOSetProgramName     = -570
_LVOGetProgramName     = -576
_LVOSetPrompt          = -582
_LVOGetPrompt          = -588
_LVOSetProgramDir      = -594
_LVOGetProgramDir      = -600
;---- V36: Device List management
_LVOSystemTagList      = -606
_LVOAssignLock         = -612
_LVOAssignLate         = -618
_LVOAssignPath         = -624
_LVOAssignAdd          = -630
_LVORemAssignList      = -636
_LVOGetDeviceProc      = -642
_LVOFreeDeviceProc     = -648
_LVOLockDosList        = -654
_LVOUnLockDosList      = -660
_LVOAttemptLockDosList = -666
_LVORemDosEntry        = -672
_LVOAddDosEntry        = -678
_LVOFindDosEntry       = -684
_LVONextDosEntry       = -690
_LVOMakeDosEntry       = -696
_LVOFreeDosEntry       = -702
_LVOIsFileSystem       = -708
;---- V36: Handler interface
_LVOFormat             = -714
_LVORelabel            = -720
_LVOInhibit            = -726
_LVOAddBuffers         = -732
;---- V36: Date, Time routines
_LVOCompareDates       = -738
_LVODateToStr          = -744
_LVOStrToDate          = -750
;---- V36: Image management
_LVOInternalLoadSeg    = -756
_LVOInternalUnLoadSeg  = -762
_LVONewLoadSeg         = -768
_LVOAddSegment         = -774
_LVOFindSegment        = -780
_LVORemSegment         = -786
;---- V36: Command support
_LVOCheckSignal        = -792
_LVOReadArgs           = -798
_LVOFindArg            = -804
_LVOReadItem           = -810
_LVOStrToLong          = -816
_LVOMatchFirst         = -822
_LVOMatchNext          = -828
_LVOMatchEnd           = -834
_LVOParsePattern       = -840
_LVOMatchPattern       = -846
_LVOFreeArgs           = -858
_LVOFilePart           = -870
_LVOPathPart           = -876
_LVOAddPart            = -882
;---- V36: Notification
_LVOStartNotify        = -888
_LVOEndNotify          = -894
;---- V36: Environment Variables functions
_LVOSetVar             = -900
_LVOGetVar             = -906
_LVODeleteVar          = -912
_LVOFindVar            = -918
_LVOCliInit            = -924
_LVOCliInitNewCli      = -930
_LVOCliInitRun         = -936
;---- V36: Misc
_LVOWriteChars         = -942
_LVOPutStr             = -948
_LVOVPrintf            = -954
;--- V36.147
_LVOParsePatternNoCase = -966
_LVOMatchPatternNoCase = -972
_LVODosGetString       = -978
;---- V37
_LVOSameDevice         = -984

	ENDC	; DOS_DOS_LIB_I
