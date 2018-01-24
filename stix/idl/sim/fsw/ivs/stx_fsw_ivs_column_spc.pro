;---------------------------------------------------------------------------
; Document name: stx_ivs_column_spc.pro
; Created by:    Nicky Hochmuth, 2012/03/05
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;      Helper function for stx_fsw_ivs_column_spc__define
;
; PURPOSE:
;      Facilitates the creation of stx_ivs_column class for spectroscopy
;
; CATEGORY:
;      STIX, helper routine
;
; CALLING SEQUENCE:
;       obj = stx_fsw_ivs_column_spc(start_time, end_time, spectrogram)
;
; HISTORY:
;       2013/06/13, nicky.hochmuth@fhnw.ch, initial release
;-

;+
; :description:
;    Creates a new stx_fsw_ivs_column_spc class
;
; :params:
;   start_time: the index on the time axis of the spectrogram the column starts
;   end_time: the index on the time axis of the spectrogram the column ends
;   spectrogram: a pointer to the spectrogram
;
; :returns:
;    A new stx_fsw_ivs_column_spc class
;-
function stx_fsw_ivs_column_spc, start_time, end_time, spectrogram, thermalboundary=thermalboundary, min_time=min_time, min_count=min_count

  default, min_time, 4.0; sec
  default, min_count, [400,400] ;[thermal, nonthermal] not corected detetcor counts over all pixel and detectors counts
  default, thermalboundary, 10

  return, obj_new('stx_fsw_ivs_column_spc', start_time, end_time, spectrogram, thermalboundary, min_time,  min_count[0], min_count[1])

end