;+
; :description:
;    Wrapper function to create a new ppl_history object
;
; :params:
;    variable : in, required, type=any
;      the input variable for which the type is evaluated
;      (can be a primitive type, an object, a structure, etc.)
;
; :returns:
;    a new pipeline history object
;
; :categories:
;    utility, pipeline
;
; :examples:
;    t = ppl_history()
;
; :history:
;    2013/10/14 - Laszlo I. Etesi (FHNW), initial release
;-
function ppl_history
  return, obj_new("ppl_history")
end