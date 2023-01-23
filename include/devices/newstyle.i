 IFND DEVICES_NEWSTYLE_I
DEVICES_NEWSTYLE_I SET 1
*------------------------------------------------------------------------*
*                                                                        *
* $Id: newstyle.i 1.1 1997/05/15 18:53:15 heinz Exp $                    *
*                                                                        *
* Support header for the New Style Device standard                       *
*                                                                        *
* (C)1996-1997 by Amiga International, Inc.                              *
*                                                                        *
*                                                                        *
*------------------------------------------------------------------------*

 IFND EXEC_IO_I
 INCLUDE "exec/io.i"
 ENDC
 
*
*  At the moment there is just a single new style general command:
*

NSCMD_DEVICEQUERY EQU $4000

 STRUCTURE NSDeviceQueryResult,0
*
* Standard information, must be reset for every query
*
 ULONG   DevQueryFormat         ; this is type 0
 ULONG   SizeAvailable          ; bytes available

*
* Common information (READ ONLY!)
*
 UWORD   DeviceType             ; what the device does
 UWORD   DeviceSubType          ; depends on the main type
 APTR    SupportedCommands      ; 0 terminated list of cmd's

* May be extended in the future! Check SizeAvailable!
 LABEL   nsdqr_SIZEOF

NSDEVTYPE_UNKNOWN   EQU 0   ; No suitable category, anything
NSDEVTYPE_GAMEPORT  EQU 1   ; like gameport.device
NSDEVTYPE_TIMER     EQU 2   ; like timer.device
NSDEVTYPE_KEYBOARD  EQU 3   ; like keyboard.device
NSDEVTYPE_INPUT     EQU 4   ; like input.device
NSDEVTYPE_TRACKDISK EQU 5   ; like trackdisk.device
NSDEVTYPE_CONSOLE   EQU 6   ; like console.device
NSDEVTYPE_SANA2     EQU 7   ; A >=SANA2R2 networking device
NSDEVTYPE_AUDIO     EQU 8   ; like audio.device
NSDEVTYPE_CLIPBOARD EQU 9   ; like clipboard.device
NSDEVTYPE_PRINTER   EQU 10  ; like printer.device
NSDEVTYPE_SERIAL    EQU 11  ; like serial.device
NSDEVTYPE_PARALLEL  EQU 12  ; like parallel.device


*------------------------------------------------------------------------*
* The following defines should really be part of device specific
* includes. So we protect them from being redefined.
*

*
*  An early new style trackdisk like device can also return this
*  new identifier for TD_GETDRIVETYPE. This should no longer
*  be the case though for newly written or updated NSD devices.
*  This identifier is ***OBSOLETE***
*

DRIVE_NEWSTYLE     EQU $4E535459 ; 'NSTY'


*
*  At the moment, only four new style commands in the device
*  specific range and their ETD counterparts may be implemented.
*

NSCMD_TD_READ64    EQU $C000
NSCMD_TD_WRITE64   EQU $C001
NSCMD_TD_SEEK64    EQU $C002
NSCMD_TD_FORMAT64  EQU $C003

NSCMD_ETD_READ64   EQU $E000
NSCMD_ETD_WRITE64  EQU $E001
NSCMD_ETD_SEEK64   EQU $E002
NSCMD_ETD_FORMAT64 EQU $E003

*------------------------------------------------------------------------*

 ENDC ; DEVICES_NEWSTYLE_I
