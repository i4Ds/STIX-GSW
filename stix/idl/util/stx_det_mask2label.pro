;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_det_mask2label
;
; :description:
;    This procedure converts a STIX detector mask to a string label that can be included in plots to
;    show the detectors used in a concise but understandable manner.
;
; :categories:
;    utilities, masks
;
; :params:
;    det_mask : in, required, type="int arr"
;             a 32 element detector mask
;
; :returns:
;    label - string
;;            Standard return values are :
;            'All' : All 32 detectors
;            'Imaging' : The 30 detectors with Fourier imaging grids (i.e. excluding the CFL and BKG detectors)
;            'Top24' : The 24 detectors with imaging grids but no extra coverings
;            'Fine' : The 6 detectors with imaging grids and extra coverings - N.B. these are currently less well calibrated so their use is not recommended
;            'CFL' : Only the Coarse Flare Locator detector
;            'BKG' : Only the Background monitor detector
;            If the mask is not one of the standard values listed then the output string will be:
;            - If a single detector is chosen the label for that detector will be given in lowercase.
;            - If multiple detectors are included the 8 character hex code of the custom mask will be given in uppercase.
;
;
; :examples:
;    IDL> stx_det_mask2label(intarr(32)+1)
;         All
;
;    IDL> mask = intarr(32)
;    IDL> mask[0] = 1
;    IDL> stx_det_mask2label(mask)
;         3c
;
;    IDL> mask = intarr(32)
;    IDL> mask[0:15] = 1
;    IDL> stx_det_mask2label(mask)
;    Custom 0x0000FFFF
;
; :history:
;    26-Aug-2022 - ECMD (Graz), initial release
;
;-
function stx_det_mask2label, det_mask

  if total(det_mask) eq 1 then begin
    w =  where(det_mask eq 1)

    stx_compute_subcollimator_indices, g01,g02,g03,g04,g05,g06,g07,g08,g09,g10,$
      l01,l02,l03,l04,l05,l06,l07,l08,l09,l10,$
      res32,res10,o32,g03_10,g01_10,g_plot,l_plot

    im_labels = [l01,l02,l03,l04,l05,l06,l07,l08,l09,l10]
    all_labels = [im_labels, 'CFL', 'BKG']
    all_indices = [g01_10, 8, 9]

    label = (all_labels[sort(all_indices)])[w]
    return, label
  endif

  name = ['All'      ,'Imaging'  ,'Top24'    ,'Fine'     ,'CFL'      ,'BKG'     ]
  hex =  ['FFFFFFFF' ,'FFFFFCFF' ,'FFF8E0FF' ,'00071C00' ,'00000100' ,'00000200']

  r = reverse(byte(det_mask))
  r1 = r[0:15]
  r2 = r[16:31]

  bin2hex, r1, hex_mask1, /upper, /quiet, nchar = 4
  bin2hex, r2, hex_mask2, /upper, /quiet, nchar = 4

  hex_mask = hex_mask1 + hex_mask2

  w =  where(hex eq hex_mask)

  label = w ne -1 ? name[w] : 'Custom 0x' + hex_mask

  return, label
end