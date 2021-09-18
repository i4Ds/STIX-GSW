;+
;
; NAME:
;   stix_label2ind
;
; PURPOSE:
;   Return an array of detector indices from the array of corresponding detector labels
;
;
; HISTORY: September 2021: Paolo created
;
;-

FUNCTION stix_label2ind, label

  stix_compute_subcollimator_indices, g01,g02,g03,g04,g05,g06,g07,g08,g09,g10,$
                                      l01,l02,l03,l04,l05,l06,l07,l08,l09,l10,$
                                      res32,res10,o32,g03_10,g01_10,g_plot,l_plot
  
  indices = intarr(n_elements(label))
  for i=0,n_elements(label)-1 do begin
    
    indices[i] = g_plot[WHERE(STRCMP(l_plot,label[i]) EQ 1)]
    
  endfor
  
  return, indices

END