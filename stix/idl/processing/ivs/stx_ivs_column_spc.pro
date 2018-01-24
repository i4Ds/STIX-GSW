;---------------------------------------------------------------------------
; Document name: stx_ivs_column_spc.pro
; Created by:    Nicky Hochmuth, 2012/03/05
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;      Helper function for stx_ivs_column_spe__define
;
; PURPOSE:
;      Facilitates the creation of stx_ivs_column class for spectroscopy
;
; CATEGORY:
;      STIX, helper routine
;
; CALLING SEQUENCE:
;       obj = stx_ivs_column_spc(start_time, end_time, rows, spectrogram)
;
; HISTORY:
;       2013/06/13, nicky.hochmuth@fhnw.ch, initial release
;-

;+
; :description:
;    Creates a new stx_ivs_column class
;
; :params:
;   start_time: the index on the time axis of the spectrogram the column starts
;   end_time: the index on the time axis of the spectrogram the column ends
;   rows: an array of all indexes on the energy axis this column is created for
;   spectrogram: a pointer to the spectrogram
; 
; :returns:
;    A new stx_ivs_column class
;-
function stx_ivs_column_spc, start_time, end_time, spectrogram, thermalboundary=thermalboundary,min_time=min_time,min_count=min_count
  
  default, thermalboundary,    25.0
  default, min_time, 4.0; sec
  default, min_count, [400000,800000] ;[thermal,non_thermal] not corected detetcor counts over all pixel and detectors counts
  
  
  return, obj_new('stx_ivs_column_spc', start_time, end_time, spectrogram,thermalboundary,min_time,min_count)
  
end