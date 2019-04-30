;+
; :project:
;       STIX
;
; :name:
;       stx_make_l1_header
;
; :purpose:
;       Creates l1 primary fits header
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
function stx_make_l1_header, header = header, filename=filename, date_obs=date_obs, $
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
;       stx_make_l1_ql_lightcurve_fits
;
; :purpose:
;       Takes l0.5 quick look lightcurve adds phyical axes and writes to a l1 fits file.
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
;       stx_make_l1_ql_lightcurve_fits(l1fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_make_l1_ql_lightcurve_fits, tm_reader, base_directory
    tm_reader->getdata, asw_ql_lightcurve=processed_lc, solo=solo

    unprocessed_lc = *solo['stx_tmtc_ql_light_curves',0,0].source_data

    integration_time = unprocessed_lc.INTEGRATION_TIME

    stx_telemetry_util_time2scet, coarse_time = unprocessed_lc.coarse_time, $
        fine_time = unprocessed_lc.fine_time, stx_time_obj=obt_beg, /reverse

    obt_beg = stx_time2any(obt_beg)

    stx_km_compression_schema_to_params, unprocessed_lc.COMPRESSION_SCHEMA_LIGHT_CURVES, $
        k=lc_k, m=lc_m, s=lc_s
    stx_km_compression_schema_to_params, unprocessed_lc.COMPRESSION_SCHEMA_TRIGGER, $
        k=tr_k, m=tr_m, s=tr_s

    energy_bin_mask = stx_mask2bits(unprocessed_lc.ENERGY_BIN_MASK, /reverse, mask_length=32)

    n_times = unprocessed_lc.DYNAMIC_NBR_OF_DATA_POINTS
    n_energies = total(energy_bin_mask)
    relative_times = indgen(n_times) * integration_time

    obt_end = obt_beg + ((n_times+1)*integration_time)

    structures = stx_l1_ql_lightcurve_structures(n_energies, n_times)
    control_struc = structures.control

    control_struc.integration_time = integration_time
    control_struc.detector_mask = processed_lc[0].detector_mask
    control_struc.pixel_mask = processed_lc[0].pixel_mask
    control_struc.energy_bin_mask = energy_bin_mask
    control_struc.compression_scheme_counts = [lc_k, lc_m, lc_s]
    control_struc.compression_scheme_triggers = [tr_k, tr_m, tr_s]

    ; ENERGY_BIN_MASK by definition doesnt contain last closing energy
    energies = stx_construct_energy_axis(select=[where(energy_bin_mask eq 1), 32])

    energy_info = structures['energy']

    energy_info.E_MIN = energies.low
    energy_info.E_MAX = energies.high
    energy_info.CHANNEL = lindgen(n_elements(energies.low))

    rate_info = structures['count']
    rate_info[*].TIMEDEL = integration_time
    rate_info.COUNTS = processed_lc[0].counts
    rate_info.TRIGGERS = processed_lc[0].triggers
    rate_info.RATE_CONTROL_REGEIME = processed_lc[0].RATE_CONTROL_REGIME
    rate_info.TIME = relative_times
    rate_info.ERROR = long(rate_info.COUNTS^0.5)

    version = 1
    obs_mode = 'Nominal'

    ;    TODO proper convertion from OBT to UTC (spicer kernels)
    date_obs = anytim(anytim(obt_beg) + 41.0d * 365 * 24 * 60 * 60, /ccsds)
    date_beg = date_obs
    date_end = anytim(anytim(obt_end) + 41.0d * 365 * 24 * 60 * 60, /ccsds)
    date_avg = anytim(((anytim(obt_end) - anytim(obt_beg))/2.0) $
        + anytim(obt_beg) + 41.0d * 365 * 24 * 60 * 60, /ccsds)

    ;    TODO proper values from external info
    obs_type = 'LC'
    soop_type = 'SOOP'
    obs_id = 'obs_id'
    obs_target = 'Sun'

    filename = 'solo_l1_stix-lightcurve_'+trim(time_stamp(date_obs))+'_V'+trim(version)+'.fits'
    path = concat_dir(base_directory, 'lightcurve')
    if ~FILE_TEST(path, /DIRECTORY) then begin
        file_mkdir, path
    endif
    fullpath = concat_dir(path, filename)

    mwrfits, !NULL, fullpath, primary_header, /create, status=stat0
    !null = mrdfits(fullpath, 0, primary_header)

    primary_header = stx_update_primary_header_l1(header=primary_header, filename=filename, $
        create_date=anytim(!stime, /ccsds), obt_beg=obt_beg, obt_end=obt_end, version=version, $
        obs_mode=obs_mode, date_obs=date_obs, date_beg=date_beg, date_avg=date_avg, $
        date_end=date_end, obs_type=obs_type, $
        soop_type=soop_type, obs_id=obs_id, obs_target=obs_target)

    mwrfits, !NULL, fullpath, primary_header, /create
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
;       stx_make_l1_ql_background_fits
;
; :purpose:
;       Takes l0.5 quick look background adds phyical axes and writes to a l1 fits file.
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
function stx_make_l1_ql_background_fits, tm_reader, base_directory

    tm_reader->getdata, asw_ql_background_monitor=processed_bg, solo=solo

    unprocessed_bg = *solo['stx_tmtc_ql_background_monitor',0,0].source_data

    integration_time = unprocessed_bg.INTEGRATION_TIME

    stx_telemetry_util_time2scet, coarse_time = unprocessed_bg.coarse_time, fine_time = unprocessed_bg.fine_time, stx_time_obj=obt_beg, /reverse

    obt_beg = stx_time2any(obt_beg)

    stx_km_compression_schema_to_params, unprocessed_bg.COMPRESSION_SCHEMA_BACKGROUND, k=bg_k, m=bg_m, s=bg_s
    stx_km_compression_schema_to_params, unprocessed_bg.COMPRESSION_SCHEMA_TRIGGER, k=tr_k, m=tr_m, s=tr_s

    energy_bin_mask = stx_mask2bits(unprocessed_bg.ENERGY_BIN_MASK, /reverse, mask_length=32)

    n_times = unprocessed_bg[0].DYNAMIC_NBR_OF_DATA_POINTS
    n_energies = total(energy_bin_mask)
    relative_times = indgen(n_times) * integration_time

    obt_end = obt_beg + ((n_times+1)*integration_time)

    structures = stx_l1_ql_background_structures( n_energies, n_times)
    control_struc = structures.control

    control_struc.integration_time = integration_time
    control_struc.energy_bin_mask = (stx_mask2bits(unprocessed_bg.ENERGY_BIN_MASK, /reverse, mask_length=33))[0:-2]
    control_struc.compression_schema_background = [bg_k, bg_m, bg_s]
    control_struc.compression_schema_trigger = [tr_k, tr_m, tr_s]

    ; ENERGY_BIN_MASK by definition doesnt contain last closing energy
    energies = stx_construct_energy_axis(select=[where(control_struc.ENERGY_BIN_MASK eq 1), 32])

    energy_info = structures['energy']
    energy_info.E_MIN = energies.low
    energy_info.E_MAX = energies.high
    energy_info.CHANNEL = lindgen(n_elements(energies.low))

    rate_info = structures['count']
    rate_info.CHANNEL = lonarr(n_energies)
    rate_info.TIMEDEL = integration_time
    rate_info.BACKGROUND = processed_bg[0].BACKGROUND
    rate_info.TRIGGERS = processed_bg[0].TRIGGERS
    rate_info.TIME = relative_times
    rate_info.ERROR = long(rate_info.BACKGROUND^0.5)

    version = 1
    obs_mode = 'Nominal'

    ;    TODO proper convertion from OBT to UTC (spicer kernels)
    date_obs = anytim(anytim(obt_beg) + 41.0d * 365 * 24 * 60 * 60, /ccsds)
    date_beg = date_obs
    date_end = anytim(anytim(obt_end) + 41.0d * 365 * 24 * 60 * 60, /ccsds)
    date_avg = anytim(((anytim(obt_end) - anytim(obt_beg))/2.0) $
        + anytim(obt_beg) + 41.0d * 365 * 24 * 60 * 60, /ccsds)

    ;    TODO proper values from external info
    obs_type = 'LC'
    soop_type = 'SOOP'
    obs_id = 'obs_id'
    obs_target = 'Sun'

    filename = 'solo_l1_stix-background_'+trim(time_stamp(date_obs))+'_V'+trim(version)+'.fits'
    path = concat_dir(base_directory, 'background')
    if ~FILE_TEST(path, /DIRECTORY) then begin
        file_mkdir, path
    endif
    fullpath = concat_dir(path, filename)

    mwrfits, !NULL, fullpath, primary_header, /create, status=stat0
    !null = mrdfits(fullpath, 0, primary_header)

    primary_header = stx_update_primary_header_l1(header=primary_header, filename=filename, $
        create_date=anytim(!stime, /ccsds), obt_beg=obt_beg, obt_end=obt_end, version=version, $
        obs_mode=obs_mode, date_obs=date_obs, date_beg=date_beg, date_avg=date_avg, $
        date_end=date_end, obs_type=obs_type, $
        soop_type=soop_type, obs_id=obs_id, obs_target=obs_target)

    mwrfits, !NULL, fullpath, primary_header, /create
    mwrfits, rate_info, fullpath, status=stat1
    mwrfits, energy_info, fullpath, status=stat2
    mwrfits, control_struc, fullpath, control_header, status=stat3

    fxhmodify, fullpath, 'EXTNAME', 'RATE', EXTENSION=1
    fxhmodify, fullpath, 'EXTNAME', 'ENEBAND', EXTENSION=2
    fxhmodify, fullpath, 'EXTNAME', 'CONTROL', EXTENSION=3

end

;+
; :project:
;       STIX
;
; :name:
;       stx_make_l1_ql_variance_fits
;
; :purpose:
;       Takes l0.5 quick look variance adds phyical axes and writes to a l1 fits file.
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
;       stx_make_l1_ql_variance_fits(l1fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_make_l1_ql_variance_fits, tm_reader, base_directory
    tm_reader->getdata, asw_ql_variance=processed_var, solo=solo

    unprocessed_var = *solo['stx_tmtc_ql_variance',0,0].source_data

    integration_time = unprocessed_var.INTEGRATION_TIME

    stx_telemetry_util_time2scet, coarse_time = unprocessed_var.coarse_time, fine_time = unprocessed_var.fine_time, stx_time_obj=obt_beg, /reverse

    obt_beg = stx_time2any(obt_beg)

    stx_km_compression_schema_to_params, unprocessed_var.COMPRESSION_SCHEMA_ACCUM, k=var_k, m=var_m, s=var_s

    energy_bin_mask = stx_mask2bits(unprocessed_var.ENERGY_MASK, /reverse, mask_length=32)

    n_times = unprocessed_var[0].NUMBER_OF_SAMPLES
    n_energies = total(energy_bin_mask)
    relative_times = indgen(n_times) * integration_time

    obt_end = obt_beg + ((n_times+1)*integration_time)

    structures = stx_l1_ql_variance_structures(n_energies, n_times)
    control_struc = structures.control

    control_struc.integration_time = integration_time
    control_struc.samples_per_variance = control_struc[0].SAMPLES_PER_VARIANCE
    control_struc.detector_mask = processed_var[0].DETECTOR_MASK
    control_struc.energy_bin_mask = stx_mask2bits(unprocessed_var.ENERGY_MASK, /reverse, mask_length=32)
    control_struc.pixel_mask = processed_var[0].PIXEL_MASK
    control_struc.compression_scheme_variance = [var_k, var_m, var_s]

    ;    data_struc.variance = processed_var[0].VARIANCE
    ;
    ;    !null = mrdfits(fits_path, 0, primary_header)
    ;    control = mrdfits(fits_path, 1, control_header)
    ;    data = mrdfits(fits_path, 2, data_header)
    ;
    ;    n_times = n_elements(data)
    ;    n_energies = total(control.ENERGY_BIN_MASK)
    ;    relative_times = indgen(n_elements(data)) * control.INTEGRATION_TIME

    ; ENERGY_BIN_MASK by definition doesnt contain last closing energy
    energies = stx_construct_energy_axis(select=[where(control_struc.ENERGY_BIN_MASK eq 1), 32])

    energy_info = structures['energy']
    energy_info.E_MIN = energies.low
    energy_info.E_MAX = energies.high
    energy_info.CHANNEL = lindgen(n_elements(energies.low))

    rate_info = structures['count']
    rate_info.CHANNEL = lonarr(n_energies)
    rate_info.TIMEDEL = control_struc.INTEGRATION_TIME
    rate_info.VARIANCE = processed_var[0].VARIANCE
    rate_info.TIME = relative_times

    version = 1
    obs_mode = 'Nominal'

    ;    TODO proper convertion from OBT to UTC (spicer kernels)
    date_obs = anytim(anytim(obt_beg) + 41.0d * 365 * 24 * 60 * 60, /ccsds)
    date_beg = date_obs
    date_end = anytim(anytim(obt_end) + 41.0d * 365 * 24 * 60 * 60, /ccsds)
    date_avg = anytim(((anytim(obt_end) - anytim(obt_beg))/2.0) $
        + anytim(obt_beg) + 41.0d * 365 * 24 * 60 * 60, /ccsds)

    ;    TODO proper values from external info
    obs_type = 'LC'
    soop_type = 'SOOP'
    obs_id = 'obs_id'
    obs_target = 'Sun'

    filename = 'solo_l1_stix-variance_'+trim(time_stamp(date_obs))+'_V'+trim(version)+'.fits'
    path = concat_dir(base_directory, 'variance')
    if ~FILE_TEST(path, /DIRECTORY) then begin
        file_mkdir, path
    endif
    fullpath = concat_dir(path, filename)

    mwrfits, !NULL, fullpath, primary_header, /create
    !null = mrdfits(fullpath, 0, primary_header)

    primary_header = stx_update_primary_header_l1(header=primary_header, filename=filename, $
        create_date=anytim(!stime, /ccsds), obt_beg=obt_beg, obt_end=obt_end, version=version, $
        obs_mode=obs_mode, date_obs=date_obs, date_beg=date_beg, date_avg=date_avg, $
        date_end=date_end, obs_type=obs_type, $
        soop_type=soop_type, obs_id=obs_id, obs_target=obs_target)

    mwrfits, !NULL, fullpath, primary_header, /create
    mwrfits, rate_info, fullpath, status=stat1
    mwrfits, energy_info, fullpath, status=stat2
    mwrfits, control_struc, fullpath, control_header, status=stat3

    fxhmodify, fullpath, 'EXTNAME', 'RATE', EXTENSION=1
    fxhmodify, fullpath, 'EXTNAME', 'ENEBAND', EXTENSION=2
    fxhmodify, fullpath, 'EXTNAME', 'CONTROL', EXTENSION=3

end


;+
; :project:
;       STIX
;
; :name:
;       stx_make_l1_ql_spectra_fits
;
; :purpose:
;       Takes l0.5 quick look spectra adds phyical axes and writes to a l1 fits file.
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
;       stx_make_l1_ql_spectra_fits(l1fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_make_l1_ql_spectra_fits, tm_reader, base_directory

    tm_reader->getdata, stx_asw_ql_spectra=processed_spec, solo=solo

    unprocessed_spec = *solo['stx_tmtc_ql_spectra',0,0].source_data

    integration_time = unprocessed_spec.INTEGRATION_TIME

    stx_telemetry_util_time2scet, coarse_time = unprocessed_spec.coarse_time, fine_time = unprocessed_spec.fine_time, stx_time_obj=obt_beg, /reverse

    obt_beg = stx_time2any(obt_beg)
    obt_end = obt_beg + integration_time * unprocessed_spec.NUMBER_OF_STRUCTURES

    n_times = (size(processed_spec[0].spectrum, /dim))[-1]
    n_energies = 32
    relative_times = (n_times + 1) * INTEGRATION_TIME

    stx_km_compression_schema_to_params, unprocessed_spec.COMPRESSION_SCHEMA_SPECTRUM, k=sp_k, m=sp_m, s=sp_s
    stx_km_compression_schema_to_params, unprocessed_spec.COMPRESSION_SCHEMA_TRIGGER, k=tr_k, m=tr_m, s=tr_s

    ; TODO Why is the number of spectra in processed and unproccesed different?
    structures = stx_l1_ql_spectra_structures(n_energies, n_times)
    control_struc = structures.control

    control_struc.pixel_mask = processed_spec[0].PIXEL_MASK
    control_struc.integration_time = integration_time
    control_struc.compression_scheme_spec = [sp_k, sp_m, sp_s]
    control_struc.compression_scheme_trigger = [tr_k, tr_m, tr_s]

    ;    data_struc.detector_mask = processed_spec[0].DETECTOR_MASK
    ;    data_struc.triggers = processed_spec[0].TRIGGERS
    ;    data_struc.spectrum = processed_spec[0].SPECTRUM
    ;
    ;    !null = mrdfits(fits_path, 0, primary_header)
    ;    control = mrdfits(fits_path, 1, control_header)
    ;    data = mrdfits(fits_path, 2, data_header)
    ;


    ; ENERGY_BIN_MASK by definition doesnt contain last closing energy
    energies = stx_construct_energy_axis()

    structures = stx_l1_ql_spectra_structures(n_energies, n_times)

    energy_info = structures['energy']
    energy_info.E_MIN = energies.low
    energy_info.E_MAX = energies.high
    energy_info.CHANNEL = lindgen(n_elements(energies.low))

    rate_info = structures['count']
    rate_info.CHANNEL = lonarr(n_energies)
    rate_info.TIMEDEL = INTEGRATION_TIME
    rate_info.COUNTS = processed_spec[0].SPECTRUM
    rate_info.DETECTOR_MASK = processed_spec[0].DETECTOR_MASK
    rate_info.TRIGGERS = processed_spec[0].TRIGGERS
    rate_info.TIME = relative_times

    version = 1
    obs_mode = 'Nominal'

    ;    TODO proper convertion from OBT to UTC (spicer kernels)
    date_obs = anytim(anytim(obt_beg) + 41.0d * 365 * 24 * 60 * 60, /ccsds)
    date_beg = date_obs
    date_end = anytim(anytim(obt_end) + 41.0d * 365 * 24 * 60 * 60, /ccsds)
    date_avg = anytim(((anytim(obt_end) - anytim(obt_beg))/2.0) $
        + anytim(obt_beg) + 41.0d * 365 * 24 * 60 * 60, /ccsds)

    ;    TODO proper values from external info
    obs_type = 'LC'
    soop_type = 'SOOP'
    obs_id = 'obs_id'
    obs_target = 'Sun'

    filename = 'solo_l1_stix-spectra_'+trim(time_stamp(date_obs))+'_V'+trim(version)+'.fits'
    path = concat_dir(base_directory, 'spectra')
    if ~FILE_TEST(path, /DIRECTORY) then begin
        file_mkdir, path
    endif
    fullpath = concat_dir(path, filename)

    mwrfits, !NULL, fullpath, primary_header, /create
    !null = mrdfits(fullpath, 0, primary_header)

    primary_header = stx_update_primary_header_l1(header=primary_header, filename=filename, $
        create_date=anytim(!stime, /ccsds), obt_beg=obt_beg, obt_end=obt_end, version=version, $
        obs_mode=obs_mode, date_obs=date_obs, date_beg=date_beg, date_avg=date_avg, $
        date_end=date_end, obs_type=obs_type, $
        soop_type=soop_type, obs_id=obs_id, obs_target=obs_target)


    mwrfits, !NULL, fullpath, primary_header, /create
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
;       stx_make_l1_ql_calibration_sepctra_fits
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
;       stx_make_l1_ql_calibration_spectra_fits(l1fitspath, 'data')
;
; :history:
;       02-May-2018 – SAM (TCD) init
;
;-
function stx_make_l1_ql_calibration_spectra_fits, tm_reader, base_directory
    tm_reader->getdata, asw_ql_calibration_spectrum=processed_calspec, solo=solo

    unprocessed_calspec = *solo['stx_tmtc_ql_calibration_spectrum',0,0].source_data

    stx_telemetry_util_time2scet, coarse_time = unprocessed_calspec.coarse_time, fine_time = 0, stx_time_obj=obt_beg, /reverse

    obt_beg = stx_time2any(obt_beg)
    obt_end = obt_beg + unprocessed_calspec.DURATION

    ; TODO allways 8 sub sepectra or use sub_spectra_mask
    strucures = stx_l1_ql_calibration_spectra_structures(8)
    control_struc = strucures.control
    data_struc  = strucures.data

    control_struc.detector_mask = stx_mask2bits(unprocessed_calspec.DETECTOR_MASK, /reverse, mask_length=32)
    control_struc.pixel_mask = stx_mask2bits(unprocessed_calspec.PIXEL_MASK, /reverse, mask_length=16)
    control_struc.duration = unprocessed_calspec.DURATION
    control_struc.quiet_time = unprocessed_calspec.QUIET_TIME
    control_struc.live_time = unprocessed_calspec.LIVE_TIME
    control_struc.average_temperature = unprocessed_calspec.AVERAGE_TEMPERATURE

    all_sub_specta = processed_calspec[0].subspectra

    for i=0, N_ELEMENTS(all_sub_specta)-1 do begin
        data_struc[i].detecotr_mask = all_sub_specta[i].DETECTOR_MASK
        data_struc[i].pixel_mask = all_sub_specta[i].PIXEL_MASK
        data_struc[i].lower_energy_bound_channel = all_sub_specta[i].LOWER_ENERGY_BOUND_CHANNEL
        data_struc[i].number_of_summed_channels = all_sub_specta[i].NUMBER_OF_SUMMED_CHANNELS
        data_struc[i].number_of_spectral_points = all_sub_specta[i].NUMBER_OF_SPECTRAL_POINTS
    endfor

    version = 1
    obs_mode = 'Nominal'

    ;    TODO proper convertion from OBT to UTC (spicer kernels)
    date_obs = anytim(anytim(obt_beg) + 41.0d * 365 * 24 * 60 * 60, /ccsds)
    date_beg = date_obs
    date_end = anytim(anytim(obt_end) + 41.0d * 365 * 24 * 60 * 60, /ccsds)
    date_avg = anytim(((anytim(obt_end) - anytim(obt_beg))/2.0) $
        + anytim(obt_beg) + 41.0d * 365 * 24 * 60 * 60, /ccsds)

    ;    TODO proper values from external info
    obs_type = 'LC'
    soop_type = 'SOOP'
    obs_id = 'obs_id'
    obs_target = 'Sun'


    filename = 'solo_l1_stix-calibration-spectra_'+trim(time_stamp(date_obs))+'_V'+trim(version)+'.fits'
    path = concat_dir(base_directory, 'calibration_spectra')
    if ~FILE_TEST(path, /DIRECTORY) then begin
        file_mkdir, path
    endif
    fullpath = concat_dir(path, filename)


    mwrfits, !NULL, fullpath, primary_header, /create
    !null = mrdfits(fullpath, 0, primary_header)

    primary_header = stx_update_primary_header_l1(header=primary_header, filename=filename, $
        create_date=anytim(!stime, /ccsds), obt_beg=obt_beg, obt_end=obt_end, version=version, $
        obs_mode=obs_mode, date_obs=date_obs, date_beg=date_beg, date_avg=date_avg, $
        date_end=date_end, obs_type=obs_type, $
        soop_type=soop_type, obs_id=obs_id, obs_target=obs_target)


    mwrfits, !NULL, fullpath, primary_header, /create
    mwrfits, data_struc, fullpath, status=stat1
    mwrfits, control_struc, fullpath, control_header, status=stat3

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
function stx_make_l1_ql_flareflag_location_fits, tm_reader, base_directory
    tm_reader->getdata, asw_ql_flare_flag_location=processed_fl, solo=solo

    unprocessed_fl = *solo['stx_tmtc_ql_flare_flag_location',0,0].source_data

    integration_time = unprocessed_fl.INTEGRATION_TIME

    stx_telemetry_util_time2scet, coarse_time = unprocessed_fl.coarse_time, fine_time = unprocessed_fl.fine_time, stx_time_obj=obt_beg, /reverse

    obt_beg = stx_time2any(obt_beg)
    obt_end = obt_beg + integration_time

    structures = stx_l1_ql_flare_flag_location(unprocessed_fl.NUMBER_OF_SAMPLES)
    control_struc = structures.control
    data_struc = structures.data

    control_struc.integration_time = integration_time
    control_struc.n_samples = unprocessed_fl.NUMBER_OF_SAMPLES

    data_struc.flare_flag = processed_fl[0].FLARE_FLAG
    data_struc.loc_z = processed_fl[0].X_POS
    data_struc.loc_y = processed_fl[0].Y_POS

    version = 1
    obs_mode = 'Nominal'

    ;    TODO proper convertion from OBT to UTC (spicer kernels)
    date_obs = anytim(anytim(obt_beg) + 41.0d * 365 * 24 * 60 * 60, /ccsds)
    date_beg = date_obs
    date_end = anytim(anytim(obt_end) + 41.0d * 365 * 24 * 60 * 60, /ccsds)
    date_avg = anytim(((anytim(obt_end) - anytim(obt_beg))/2.0) $
        + anytim(obt_beg) + 41.0d * 365 * 24 * 60 * 60, /ccsds)

    ;    TODO proper values from external info
    obs_type = 'LC'
    soop_type = 'SOOP'
    obs_id = 'obs_id'
    obs_target = 'Sun'

    filename = 'solo_l0.5_stix-flare-flag-location_'+trim(time_stamp(date_obs))+'_V'+trim(version)+'.fits'
    path = concat_dir(base_directory, 'flareflag')
    if ~FILE_TEST(path, /DIRECTORY) then begin
        file_mkdir, path
    endif
    fullpath = concat_dir(path, filename)

    mwrfits, !NULL, fullpath, primary_header, /create
    !null = mrdfits(fullpath, 0, primary_header)

    primary_header = stx_update_primary_header_l1(header=primary_header, filename=filename, $
        create_date=anytim(!stime, /ccsds), obt_beg=obt_beg, obt_end=obt_end, version=version, $
        obs_mode=obs_mode, date_obs=date_obs, date_beg=date_beg, date_avg=date_avg, $
        date_end=date_end, obs_type=obs_type, $
        soop_type=soop_type, obs_id=obs_id, obs_target=obs_target)


    mwrfits, !NULL, fullpath, primary_header, /create
    mwrfits, data_struc, fullpath, status=stat1
    mwrfits, control_struc, fullpath, control_header, status=stat3

    fxhmodify, fullpath, 'EXTNAME', 'DATA', EXTENSION=1
    fxhmodify, fullpath, 'EXTNAME', 'CONTROL', EXTENSION=2
end

pro stx_make_l1_ql_fits, scenario_name=scenario_name, base_directory
    default, scenario_name, 'stx_scenario_2'
    default, base_directory, concat_dir(concat_dir(concat_dir(getenv("SSW_STIX"), 'data'), 'l1'), 'quicklook'); SSW_STIX/data/l1/quicklook/

    tm_reader = stx_telemetry_reader(filename=scenario_name + '/tmtc.bin')

    tm_reader.getdata, solo_packets=solo_packets

    if solo_packets.haskey('stx_tmtc_ql_light_curves') then ql_lc = stx_make_l1_ql_lightcurve_fits(tm_reader, base_directory)
    if solo_packets.haskey('stx_tmtc_ql_calibration_spectrum') then ql_cal_spectra = stx_make_l1_ql_calibration_spectra_fits(tm_reader, base_directory)
    if solo_packets.haskey('stx_tmtc_ql_variance') then ql_variance = stx_make_l1_ql_variance_fits(tm_reader, base_directory)
    if solo_packets.haskey('stx_tmtc_ql_spectra') then ql_spectra = stx_make_l1_ql_spectra_fits(tm_reader, base_directory)
    if solo_packets.haskey('stx_tmtc_ql_background_monitor') then ql_background = stx_make_l1_ql_background_fits(tm_reader, base_directory)
    if solo_packets.haskey('stx_tmtc_ql_flare_flag_location') then ql_flarelist = stx_make_l1_ql_flareflag_location_fits(tm_reader, base_directory)

end


;pro stx_make_l1_ql_fits, base_directory
;    default, base_directory, concat_dir(concat_dir(concat_dir(getenv("SSW_STIX"), 'data'), 'l1'), 'quicklook')
;    l05_directory = concat_dir(concat_dir(concat_dir(getenv("SSW_STIX"), 'data'), 'l0.5'), 'quicklook')
;
;    quicklook_types = FILE_SEARCH(l05_directory, '*', /TEST_DIRECTORY)
;    foreach quicklook, quicklook_types do begin
;        quicklook_files = FILE_SEARCH(quicklook, '*.fits')
;        foreach ql_file, quicklook_files do begin
;            if STRMATCH(ql_file, '*lightcurve*') then begin
;                res = stx_make_l1_ql_lightcurve_fits(ql_file, base_directory)
;            endif else if STRMATCH(ql_file, '*background*') then begin
;                res = stx_make_l1_ql_background_fits(ql_file, base_directory)
;            endif else if STRMATCH(ql_file, '*variance*') then begin
;                res = stx_make_l1_ql_variance_fits(ql_file, base_directory)
;            endif else if STRMATCH(ql_file, '*spectra*') && ~STRMATCH(ql_file, '*_spectra*') then begin
;                res = stx_make_l1_ql_spectra_fits(ql_file, base_directory)
;            endif else if STRMATCH(ql_file, '*calibration_spectra*') then begin
;                res = stx_make_l1_ql_calibration_spectra_fits(ql_file, base_directory)
;            endif else if STRMATCH(ql_file, '*flareflag*') then begin
;                res = stx_make_l1_ql_flareflag_location_fits(ql_file, base_directory)
;            endif
;        endforeach
;    endforeach
;end