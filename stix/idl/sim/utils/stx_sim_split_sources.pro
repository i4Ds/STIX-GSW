;+
; :description:
;    This routine takes an array of stx_sim_source_structure and splits
;    every source structure into structures with smaller durations if
;    source.duration * source.flux execeds the max_photon criterion.
;    The routine will take care of setting the start times properly
;
; :categories:
;    simulation, source, utility
;
; :keywords:
;    sources : in, required, type='array of stx_sim_source_structure'
;      one or many source structures to be analyzed for a max photon criterion and split if necessary
;    max_photons : in, optional, type='long', default=10L^7
;      the number of maximum photons (split criterion)
;
; :returns:
;    an array of stx_sim_source_structure with every entry (source structure) complying with the max_photon
;    requirement.
;
; :examples:
;    sources = stx_sim_split_sources(sources=stx_sim_source_structure())
;
; :history:
;    04-Aug-2014 - Laszlo I. Etesi (FHNW), initial release
;    28-Oct-2014 - Laszlo I. Etesi (FHNW), adjusted input flux with
;                  number of detectors and pixel size
;    03-Dec-2014 - Shaun Bloomfield (TCD), added support for 32-element
;                  array of detector background multiplication factors
;                  to simulate over and under noisy detectors. Element
;                  values scale detector areas into effective areas,
;                  with values of 0 indicating that detector will not
;                  be treated. CURRENTLY NOT SWITCHED ON FOR PHOTON
;                  SOURCES (i.e., always assumes that we will simulate
;                  source photons in all subcollimators)
;    04-Dec-2014 - Shaun Bloomfield (TCD), DRM now used to determine
;                  photon-spectrum-weighted efficiency factor. This
;                  calculates correct numbers of counts to draw based
;                  on source flux and spectral form and passes array
;                  of these factors on to save being recalculated in
;                  stx_sim_multisource_sourcestruct2photon.pro
;    05-Dec-2014 - Shaun Bloomfield (TCD), modified to use background
;                  effective area multiplier array from the background
;                  source structure
;    04-Mar-2015 - Laszlo I. Etesi (FHNW), bugfixing: integer division problem (estimated splits)
;                                          caused a negative duration
;    15-May-2015 - ECMD (Graz), if time distribution is not 'uniform' splits
;                  into n sub-sources each with 1/n flux, each one over the
;                  same time ranges as the original source
;    08-Feb-2017   Shane Maloney (TCD) Added thermal soucrce option and updated source parameters
;                  they are in order
;
; :todo:
;    4-Aug-2014 - Laszlo I. Etesi (FHNW), splitting is assuming uniform time distribution
;-
function stx_sim_split_sources, sources=sources, max_photons=max_photons, $
  subc_str=subc_str, all_drm_factors=all_drm_factors, $
  drm0=drm0, drm1=drm1, background=background

  default, max_photons, 10L^7
  default, subc_str, stx_construct_subcollimator()
  background = keyword_set(background)

  srcs_split = list()

  ; initialize array for all drm_factor values
  all_drm_factors = [-1.]
  old_func_name = ''
  old_func_param = [ 0., 0. ]
  old_drm_factor = 1.

  for src_idx = 0L, n_elements(sources)-1 do begin
    ; extract current source
    src_curr = sources[src_idx]

    if (background) then begin
      ; if background counts
      ;  i) flux defined as counts/cm^2/s in the detector itself, no
      ;     need to modify by spacecraft distance in AU (i.e., use 1)
      ; ii) detector areas converted into effective area by applying
      ;     background flux multipliers and summing
      distance = 1.
      eff_area = total( subc_str.det.area * src_curr.background_multiplier )
      drm_factor = 1.
    endif else begin
      ; if source photons
      ;  i) flux is defined as photons/cm^2/s at 1 AU, so needs to be
      ;     modified by square of the spacecraft distance from Sun
      ; ii) sum active detector areas (detectors with bkg_mult_mask
      ;     values of 0 are not simulated)
      distance = src_curr.distance
      eff_area = total( subc_str.det.area )
      ; set photon spectrum type and parameters
      case strlowcase(src_curr.energy_spectrum_type) of
        'powerlaw': begin
          func_name  = 'f_pow'
          func_param = [src_curr.energy_spectrum_param1, src_curr.energy_spectrum_param2 ]
        end
        'thermal': begin
          func_name = 'f_vth'
          func_param = [src_curr.energy_spectrum_param1, src_curr.energy_spectrum_param2 ]
        end
        'uniform': begin
          func_name = 'stx_uniform_dstn'
          func_param = [src_curr.energy_spectrum_param1, src_curr.energy_spectrum_param2 ]
        end
        else: begin
          print, 'Unknown type of source energy spectrum - defaulting to power-law with index of 5.0'
          func_name  = 'f_pow'
          func_param = [ 1., 5. ]
        end
      endcase
      ; only deal with DRM on first run or a change in source energy
      ; spectrum type/parameters
      if (func_name ne old_func_name) or $
        (func_param[0] ne old_func_param[0]) or $
        (func_param[1] ne old_func_param[1]) then begin
        ; create DRM for no attenuator from source parameterized energy
        ; spectrum and pull out the resulting photon spectrum
        stx_random_sample_count_spectrum, 1, e_atten0=e0, drm0=drm0, $
          func_name=func_name, func_param=func_param, out_photon_spec=ph_spec, ninterp= 500 ;  03-Dec-2018 – ECMD - don't need ninterp to be high when getting factors to estimate flux 
        ; calculate photon-spectrum-weighted DRM efficiency factor
        drm_factor = total( ph_spec*drm0.efficiency ) / total( ph_spec )
        ; if no spectral change, duplicate last DRM efficiency factor
      endif else drm_factor = old_drm_factor
      ; update last known parameters for comparison with next source
      old_func_name  = func_name
      old_func_param = func_param
      old_drm_factor = drm_factor
    endelse

    ; estimate number of counts to simulate from time, photon/count
    ; flux [#/cm^2/s], DRM efficiency factor (<1 if source photons,
    ; =1 if background) and active detector effective areas
    ct_estim = ceil( src_curr.duration * $
      (src_curr.flux/(distance^2.)) * $
      drm_factor * $
      eff_area, /L64  )

    ; test if split necessary
    if(ct_estim gt max_photons) then begin
      ; estimate number of splits
      splts_estim = double(floor(ct_estim / double(max_photons)))

      ; replicate splits
      splt_srcs = replicate(src_curr, splts_estim)

      if src_curr.time_distribution eq 'uniform' then begin
        ; calculate durations
        splt_duration = src_curr.duration / splts_estim

        ; update durations, NB: duration of last source fixed to full duration
        splt_srcs.duration = splt_duration

        ; updating relative time
        cumul_durations = [0, total(splt_srcs.duration, /cumulative, /double)]
        splt_srcs.start_time += cumul_durations[0:n_elements(cumul_durations)-2]
      endif else begin

        ; calculate reduced fluxes for slit sources
        splt_flux = round( float(splt_srcs.flux) / float(splts_estim))
        ; update fluxes for all split sources
        splt_srcs.flux = splt_flux

      endelse
      for splt_src_idx = 0L, n_elements(splt_srcs)-1 do srcs_split.add, splt_srcs[splt_src_idx]
      all_drm_factors = [ all_drm_factors, replicate( drm_factor, n_elements(splt_srcs) ) ]
    endif else begin
      srcs_split.add, src_curr ; add original source to list if no splitting is necessary
      all_drm_factors = [ all_drm_factors, drm_factor ]
    endelse
  endfor

  ; trim out initialized value
  if ( n_elements(all_drm_factors) gt 1 ) then all_drm_factors = all_drm_factors[1:*]

  ; return split sources
  return, srcs_split.toarray()
end