;---------------------------------------------------------------------------
; Document name: stx_img_spectra_control.pro
;---------------------------------------------------------------------------
;
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_img_spectra_control__define
;
; PURPOSE: 
; This routine gives the defaults for the STX_IMG_SPECTRA object control parameters
;       
;
; CATEGORY:
;       
; 
; CALLING SEQUENCE:
;       
;    var = stx_img_spectra_control() 
;    IDL> var = stx_img_spectra_control()
;    % RESTORE: Portable (XDR) SAVE/RESTORE file.
;    % RESTORE: Save file written by raschwar@GS671-DECKARD, Fri Jun 20 12:23:59 2014.
;    % RESTORE: IDL version 8.1 (Win32, x86_64).
;    % RESTORE: Restored variable: IOUT.
;    IDL>    
;    IDL> help, var, /st
;    ** Structure STX_IMG_SPECTRA_CONTROL, 2 tags, length=12, data length=12:
;       IMG             POINTER   <PtrHeapVar19>  ;these are created by the interval selectin alg.
;       ERANGE          FLOAT     Array[2]
;    IDL> simg = obj_new( 'stx_img_spectra' )
;    IDL> help, simg->get(/img)
;    <Expression>    STRUCT    = -> <Anonymous> Array[976]
;    IDL> help, simg->get(/img), /st
;    ** Structure <e830090>, 8 tags, length=80, data length=78, refs=2:
;       TYPE            STRING    'stx_ivs_interval'
;       START_TIME      STRUCT    -> <Anonymous> Array[1]
;       END_TIME        STRUCT    -> <Anonymous> Array[1]
;       START_ENERGY    FLOAT           6.00000
;       END_ENERGY      FLOAT           8.00000
;       COUNTS          LONG              4551
;       TRIM            BYTE        10
;       SPECTROSCOPY    BYTE         0
;        
;
; SEE ALSO:
;       
;       
;
; HISTORY:
; Created by:  rschwartz70@gmail.com
;
; Last Modified: 25-jun-2014
;   ras, use the file we search for!
;
;-
;

function stx_img_spectra_control

file = file_search( concat_dir( getenv('SSW_STIX'), '..'), 'iout.sav', count=count)
if count eq 1 then restore,/ver, file[0] else $
  stx_ivs_demo, obs_time = '2002/07/23 ' + ['00:10:00', '00:55:00'], plotting=0, intervals_out = iout
  
zz = where( iout.spectroscopy eq 0 )
iout = iout[zz]
energy_edge = get_uniq(  [iout.start_energy, iout.end_energy] )

var = {stx_img_spectra_control}

var.img = ptr_new( iout )
var.erange = energy_edge[[6, 12]]



RETURN, var

END


;---------------------------------------------------------------------------
; End of 'stx_img_spectra_control.pro'.
;---------------------------------------------------------------------------
