
                              ;struct  MyUnit
                              ;{
mu_Unit                = 0    ;    struct  Unit mu_Unit;
mu_PortNumber          = 38   ;    UBYTE   mu_PortNumber; >- N° de Port IDE
mu_RDBSector           = 39   ;    UBYTE   mu_RDBSector;  >- Emplacement du RDB
mu_SysBase             = 40   ;    APTR    mu_SysBase;    >- ExecBase
mu_Device              = 44   ;    APTR    mu_Device;     >- Adr. du Device
mu_PortAddr            = 48   ;    APTR    mu_PortAddr;   >- Adr. du Port IDE
mu_RPCache             = 52   ;    APTR    mu_RPCache;   \
mu_RPOffset            = 56   ;    ULONG   mu_RPOffset;   |
mu_NextRP              = 60   ;    ULONG   mu_NextRP;     |
mu_WCacheTags          = 64   ;    APTR    mu_WCacheTags; |- Gestion des caches
mu_Updated             = 68   ;    UBYTE   mu_Updated;    |
mu_RPCount             = 69   ;    UBYTE   mu_RPCount;   /
mu_MultiMode           = 70   ;    UBYTE   mu_MultiMode; \
mu_DReqMode            = 70   ;    UBYTE   mu_DReqMode;   |
mu_LBAMode             = 71   ;    UBYTE   mu_LBAMode;    |
mu_AtapiDev            = 72   ;    UBYTE   mu_AtapiDev;   |
mu_Swapped             = 73   ;    UBYTE   mu_Swapped;    |
mu_Removable           = 74   ;    UBYTE   mu_Removable;  |- Flags
mu_Protect             = 75   ;    UBYTE   mu_Protect;    |
mu_RCache              = 76   ;    UBYTE   mu_RCache;     |
mu_WCache              = 77   ;    UBYTE   mu_WCache;     |
mu_MultiCount          = 78   ;    UWORD   mu_MultiCount;/
mu_UnitNumber          = 80   ;    UBYTE   mu_UnitNumber;\
mu_DevMask             = 81   ;    UBYTE   mu_DevMask;    |
mu_Heads               = 82   ;    UBYTE   mu_Heads;      |
mu_SectorsT            = 83   ;    UBYTE   mu_SectorsT;   |
mu_SectorsC            = 84   ;    UWORD   mu_SectorsC;   |- Géométrie
mu_Cylinders           = 86   ;    UWORD   mu_Cylinders;  |
mu_Blocks              = 88   ;    ULONG   mu_Blocks;     |
mu_SectSize            = 92   ;    ULONG   mu_SectSize;   |
mu_SectShift           = 96   ;    UBYTE   mu_SectShift;  |
mu_DevType             = 97   ;    UBYTE   mu_DevType;   /
mu_VendorID            = 98   ;    char    mu_VendorID[8];   \
mu_ProductID           = 106  ;    char    mu_ProductID[16];  |- Identification
mu_ProductRev          = 122  ;    char    mu_ProductRev[8]; /
mu_Sense               = 130  ;    UWORD   mu_Sense;     \
mu_LBASense            = 132  ;    ULONG   mu_LBASense;   |- Emulation SCSI
mu_LastLBA             = 136  ;    ULONG   mu_LastLBA;   /
mu_DiskChange          = 140  ;    ULONG   mu_DiskChange;
mu_SIZEOF              = 144  ;};

                              ;struct  MyDevice
                              ;{
md_LibNode             = 0    ;    struct  Library md_LibNode;
md_Interrupt           = 34   ;    struct  Interrupt md_Interrupt;
md_PortBase            = 56   ;    APTR    md_PortBase;
md_IntrBase            = 60   ;    APTR    md_IntrBase
md_SigMask             = 64   ;    ULONG   md_SigMask;
md_SigTask             = 68   ;    struct  Task *md_SigTask;
md_ExecBase            = 72   ;    struct  Library *md_ExecBase;
md_SigBit              = 76   ;    UBYTE   md_SigBit;
md_Status              = 77   ;    UBYTE   md_Status;
md_NumUnit             = 78   ;    UWORD   md_NumUnit;
md_NumLoop             = 80   ;    ULONG   md_NumLoop;
md_TaskData            = 84   ;    struct  TaskData *md_TaskData;
md_DeamonData          = 88   ;    struct  DeamonData *md_DeamonData;
md_Units               = 92   ;    struct  MyUnit *md_Units[4];
md_SIZEOF              = 108  ;};
