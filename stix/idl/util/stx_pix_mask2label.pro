;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_pix_mask2label
;
; :description:
;    This procedure converts a STIX pixel mask to a string label that can be included in plots to
;    show the pixels used in a concise but understandable manner.
;
; :categories:
;    utilities, masks
;
; :params:
;    pix_mask : in, required, type="int arr"
;             a 12 element pixel mask
;
; :returns:
;    label - string
;            Standard return values are :
;            'All' : All 12 pixels.
;            'Top' : The 4 large pixels in the top row.
;            'Bottom' : The 4 large pixels in the bottom row.
;            'Small' : The 4 small pixels.
;            'Large' : The 8 large pixels (i.e. top + bottom rows).
;            If the mask is not one of the standard values listed then the output string will be:
;            - If a single pixel is chosen the label for that pixel will be given.
;            - If multiple detectors are included the 3 character hex code of the custom mask will be given in uppercase.
;
;
; :examples:
;    IDL> stx_pix_mask2label(intarr(12)+1)
;         All
;
;    IDL> mask = intarr(12)
;    IDL> mask[0] = 1
;    IDL> stx_pix_mask2label(mask)
;         L0
;
;    IDL> mask = intarr(12)
;    IDL> mask[0:10] = 1
;    IDL> stx_pix_mask2label(mask)
;    Custom 0x7FF
;
; :history:
;    26-Aug-2022 - ECMD (Graz), initial release
;
;-
function stx_pix_mask2label, pix_mask

  if total(pix_mask) eq 1 then begin
    w =  where(pix_mask eq 1)
    all_labels = ['L0', 'L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7' , 'S8', 'S9', 'S10', 'S11' ]
    out = all_labels[w]
    return, out
  endif

  name = ['Top', 'Bottom', 'Small', 'Large', 'All' ]
  hex =  ['00F', '0F0'   , 'F00'  , '0FF'  , 'FFF']

  r = reverse(byte(pix_mask))

  bin2hex, r, hex_mask, /upper, /quiet, nchar = 3

  w =  where(hex eq hex_mask)

  out = w ne -1 ? name[w] : 'Custom 0x' + hex_mask

  return, out
end