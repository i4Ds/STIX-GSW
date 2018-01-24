;---------------------------------------------------------------------------
; Document name: stx_spectrogram.pro
; Created by:    Nicky Hochmuth, 2012/04/26
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       STIX spectrogram structure
;
; PURPOSE:
;       Data exchange structure for spectrograms
;
; CATEGORY:
;       Hespe data exchange
;
; CALLING SEQUENCE:
;       structure = hsp_spectrogram(data, t_axis, e_axis, ltime)
;
; HISTORY:
;       2012/04/26, Nicky.Hochmuth@fhnw.ch, copied from HESPE
;
;-

;+
; :description:
;    This helper method creates a named structure 'hsp_spectrogram'
;    containing the spectrogram data with its time and energy axis
;
; :params:
;    data is the 2D-data array containing counts for energy over time [e,t]
;    t_axis is the 1D-data array containing the time axis
;    e_axis is a binning code
;    ltime are the live time data
;-
function stx_spectrogram, data, t_axis, e_axis, ltime, attenuator_state=attenuator_state
  error = 0
  catch, error
  if (error ne 0)then begin
    catch, /cancel
    err = err_state()
    message, err
    return, 0
  endif
  
  ; Do some parameter checking
  if ~(isarray(data) and size(data, /n_dimensions) eq 2) then message, "Parameter 'data' must be a 2D int array"
  if ~(ppl_typeof(t_axis,compareto='stx_time_axis')) then message, "Parameter 't_axis' must be a stx_time_axis structure"
  if ~(ppl_typeof(e_axis, compareto='stx_energy_axis')) then message, "Parameter 'e_axis' must be a stx_energy_axis structure"
  
  
  sizeltime = size(ltime)
  sizedata = size(data)
  
  if (sizeltime[1] ne sizedata[1] || sizeltime[2] ne sizedata[2]) then message, "Life-time data dimensions don't agree with data dimensions"
  
  ; Do some final checking on dimenstions (do they agree)
  data_dim = size(data, /dimensions)
  t_axis_dim = size(t_axis.duration)
  e_axis_dim = n_elements(e_axis.mean)
  
  if (data_dim[1] ne t_axis_dim[1]) then message, "'t_axis' dimensions do not agree with 'data' dimensions"
  if (data_dim[0] ne e_axis_dim) then message, "'e_axis' dimensions do not agree with 'data' dimensions"
  
  if keyword_set(attenuator_state) then begin
    if n_elements(attenuator_state) ne t_axis_dim[1] then message, "'t_axis' dimensions do not agree with 'attenuator_state' dimensions"
  endif else begin
    attenuator_state = make_array(t_axis_dim[1],/byte,value=0)
  end  
  
  ; If all goes well, put the hsp_spectrogram structure together and return it to caller
  str = { type              : 'stx_spectrogram', $
          data              : ULONG64(data), $
          t_axis            : t_axis, $
          e_axis            : e_axis, $
          ltime             : ltime,$
          attenuator_state  : attenuator_state }
    
  return, str
end