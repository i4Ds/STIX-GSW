;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_label2pix_ind
;
; :description:
;     This procedure converts a STIX standard pixel mask label string to the corresponding array of indices.
;
; :categories:
;    utilities, masks 
;
; :params:
;    label : in, required, type="string"
;            The pixel label to be converted to an index array
;            Allowed values are :
;            'All' : All 12 pixels.
;            'Top' : The 4 large pixels in the top row.
;            'Bottom' : The 4 large pixels in the bottom row.
;            'Small' : The 4 small pixels.
;            'Large' : The 8 large pixels (i.e. top + bottom rows).
;            Multiple labels can be combined with the plus sign e.g. 'bottom+small'
;             
; :returns:
;    An array of pixel indices corresponding to the input label.
;
; :examples:
; 
;    IDL> stx_label2pix_ind('top')
;       0       1       2       3
;    IDL> pix = stx_label2pix_ind('bottom+small')
;    IDL> print, pix
;    4       5       6       7       8       9      10      11
;    
; :history:
;    26-Aug-2022 - ECMD (Graz), initial release
;
;-
function stx_label2pix_ind, label

  label = strsplit(label, '+', count=count, /extract)

  pix_ind= []
  for i = 0,count-1 do begin
    case strupcase(label[i]) of
      'TOP' : pix_ind =  [pix_ind, [0,1,2,3]]
      'BOTTOM' : pix_ind = [pix_ind,[4,5,6,7]]
      'SMALL' : pix_ind = [pix_ind, [8,9,10,11]]
      'LARGE' : pix_ind = [pix_ind, [0,1,2,3,4,5,6,7]]
      'ALL' : pix_ind = [pix_ind,[0,1,2,3,4,5,6,7,8,9,10,11]]
      else: message, 'Pixel label not recognised'
    endcase
  endfor
  pix_ind = get_uniq( pix_ind, sort(pix_ind))

  return, pix_ind
end