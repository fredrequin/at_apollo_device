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

;********************************************
;******** Description du scsi.device ********
;********************************************

STACK_SIZE = 1000

 STRUCTURE ScsiDevice,LIB_SIZE        ;Structure Library de base
    UWORD   sd_PadWord                ;Mot d'alignement
    APTR    sd_SysLib                 ;Pointeur sur ExecBase
    APTR    sd_MsgPort                ;Message-Port de la tâche
    STRUCT  sd_UnitList,MLH_SIZE      ;Liste des unités
    APTR    sd_DiagArea               ;DiagArea des partitions bootable
    APTR    sd_ConfigDev              ;ConfigDev associé au port IDE
    LABEL   sd_SIZEOF                 ;64 octets

 STRUCTURE ScsiTaskData,0
    STRUCT  std_Stack,STACK_SIZE      ;Pile de la tâche
    STRUCT  std_Task,TC_SIZE          ;Structure Task
    STRUCT  std_MsgPort,MP_SIZE       ;Structure MsgPort
    LABEL   std_SIZEOF                ;1126 octets

;**********************************************************
;******** Description de l'interruption (ancienne) ********
;**********************************************************

 STRUCTURE OldScsiInterrupt,0
    APTR    osi_SysLib
    APTR    osi_PortAddr
    APTR    osi_MsgPort
    APTR    osi_SigTask
    APTR    osi_Interrupt
    ULONG   osi_Pad1
    APTR    osi_IntrAddr
    UBYTE   osi_SigBit
    UBYTE   osi_Pad2
    ULONG   osi_SigMask
    STRUCT  osi_ToBeDef,36
    LABEL   osi_SIZEOF

;**********************************************************
;******** Description de l'interruption (nouvelle) ********
;**********************************************************

 STRUCTURE NewScsiInterrupt,0
    APTR    nsi_SysLib
    APTR    nsi_PortAddr
    APTR    nsi_IntrAddr
    APTR    nsi_SigTask
    APTR    nsi_SigMask
    UBYTE   nsi_SigBit
    UBYTE   nsi_Status
    UWORD   nsi_Pad
    LABEL   nsi_SIZEOF

;***************************************************
;******** Description de l'unité (ancienne) ********
;***************************************************

 STRUCTURE OldScsiUnit,MLN_SIZE       ;Structure noeud
    UBYTE   osu_UnitNumber            ;Numéro d'unité
    UBYTE   osu_LunNumber             ;Numéro de LUN
    UBYTE   osu_CtrlNumber            ;Numéro de contrôleur
    UBYTE   osu_DevType               ;Type de périphérique
    UBYTE   osu_DevAttr               ;Attributs du périphérique
    UBYTE   osu_Mounted               ;Partition montées
    UBYTE   osu_TDUnit                ;Unité style "TrackDisk"
    UBYTE   osu_Protect               ;Protection en écriture
    UBYTE   osu_RdbFlags              ;Flags du RigidDiskBlock
    UBYTE   osu_SelMask               ;Masque de sélection IDE
    UWORD   osu_BBNum                 ;Nombre de BadBlocks
    APTR    osu_BBList                ;Liste des BadBlocks
    ULONG   osu_SectSize              ;Taille des secteurs
    ULONG   osu_MaxLba                ;Numéro de LBA maximal
    ULONG   osu_MaxTrans              ;Transfert maximal
    UWORD   osu_SectShift             ;Taille des secteurs (log 2)
    APTR    osu_RdbAddr               ;Adresse du RigidDiskBlock
    ULONG   osu_ChangeNum             ;Changement du média
    APTR    osu_RemoveInt             ;Interrupt pour TD_REMOVE
    STRUCT  osu_ChangeList,MLH_SIZE   ;Liste pour TD_(ADD|REM)CHANGEINT
    STRUCT  osu_ToBeDef1,26           ;???
    ;$03E-$045 : Structure MinNode
    ;$046-$051 : Structure MinList
    ;$052-$057 : ???
    ULONG   osu_Cylinders             ;Nombre de cylindres
    UWORD   osu_SectorsT              ;Nombre de secteurs par piste
    ULONG   osu_SenseLba              ;LBA de l'erreur SCSI
    UBYTE   osu_MultCmd               ;Transfert multiple
    STRUCT  osu_ToBeDef2,3            ;???
    STRUCT  osu_BufIdent,512          ;Buffer pour "Identify Device"
    ULONG   osu_SenseFlags            ;Flags de l'erreur SCSI
    UWORD   osu_SectorsC              ;Nombre de secteurs par cylindre
    UBYTE   osu_Heads                 ;Nombre de têtes
    STRUCT  osu_ToBeDef3,4            ;???
    LABEL   osu_SIZEOF                ;625 octets

;***************************************************
;******** Description de l'unité (nouvelle) ********
;***************************************************

 STRUCTURE NewScsiUnit,MLN_SIZE       ;(=) Structure noeud
    UBYTE   nsu_UnitNumber            ;(=) Numéro d'unité
    UBYTE   nsu_LunNumber             ;(=) Numéro de LUN
    UBYTE   nsu_CtrlNumber            ;(=) Numéro de contrôleur
    UBYTE   nsu_SelMask               ;Masque de sélection

;**** Gestion des disques de plus de 4Go par LUNs:

    ULONG   nsu_BlockOffset           ;Offset à ajouter au LBA
    ULONG   nsu_LogicalCyl            ;Nombre logique de cylindres
    ULONG   nsu_LogicalBlk            ;Nombre logique de blocs

;**** Géométrie du disque:

    UBYTE   nsu_Heads                 ;Nombre de têtes
    UBYTE   nsu_SectorsT              ;Nombre de secteurs par piste
    UWORD   nsu_SectorsC              ;Nombre de secteurs par cylindre
    ULONG   nsu_Cylinders             ;Nombre de cylindres
    ULONG   nsu_Blocks                ;Nombre de blocs
    ULONG   nsu_SectSize              ;Taille des blocs
    UBYTE   nsu_SectShift             ;Taille des blocs (log 2)
    UBYTE   nsu_RdbSector             ;LBA du RigidDiskBlock

;**** Gestion du "DiskChange":

    ULONG   nsu_ChangeNum             ;(=) Nombre de changements de média
    APTR    nsu_RemoveInt             ;(=) Structure Interrupt pour TD_REMOVE
    STRUCT  nsu_ChangeList,MLH_SIZE   ;(=) Liste des IoStdRequest pour "Diskchange"
    UBYTE   nsu_DiskPresent           ;Média présent/absent
    UBYTE   nsu_Used                  ;Unité utilisée

;**** Emulation SCSI:

    ULONG   nsu_SenseLba              ;LBA de l'erreur SCSI
    UBYTE   nsu_SenseKey              ;Erreur SCSI
    UBYTE   nsu_AddSC                 ;Code additionnel 1
    UBYTE   nsu_AddSCQ                ;Code additionnel 2
    UBYTE   nsu_PadByte

;**** Gestion des caches:

    APTR    nsu_RCacheAddr            ;Adresse du cache de lecture
    ULONG   nsu_RCacheBlock           ;Position des données du cache de lecture
    ULONG   nsu_RCacheNext            ;Prochaine position des données
    APTR    nsu_WCacheFlags           ;Flags du cache d'écriture
    APTR    nsu_WCacheTags            ;Tags du cache d'écriture
    UBYTE   nsu_RCacheCount           ;Nombre de lectures avant un "Prefetch"
    UBYTE   nsu_WCacheUpd             ;Cache d'écriture mis-à-jour
    UBYTE   nsu_RCacheOn              ;Cache de lecture activé
    UBYTE   nsu_WCacheOn              ;Cache d'écriture activé
    ULONG   nsu_RCacheSize            ;Taille du cache de lecture (en blocs)
    UWORD   nsu_WCacheSize            ;Taille-1 du cache d'écriture (en blocs)

;**** Buffer pour IDENTIFY DEVICE:

    STRUCT  nsu_BufIdent,424          ;(=) 424 octets de réservés

;**** Gestion du "RigidDiskBlock":

    STRUCT  nsu_PartList,MLH_SIZE     ;Liste des partitions
    ULONG   nsu_RdbFlags              ;Flags du RigidDiskBlock
    APTR    nsu_RdbAddr               ;Adresse du RigidDiskBlock

;**** Vecteurs internes:

    LABEL   nsu_JumpTable

    UWORD   nsu_ReadJmp
    APTR    nsu_ReadSub               ;Routine de lecture bas-niveau

    UWORD   nsu_WriteJmp
    APTR    nsu_WriteSub              ;Routine d'écriture bas-niveau

    UWORD   nsu_FormatJmp
    APTR    nsu_FormatSub             ;Routine de formatage bas-niveau

    UWORD   nsu_SeekJmp
    APTR    nsu_SeekSub               ;Routine de déplacement bas-niveau

    UWORD   nsu_EjectJmp
    APTR    nsu_EjectSub              ;Routine d'éjection bas-niveau

    UWORD   nsu_TestJmp
    APTR    nsu_TestSub               ;Routine test du média bas-niveau

    UWORD   nsu_ScsiJmp
    APTR    nsu_ScsiSub               ;Routine SCSI-Direct bas-niveau

;**** Flags du disque:

    UBYTE   nsu_Mounted               ;Partitions montées
    UBYTE   nsu_DevType               ;Type de périphérique
    UBYTE   nsu_TDStyle               ;Unité style "TrackDisk"
    UBYTE   nsu_Removable             ;Disque amovible
    UBYTE   nsu_WrProtect             ;Protection écriture
    UBYTE   nsu_Swapped               ;Données inversées
    LABEL   nsu_DReqMode              ;Interruption lors de l'envoi du CDB
    UBYTE   nsu_FastTrans             ;Lecture / écriture rapide des données
    UBYTE   nsu_LbaMode               ;Mode d'adressage LBA
    UBYTE   nsu_AtapiDev              ;Périphérique ATAPI
    UBYTE   nsu_MultMask              ;Commande multiple : masque du compteur
    UBYTE   nsu_RdCmd                 ;Octet de la commande ATA de lecture
    UBYTE   nsu_WrCmd                 ;Octet de la commande ATA d'écriture
    ULONG   nsu_NumLoop               ;Nombre maximum de boucles de polling

;**** Pointeurs divers:

    APTR    nsu_IntrAddr              ;Adresse de la gestion des interruptions
    APTR    nsu_PortAddr              ;Adresse de départ du port IDE
    APTR    nsu_SysLib                ;Execbase
    APTR    nsu_Device                ;Pointeur sur le scsi.device
    APTR    nsu_IntrData              ;Structure NewScsiInterrupt

    LABEL   nsu_SIZEOF                ;632 octets

;**** nsu_Flags:

 BITDEF AU,SWAP,0                     ;Compatibilité vieux contrôleurs ZII
 BITDEF AU,FREAD,1                    ;Lecture rapide activée
 BITDEF AU,FWRITE,2                   ;Ecriture rapide
 BITDEF AU,RCACHE,3                   ;Cache en lecture activé
 BITDEF AU,WCACHE,4                   ;Cache en écriture activé
 BITDEF AU,REMOVE,7                   ;Disque amovible

;**************************************************
;******** Description du cache en écriture ********
;**************************************************

; Cache flags:
;-------------
cf_Update = 0                         ;Blocs mis-à-jour
cf_Valid  = 1                         ;Blocs valides
cf_SIZEOF = 2                         ;Nombre d'octets pour un tampon

; Cache Tags:
;------------
ct_Offset = 0                         ;Position des blocs sur le disque
ct_Data   = 4                         ;Adresse des blocs en mémoire
ct_SIZEOF = 8                         ;Nombre d'octets pour un tampon

;***************************************
;******** Commandes spécifiques ********
;***************************************

SDCMD_TESTCHANGED = $001D             ;Test de changement d'un disque
