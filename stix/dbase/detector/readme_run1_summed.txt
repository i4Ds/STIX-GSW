IDL> ;save,run1_summed,file='run1_summed.sav'
IDL> restore,/ver,'run1.sav
% RESTORE: Portable (XDR) SAVE/RESTORE file.
% RESTORE: Save file written by richard@RSXPSLT, Thu Mar 07 05:12:28 2019.
% RESTORE: IDL version 8.5.1 (Win32, x86_64).
% RESTORE: Restored variable: B1.
% RESTORE: Restored variable: OUT1.
IDL> help, b1
B1              LIST  <ID=1337  NELEMENTS=37>
IDL> help, b1[0]
** Structure <e05bd00>, 4 tags, length=40, data length=36, refs=2:
TYPE            STRING    'stx_asw_ql_calibration_spectrum'
START_TIME      STRUCT    -> STX_TIME Array[1]
END_TIME        STRUCT    -> STX_TIME Array[1]
SUBSPECTRA      OBJREF    <ObjHeapVar708(LIST)>
IDL> help, b1[0].subspectra[0]
** Structure <e0500e0>, 7 tags, length=1572936, data length=1572930, refs=2:
TYPE            STRING    'stx_asw_ql_calibration_subspectrum'
SPECTRUM        LONG      Array[1024, 12, 32]
LOWER_ENERGY_BOUND_CHANNEL
INT              0
NUMBER_OF_SUMMED_CHANNELS
INT              1
NUMBER_OF_SPECTRAL_POINTS
INT           1024
PIXEL_MASK      BYTE      Array[12]
DETECTOR_MASK   BYTE      Array[32]
IDL> help, out1
OUT1            LONG      = Array[1024, 12, 32, 37]
IDL> run1_summed= total(out1,4)