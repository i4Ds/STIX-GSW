; Get heliocentric distance for a given array of times, and convert to
; solar image radius
function get_solrad, times_UTC
  common config
  restore, param_dir + '/SAS_global_param.sav'  ; read global parameters (focal length, solar radius (in m), etc.)

  nb = n_elements(times_UTC)
  d_sol = fltarr(nb)

  for i=0,nb-1 do begin
    ; convert date to tdb and compute relative positions
    cspice_str2et,times_UTC[i],tdb
    cspice_spkpos,'Sun',tdb,'J2000','None','SOLO',state_sol,ltime
    d_sol[i] = cspice_vnorm(state_sol)*1e3   ; in m
  endfor
  return, foclen*(solrad_m/d_sol)
end
