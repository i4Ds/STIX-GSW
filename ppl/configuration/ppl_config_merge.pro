;---------------------------------------------------------------------------
; Document name: ppl_config_merge.pro
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
;       merges two configurations by overriding each tag from the master to the draft
;
; CATEGORY:
;       Pipeline processing module
;
; CALLING SEQUENCE:
;       merged_config = ppl_config_merge(base_config,master_config)
;
; HISTORY:
;       2012/07/18, nicky.hochmuth@fhnw.ch, initial release
;
;-

;+
; :description:
;    This helper method merges two configurations by overriding each tag from the master to the base
;
; :params:
;    draft: the draft configuration
;    master: each tag from this configuration will be copied and ovveried to the base
;
;-

;+
; :description:
;    Merges two configurations by overriding and optionally copying each tag from the master to the base
;
; :categories:
;    pipeline, configuration, utility
;
; :params:
;    base : in, required, type='ppl_configuration'
;      this is the base configuration (e.g. the default configuration) structure
;
;    master : in, required, type='ppl_configuration'
;      this is the master configuration (e.g. the user configuration) structure
;       
; :keywords:
;    add_to_base : in, optional, type='boolean', default='0'
;      if set to 1, missing tags in 'master' are copied to base
;    recursive : in, optional, type='boolean', default='0'
;      if set to 1, the merge algorithm will descend into tags that are of type ppl_configuration and 'deep copy'
;      
; :returns:
;    a new configuration product of the two input configurations
;
; :examples:
;    merged_config = ppl_config_merge(base_config, master_config)
;
; :history:
;    18-Jul-2012 - Nicky Hochmuth (FHNW), initial release
;    21-Aug-2014 - Laszlo I. Etesi (FHNW), updated functionality to allow for nested structures
;-
function ppl_config_merge, base, master, add_to_base=add_to_base, recursive=recursive
  default, recursive, 0
  default, add_to_base, 0
  
  if(~ppl_typeof(base, compareto="ppl_configuration")) then message, "You must pass a valid configuration as parameter 'base'"
  if(~ppl_typeof(master, compareto="ppl_configuration")) then message, "You must pass a valid configuration as parameter 'master'"
  
  defcon = base
  
  tags = tag_names(master)
  for index = 0L, n_elements(tags)-1 do begin
    if(tag_exist(defcon, tags[index])) then begin
      if(recursive and ppl_typeof(master.(index), compareto="ppl_configuration")) then begin
        defcon.(tag_index(defcon, tags[index])) = ppl_config_merge(defcon.(tag_index(defcon, tags[index])), master.(index), add_to_base=add_to_base, recursive=recursive)
      endif else defcon.(tag_index(defcon, tags[index])) = master.(index)
    endif else begin
      if (add_to_base) then defcon = add_tag(defcon, master.(index), tags[index])
    endelse
  endfor
  
  return, defcon
end