;---------------------------------------------------------------------------
; Document name: stx_triggergram.pro
; Created by:    Richard Schwartz, 17-apr-2015
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       STIX triggergram structure
;
; PURPOSE:
;       Data exchange structure for triggergrams
;
; CATEGORY:
;       
;
; CALLING SEQUENCE:
;       structure = stx_triggergram(triggerdata, t_axis)
;
; HISTORY:
;       17-apr-2015, based on stx_spectrogram
;
;-

;+
; :description:
;    This helper method creates a named structure 'triggergram'
;    containing the triggergram data with its time and accumulator axes
;
; :params:
;    triggerdata is the 2D-data array containing triggers over time, either all 16 triggers by time or 1 trigger id by time
;    t_axis is the 1D-data array containing the time axis
;    adg_idx - Keyword, if passed it is the adg_idx (1-16) of the single trigger accumulator data passed
;    
;-
function stx_triggergram, triggerdata, t_axis, adg_idx = adg_idx
  error = 0
  catch, error
  if (error ne 0)then begin
    catch, /cancel
    err = err_state()
    message, err
    return, 0
  endif
  
  t_axis_dim = size(t_axis.duration, /dimension)
  if  t_axis_dim[0] eq 1 then triggerdata = reform(triggerdata,n_elements(triggerdata),1)
  
  sizetriggerdata = size(triggerdata, /str)
  ; Do some parameter checking
  if ~(isarray(triggerdata) and sizetriggerdata.dimensions[0] eq 16 or sizetriggerdata.dimensions[0] eq 1) then $
     message, "Parameter 'triggerdata' must be a 16 x M or 1 x M int array"
  if ~(ppl_typeof(t_axis,compareto='stx_time_axis')) then message, "Parameter 't_axis' must be a stx_time_axis structure"
  if sizetriggerdata.dimensions[0] eq 16 then adg_idx = indgen(16) + 1
  
  
  ; Do some final checking on dimenstions (do they agree)
  triggerdata_dim = sizetriggerdata.dimensions
  
  
;  if (triggerdata_dim[1] ne t_axis_dim[0] or t_axis_dim[0] eq 1) then $
    if (triggerdata_dim[1] ne t_axis_dim[0]) then $
     message, "'t_axis' dimensions do not agree with 'triggerdata' dimensions"
  
  
  ; If all goes well, put the hsp_triggergram structure together and return it to caller
  trigstr = { type              : 'stx_triggergram', $
          triggerdata           : ULONG64(triggerdata), $
          adg_idx           : adg_idx, $
          t_axis            : t_axis } ; $

    
  return, trigstr
end