;+
; Description :
;   Procedure to smooth the STIX Aspect data by a factor two. The size of the resulting arrays
;   is half the size of the input data.
;
; Category    : analysis
;
; Syntax      : stx_smooth_sas_data, data
;
; Inputs      :
;   data      = a structure as returned by read_sas_data
;
; Output      : The input structure is replaced with the smoothed version.
;
; Keywords    : None.
;
; History     :
;   2020-05-14, F. Schuller (AIP) : created
;   2020-06-01, FSc (AIP) : add /double for times
;   2020-09-18, FSc (AIP) : changed input from keyword to variable
;   2021-10-21, FSc (AIP) : corrected computation of UTC strings
;   2021-12-16, FSc (AIP) : use IDL's rebin instead of "my_smooth"
;   2022-01-28, FSc (AIP) : adapted to STX_ASPECT_DTO structure
;   2022-02-15, FSc (AIP) : fixed issue related to integration with STIXcore
;   2022-04-21, FSc (AIP) : changed name from "smooth_data" to "stx_smooth_sas_data"
;-
pro stx_smooth_sas_data, data
  nb = n_elements(data)
  new_dim = nb/2
  
  ; rebin arrays of time
  num_times = anytim(data.time, /TAI)
  new_times = rebin(num_times[0:2*new_dim-1],new_dim)
  new_utc = anytim2utc(new_times, /ccsds, /truncate)

  ; rebin signals
  new_sigA  = rebin(reform(data[0:2*new_dim-1].CHA_DIODE0),new_dim)
  new_sigB  = rebin(reform(data[0:2*new_dim-1].CHA_DIODE1),new_dim)
  new_sigC  = rebin(reform(data[0:2*new_dim-1].CHB_DIODE0),new_dim)
  new_sigD  = rebin(reform(data[0:2*new_dim-1].CHB_DIODE1),new_dim)
  ; and calib factor
  new_cal = rebin(reform(data[0:2*new_dim-1].CALIB),new_dim)
  
  ; also rebin spice_disc_size, y_srf and z_srf
  new_y = rebin(data[0:2*new_dim-1].y_srf,new_dim)
  new_z = rebin(data[0:2*new_dim-1].z_srf,new_dim)
  new_rsol = rebin(data[0:2*new_dim-1].SPICE_DISC_SIZE,new_dim)
  
  ; new duration: compute the sum of two consecutive durations
  new_dura = fltarr(new_dim)
  for i=0,new_dim-1 do new_dura[i] = data[2*i].duration + data[2*i+1].duration

  ; also rebin SCET times ...
  new_scet_c = rebin(data[0:2*new_dim-1].scet_time_c,new_dim)
  new_scet_f = rebin(data[0:2*new_dim-1].scet_time_f,new_dim)
  ; ... as well as CONTROL_INDEX and PARENTFITS
  new_control = rebin(data[0:2*new_dim-1].control_index,new_dim)
  new_parentfits = rebin(data[0:2*new_dim-1].parentfits,new_dim)
  
  ; ERROR strings: keep an error message if present for one of the two rebinned values
  new_err = strarr(new_dim)
  new_sas_ok = intarr(new_dim)
  for i=0,new_dim-1 do if data[2*i].ERROR then new_err[i] = data[2*i].ERROR
  for i=0,new_dim-1 do if data[2*i+1].ERROR then new_err[i] = data[2*i+1].ERROR
  for i=0,new_dim-1 do if (data[2*i].sas_ok eq 1 AND data[2*i+1].sas_ok eq 1) then new_sas_ok[i] = 1

  ; build new array of data structures
  for i=0,new_dim-1 do begin
    a = {stx_aspect_dto, $
         cha_diode0: new_sigA[i],$
         cha_diode1: new_sigB[i],$
         chb_diode0: new_sigC[i],$
         chb_diode1: new_sigD[i],$
         time: new_utc[i],$
         scet_time_c: new_scet_c[i],$
         scet_time_f: new_scet_f[i],$
         duration: new_dura[i],$
         spice_disc_size: new_rsol[i], $
         y_srf: new_y[i],$
         z_srf: new_z[i],$
         calib: new_cal[i],$
         sas_ok: new_sas_ok[i],$
         error: new_err[i], $
         control_index: new_control[i],$
         parentfits: new_parentfits[i]}
    if i eq 0 then data = [a] else data = [data, a]
  endfor

end
