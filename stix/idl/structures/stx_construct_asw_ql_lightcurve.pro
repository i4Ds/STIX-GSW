;+
; :Description: Stx_construct_energy_axis is an energy axis structure constructor function
; :Params:
;   n_time_bins     - keyword, number of time bins
;   from            - keyword, an ql_lightcurve like structure
;   time_axis       - a time axis struct
;                   |--> on of these keywords has to be set
;   
;   n_energy_bins   - number of energy bins
;   energy_axis     - an energy_axis struct
;   counts          - a two dimensional (n_energy_bins,n_time_bins) ulong array of counts
;   triggers        - ulong array of triggers
;   rcr             - byte array of rcr
;   detector_mask   - byte array of lenght 32
;   pixel_mask      - byte array of lenght 12
;   
; :History:
;   28-Jun-2016 - Simon Marcin (FHNW), initial version
;-

function stx_construct_asw_ql_lightcurve, n_time_bins=n_time_bins, n_energy_bins=n_energy_bins, $
  from=from, time_axis=time_axis, energy_axis=energy_axis, $
  counts=counts, triggers=triggers, rcr=rcr, $
  detector_mask=detector_mask, pixel_mask=pixel_mask

  ; check if at least one of the mandatory keywords is set
  if not keyword_set(n_time_bins) and not keyword_set(from) and not keyword_set(time_axis) then begin
    message, "at least  keyword 'n_time_bins', 'time_axis' or 'from' has to be set."
  endif
  

  if ppl_typeof(from, compareto='stx_fsw_ql_lightcurve') then begin
    dim = size(from.accumulated_counts, /dimensions)

    if(n_elements(dim) eq 2) then lc = stx_lightcurve(dim[0], dim[1]) $
    else lc = stx_lightcurve(dim[0], dim[3])
    lc.unit = "total detector counts"

    if(n_elements(dim) eq 2) then lc.data = from.accumulated_counts $
    else lc.data = from.accumulated_counts[*,0,0,*]
    lc.energy_axis = from.energy_axis
    lc.time_axis = from.time_axis
  end

  if ppl_typeof(from, compareto='stx_fsw_result_background') then begin
    dim = size(from.data, /dimensions)

    lc = stx_lightcurve(dim[1], dim[0])
    ;lc.unit = "background avg rate / s / detector"
    lc.unit = "total detector counts"
    lc.data = transpose(from.data)
    lc.energy_axis = from.energy_axis
    lc.time_axis = from.time_axis
  end
  
  ; define bin sizes if not defined explicit
  if keyword_set(energy_axis) then n_energy_bins=size(energy_axis.WIDTH, /DIM)
  if keyword_set(time_axis) then n_time_bins=size(time_axis.duration, /DIM)
  
  ; create lightcurve struct
  lc=stx_asw_ql_lightcurve(n_time_bins,n_energy_bins)
  
  ; fill struct with requested information
  if keyword_set(time_axis) then lc.time_axis = time_axis
  if keyword_set(energy_axis) then lc.energy_axis = energy_axis
  if keyword_set(counts) then lc.counts = counts
  if keyword_set(triggers) then lc.triggers = triggers
  if keyword_set(rcr) then lc.rate_control_regime = rcr
  if keyword_set(detector_mask) then lc.detector_mask = detector_mask
  if keyword_set(pixel_mask) then lc.pixel_mask = pixel_mask

  return, lc
end



