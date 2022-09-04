;+
;
; NAME:
;   stx_label2ind
;
; PURPOSE:
;   Return an array of detector indices from the corresponding array of labels
; 
; INPUTS:
;   label: string array containing detector labels to be converted to corresponding indices (between 0 and 31)
;
; HISTORY: September 2022, Massa P., created from 'stx_label2ind'
;
;-

FUNCTION stx_label2ind, label

  g10=[3,20,22]-1
  l10=['10a','10b','10c']
  g09=[16,14,32]-1
  l09=['9a','9b','9c']
  g08=[21,26,4]-1
  l08=['8a','8b','8c']
  g07=[24,8,28]-1
  l07=['7a','7b','7c']
  g06=[15,27,31]-1
  l06=['6a','6b','6c']
  g05=[6,30,2]-1
  l05=['5a','5b','5c']
  g04=[25,5,23]-1
  l04=['4a','4b','4c']
  g03=[7,29,1]-1
  l03=['3a','3b','3c']
  g02=[12,19,17]-1
  l02=['2a','2b','2c']
  g01=[11,13,18]-1
  l01=['1a','1b','1c']
  gcfl = [8]
  lcfl = ['cfl']
  gbkg = [9]
  lbkg = ['bkg']
  
  grid_idx=[g10,g05,g09,g04,g08,g03,g07,g02,g06,g01,gcfl,gbkg]
  grid_label=[l10,l05,l09,l04,l08,l03,l07,l02,l06,l01,lcfl,lbkg]

  indices = intarr(n_elements(label))
  for i=0,n_elements(label)-1 do begin

    indices[i] = grid_idx[WHERE(STRCMP(grid_label,label[i]) EQ 1)]

  endfor

  return, indices

END