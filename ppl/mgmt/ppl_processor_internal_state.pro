;+
; :file_comments:
;    Applications must store their internal state in this internal state structure. The separation
;    of processing and state allows for an easier saving and restoring procedure. The state structure created
;    with this routine is a generalized structure, which can (must be) specialized for every specific
;    application.
;
; :categories:
;    pipeline processing framework
;
; :examples:
;    n/a
;
; :history:
;    10-May-2016 -  Laszlo I. Etesi (FHNW), initial release
;-
;+
; :description:
;   this routine creates an empty internal state for a given specialization (e.g.
;   for the Flight Software Simulator); this routine wil attach the configuration manager
;   and other pipeline-level elements
;
; :keywords:
;   specific_state : in, required, type='XXX_internal_state'
;     a specialized internal state implementation (e.g. for the Flight Software Simulator)
;-
function ppl_processor_internal_state, specific_state=specific_state
  ; simple check if type is a valid state
  ; IDL command 'isa' would be safe, but it is IDL 8+
  help, specific_state, output=state_name
  if(where(stregex(state_name, '.*_internal_state.*', /boolean, /fold_case) eq 1) eq -1) then return, 0

  ; add all ppl_processor level state variables
  is = { $
    configuration_manager : ptr_new() $                         ; a pointer to the configuration manager
  }
  
  is_names = tag_names(is)
  
  new_internal_state = specific_state
  
  ; merge the implementation specific state with the ppl processor state
  for i = 0L, n_tags(is)-1 do begin
    new_internal_state = add_tag(new_internal_state, is.(i), is_names[i], /duplicate) 
  endfor
  
  return, new_internal_state
end