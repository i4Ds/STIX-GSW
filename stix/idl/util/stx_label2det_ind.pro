;+
; :project:
;       STIX
;
; :name:
;       stx_label2det_ind
;
; :description:
;     This procedure converts a STIX standard detector mask label string to the corresponding array of indices.
;
; :categories:
;    utilities, masks
;
; :params:
;    label : in, required, type="string"
;            The detector label to be converted to an index array
;            Allowed values are :
;            'ALL' : All 32 detectors
;            'IMAGING' : The 30 detectors with Fourier imaging grids (i.e. excluding the CFL and BKG detectors)
;            'TOP24' : The 24 detectors with imaging grids but no extra coverings
;            'FINE' : The 6 detectors with imaging grids and extra coverings - N.B. these are currently less well calibrated so their use is not recommended
;            'CFL' : Only the Coarse Flare Locator detector
;            'BKG' : Only the Background monitor detector
;
; :returns:
;    array of detector indices
;
; :examples:
;
;    IDL> stx_label2det_ind('top24')
;          0       1       2       3       4       5       6       7      13      14      15      19      20      21      22      23      24      25
;          26      27      28      29      30      31
;
;    IDL> stx_label2det_ind('bkg+cfl')
;          8       9
;
; :history:
;    26-Aug-2022 - ECMD (Graz), initial release
;
;-
function stx_label2det_ind, label

  label = strsplit(label, '+', count = count, /extract)

  stx_compute_subcollimator_indices, g01,g02,g03,g04,g05,g06,g07,g08,g09,g10,$
    l01,l02,l03,l04,l05,l06,l07,l08,l09,l10,$
    res32,res10,o32,g03_10,g01_10,g_plot,l_plot

  det_ind = []

  for i = 0, count-1 do begin
    case strupcase(label[i]) of
      'ALL' :  det_ind = [det_ind, indgen(32)]
      'IMAGING' :  det_ind = [det_ind, g01_10[sort(g01_10)]]
      'TOP24' :   det_ind = [det_ind, g03_10[sort(g03_10)]]
      'FINE' : det_ind = [det_ind, ([g01,g02])[sort([g01,g02])]]
      'CFL' : det_ind = [det_ind, [8]]
      'BKG' : det_ind = [det_ind, [9]]
      else: message, 'Detector label not recognised'
    endcase
  endfor

  det_ind = get_uniq( det_ind, sort(det_ind))

  return, det_ind
end