**** ATA registers of 3-State AT-Apollo 2000:

ata_DataPort    = $0000
ata_Error       = $0401
ata_Features    = $0401
ata_SectorCnt   = $0801
ata_SectorNum   = $0C01
ata_CylinderL   = $1001
ata_CylinderH   = $1401
ata_DevHead     = $1801
ata_Status      = $1C01
ata_Command     = $1C01
ata_AltStatus   = $3801
ata_DevCtrl     = $3801

ata_NextPort    = $2000
ata_NextReg     = $0400

**** ATAPI registers:

atapi_DataPort  = $0000
atapi_Error     = $0401
atapi_Features  = $0401
atapi_Reason    = $0801
atapi_SamTag    = $0C01
atapi_ByteCntL  = $1001
atapi_ByteCntH  = $1401
atapi_DriveSel  = $1801
atapi_Status    = $1C01
atapi_Command   = $1C01
atapi_AltStatus = $3801
atapi_DevCtrl   = $3801
