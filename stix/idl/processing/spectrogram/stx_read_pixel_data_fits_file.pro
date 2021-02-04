pro stx_read_pixel_data_fits_file, fits_path, time_shift, primary_header = primary_header, data_str = data, data_header = data_header, control_str = control, $
  control_header= control_header, energy_str = energy, energy_header = energy_header, t_axis = t_axis, e_axis = e_axis, energy_shift = energy_shift 

  default, time_shift, 0
  default, energy_shift, 0 
  
  !null = mrdfits(fits_path, 0, primary_header)
  control = mrdfits(fits_path, 1, control_header, /unsigned)
  data = mrdfits(fits_path, 2, data_header, /unsigned)
  energy = mrdfits(fits_path, 3, energy_header, /unsigned)


  hstart_time = (sxpar(primary_header, 'DATE_BEG'))

  ; create time object
  stx_time_obj = stx_time()
  stx_time_obj.value =  anytim(hstart_time , /mjd)
  start_time = stx_time_add(stx_time_obj, seconds = time_shift)
  t_edges = stx_time_add( start_time, $
    seconds = [0, total(data.timedel,/cum)] )

  t_axis = stx_construct_time_axis(t_edges)


  energies_used = where( control.energy_bin_mask eq 1 )


  e_axis = stx_construct_energy_axis(energy_edges = [(energy.e_low)[0],  energy.e_high] + energy_shift, select = energies_used )


end