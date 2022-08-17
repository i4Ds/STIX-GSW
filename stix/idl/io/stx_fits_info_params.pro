
function stx_fits_info_params, fits_path_data = fits_path_data, data_level = data_level, $
  distance = distance,  time_shift = time_shift, fits_path_bk = fits_path_bk, uid= uid, $
  generate_fits = generate_fits, specfile = specfile, srmfile = srmfile, elut_file = elut_file

  if n_elements(generate_fits) ne 0 then begin
    if generate_fits eq 0 and keyword_set(specfile) || keyword_set(srmfile) then begin
      message, 'FITS file generation has been set to 0 but an output filename has been specified.'
    endif
  endif

  background_subtracted = keyword_set(fits_path_bk)

  default, generate_fits, 1
  default, specfile, ''
  default, srmfile, ''
  default, elut_file, ''
  default, fits_path_bk, ''
  default, distance, 0.

  break_file, fits_path_data, disk, dir, data_file_name, ext
  fits_data_file = data_file_name + '.fits'
  if background_subtracted then begin
    break_file, fits_path_bk, disk, dir, bk_file_name, ext
    fits_background_file = bk_file_name + '.fits'
  end

  if specfile ne '' then begin
    break_file, specfile, disk, dir, sp_file_name, ext
    specfile = sp_file_name + '.fits'
  end

  if srmfile ne '' then begin
    break_file, srmfile, disk, dir, rm_file_name, ext
    srmfile = rm_file_name + '.fits'
  end


  stx_fits_info = {uid:uid, fits_data_file:fits_data_file, data_level:data_level, $
    distance:distance, time_shift:time_shift, grid_factor:0., $
    background_subtracted:background_subtracted, fits_background_file:fits_background_file, $
    generate_fits:generate_fits, specfile:specfile, srmfile:srmfile, elut_file:elut_file}

  return, stx_fits_info

end