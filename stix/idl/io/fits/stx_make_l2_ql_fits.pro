;+
; :project:
;       STIX
;
; :name:
;       stx_make_l2_header
;
; :purpose:
;       Creates l2 primary fits header
;
; :categories:
;       telemetry, fits, io
;
; :keyword:
;       header : in (opt), type="str"
;           Optional the header to add to
;
;       filename : in, type="str"
;           File name the fits file will be written to
;
;       obt_beg : in, type="double"
;           Start OBT time of data in TM
;
;       obt_end : in, type="double"
;           Start OBT time of data in TM
;
;       integration_time : in, type="int"
;           Integration time for data in TM [0.1s]
;
; :returns:
;       Fits header data as string array
;
; :examples:
;       stx_make_l2_header(header=primary_header, filename=filename, date_obs=date_obs, $
;       integration_time=integration_time, history='test')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;       14-Apr-2020 – ECMD (Graz), updated based on significant changes to fits formats
;
;-
function stx_make_l2_header, header = header, filename=filename, $
  history=history, version= version

  currtime = anytim(!stime, /ccsds)

  ;ToDo: OBT time and date
  sxaddpar, header, 'COMMENT','------------------------------------------------------------------------'
  sxaddpar, header, 'FILENAME',filename,'FITS filename'
  sxaddpar, header, 'DATE',currtime,'FITS file creation date in UTC'
  ;  sxaddpar, header, 'COMMENT','------------------------------------------------------------------------'
  sxaddpar, header, 'LEVEL','L2','Processing level of the data'
  sxaddpar, header, 'VERSION',version,'Version of data product'
  sxaddpar, header, 'CREATOR','mwrfits','FITS creation software'
  sxaddpar, header, 'COMMENT','------------------------------------------------------------------------'
  ;  sxaddpar, header, 'OBS_MODE',obs_mode,'Observation mode'
  ;  sxaddpar, header, 'COMMENT','------------------------------------------------------------------------'
  sxaddpar, header, 'HISTORY',history,'Example of SW and runID that created file'
  return, header
end

;+
; :description:
;    This function saves a property file at given location. The properties... etc.
;
; :categories:
;       fits, io, quicklook, flareflag
;
; :params:
;    thermal_flag : in, required, type="int"
;                   An array with the thermal flag for each time bin
;
;    nonthermal_flag : in, required, type="int"
;                   An array with the nonthermal flag for each time bin
;
;    location_status : in, required, type="int"
;                   An array with the location status flag for each time bin
;
; :returns:
;    strarr with the definition of each flag for each time bin
;
; :examples:
;    result = stx_l2_convert_flag_to_def( thermal_flag, nonthermal_flag, location_status)
;
; :history:
;       14-Apr-2020 – ECMD (Graz), initial release
;
;-
function stx_l2_convert_flag_to_def, thermal_flag, nonthermal_flag, location_status

  Thermal_flare_definition = [ 'No flare detected' , 'Minor event (Threshold ~B1)', 'Small event (Threshold ~C1)', $
    'Moderate event (Threshold ~M1)', 'Major event (Threshold ~X1)' ]

  Nonthermal_flare_definition = ['no significant non-thermal flux', 'weak non-thermal flux detected ( > ~100 photons/s/cm2)' ,$
    'significant non-thermal flux (> ~1000 photons/s/cm2)']

  Location_status_definition = ['No location available','Using previous location estimate', 'New location value']

end

;+
; :description:
;    This function multiplies the counts in all time bins by an energy dependant array of scaling factors
;
; :categories:
;       fits, io, quicklook
;
; :params:
;    counts : in, required, type="int"
;             an array of [N energies (usu 5 ql bins) x M times] counts to be scaled
;
;
;    factors :in required,  type="float"
;             an array of N scaling factors, one for each energy band to be applied for all time bins
;
;
; :returns:
;    counts_out - the counts scaled by the given factor
;
; :examples:
;
;     counts_out = stx_l2_apply_constant_factor( counts, detector_efficiency)
;
; :history:
;       14-Apr-2020 – ECMD (Graz), initial release
;
;-
function stx_l2_apply_constant_factor, counts, factors

  n_times = (size(counts))[2]

  counts_out = counts*((factors)#(fltarr(n_times)+1.))

  return, counts_out
end

;+
; :description:
;    This function converts the number of triggers to livetime fraction a given detector
;
; :categories:
;       fits, io, quicklook
;
; :params:
;    triggers : in, required, type="float"
;               The number of triggers
;
;    duration :in, required
;
;
; :keywords:
;    tau : in, type="float", default="9.6e-6"
;          detector total reset time
;
;    eta : in, type="float", default="1e-5"
;          detector latency time
;
;
; :returns:
;    livetime - the calculated livetime fraction for a detector producing the input number of triggers
;
; :examples:
;      livetime = stx_l2_detector_specific_livetime( triggers ,duration, tau = tau, eta = eta)
;
; :history:
;       14-Apr-2020 – ECMD (Graz), initial release
;
;-
function stx_l2_detector_specific_livetime, triggers, duration, tau = tau, eta = eta

  ; :todo: - detector parameters should be read in from a database not hardcoded here
  default, tau , 9.6e-6
  default, eta ,  1e-5

  nin = triggers/duration /(1. - triggers*tau/duration)
  livetime = exp(-1.*tau*nin)/(1. - nin*tau)

  return, livetime
end

;+
; :description:
;    This function converts the number of triggers to average livetime fraction for an array of detectors
;
; :categories:
;       fits, io, quicklook
;
; :params:
;    triggers : in, required, type="float"
;               The number of triggers for each measurement
;
;    duration :in, required
;              duration in seconds for each time bin
;
;   detector_mask: in, required
;               mask of active detectors which contributed to the trigger measurement
;
; :keywords:
;    tau : in, type="float", default="9.6e-6"
;          detector total reset time
;
;    eta : in, type="float", default="1e-5"
;          detector latency time
;
; :returns:
;    livetime - the calculated average livetime fraction for the array of triggers
;
; :examples:
;      livetime = stx_l2_detector_averaged_livetime( triggers, control_l1.detector_mask, duration, tau = tau, eta = eta)
;
; :history:
;       14-Apr-2020 – ECMD (Graz), initial release
;
;-
function stx_l2_detector_averaged_livetime, triggers, detector_mask, duration, tau = tau, eta = eta

  default, tau , 9.6e-6
  default, eta ,  1e-5

  n_active_detectors = total(detector_mask)
  average_triggers = float(triggers)/n_active_detectors
  livetime = stx_l2_detector_specific_livetime(average_triggers, duration , tau = tau, eta = eta)

  return, livetime
end

;+
; :description:
;    This function calculates the fraction of detectors which were active corresponding to a given mask
;
; :categories:
;       fits, io, quicklook
;
; :params:
;    detector_mask : in, required, type="int"
;             a 32 bit mask of active detectors
;
; :returns:
;   The fraction of active detectors
;
; :examples:
;  fraction_active_detectors =  stx_l2_active_detectors( control_l1.detector_mask)
;
; :history:
;       14-Apr-2020 – ECMD (Graz), initial release
;
;-
function stx_l2_active_detectors, detector_mask

  n_active_detectors = total(detector_mask)
  fraction_active_detectors  = float(n_active_detectors)/32.

  return, fraction_active_detectors
end


;+
; :description:
;    This function calculates the fraction of pixels which were active corresponding to a given mask
;
; :categories:
;       fits, io, quicklook
;
; :params:
;    pixel_mask : in, required, type="int"
;             a 12 bit mask of active pixels
;
; :returns:
;   The fraction of active pixels
;
; :examples:
;  fraction_active_pixels = stx_l2_active_pixels( control_l1.pixel_mask )
;
; :history:
;       14-Apr-2020 – ECMD (Graz), initial release
;
;-
function stx_l2_active_pixels, pixel_mask

  subc = stx_construct_subcollimator()

  large_area =  (subc.det.pixel.area)[0,0]
  small_area =  (subc.det.pixel.area)[8,0]
  detector_area = (subc.det.area)[0,0]


  fraction_active_pixels = (total((pixel_mask)[0:7]*large_area)  +  total((pixel_mask)[8:11]*small_area) )/ detector_area

  return, fraction_active_pixels
end

;+
; :description:
;   This function multiplies the counts in all time bins by an energy dependent array of detector efficiency factors
;
; :categories:
;       fits, io, quicklook
;
; :params:
;    counts : in, required, type="int"
;             an array of [N energies (usu 5 ql bins) x M times] counts to be scaled
;
; :keywords:
;    detector_efficiency : in, type="float", default="[9.21, 1.97, 1.30, 1.31, 1.24]"
;                An array of N energy dependent efficiency factors, one for each energy band
;
; :returns:
;    counts_out the counts in each time bin scaled by the relevant detector efficiency factor
;
; :examples:
;      counts =  stx_l2_correct_detector_efficiency( counts )
;
; :history:
;       14-Apr-2020 – ECMD (Graz), initial release
;
;-
function stx_l2_correct_detector_efficiency, counts, detector_efficiency = detector_efficiency

  ; :todo: - detector efficiency factors should be read in from a database not hardcoded here
  detector_efficiency = [9.21, 1.97, 1.30, 1.31, 1.24]

  counts_out = stx_l2_apply_constant_factor( counts, detector_efficiency)

  return,counts_out
end


;+
; :description:
;   This function multiplies the counts in all time bins by an energy dependent array of window transmission factors
;
; :categories:
;       fits, io, quicklook
;
; :params:
;    counts : in, required, type="int"
;             an array of [N energies (usu 5 ql bins) x M times] counts to be scaled
;
; :keywords:
;    detector_efficiency : in, type="float", default="[12.80, 2.06, 1.29, 1.15, 1.10]"
;                An array of N energy dependent transmission factors, one for each energy band
;
; :returns:
;    counts_out the counts in each time bin scaled by the relevant window transmission factor
;
; :examples:
;      counts = stx_l2_correct_window_transmission( counts)
;
; :history:
;       14-Apr-2020 – ECMD (Graz), initial release
;
;-
function stx_l2_correct_window_transmission, counts, window_transmission = window_transmission


  ; :todo: - transmissions factors should be read in from a database not hardcoded here
  window_transmission = [12.80, 2.06, 1.29, 1.15, 1.10]

  counts_out = stx_l2_apply_constant_factor( counts, window_transmission)

  return,counts_out
end



;+
; :description:
;   This function multiplies the counts in all time bins by an energy dependent array of attenuator transmission factors
;
; :categories:
;       fits, io, quicklook
;
; :params:
;    counts : in, required, type="int"
;             an array of [N energies (usu 5 ql bins) x M times] counts to be scaled
;
;    rcr :    in, required, type="int"
;             an array of giving the rate control regime for each of the M time bins
;
; :keywords:
;    detector_efficiency : in, type="float", default="[1.72e+07, 7.39e+02, 9.07e+00, 1.70e+00, 1.06e+00]"
;                An array of N energy dependent transmission factors, one for each energy band
;
; :returns:
;    counts_out the counts in each time bin scaled by the relevant attenuator transmission factor
;
; :examples:
;     counts =  stx_l2_correct_attenuator_transmission( counts, rcr)
;
; :history:
;       14-Apr-2020 – ECMD (Graz), initial release
;
;-
function stx_l2_correct_attenuator_transmission, counts, rcr, attenuator_transmission = attenuator_transmission

  ; :todo: - transmissions factors should be read in from a database not hardcoded here
  attenuator_transmission = [1.72e+07, 7.39e+02, 9.07e+00, 1.70e+00, 1.06e+00]
  att_in = where( rcr  ge 1, count_att_in)

  if count_att_in gt 0 then (counts)[att_in]  =  (counts)[att_in] * (attenuator_transmission#(fltarr(count_att_in)+1))

  return,counts
end


;+
; :description:
;   This function multiplies the counts in all time bins by an energy dependent array of window transmission factors
;
; :categories:
;       fits, io, quicklook
;
; :params:
;    counts : in, required, type="int"
;             an array of [N energies (usu 5 ql bins) x M times] counts to be scaled
;
; :keywords:
;    detector_efficiency : in, type="float", default="[12.80, 2.06, 1.29, 1.15, 1.10]"
;                An array of N energy dependent transmission factors, one for each energy band
;
; :returns:
;    counts_out the counts in each time bin scaled by the relevant window transmission factor
;
; :examples:
;      counts = stx_l2_correct_window_transmission( counts)
;
; :history:
;       14-Apr-2020 – ECMD (Graz), initial release
;
;-
function stx_l2_correct_grid_transmission, counts, grid_transmission = grid_transmission

  ; :todo: - transmissions factors should be read in from a database not hardcoded here
  grid_transmission =  [4.00, 4.00, 4.00, 4.00, 3.73]

  counts_out = stx_l2_apply_constant_factor( counts, grid_transmission)

  return,counts_out
end

;+
; :description:
;   This function multiplies the counts in all time bins by an energy dependent array of window transmission factors
;
; :categories:
;       fits, io, quicklook
;
; :params:
;    counts : in, required, type="int"
;             an array of [N energies (usu 5 ql bins) x M times] counts to be scaled
;
; :keywords:
;    detector_efficiency : in, type="float", default="[12.80, 2.06, 1.29, 1.15, 1.10]"
;                An array of N energy dependent transmission factors, one for each energy band
;
; :returns:
;    counts_out the counts in each time bin scaled by the relevant window transmission factor
;
; :examples:
;      counts = stx_l2_correct_window_transmission( counts)
;
; :history:
;       14-Apr-2020 – ECMD (Graz), initial release
;
;-
function stx_l2_correct_bkg_grid_transmission, counts, bkg_grid_transmission = bkg_grid_transmission

  ; :todo: - transmissions factors should be read in from a database not hardcoded here
  bkg_grid_transmission = [36.82, 36.82, 36.82, 36.82, 19.85]

  counts_out = stx_l2_apply_constant_factor( counts, bkg_grid_transmission)

  return,counts_out
end

;+
; :description:
;    This function cellulates the time stamp string in the appropriate format for the fits files
;    This is an exact duplicate of the time_stamp function in stx_make_l1_ql_fits I am leaving it intact in this script as
;    it is uncertain if the IDL l1 fits scripts will remain as l1 processing is currently performed in python
;
;-
function time_stamp, time
  default, time, !stime
  time = anytim(time, /ccsds)
  tstamp = strmid(time, 0, 4)+strmid(time, 5, 2)+strmid(time, 8, 5)+strmid(time, 14, 2)+strmid(time, 17, 2)
  return, tstamp
end


;+
; :project:
;       STIX
;
; :name:
;       stx_make_l2_ql_lightcurve_fits
;
; :purpose:
;       Takes l1 quick look lightcurve adds physical axes and writes to a l2 fits file.
;
; :categories:
;       telemetry, fits, io
;
; :params:
;       tm_reader : in, type="stx_telemetry_reader"
;           STIX Telemetry reader object
;
; :returns:
;
;
; :examples:
;       stx_make_l2_ql_lightcurve_fits(l2fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;       14-Apr-2020 – ECMD (Graz), updated based on significant changes to fits formats
;
;-
function stx_make_l2_ql_lightcurve_fits, fits_path, l2_directory
  !null = mrdfits(fits_path, 0, primary_header)
  rate_l1 = mrdfits(fits_path, 1, rate_header)
  energy_l1 = mrdfits(fits_path, 2, energy_header)
  control_l1 = mrdfits(fits_path, 3, control_header)
  version = 1


  sxaddpar, data_header, 'TUNIT1', 'Normalized counts/cm2/second', 'Unit for COUNTS', after = 'TFIELDS'
  sxaddpar, data_header, 'TUNIT2', '', 'Unit for CHANNEL', after = 'TUNIT1'
  sxaddpar, data_header, 'TUNIT3', 's', 'Unit for RELATIVE_TIME', after = 'TUNIT2'
  sxaddpar, energy_header, 'TUNIT1', '', after = 'TFIELDS'
  sxaddpar, energy_header, 'TUNIT2', 'keV', after = 'TUNIT1'
  sxaddpar, energy_header, 'TUNIT3', ' keV', after = 'TUNIT2'


  n_times = n_elements(rate_l1)
  n_energies = n_elements(energy_l1)

  relative_times = findgen(n_elements(rate_l1)) * control_l1.INTEGRATION_TIME
  obt_beg = float(sxpar(primary_header, 'OBT_BEG'))

  structures = stx_l2_ql_lightcurve_structures(n_energies,n_times)

  control_l2 = structures('control')
  control_l2.integration_time = control_l1.integration_time
  control_l2.detector_mask = control_l1.detector_mask
  control_l2.pixel_mask = control_l1.pixel_mask
  control_l2.energy_bin_mask = control_l1.energy_bin_mask
  control_l2.compression_scheme_counts = control_l1.compression_scheme_counts_skm
  control_l2.compression_scheme_triggers = control_l1.compression_scheme_triggers_skm

  energy_L2 = energy_l1

  rate_l2 = structures('count')

  counts = rate_l1.counts
  rcr = rate_l1.rate_control_regime
  triggers = rate_l1.triggers
  duration = control_l1.INTEGRATION_TIME
  livetime = stx_l2_detector_averaged_livetime( triggers,control_l1.detector_mask ,duration, tau = tau, eta = eta)

  counts =  counts/(livetime##(fltarr(n_energies)+1))

  control_l2.tau = tau
  control_l2.eta = eta

  counts =  stx_l2_correct_detector_efficiency( counts, detector_efficiency = detector_efficiency)

  control_l2.detector_efficiency = detector_efficiency

  counts =  stx_l2_correct_window_transmission( counts, window_transmission = window_transmission)

  control_l2.window_transmission = window_transmission

  counts =  stx_l2_correct_attenuator_transmission( counts, rcr, attenuator_transmission = attenuator_transmission)

  control_l2.attenuator_transmission = attenuator_transmission

  counts =  stx_l2_correct_grid_transmission( counts, grid_transmission = grid_transmission)
  control_l2.grid_transmission = grid_transmission

  fraction_active_detectors =  stx_l2_active_detectors( control_l1.detector_mask)

  fraction_active_pixels = stx_l2_active_pixels( control_l1.pixel_mask,detector_area=detector_area )

  effective_area = detector_area*fraction_active_pixels*fraction_active_detectors
  counts /= effective_area


  rate_l2.COUNTS = counts

  rate_l2.TIMEDEL = replicate(control_l1.INTEGRATION_TIME, n_times)
  rate_l2.TRIGGERS = rate_l1.TRIGGERS



  rate_l2.rate_control_regeime = rcr
  rate_l2.TIME = relative_times + obt_beg
  rate_l2.livetime = livetime
  rate_l2.error = COUNTS^0.5


  filename = 'solo_L2_stix-ql-light-curves_'+trim(time_stamp(obt_beg))+'_V'+trim(version)+'.fits'

  fullpath = concat_dir(l2_directory, filename)

  date_obs = anytim(obt_beg, /ccsds)

  primary_header = stx_make_l2_header(header=primary_header, filename=filename, $
    history='Processed by STIX IDL GSW', version = version)

  mwrfits, !NULL, fullpath, primary_header, /create, status=stat0
  mwrfits, rate_l2, fullpath, status=stat1
  mwrfits, energy_l2, fullpath, status=stat2
  mwrfits, control_l2, fullpath, status=stat3

  fxhmodify, fullpath, 'EXTNAME', 'RATE', EXTENSION=1
  fxhmodify, fullpath, 'EXTNAME', 'ENEBAND', EXTENSION=2
  fxhmodify, fullpath, 'EXTNAME', 'CONTROL', EXTENSION=3

end

;+
; :project:
;       STIX
;
; :name:
;       stx_make_l2_ql_background_fits
;
; :purpose:
;       Takes l1 quick look background adds physical axes and writes to a l2 fits file.
;
; :categories:
;       telemetry, fits, io
;
; :params:
;       tm_reader : in, type="stx_telemetry_reader"
;           STIX Telemetry reader object
;
; :returns:
;
;
; :examples:
;       stx_make_l2_ql_background_fits(l2fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;       14-Apr-2020 – ECMD (Graz), updated based on significant changes to fits formats
;
;-
function stx_make_l2_ql_background_fits, fits_path, l2_directory
  version = 1


  !null = mrdfits(fits_path, 0, primary_header)
  rate_l1 = mrdfits(fits_path, 1, rate_header)
  energies_l1 = mrdfits(fits_path, 2, energy_header)
  control_l1= mrdfits(fits_path, 3, control_header)

  n_times = n_elements(rate_l1)
  n_energies = n_elements(energies_l1)
  relative_times = findgen(n_elements(rate_l1)) * control_l1.integration_time


  structures = stx_l2_ql_background_structures(n_energies,n_times)


  control_l2 = structures('control')
  control_l2.integration_time = control_l1.integration_time
  control_l2.energy_bin_mask = control_l1.energy_bin_mask
  control_l2.compression_scheme_background_skm = control_l1.compression_scheme_background_skm
  control_l2.compression_scheme_triggers_skm = control_l1.compression_scheme_triggers_skm


  ; Low

  counts = rate_l1.counts
  triggers = rate_l1.triggers
  duration = control_l1.INTEGRATION_TIME

  fraction_active_pixels = stx_l2_active_pixels( [1,1,1,1,1,1,1,1,0,0,0,0], detector_area=detector_area )

  effective_area = detector_area*fraction_active_pixels
  counts /= effective_area

  livetime = stx_l2_detector_specific_livetime( triggers ,duration, tau = tau, eta = eta)

  counts =  counts/(livetime##(fltarr(n_energies)+1))

  control_l2.tau = tau
  control_l2.eta = eta

  counts =  stx_l2_correct_detector_efficiency( counts, detector_efficiency = detector_efficiency)

  control_l2.detector_efficiency = detector_efficiency

  low_flux_rate_l2 = structures('low_flux_rate')
  low_flux_rate_l2.background = counts
  low_flux_rate_l2.TRIGGERS = rate_l1.TRIGGERS
  low_flux_rate_l2.TIME = relative_times
  low_flux_rate_l2.ERROR = rate_l1.COUNTS^0.5

  ; High

  counts  = stx_l2_correct_window_transmission( counts, window_transmission = window_transmission)
  control_l2.window_transmission =window_transmission

  counts = stx_l2_correct_bkg_grid_transmission( counts, bkg_grid_transmission = bkg_grid_transmission)
  control_l2.bkg_grid_transmission = bkg_grid_transmission

  high_flux_rate_l2 = structures('high_flux_rate')
  high_flux_rate_l2.background = counts

  high_flux_rate_l2.TRIGGERS = rate_l1.TRIGGERS
  high_flux_rate_l2.TIME = relative_times
  high_flux_rate_l2.ERROR = rate_l1.COUNTS^0.5

  obt_beg = float(sxpar(primary_header, 'OBT_BEG'))

  filename = 'solo_l2_stix-background_'+trim(time_stamp(obt_beg))+'_V'+trim(version)+'.fits'

  fullpath = concat_dir(l2_directory, filename)

  primary_header = stx_make_l2_header(header=primary_header, filename=filename, $
    history='Processed by STIX IDL GSW', version = version)

  mwrfits, !NULL, fullpath, primary_header, /create, status=stat0
  mwrfits, high_flux_rate, fullpath, status=stat1
  mwrfits, low_flux_rate, fullpath, status=stat1
  mwrfits, energy_info, fullpath, status=stat2
  mwrfits, control, fullpath, status=stat3

  fxhmodify, fullpath, 'EXTNAME', 'HFRATE', EXTENSION=1
  fxhmodify, fullpath, 'EXTNAME', 'LFRATE', EXTENSION=2
  fxhmodify, fullpath, 'EXTNAME', 'ENEBAND', EXTENSION=3
  fxhmodify, fullpath, 'EXTNAME', 'CONTROL', EXTENSION=4


end

;+
; :project:
;       STIX
;
; :name:
;       stx_make_l2_ql_variance_fits
;
; :purpose:
;       Takes l1 quick look variance adds physical axes and writes to a l2 fits file.
;
; :categories:
;       telemetry, fits, io
;
; :params:
;       tm_reader : in, type="stx_telemetry_reader"
;           STIX Telemetry reader object
;
; :returns:
;
;
; :examples:
;       stx_make_l2_ql_variance_fits(l2fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;       14-Apr-2020 – ECMD (Graz), updated based on significant changes to fits formats
;
;-
function stx_make_l2_ql_variance_fits, fits_path, l2_directory

  !null = mrdfits(fits_path, 0, primary_header)
  rate_l1 = mrdfits(fits_path, 1, rate_header)
  energy_l1 = mrdfits(fits_path, 2, energy_header)
  control_l1= mrdfits(fits_path, 3, control_header)
  version = 1

  n_times = n_elements(rate_l1)

  obt_beg = float(sxpar(primary_header, 'OBT_BEG'))

  structures = stx_l2_ql_variance_structures(n_times)

  energy_l2 =energy_l1

  control_l2 = structures('control')
  control_l2.integration_time = control_l1.integration_time*0.1
  control_l2.energy_bin_mask = control_l1.energy_bin_mask
  control_l2.detector_mask = control_l1.detector_mask
  control_l2.pixel_mask = control_l1.pixel_mask
  control_l2.compression_scheme_variance_skm = control_l1.compression_scheme_variance_skm
  control_l2.samples_per_variance = control_l1.samples

  relative_times = findgen(n_times) * control_l2.integration_time

  rate_l2 = structures('count')

  variance = double(rate_l1.variance)*16.


  rate_l2.timedel = replicate(control_l1.integration_time, n_times)
  rate_l2.time = relative_times + obt_beg


  filename = 'solo_L2_stix-ql-variance_'+trim(time_stamp(obt_beg))+'_V'+trim(version)+'.fits'

  fullpath = concat_dir(l2_directory, filename)

  date_obs = anytim(obt_beg, /ccsds)

  primary_header = stx_make_l2_header(header=primary_header, filename=filename, $
    history='Processed by STIX IDL GSW', version = version)

  mwrfits, !NULL, fullpath, primary_header, /create, status=stat0
  mwrfits, rate_l2, fullpath, status=stat1
  mwrfits, energy_l2, fullpath, status=stat2
  mwrfits, control_l2, fullpath, status=stat3

  fxhmodify, fullpath, 'EXTNAME', 'RATE', EXTENSION=1
  fxhmodify, fullpath, 'EXTNAME', 'ENEBAND', EXTENSION=2
  fxhmodify, fullpath, 'EXTNAME', 'CONTROL', EXTENSION=3


end


;+
; :project:
;       STIX
;
; :name:
;       stx_make_l2_ql_spectra_fits
;
; :purpose:
;       Takes l1 quick look spectra adds physical axes and writes to a l2 fits file.
;
; :categories:
;       telemetry, fits, io
;
; :params:
;       tm_reader : in, type="stx_telemetry_reader"
;           STIX Telemetry reader object
;
; :returns:
;
;
; :examples:
;       stx_make_l2_ql_spectra_fits(l2fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_make_l2_ql_spectra_fits, fits_path, l2_directory
  !null = mrdfits(fits_path, 0, primary_header)
  data = mrdfits(fits_path, 1, data_header)
  energies = mrdfits(fits_path, 2, energy_header)
  control = mrdfits(fits_path, 3, control_header)

  version = 1

  print, 1

end

;+
; :project:
;       STIX
;
; :name:
;       stx_make_l2_ql_calibration_sepctra_fits
;
; :purpose:
;       Takes l2 quick look calibration spectra adds physical axes and writes to a l2 fits file.
;
; :categories:
;       telemetry, fits, io
;
; :params:
;       tm_reader : in, type="stx_telemetry_reader"
;           STIX Telemetry reader object
;
; :returns:
;
;
; :examples:
;       stx_make_l2_ql_calibration_spectra_fits(l2fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;       14-Apr-2020 – ECMD (Graz), updated based on significant changes to fits formats
;
;-
function stx_make_l2_ql_calibration_spectra_fits, fits_path, l2_directory
  version = 1

  asw_ql_calibration_spectra =  stx_read_calibration_fits_file( fits_path, primary_header = primary_header, rate_str= rate_l1,rate_header = rate_header, control_str= control_l1,control_header= control_header, $
    subspectra_definition = subspectra_definition, pixel_mask= pixel_mask, detector_mask = detector_mask,subspectrum_mask = subspectrum_mask, start_time = start_time, end_time = end_time)

  n_times = n_elements(rate_l1)
  nsubspec = total(subspectrum_mask)
  obt_beg = float(sxpar(primary_header, 'OBT_BEG'))


  structures = stx_l2_ql_calibration_spectra_structures(nsubspec)

  control_l2 = structures('control')
  rate_l2 = structures('data')


  control_l2.pixel_mask = pixel_mask
  control_l2.detector_mask = detector_mask
  control_l2.subspectrum_mask = subspectrum_mask
  control_l2.quiet_time = control_l1.quiet_time*15.2588e-6
  control_l2.live_time = float(control_l1.live_time)/1000.
  control_l2.average_temp = stx_temp_convert(control_l1.average_temp)
  control_l2.subspectra_definition = subspectra_definition
  control_l2.compression_scheme_accum_skm = control_l1.compression_scheme_accum_skm

  rate_l2.timedel = control_l1.duration
  rate_l2.time =  obt_beg
  rate_l2.spectrum = stx_calibration_data_array( asw_ql_calibration_spectra)

  filename = 'solo_L2_stix-calibration-spectrum_'+trim(time_stamp(obt_beg))+'_V'+trim(version)+'.fits'

  fullpath = concat_dir(l2_directory, filename)

  date_obs = anytim(obt_beg, /ccsds)

  primary_header = stx_make_l2_header(header=primary_header, filename=filename, $
    history='Processed by STIX IDL GSW', version = version)

  mwrfits, !NULL, fullpath, primary_header, /create, status=stat0
  mwrfits, rate_l2, fullpath, status=stat1
  mwrfits, control_l2, fullpath, status=stat2

  fxhmodify, fullpath, 'EXTNAME', 'RATE', EXTENSION=1
  fxhmodify, fullpath, 'EXTNAME', 'CONTROL', EXTENSION=2


end

;+
; :project:
;       STIX
;
; :name:
;       stx_make_l2_ql_flareflag_location_fits
;
; :purpose:
;       Takes l2 quick look flare flag and location adds physical axes and writes to a l2 fits file.
;
; :categories:
;       telemetry, fits, io
;
; :params:
;       tm_reader : in, type="stx_telemetry_reader"
;           STIX Telemetry reader object
;
; :returns:
;
;
; :examples:
;       stx_make_l2_ql_flareflag_location_fits(l2fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_make_l2_ql_flareflag_location_fits, fits_path, base_directory
  !null = mrdfits(fits_path, 0, primary_header)
  rate = mrdfits(fits_path, 1, rate_header)
  control = mrdfits(fits_path, 2, control_header)
  version = 1


  stop
  ; TODO Not sure what more can be done as are low level data anyway
  print, 1
end

;+
; :description:
;    This procedure saves a property file at given location. The properties... etc.
;
; :categories:
;       fits, io, quicklook
;
; :params:
;    param1 : in, required, type="string"
;             a required string input
;    param2 :
;
;
; :keywords:
;    keyword1 : in, type="float", default="1.0"
;               an output float value
;    keyword2 :
;
;
; :examples:
;    prosample, 10, 'hello', /verbose
;
; :history:
;       14-Apr-2020 – ECMD (Graz), initial release of stx_make_l2_ql_fits
;                                  - based on stx_make_l1_ql_fits
;-
pro stx_make_l2_ql_fits, base_directory

  default, base_directory, concat_dir(concat_dir(concat_dir(getenv("SSW_STIX"), 'data'), 'l2'), 'quicklook')
  l1_directory = concat_dir(base_directory, 'quicklook')
  l2_directory = concat_dir(base_directory, 'l2_quicklook')

  if ~file_test(l2_directory, /directory) then begin
    file_mkdir, l2_directory
  endif


  quicklook_files = file_search(l1_directory, '*.fits')

  foreach ql_file, quicklook_files do begin
    if STRMATCH(ql_file, '*light-curves*') then begin
      res = stx_make_l2_ql_lightcurve_fits(ql_file, l2_directory)
    endif else if STRMATCH(ql_file, '*background*') then begin
      res = stx_make_l2_ql_background_fits(ql_file, l2_directory)
    endif else if STRMATCH(ql_file, '*variance*') then begin
      res = stx_make_l2_ql_variance_fits(ql_file, l2_directory)
    endif else if STRMATCH(ql_file, '*spectrogram*') then begin
      ; res = stx_make_l2_ql_spectra_fits(ql_file, l2_directory)
    endif else if STRMATCH(ql_file, '*calibration-spectrum*') then begin
      res = stx_make_l2_ql_calibration_spectra_fits(ql_file, l2_directory)
    endif else if STRMATCH(ql_file, '*flareflag*') then begin
      res = stx_make_l2_ql_flareflag_location_fits(ql_file, l2_directory)
    endif
  endforeach


end
