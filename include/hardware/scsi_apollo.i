    IFND EXEC_TYPES_I
    include "exec/types.i"
    ENDC

**** SCSI registers of 3-State AT/SCSI Apollo 2000:

SCSI_PORT_BASE   = $4000

SCSI_BUS_RETRIES = 4

scsi_DataPort    = $0000
scsi_Arbitration = $0401
scsi_StatusRead  = $0801
scsi_StatusWrite = $0c00

**** SCSI Status register (R/W):

 BITDEF SCSI,BSY,7
 BITDEF SCSI,IRQ,6
 BITDEF SCSI,SEL,5
 BITDEF SCSI,COD,4     ;Read only
 BITDEF SCSI,RST,4     ;Write only
 BITDEF SCSI,IO,3
 BITDEF SCSI,MSG,2
 BITDEF SCSI,REQ,1
 BITDEF SCSI,JMP,0     ;Read only

; SCSI phases :
;
;             MSG -----+
;             I/O ----+|
;             C/D ---+||
;                    |||
;                    VVV
PHASE_MASK     = %00011100
PHASE_DATA_OUT = %00011100
PHASE_DATA_IN  = %00010100
PHASE_UNDEF_1  = %00011000
PHASE_UNDEF_2  = %00010000
PHASE_COMMAND  = %00001100
PHASE_STATUS   = %00000100
PHASE_MESS_OUT = %00001000
PHASE_MESS_IN  = %00000000

**** SCSI Arbitration register :

 BITDEF SCSI,HOST,7
