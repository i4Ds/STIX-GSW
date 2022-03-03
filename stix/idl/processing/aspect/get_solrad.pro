; Get heliocentric distance for a given array of times, and convert to
; solar image radius
function get_solrad, times_UTC
  ; define constants
  foclen = 0.55         ; SAS focal length, in [m]
  solrad_m = 6.9566e8   ; solar radius [m]

  nb = n_elements(times_UTC)
  d_sol = fltarr(nb)

  ; get position of SolO with respect to the Sun
  solo_pos = get_sunspice_lonlat(times_UTC,'SOLO')
  ; convert distance to [m]
  d_sol = reform(solo_pos[0,*]) * 1.e3
  ; then the image radius in the focal plane is:
  return, foclen*(solrad_m/d_sol)
end
