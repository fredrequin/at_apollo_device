	IFND    LIBRARIES_BOARDS_I
LIBRARIES_BOARDS_I    SET     1
**
**      $VER: boards.i 2.0 (11-Apr-96)
**
**      boards.library definitions
**
**      (C)1996 by Torsten Bach
**      All Rights Reserved.
**


		IFND    EXEC_TYPES_I
		INCLUDE 'exec/types.i'
		ENDC

;------------------------------------------------------------------------
; Generic library informations

BOARDSNAME      MACRO
		dc.b    "boards.library",0
		ENDM

BOARDSVERSION   EQU     2


;------------------------------------------------------------------------
;
; BoardInfo structure
;
; This structure must only be allocated by boards.library with
; AllocBoardInfo().
;
; The BoardInfo structure are filled with NextBoardInfo()
; It`s READ-ONLY!

  STRUCTURE BoardInfo,0
	APTR	ConfigDev	; Pointer to ConfigDev structure
	ULONG	bi_flags	; BoardInfo-flags
	APTR	bi_ConfigDev	; Pointer to ConfigDev-address [10]
	APTR	bi_ExAddress	; Pointer to Expansion-address [10]
	APTR	bi_ExSize	; Pointer to Expansion-size [10]
	APTR	bi_ManuID	; Pointer to ManufacturerID [6]
	APTR	bi_ProdID	; Pointer to ProductID [4]
	APTR	bi_ManuName	; Pointer to Manufacturer [48]
	APTR	bi_ProdName	; Pointer to Product [48]
	APTR	bi_cd_flags	; Pointer to ConfigDev-flags [4]
	APTR	bi_er_type	; Pointer to Expansion-type [4]
	APTR	bi_er_serial	; Pointer to SerialNumber [12]
	LABEL	bi_sizeoff

; You can change the string format by setting the BoardInfo-flags if you
; call AllocBoardInfo()


;------------------------------------------------------------------------
; BoardInfo-flags

SB_EXPANSION_SIZE_HEX	EQU	1	;Default = DEC (e.g. 64k )
SB_MANUFACTURERID_HEX	EQU	4	;Default = DEC (e.g. 2017 )
SB_PRODUCTID_HEX	EQU	8	;Default = DEC (e.g. 1 )
SB_SERIALNUMBER_HEX	EQU	16	;Default = DEC (e.g. 123456 )
SB_CONFIGDEV_FLAGS_DEC	EQU	32	;Default = HEX (e.g. $02 )
SB_EXPANSION_TYPE_DEC	EQU	64	;Default = HEX (e.g. $c1 )

	ENDC
