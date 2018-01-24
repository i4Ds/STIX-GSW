;---------------------------------------------------------------------------
; Document name: ppl_config_create_and_merge_extra.pro
; Created by:    Nicky Hochmuth, 2012/07/19
;---------------------------------------------------------------------------
;+
; PROJECT:
;       IDL Pipeline
;
; NAME:
;       IDL Pipeline configuration structure
;
; PURPOSE:
;       merges two configurations: a given one and an  implicit given one by additional keywords 
;
; CATEGORY:
;       Pipeline processing module
;
; CALLING SEQUENCE:
;       merged_config = ppl_config_create_and_merge_extra(config=config,test1=3,foo=4,bar=[1,2,3],...)
;
; HISTORY:
;       2012/07/19, nicky.hochmuth@fhnw.ch, initial release
;
;-

;+
; :description:
;    merges two configurations: a given one and an  implicit given one by additional keywords
;
; :Keywords:
;    config: the draft configuration
;    every other keyword will by merged into config
;
;-
function ppl_config_create_and_merge_extra, config=config, _extra=ex
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
  
   if keyword_set(config) && ~keyword_set(ex) then return, config

   if ~keyword_set(config) && keyword_set(ex) then return, ppl_config_create_from_extra(_extra=ex)
   
   if ~keyword_set(config) && ~keyword_set(ex) then return,  {type : 'ppl_configuration'}
   
   return, ppl_config_merge(config, ppl_config_create_from_extra(_extra=ex),/add_to_draft)

end