;+
; :Description:
;    STX_FSW_BLD_ARCHIVE_BUFFER stores the archive_buffer base array for
;    a single time interval and expands and fills it with the input 
;    relative time array values.
;
; :Params:
;    rel_time - relative times created in stx_fsw_evl2archive
;
; :Method:
;   The single time archive buffer expanded for energies, detectors, and pixels is
;   only created once instead of every time entering the calling routine
;
; :Author: rschwartz70@gmail.com
; :History: 3-Jun-2016, Created
;-
function stx_fsw_bld_archive_buffer, rel_time

  common stx_fsw_bld_archive_buffer_com, ab_base

  if n_elements( ab_base ) eq 0 then begin
    n_energies = 32
    n_detectors = 32
    n_pixels = 12
    ab_base = replicate({stx_fsw_archive_buffer}, n_energies, n_detectors, n_pixels)
    for i = 0, n_energies  - 1 do ab_base[ i, *, *, * ].energy_science_channel = i
    for i = 0, n_detectors - 1 do ab_base[ *, i, *, * ].detector_index = i + 1
    for i = 0, n_pixels    - 1 do ab_base[ *, *, i, * ].pixel_index    = i
  endif
  n_gbins = n_elements( rel_time ) / 2
  archive_buffer = reproduce( ab_base, n_gbins )
  for i = 0, n_gbins     - 1 do archive_buffer[ *, *, *, i ].relative_time_range = rel_time[*,i]

  return, archive_buffer
end