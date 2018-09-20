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
;       stx_make_l1_header(header=primary_header, filename=filename, date_obs=date_obs, $
;       integration_time=integration_time, history='test')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_make_l2_header, header = header, filename=filename, date_obs=date_obs, $
  history=history

  ;  fxhmake, header, /date, /init, /extend, errmsg = errmsg

  currtime = anytim(!stime, /ccsds)

  ;ToDo: OBT time and date
  sxaddpar, header, 'COMMENT','------------------------------------------------------------------------'
  sxaddpar, header, 'FILENAME',filename,'FITS filename'
  sxaddpar, header, 'DATE',currtime,'FITS file creation date in UTC'
  sxaddpar, header, 'DATE-OBS',date_obs,'Start of acquisition time in UT'
  ;  sxaddpar, header, 'OBT-END',trim(string(obt_end)),'End of acquisition time in OBT'
  sxaddpar, header, 'TIMESYS','OBT','System used for time keywords'
  ;  sxaddpar, header, 'COMMENT','------------------------------------------------------------------------'
  sxaddpar, header, 'LEVEL','L1','Processing level of the data'
  sxaddpar, header, 'CREATOR','mwrfits','FITS creation software'
  sxaddpar, header, 'ORIGIN','Solar Orbiter SOC, ESAC','Location where file has been generated'
  sxaddpar, header, 'VERS_SW','2.4','Software version'
  sxaddpar, header, 'VERSION','201810121423','Version of data product'
  ;  sxaddpar, header, 'COMPLETE',complete_flag,'C if data complete, I if incomplete'
  sxaddpar, header, 'COMMENT','------------------------------------------------------------------------'
  sxaddpar, header, 'OBSRVTRY','Solar Orbiter','Satellite name'
  sxaddpar, header, 'TELESCOP','SOLO/STIX','Telescope/Sensor name'
  sxaddpar, header, 'INSTRUME','STIX','Instrument name'
  ;  sxaddpar, header, 'OBS_MODE',obs_mode,'Observation mode'
  ;  sxaddpar, header, 'COMMENT','------------------------------------------------------------------------'
  sxaddpar, header, 'HISTORY',history,'Example of SW and runID that created file'
  return, header
end


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
;       Takes l1 quick look lightcurve adds phyical axes and writes to a l2 fits file.
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
;       stx_make_l2_ql_lightcurve_fits(l1fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_make_l2_ql_lightcurve_fits, fits_path, base_directory
  !null = mrdfits(fits_path, 0, primary_header)
  control = mrdfits(fits_path, 1, control_header)
  data = mrdfits(fits_path, 2, data_header)

  n_times = n_elements(data)
  n_energies = total(control.ENERGY_BIN_MASK)
  relative_times = indgen(n_elements(data)) * control.INTEGRATION_TIME
  
  ; ENERGY_BIN_MASK by definition doesnt contain last closing energy 
  energies = stx_construct_energy_axis(select=[where(control.ENERGY_BIN_MASK eq 1), 32])

  energy_structure = {CHANNEL: 0L, E_MIN: 0.0, E_MAX: 0.0}
  energy_info = REPLICATE(energy_structure, n_energies)
  energy_info.E_MIN = energies.low
  energy_info.E_MAX = energies.high
  energy_info.CHANNEL = lindgen(n_elements(energies.low))
  
  rate_structure = {COUNTS: lonarr(n_energies), TRIGGERS: 0L, RATE_CONTROL_REGEIME: 0b, $
                    CHANNEL: lonarr(n_energies), TIME: 0.0d, TIMEDEL: 0.0, LIVETIME: 1, ERROR: lonarr(n_energies)}
                    
  rate_structure.CHANNEL = lonarr(n_energies)
  rate_structure.TIMEDEL = control.INTEGRATION_TIME
  
  rate_info = REPLICATE(rate_structure, n_times)
  rate_info.COUNTS = data.COUNTS
  rate_info.TRIGGERS = data.TRIGGERS
  rate_info.RATE_CONTROL_REGEIME = data.RATE_CONTROL_REGEIME
  rate_info.TIME = relative_times
  rate_info.ERROR = long(data.counts^0.5)
  
  obt_beg = float(sxpar(primary_header, 'OBT-BEG'))
  
  filename = 'solo_l2_stix-lightcurve_'+trim(time_stamp(obt_beg))+'_V'+trim(tstamp)+'.fits'
  path = concat_dir(base_directory, 'lightcurve')
  if ~FILE_TEST(path, /DIRECTORY) then begin
    file_mkdir, path
  endif
  fullpath = concat_dir(path, filename)
  
  date_obs = anytim(obt_beg, /ccsds)
  
  primary_header = stx_make_l2_header(header=primary_header, filename=filename, date_obs=date_obs, $
    history='test')
  
  mwrfits, !NULL, fullpath, primary_header, /create, status=stat0
  mwrfits, rate_info, fullpath, status=stat1
  mwrfits, energy_info, fullpath, status=stat2
  mwrfits, control, fullpath, control_header, status=stat3
  
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
;       Takes l1 quick look background adds phyical axes and writes to a l2 fits file.
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
;       stx_make_l2_ql_background_fits(l1fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_make_l2_ql_background_fits, fits_path, base_directory
  !null = mrdfits(fits_path, 0, primary_header)
  control = mrdfits(fits_path, 1, control_header)
  data = mrdfits(fits_path, 2, data_header)

  n_times = n_elements(data)
  n_energies = total(control.ENERGY_BIN_MASK)
  relative_times = indgen(n_elements(data)) * control.INTEGRATION_TIME
  
  ; ENERGY_BIN_MASK by definition doesnt contain last closing energy 
  energies = stx_construct_energy_axis(select=[where(control.ENERGY_BIN_MASK eq 1), 32])

  energy_structure = {CHANNEL: 0L, E_MIN: 0.0, E_MAX: 0.0}
  energy_info = REPLICATE(energy_structure, n_energies)
  energy_info.E_MIN = energies.low
  energy_info.E_MAX = energies.high
  energy_info.CHANNEL = lindgen(n_elements(energies.low))

  rate_structure = {BACKGROUND: lonarr(n_energies), TRIGGERS: 0L, CHANNEL: lonarr(n_energies), TIME: 0.0d, $
                    TIMEDEL: 0.0, LIVETIME: 1, ERROR: lonarr(n_energies)}
  rate_structure.CHANNEL = lonarr(n_energies)
  rate_structure.TIMEDEL = control.INTEGRATION_TIME

  rate_info = REPLICATE(rate_structure, n_times)
  rate_info.BACKGROUND = data.BACKGROUND
  rate_info.TRIGGERS = data.TRIGGERS
  rate_info.TIME = relative_times
  rate_info.ERROR = long(data.BACKGROUND^0.5)

  obt_beg = float(sxpar(primary_header, 'OBT-BEG'))

  filename = 'solo_l2_stix-background_'+trim(time_stamp(obt_beg))+'_V'+trim(tstamp)+'.fits'
  path = concat_dir(base_directory, 'background')
  if ~FILE_TEST(path, /DIRECTORY) then begin
    file_mkdir, path
  endif
  fullpath = concat_dir(path, filename)

  date_obs = anytim(obt_beg, /ccsds)

  primary_header = stx_make_l2_header(header=primary_header, filename=filename, date_obs=date_obs, $
    history='test')

  mwrfits, !NULL, fullpath, primary_header, /create, status=stat0
  mwrfits, rate_info, fullpath, status=stat1
  mwrfits, energy_info, fullpath, status=stat2
  mwrfits, control, fullpath, control_header, status=stat3
  
  fxhmodify, fullpath, 'EXTNAME', 'RATE', EXTENSION=1
  fxhmodify, fullpath, 'EXTNAME', 'ENEBAND', EXTENSION=2
  fxhmodify, fullpath, 'EXTNAME', 'CONTROL', EXTENSION=3

end

;+
; :project:
;       STIX
;
; :name:
;       stx_make_l2_ql_variance_fits
;
; :purpose:
;       Takes l1 quick look variance adds phyical axes and writes to a l2 fits file.
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
;       stx_make_l2_ql_variance_fits(l1fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_make_l2_ql_variance_fits, fits_path, base_directory
  !null = mrdfits(fits_path, 0, primary_header)
  control = mrdfits(fits_path, 1, control_header)
  data = mrdfits(fits_path, 2, data_header)

  n_times = n_elements(data)
  n_energies = total(control.ENERGY_BIN_MASK)
  relative_times = indgen(n_elements(data)) * control.INTEGRATION_TIME

  ; ENERGY_BIN_MASK by definition doesnt contain last closing energy
  energies = stx_construct_energy_axis(select=[where(control.ENERGY_BIN_MASK eq 1), 32])

  energy_structure = {CHANNEL: 0L, E_MIN: 0.0, E_MAX: 0.0}
  energy_info = REPLICATE(energy_structure, n_energies)
  energy_info.E_MIN = energies.low
  energy_info.E_MAX = energies.high
  energy_info.CHANNEL = lindgen(n_elements(energies.low))

  rate_structure = {VARIANCE: 0L, TRIGGERS: 0L, CHANNEL: lonarr(n_energies), TIME: 0.0d, TIMEDEL: 0.0, $
                    LIVETIME: 1, ERROR: 0L}
  rate_structure.CHANNEL = lonarr(n_energies)
  rate_structure.TIMEDEL = control.INTEGRATION_TIME

  rate_info = REPLICATE(rate_structure, n_times)
  rate_info.VARIANCE = data.VARIANCE
  rate_info.TIME = relative_times

  obt_beg = float(sxpar(primary_header, 'OBT-BEG'))

  filename = 'solo_l2_stix-variance_'+trim(time_stamp(obt_beg))+'_V'+trim(tstamp)+'.fits'
  path = concat_dir(base_directory, 'variance')
  if ~FILE_TEST(path, /DIRECTORY) then begin
    file_mkdir, path
  endif
  fullpath = concat_dir(path, filename)

  date_obs = anytim(obt_beg, /ccsds)

  primary_header = stx_make_l2_header(header=primary_header, filename=filename, date_obs=date_obs, $
    history='test')

  mwrfits, !NULL, fullpath, primary_header, /create, status=stat0
  mwrfits, rate_info, fullpath, status=stat1
  mwrfits, energy_info, fullpath, status=stat2
  mwrfits, control, fullpath, control_header, status=stat3

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
;       Takes l1 quick look spectra adds phyical axes and writes to a l2 fits file.
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
;       stx_make_l2_ql_spectra_fits(l1fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_make_l2_ql_spectra_fits, fits_path, base_directory
  !null = mrdfits(fits_path, 0, primary_header)
  control = mrdfits(fits_path, 1, control_header)
  data = mrdfits(fits_path, 2, data_header)

  n_times = n_elements(data)
  n_energies = 32
  relative_times = indgen(n_elements(data)) * control.INTEGRATION_TIME

  ; ENERGY_BIN_MASK by definition doesnt contain last closing energy
  energies = stx_construct_energy_axis()

  energy_structure = {CHANNEL: 0L, E_MIN: 0.0, E_MAX: 0.0}
  energy_info = REPLICATE(energy_structure, 32)
  energy_info.E_MIN = energies.low
  energy_info.E_MAX = energies.high
  energy_info.CHANNEL = lindgen(n_elements(energies.low))

  rate_structure = {COUNTS: lonarr(32, 32), TRIGGERS: 0L, CHANNEL: lonarr(n_energies), DETECTOR_MASK: bytarr(32), TIME: 0.0d, TIMEDEL: 0.0}
  rate_structure.CHANNEL = lonarr(n_energies)
  rate_structure.TIMEDEL = control.INTEGRATION_TIME

  rate_info = REPLICATE(rate_structure, n_times)
  rate_info.COUNTS = data.SPECTRUM
  rate_info.DETECTOR_MASK = data.DETECTOR_MASK
  rate_info.TIME = relative_times

  obt_beg = float(sxpar(primary_header, 'OBT-BEG'))

  filename = 'solo_l2_stix-spectra_'+trim(time_stamp(obt_beg))+'_V'+trim(tstamp)+'.fits'
  path = concat_dir(base_directory, 'spectra')
  if ~FILE_TEST(path, /DIRECTORY) then begin
    file_mkdir, path
  endif
  fullpath = concat_dir(path, filename)

  date_obs = anytim(obt_beg, /ccsds)

  primary_header = stx_make_l2_header(header=primary_header, filename=filename, date_obs=date_obs, $
    history='test')

  mwrfits, !NULL, fullpath, primary_header, /create, status=stat0
  mwrfits, rate_info, fullpath, status=stat1
  mwrfits, energy_info, fullpath, status=stat2
  mwrfits, control, fullpath, control_header, status=stat3

  fxhmodify, fullpath, 'EXTNAME', 'RATE', EXTENSION=1
  fxhmodify, fullpath, 'EXTNAME', 'ENEBAND', EXTENSION=2
  fxhmodify, fullpath, 'EXTNAME', 'CONTROL', EXTENSION=3

end

;+
; :project:
;       STIX
;
; :name:
;       stx_make_l2_ql_calibration_sepctra_fits
;
; :purpose:
;       Takes l1 quick look calibration spectra adds phyical axes and writes to a l2 fits file.
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
;       stx_make_l2_ql_calibration_spectra_fits(l1fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_make_l2_ql_calibration_spectra_fits, fits_path, base_directory
  !null = mrdfits(fits_path, 0, primary_header)
  control = mrdfits(fits_path, 1, control_header)
  data = mrdfits(fits_path, 2, data_header)

  ; TODO Not sure what more can be done as are low level data anyway
end

;+
; :project:
;       STIX
;
; :name:
;       stx_make_l2_ql_flareflag_location_fits
;
; :purpose:
;       Takes l1 quick look flare flag and location adds phyical axes and writes to a l2 fits file.
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
;       stx_make_l2_ql_flareflag_location_fits(l1fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_make_l2_ql_flareflag_location_fits, fits_path, base_directory
  !null = mrdfits(fits_path, 0, primary_header)
  control = mrdfits(fits_path, 1, control_header)
  data = mrdfits(fits_path, 2, data_header)

  ; TODO Not sure what more can be done as are low level data anyway
  print, 1
end

pro stx_make_l2_ql_fits, base_directory
  default, base_directory, concat_dir(concat_dir(concat_dir(getenv("SSW_STIX"), 'data'), 'l2'), 'quicklook')
  l1_directory = concat_dir(concat_dir(concat_dir(getenv("SSW_STIX"), 'data'), 'l1'), 'quicklook')
  
  quicklook_types = FILE_SEARCH(l1_directory, '*', /TEST_DIRECTORY)
  foreach quicklook, quicklook_types do begin
    quicklook_files = FILE_SEARCH(quicklook, '*.fits')
    foreach ql_file, quicklook_files do begin
      if STRMATCH(ql_file, '*lightcurve*') then begin
        res = stx_make_l2_ql_lightcurve_fits(ql_file, base_directory)
      endif else if STRMATCH(ql_file, '*background*') then begin
        res = stx_make_l2_ql_background_fits(ql_file, base_directory)
      endif else if STRMATCH(ql_file, '*variance*') then begin
        res = stx_make_l2_ql_variance_fits(ql_file, base_directory)
      endif else if STRMATCH(ql_file, '*spectra*') && ~STRMATCH(ql_file, '*_spectra*') then begin
        res = stx_make_l2_ql_spectra_fits(ql_file, base_directory)
      endif else if STRMATCH(ql_file, '*calibration_spectra*') then begin
        ;res = stx_make_l2_ql_calibration_spectra_fits(ql_file, base_directory)
      endif else if STRMATCH(ql_file, '*flareflag*') then begin
        ;res = stx_make_l2_ql_flareflag_location_fits(ql_file, base_directory)
      endif
    endforeach
  endforeach

  
end