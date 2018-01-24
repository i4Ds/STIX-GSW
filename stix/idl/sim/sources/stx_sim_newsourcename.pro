;+
; :description:
;     This function creates a unique name for each defined source
;
; :params:
;     strtab : in, required, type="array of stx_sim_source structures"
;              array containing parameters of simulated sources
;              structures are defined by procedure stx_sim_source_structure.pro
;
;  :returns:
;     m : out, type = "long"
;         first not occurring number in the name field of input array
;     
;  :history:
;     29-Oct-2012 - Marek Steslicki (Wro), initial release
;     01-Nov-2013 - Shaun Bloomfield (TCD), 'name' tag changed to
;                   'source'
;-
function stx_sim_newsourcename, strtab
  n=n_elements(strtab)
  if n lt 1 then begin
    m=n+1
  endif else begin
    m=strtab[0].source
    for i=0,n-1 do if m lt strtab[i].source then m=strtab[i].source
    m++
  endelse
  return,m
end
