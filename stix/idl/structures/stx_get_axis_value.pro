;---------------------------------------------------------------------------
; Document name: stx_get_axis_value.pro
; Created by:    nicky.hochmuth 25.07.2012
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME: STIX get axis value
;       
;
; PURPOSE:
;       convenience access to the axis data of a stx_pxel_data
;
; CATEGORY:
;       data access
;
; CALLING SEQUENCE:
;       time = stx_get_axis_value(pixel_data,23,/time)
;       time_ext = stx_get_axis_value(pixel_data,23,/time,/struct)
;       time_span = stx_get_axis_value(pixel_data,23,index_end=30,/time,/struct)
;       
;
; HISTORY:
;       25.07.2012 nicky.hochmuth@fhnw.ch initial release
;-
;
;
;+
; :Description:
;    convenience access to the axis data of a stx_pxel_data
;
; :Params:
;    pixel_data: the stix pixel data struct
;    index: the index on the axis  
;
; :Keywords:
;    index_end: optional end index - if set the span between index and end_index is calculated
;    time: access to the time axis (default)
;    energy: access to the energy axis
;    struct: if set a struct with extendet data is returned
;
; :returns:
;   the value of the axis on the spezified index (default)
;   a struct with extended data if keyword set
;-
function stx_get_axis_value, pixel_data, index, index_end=index_end, time=time, energy=energy, struct=struct

  debug = exist(!DEBUG) ? !DEBUG  : 0
  
  if(~debug) then begin
    ; Do some error handling
    error = 0
    catch, error
    if (error ne 0)then begin
      catch, /cancel
      err = err_state() 
      message, err, continue=~debug
      ; DO MANUAL CLEANUP
      return, 0
    endif
  endif
  
  if ~ppl_typeof(pixel_data,COMPARETO='stx_pixel_data') then message, "'stx_pixel_data' acpected as input", /block
  
  checkvar, index, 0
  
  axis_label = 'taxis'
  
  if KEYWORD_SET(time) then axis_label = 'taxis'
  if KEYWORD_SET(energy) then axis_label = 'eaxis'
  
  axis = ((axis_label eq 'taxis') ? pixel_data.taxis : pixel_data.eaxis) 
  
  if ~KEYWORD_SET(struct) then return, axis[index]
  
  checkvar, index_end, index+1
  
  index_end = min([index_end,N_ELEMENTS(axis)-1])
  
  value = axis[index]
  value_end = axis[index_end]
  
  return, { type        : 'stx_axis_value', $ 
            axis        : axis_label, $
            value       : value, $
            bin_start   : value, $
            bin_end     : value_end, $
            value_span  : value_end - value $
         }
end