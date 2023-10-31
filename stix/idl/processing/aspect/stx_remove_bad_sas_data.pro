;+
; Description :
;   Procedure to remove data points with some error from an SAS data object
;
; Category    : analysis
;
; Syntax      : stx_remove_bad_sas_data, data
;
; Inputs      :
;   data      = an array of stx_aspect_dto structures
;
; Output      : The input structure is modified
;
; Keywords    : None.
;
; History     :
;   2023-08-30, F. Schuller (AIP) : created
;-
pro stx_remove_bad_sas_data, data
  ; Make sure that input is as expected
  if n_params() lt 1 then message,' SYNTAX: stx_remove_bad_sas_data, data'
  if not is_struct(data) then message," ERROR: input variable is not a structure."

  ; test for the existence of bad data points
  bad = where(data.error ne '', n_bad)
  if n_bad eq 0 then begin
    print, "STX_REMOVE_BAD_SAS_DATA: No bad data points found - doing nothing."
    return
  endif

  good = where(data.error eq '', n_good)
  print, n_good, n_elements(data), format='("Keeping only ",I5," out of ",I5," measurements.")'
  result = []
  for i=0,n_good-1 do begin
    one_data = {stx_aspect_dto, $
                cha_diode0: data[good[i]].cha_diode0, cha_diode1: data[good[i]].cha_diode1, $
                chb_diode0: data[good[i]].chb_diode0, chb_diode1: data[good[i]].chb_diode1, $
                time: data[good[i]].time, $
                scet_time_c: data[good[i]].scet_time_c, scet_time_f: data[good[i]].scet_time_f, $
                duration: data[good[i]].duration, $
                spice_disc_size: data[good[i]].spice_disc_size, $
                y_srf: data[good[i]].y_srf, z_srf: data[good[i]].z_srf, $
                calib: data[good[i]].calib, sas_ok : 1, error : "", $
                control_index: data[good[i]].control_index, parentfits: data[good[i]].parentfits}
    result = [result, one_data]
  endfor
  data = result
end
