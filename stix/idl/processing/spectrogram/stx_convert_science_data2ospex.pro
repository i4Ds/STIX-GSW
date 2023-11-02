;---------------------------------------------------------------------------
;+
; :project:
;       STIX
;
; :name:
;       stx_convert_science_data2ospex
;
; :description:
;    This procedure takes a science data formatted as a stx_fsw_sd_spectrogram structure calculates the
;    livetime corrected values and optionally subtracts a background observation from a supplied background file.
;    This data is then passed to an OSPEX object.
;
; :categories:
;    spectroscopy
;
; :keywords:
;
;    spectrogram : in, type="stx_fsw_sd_spectrogram", default="1.0"
;               the spectrogram structure containing the data
;
;    specpar : in, type="float",
;               spectrum control and information parameters for OSPEX
;
;    time_shift : in, type="float", 
;               Applied light travel time correction
;
;    data_level : in, type="int", default="1.0"
;               The science data x-ray compaction level used to create the spectrogram
;
;    data_dims : in, type="float", default="1.0"
;               The dimensions of the spectrogram count data
;
;    fits_path_bk : in, optional, type="string"
;              The path to file containing the background observation this should be in pixel data format i.e. sci-xray-cpd (or sci-xray-l1)
;
;    distance : in, optional, type="float", default taken from FITS header
;               The distance between Solar Orbiter and the Sun centre in Astronomical Units needed to correct flux.
;
;    flare_location_hpc : in, type=" 2 element float array", 
;               the location of the flare (X,Y) in Helioprojective Cartesian coordinates as seen from Solar Orbiter [arcsec]
;               If no location is passed in the on-axis approximation is used to calculate the grid response. In this case 
;               a value [Nan, Nan] is passed to the output files.
;
;    aux_fits_file : in, required if flare_location_hpc is passed in, type="string"
;                the path of the auxiliary ephemeris FITS file to be read."
;                
;    eff_ewidth : in, type="float arr"
;               an output float value
;
;    sys_uncert : in, type="float", default="0.05"
;                 The fractional systematic uncertanty to be added

;    fits_info_params : in, type="structure"
;                       Structure of information parameters to be written out to the spectrum and srm FITS files
;
;    background_data : out, type="stx_background_data structure"
;                     Structure containing the subtracted background for external plotting.
;
;    plot : in, type="boolean", default="1"
;           If set open OSPEX GUI and plot lightcurve in standard quicklook energy bands where there is data present
;
;    generate_fits : in, type="boolean", default="1"
;                    If set spectrum and srm FITS files will be generated and read using the stx_read_sp using the
;                    SPEX_ANY_SPECFILE strategy. Otherwise use the spex_user_data strategy to pass in the data
;                    directly to the ospex object.
;
;    ospex_obj : out, type="OSPEX object",
;                the output OSPEX object containing the data
;
;
; :history:
;    18-Jun-2021 - ECMD (Graz), initial release
;    22-Feb-2022 - ECMD (Graz), documented, improved error calculation
;    04-Jul-2022 - ECMD (Graz), added plot keyword
;    29-Jul-2022 - ECMD (Graz), by default use distance from header
;                               don't open the OSPEX GUI unless plot keyword is set
;    08-Aug-2022 - ECMD (Graz), can now pass in file names for the output spectrum and srm FITS files
;                               default file name is based on unique request ID
;                               added keyword to allow the user to specify the systematic uncertainty
;                               pass through structure of info parameters to write in FITS file
;    16-Aug-2022 - ECMD (Graz), pass out background data structure for plotting
;    16-Jun-2023 - ECMD (Graz), for a source location dependent response estimate, the location in HPC and the auxiliary ephemeris file must be provided.
;
;-
pro stx_convert_science_data2ospex, spectrogram = spectrogram, specpar = specpar, time_shift = time_shift, data_level = data_level, data_dims = data_dims,  fits_path_bk = fits_path_bk,$
  distance = distance, fits_path_data = fits_path_data, fits_info_params = fits_info_params, aux_fits_file = aux_fits_file, flare_location_hpc = flare_location_hpc, flare_location_stx = flare_location_stx, $
   eff_ewidth = eff_ewidth, sys_uncert = sys_uncert, xspec = xspec, background_data = background_data, plot = plot, generate_fits = generate_fits, pickfile = pickfile, ospex_obj = ospex_obj

  default, plot, 0

    time_range = atime(stx_time2any([spectrogram.time_axis.time_start[0], spectrogram.time_axis.time_end[-1]]))
    
    if n_elements(flare_location_hpc) eq 2 and n_elements(aux_fits_file) eq 0 then aux_fits_file =  stx_get_ephemeris_file( time_range[0], time_range[1])

    
    if n_elements(flare_location_stx) eq 0 then flare_location_stx = stx_location4spectroscopy( flare_location_hpc = flare_location_hpc, aux_fits_file = aux_fits_file, time_range = time_range)
    specpar.flare_xyoffset = flare_location_stx

  ;if distance is not set use the average value from the fits header
  stx_get_header_corrections, fits_path_data, distance = header_distance
  default, distance, header_distance
  print, 'Using Solar Orbiter distance of : ' + strtrim(distance,2) +  ' AU'

  dist_factor = 1./(distance^2.)

  n_energies = data_dims[0]
  n_detectors = data_dims[1]
  n_pixels = data_dims[2]
  n_times = data_dims[3]

  counts_spec  = spectrogram.counts
  livetime_frac =  stx_spectrogram_livetime( spectrogram, corrected_counts = corrected_counts, corrected_error = corrected_error, level = data_level )

  corrected_counts = total(reform(corrected_counts, [n_energies, n_detectors, n_times ]),2)

  counts_spec = total(reform(counts_spec,[n_energies, n_detectors, n_times ]),2)

  corrected_error = sqrt(total(reform(corrected_error, [n_energies, n_detectors, n_times ])^2.,2))


  if keyword_set(fits_path_bk) then begin

    stx_read_pixel_data_fits_file, fits_path_bk,time_shift, data_str = data_str_bk, control_str = control_str_bk, $
      energy_str = energy_str_bk, t_axis = t_axis_bk, e_axis = e_axis_bk, use_discriminators = 0, shift_duration = 0
    bk_data_level = 1

    counts_in_bk = data_str_bk.counts

    dim_counts_bk = counts_in_bk.dim

    ntimes_bk = n_elements(dim_counts_bk) gt 3 ? dim_counts_bk[3] : 1
    pixels_used = where(spectrogram.pixel_mask eq 1)
    detectors_used = where(spectrogram.detector_mask eq 1)
    n_pixels_bk = n_elements(pixels_used)
    n_detectors_bk = n_elements(detectors_used)

    spec_in_bk = total(reform(data_str_bk.counts[*,pixels_used,detectors_used,*], dim_counts_bk[0], n_pixels_bk, n_detectors_bk, ntimes_bk  ),2)
    spec_in_bk = reform(spec_in_bk, dim_counts_bk[0],n_detectors_bk, ntimes_bk)

    error_in_bk = sqrt(total(reform(data_str_bk.counts_err[*,pixels_used,detectors_used,*], dim_counts_bk[0], n_pixels_bk, n_detectors_bk, ntimes_bk  )^2.,2))
    error_in_bk = reform(error_in_bk, dim_counts_bk[0],n_detectors_bk, ntimes_bk)


    spectrogram_bk = { $
      type          : "stx_fsw_sd_spectrogram", $
      counts        : spec_in_bk, $
      trigger       : transpose(data_str_bk.triggers), $
      trigger_err   : transpose(data_str_bk.triggers_err), $
      time_axis     : t_axis_bk , $
      energy_axis   : e_axis_bk, $
      pixel_mask    : spectrogram.pixel_mask , $
      detector_mask : spectrogram.detector_mask, $
      error         : error_in_bk}

    livetime_frac_bk =  stx_spectrogram_livetime(  spectrogram_bk, corrected_counts = corrected_counts_bk,  corrected_error = corrected_error_bk, level = bk_data_level )

    corrected_counts_bk = total(reform(corrected_counts_bk,[dim_counts_bk[0], n_detectors_bk, ntimes_bk ]),2)

    corrected_counts_bk = (total(reform(corrected_counts_bk, dim_counts_bk[0], ntimes_bk),2)/total(data_str_bk.timedel))#(spectrogram.time_axis.duration)

    corrected_counts_bk  = reform(corrected_counts_bk,dim_counts_bk[0], n_times)

    energy_bins = spectrogram.energy_axis.low_fsw_idx

    corrected_counts_bk =  corrected_counts_bk[energy_bins,*] * reproduce(eff_ewidth, n_times)

    corrected_counts_bk =  reform(corrected_counts_bk,[n_elements(energy_bins), n_times])


    spec_in_bk = total(reform(spec_in_bk,[dim_counts_bk[0], n_detectors_bk, ntimes_bk ]),2)

    spec_in_bk = (total(reform(spec_in_bk, dim_counts_bk[0], ntimes_bk),2)/total(data_str_bk.timedel))#(spectrogram.time_axis.duration)

    spec_in_bk  = reform(spec_in_bk,dim_counts_bk[0], n_times)

    spec_in_bk =  spec_in_bk[energy_bins,*] * reproduce(eff_ewidth, n_times)

    spec_in_bk =  reform(spec_in_bk,[n_elements(energy_bins), n_times])


    error_bk = sqrt(total(reform(corrected_error_bk,[dim_counts_bk[0], n_detectors_bk, ntimes_bk ])^2.,2))

    error_bk = (sqrt(total(reform(error_bk, dim_counts_bk[0], ntimes_bk)^2.,2))/total(data_str_bk.timedel))#(spectrogram.time_axis.duration)

    error_bk  = reform(error_bk, dim_counts_bk[0], n_times)

    error_bk =  error_bk[energy_bins,*] * reproduce(eff_ewidth, n_times)

    error_bk =  reform(error_bk,[n_elements(energy_bins), n_times])


    spec_in_corr = corrected_counts - corrected_counts_bk

    spec_in_uncorr = counts_spec - spec_in_bk

    total_error = sqrt(corrected_error^2. + error_bk^2. )

    background_data = { $
      type          : "stx_background_data", $
      counts        : corrected_counts_bk, $
      error         : error_bk}

  endif else begin

    spec_in_corr = corrected_counts

    spec_in_uncorr = counts_spec

    total_error = corrected_error

    background_data = { $
      type          : "stx_background_data", $
      counts        : 0L*corrected_counts, $
      error         : 0L*corrected_error}

  endelse


  eff_livetime_fraction = f_div(total(counts_spec,1) , total(corrected_counts,1) , default = 1 )
  ; 22-Jul-2022 - ECMD, changed from mean to total for more consistent estimate
  eff_livetime_fraction_expanded = transpose(rebin([eff_livetime_fraction],n_elements(eff_livetime_fraction),n_energies))
  spec_in_corr *= eff_livetime_fraction_expanded
  total_error *= eff_livetime_fraction_expanded

  e_axis = spectrogram.energy_axis
  emin = 1
  emax = 150
  ; 10-Jun-2022 ECMD issue which removed highest energy bin
  new_edges = where( spectrogram.energy_axis.edges_1 gt emin and  spectrogram.energy_axis.edges_1 le emax, n_energy_edges)
  e_axis_new = stx_construct_energy_axis(energy_edges = e_axis.edges_1, select = new_edges)

  new_energies = where_arr(fix(10*e_axis.mean),fix(10*e_axis_new.mean))

  spec_in_corr = spec_in_corr[new_energies,*]
  total_error = total_error[new_energies,*]
  n_energies = n_energy_edges-1

  ;insert the information from the telemetry file into the expected stx_fsw_sd_spectrogram structure
  spectrogram = { $
    type          : "stx_fsw_sd_spectrogram", $
    counts        : spec_in_corr, $
    trigger       : transpose(spectrogram.trigger), $
    time_axis     : spectrogram.time_axis , $
    energy_axis   : e_axis_new, $
    pixel_mask    : spectrogram.pixel_mask , $
    detector_mask : spectrogram.detector_mask, $
    rcr           : spectrogram.rcr,$
    error         : total_error}

  uid = fits_info_params.uid


  fstart_time = time2fid(atime(stx_time2any((spectrogram.time_axis.time_start)[0])),/full,/time)

  default, specfilename, 'stx_spectrum_' + strtrim(uid,2) + '.fits'
  default, srmfilename,  'stx_srm_'      + strtrim(uid,2) + '.fits'


  if keyword_set(pickfile) then begin
    specfilename = dialog_pickfile(file = specfilename, path=curdir(), filter='*.fits', $
      title = 'Select output file name')
    srmfilename = dialog_pickfile(file = srmfilename, path=curdir(), filter='*.fits', $
      title = 'Select output file name')
  endif

  fits_info_params.distance = distance
  ;15-Feb-2023 - ECMD, fix for file name issue suggested by William Setterberg
  cur_spec_fn = fits_info_params.specfile
  cur_srm_fn = fits_info_params.srmfile
  fits_info_params.specfile = (cur_spec_fn eq '') ? specfilename : cur_spec_fn
  fits_info_params.srmfile = (cur_srm_fn eq '') ? srmfilename : cur_srm_fn

  transmission = read_csv(loc_file( 'stix_trans_by_component.csv', path = getenv('STX_GRID')))

  phe = transmission.field9
  phe = phe[where(phe gt emin-1 and phe lt 2*emax)]
  edge_products, phe, mean = mean_phe, width = w_phe
  ph_in = [mean_phe[0] - w_phe[0], mean_phe]

  ospex_obj = stx_fsw_sd_spectrogram2ospex( spectrogram, specpar = specpar, time_shift= time_shift, ph_energy_edges = ph_in, $
    /include_damage, generate_fits = generate_fits, xspec = xspec, /tail, livetime_fraction = eff_livetime_fraction, $
    dist_factor = dist_factor, flare_location_stx = flare_location_stx, sys_uncert = sys_uncert, fits_info_params = fits_info_params, background_data = background_data)

  if keyword_set(plot) then begin
    ospex_obj ->gui
    ospex_obj ->set, spex_eband = get_edges([4.,10.,15.,25, 50, 84.], /edges_2)
    ospex_obj ->plot_time,  spex_units='flux', /show_err, obj = plotman_object
  endif

end