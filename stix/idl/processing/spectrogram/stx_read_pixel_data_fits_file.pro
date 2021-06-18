pro stx_read_pixel_data_fits_file, fits_path, time_shift, primary_header = primary_header, data_str = data, data_header = data_header, control_str = control, $
  control_header= control_header, energy_str = energy, energy_header = energy_header, t_axis = t_axis, e_axis = e_axis, $
  energy_shift = energy_shift, use_discriminators = use_discriminators

  default, time_shift, 0
  default, energy_shift, 0
  default, use_discriminators, 1

  !null = mrdfits(fits_path, 0, primary_header)
  control = mrdfits(fits_path, 1, control_header, /unsigned)
  data = mrdfits(fits_path, 2, data_header, /unsigned)
  energy = mrdfits(fits_path, 3, energy_header, /unsigned)


  hstart_time = (sxpar(primary_header, 'DATE_BEG'))

  ; create time object
  stx_time_obj = stx_time()
  stx_time_obj.value =  anytim(hstart_time , /mjd)
  start_time = stx_time_add(stx_time_obj, seconds = time_shift)

 
  t_start = stx_time_add( start_time,  seconds = [ data.time - data.timedel/2.] )
  t_end = stx_time_add( start_time,  seconds = [ data.time + data.timedel/2.] )
  t_mean = stx_time_add( start_time,  seconds = [data.time] )

 
  t_axis  = stx_time_axis(n_elements(data.time))
  t_axis.mean =  t_mean
  t_axis.time_start = t_start
  t_axis.time_end = t_end
  t_axis.DURATION = data.timedel

  
  if control.energy_bin_mask[0] || control.energy_bin_mask[-1] and ~keyword_set(use_discriminators) then begin

    control.energy_bin_mask[0] = 0
    control.energy_bin_mask[-1] = 0
    data.counts[0,*,*,*] = 0.
    data.counts[-1,*,*,*] = 0.

    data.counts_err[0,*,*,*] = 0.
    data.counts_err[-1,*,*,*] = 0.

  endif

  energies_used = where( control.energy_bin_mask eq 1 , nenergies)
  energy_edges_2 = transpose([[energy[energies_used].e_low], [energy[energies_used].e_high]])
  edge_products, energy_edges_2, edges_1 = energy_edges_1

  energy_edges_all2 = transpose([[energy.e_low], [energy.e_high]])
  edge_products, energy_edges_all2, edges_1 = energy_edges_all1

  use_energies = where_arr(energy_edges_all1,energy_edges_1)
  energy_edge_mask = intarr(33)
  energy_edge_mask[use_energies] = 1

  e_axis = stx_construct_energy_axis(energy_edges = energy_edges_all1 + energy_shift, select = use_energies)


end