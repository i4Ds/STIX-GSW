;+
; :Description: Stx_construct_ql_spectra is a spectra axis structure constructor function
; :Params:
;   n_time_bins     - keyword, number of time bins
;   from            - keyword, an stx_fsw_ql_spectra like structure
;   time_axis       - a time axis struct
;                   |--> on of these keywords has to be set
;
;   spectrum        - a three dimensional (energy_bin,n_detector,n_time_bins) ulong array of counts
;   triggers        - ulong array of triggers (n_detector,n_time_bins)
;   pixel_mask      - byte array of lenght 12
;
; :History:
;   10-Aug-2016 - Simon Marcin (FHNW), initial version
;-

function stx_construct_asw_ql_spectra, n_time_bins=n_time_bins, $
  from=from, time_axis=time_axis, spectrum=spectrum, triggers=triggers, pixel_mask=pixel_mask, $
  energy_axis=energy_axis, detector_mask=detector_mask

  ; check if at least one of the mandatory keywords is set
  if not keyword_set(n_time_bins) and not keyword_set(from) and not keyword_set(time_axis) then begin
    message, "at least  keyword 'n_time_bins', 'time_axis' or 'from' has to be set."
  endif

  ; use existing stx_fsw_ql_spectra structure
  if ppl_typeof(from, compareto='stx_fsw_ql_spectra') then begin
    dim = size(from.accumulated_counts, /dimensions)
    acc_counts = from.accumulated_counts
    time_axis = from.time_axis
  end


  ; define bin sizes if not defined explicit
  if keyword_set(time_axis) then n_time_bins=size(time_axis.duration, /DIM)

  ; create spectra struct
  spectra=stx_asw_ql_spectra(n_time_bins)

  ; fill struct with requested information
  if keyword_set(time_axis) then spectra.time_axis = time_axis
  if keyword_set(energy_axis) then spectra.energy_axis = energy_axis
  if keyword_set(spectrum) then spectra.spectrum = spectrum
  if keyword_set(triggers) then spectra.triggers = triggers
  if keyword_set(pixel_mask) then spectra.pixel_mask = pixel_mask
  if keyword_set(detector_mask) then spectra.detector_mask = detector_mask

  return, spectra
end



