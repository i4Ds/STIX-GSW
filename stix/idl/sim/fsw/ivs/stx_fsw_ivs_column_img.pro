;---------------------------------------------------------------------------
; Document name: stx_fsw_ivs_column_img.pro
; Created by:    Nicky Hochmuth, 2015/03/10
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;      Helper function for stx_fsw_ivs_column_img__define
;
; PURPOSE:
;      Facilitates the creation of stx_fsw_ivs_column_img classes
;
; CATEGORY:
;      STIX, helper routine
;
; CALLING SEQUENCE:
;       obj = stx_fsw_ivs_column_img(start_time, end_time, rows, spectrogram)
;
; HISTORY:
;       2015/03/10, nicky.hochmuth@fhnw.ch, initial release
;-

;+
; :description:
;    Creates a new stx_fsw_ivs_column_img class
;
; :params:
;   start_time: the index on the time axis of the spectrogram the column starts
;   end_time: the index on the time axis of the spectrogram the column ends
;   rows: an array of all indexes on the energy axis this column is created for
;   spectrogram: a pointer to the stx_fsw_spectrogram
;
; :returns:
;    A new stx_fsw_ivs_column_img class
;-
function stx_fsw_ivs_column_img, start_time, end_time, rows, spectrogram, level=level,thermalboundary=thermalboundary,min_time=min_time,min_count=min_count
  default, level, 0
  default, thermalboundary,   10
  default, min_time,          [0.0,0]; [thermal,non_thermal] sec
  default, min_count,         [[4000,500],[8000,1000]]  ;[[N1 thermal,N1 non_thermal],[N2 thermal,N2 non_thermal]] not corected detetcor counts

  
  
  
  return, obj_new('stx_fsw_ivs_column_img', start_time, end_time, rows, spectrogram, level, thermalboundary, min_time, min_count)

end