;+
; :description:
;
;    This procedure fits the input calibration spectra and adds the metadata (Hole trap length, Electron trap length, Peak counts, Line energy & Noise FWHM ) for the 3
;    calibration lines to the database fits file
;
; :categories:
;
;    calibration, database, drm
;
;
; :params:
;
;    calibration_data : in, type="stx_asw_ql_calibration_spectrum structure"
;               an output float value
;
; :keywords:
;
;
;    dbfilename :in,  type="string", default="'test_rad_db.fits'"
;                the name of the database fits file
;
;    generate_new_drm : in, type="bool", default="1"
;              if set a new drm structure will be generated using the fit parameters
;
;    drmfilename : in, type="string", default="test_drm.fits"
;               the name of the drm fits file
;
;    new_db : in, type="bool", default="1"
;             set if generating a new database file rather than updating an existing one.
;
; :examples:
;    stx_update_radiation_databse, calibration_data = calibration_spectra, /generate_new_drm
;
; :history:
;    29-Mar-2018 - ECMD (Graz), initial release
;
;-
pro stx_update_radiation_databse,  calibration_data, generate_new_drm = generate_new_drm, dbfilename =dbfilename, $
  drmfilename = drmfilename, new_db =new_db

  default, dbfilename,'test_rad_db.fits'
  default, write_drm, 1
  default, drmfilename, 'test_drm.fits'


  pixel_mask = make_array(12, /byte, value=1b)
  detector_mask = make_array(32, /byte, value=1b)

  calibration_spectrum = stx_calibration_data_array(calibration_data, pixel_mask = pixel_mask , detector_mask = detector_mask )

  ;check if database already exits
  ;
  existing_db = loc_file(dbfilename, count = count)
  if (count GT 0)  and keyword_set(new_db) then message,'Database '+string(34B) + dbfilename + string(34B) + ' already exists. Call without new_db keyword to update exisiting file.'

  ;read in current database
  if (count GT 0) then db_str = stx_read_radiation_database(filename = dbfilename, /fulldb) else db_str =  stx_rad_database_str()
  ;db_str =  stx_rad_database_str()
  ;db_str.time = 1.

  rad_par = replicate(stx_rad_para(), 32, 12)

  ; start with current offset and gain estimates to conved ad channel to
  offset_gain =  stx_offset_gain_reader( 'offset_gain_table.csv')
  offset_gain = reform(offset_gain, 12, 32 )


  for idx_det = 0, 31 do begin
    if detector_mask[idx_det] eq 1 then begin
      for idx_pix = 0, 11 do begin
        if pixel_mask[idx_pix] eq 1 then begin

          gain = offset_gain[ idx_pix, idx_det].gain
          offset = offset_gain[ idx_pix, idx_det].offset
          energy = gain*(findgen(1024)*4. - offset)

          cal_line_str =  stx_fit_cal_lines_tail(reform(calibration_spectrum[*, idx_pix,idx_det ]),energy, parameters = current_params)

          rad_par[idx_det, idx_pix].det_nr = idx_det + 1
          rad_par[idx_det, idx_pix].pix_nr = idx_pix
          rad_par[idx_det, idx_pix].line_par = reform(current_params.toarray(),15)

        endif
      endfor
    endif
  endfor


  all_params = reform(rad_par.line_par, 15, 384)

  curr_dbase_str = stx_rad_database_str()
  curr_dbase_str.time =  stx_time2any(calibration_data.start_time)

  ;;check if already there
  repeated_time = where(curr_dbase_str.time eq db_str.time, count_times)
  if count_times eq 1 then db_str[repeated_time] = curr_dbase_str else begin
    db_str = [db_str,curr_dbase_str]
    ;;;check sort unique
    db_str = db_str[sort(db_str.time)]
  endelse

  ;write_new params to file
  mwrfits, db_str, dbfilename, /create

  if keyword_set(generate_new_drm) then begin

    drm =  stx_drm_from_database( srmfilename = drmfilename, pixel_mask=pixel_mask, detector_mask=detector_mask, parameters = all_params, $
      write = write_drm)

  endif



end
