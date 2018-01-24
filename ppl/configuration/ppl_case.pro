;+
; :description:
;    creates a structure to host sub configurations 
;
; :params:
;    value  : the initial case
     
; :returns:
;   a struct of type ppl_case and with a "value" tag
;      
; :categories:
;    utility, legacy, pipeline
;    
; :examples: 
; use in configuration file to mark a subcae
; 
; algo = ppl_case('uvsmooth') ; [clean|bpmap|bproj|memnjit|uvsmooth|fwdfit]
;   
; 
; :history:
;    2014/01/05 nicky.hochmuth@fhnw.ch, initial release
;-
function ppl_case, value
  default, value, ''
  str = { $
    type    : "ppl_case", $ 
    value   : value $
  }
  return, str
end