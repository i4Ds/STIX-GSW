;+
; Name: stx_vis_get_snr
;
; Purpose: Get Signal to Noise Ratio (SNR) for the given visibility bag
;
; Method:  Try to use the coarser sub-collimators, but if don't have enough visibilities in them, keep adding
;   in the finer ISCs until we have at least 2 visiblities, then use resistant mean of of abs(obsvis) / sigamp
;
; Calling arguments:
;  vis - STIX visibility bag
;
; Output: Returns the SNR value. If couldn't compute it, returns -1
;


function stx_vis_get_snr, vis

  ; Loop through ISCs starting with 3-10, but if we don't have at least 2 vis, lower isc_min to include next one down, etc.
  isc_min = 3
  nbig = 0

  while isc_min ge 0 and nbig lt 2 do begin
    ibig = where(float(vis.label) ge isc_min, nbig)
    isc_min = isc_min - 1
  endwhile

  ; If still don't have at least 2 vis, return -1, otherwise calculate mean (but reject points > sigma away from mean)
  if nbig lt 2 then snr_value = -1 else resistant_mean, f_div( abs(vis[ibig].obsvis), vis[ibig].sigamp ), 3., snr_value

  return, snr_value

end
