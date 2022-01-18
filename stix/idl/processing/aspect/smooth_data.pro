;+
; Description :
;   Procedure to smooth the data by a factor two. The size of the resulting arrays is half the
;   size of the input data.
;
; Category    : analysis
;
; Syntax      : smooth_data, data
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
;   2020-06-01, FSc : add /double for times
;   2020-09-18, FSc : changed input from keyword to variable
;   2021-10-21, FSc : corrected computation of UTC strings
;   2021-12-16, FSc : use IDL's rebin instead of "my_smooth"
;
;-
pro smooth_data, data
  nb = n_elements(data.times)
  new_dim = nb/2
  
  ; rebin arrays of time
  new_times = rebin(data.times[0:2*new_dim-1],new_dim)
  new_utc = anytim2utc(new_times, /ccsds)

  ; rebin signals
  new_sigA  = rebin(reform(data.signal[0,0:2*new_dim-1]),new_dim)
  new_sigB  = rebin(reform(data.signal[1,0:2*new_dim-1]),new_dim)
  new_sigC  = rebin(reform(data.signal[2,0:2*new_dim-1]),new_dim)
  new_sigD  = rebin(reform(data.signal[3,0:2*new_dim-1]),new_dim)
  new_signal= transpose([[new_sigA],[new_sigB],[new_sigC],[new_sigD]])

  ; also rebin y_srf and z_srf
  new_y = rebin(data.y_srf[0:2*new_dim-1],new_dim)
  new_z = rebin(data.z_srf[0:2*new_dim-1],new_dim)
  
  ; build new data structure
  data = {times:new_times, UTC:new_utc, signal:new_signal, _calibrated:data._calibrated, $
          primary:data.primary, y_srf:new_y, z_srf:new_z}
end
