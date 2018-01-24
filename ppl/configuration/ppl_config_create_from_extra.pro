;---------------------------------------------------------------------------
; Document name: ppl_config_create_from_extra.pro
; Created by:    Nicky Hochmuth, 2012/07/18
;---------------------------------------------------------------------------
;+
; PROJECT:
;       IDL Pipeline
;
; NAME:
;       IDL Pipeline configuration structure
;
; PURPOSE:
;       creates a configuration structure based on all extra parameters 
;
; CATEGORY:
;       Pipeline processing module
;
; CALLING SEQUENCE:
;       config = ppl_config_create_from_extra(test1=3,foo=4,bar=[1,2,3])
;
; HISTORY:
;       2012/07/18, nicky.hochmuth@fhnw.ch, initial release
;
;-

;+
; :description:
;    This helper method creates a configuration structure based on all extra parameters 
;
; :Keywords:
;   every keyword will by packed into the structure
;
;-
function ppl_config_create_from_extra, _EXTRA=ex
  if(exist(!DEBUG)) then debug = !DEBUG $
  else debug = 0
  
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
  
  defcon = {type : 'ppl_configuration'}
     
    tags = tag_names(ex)
    for index = 0L, n_elements(tags)-1 do begin
      defcon = add_tag(defcon, ex.(index), tags[index])
    endfor
  
  
    return, defcon
end