; converts a coarse and fine time to an time axis
; uses an array of seconds to create the axis

function stx_telemetry_util_scet2axis, coarse_time=coarse_time, fine_time=fine_time, $
  nbr_structures=nbr_structures, integration_time_in_s=integration_time_in_s, seconds=seconds

  if n_elements(seconds) eq 0 then begin
    seconds=lindgen(nbr_structures+1)*integration_time_in_s
  endif

  stx_telemetry_util_time2scet, coarse_time=coarse_time, fine_time=fine_time, $
    stx_time_obj=t0, /reverse
  axis=stx_time_add(t0,seconds=seconds)
  return, stx_construct_time_axis(axis)

end
