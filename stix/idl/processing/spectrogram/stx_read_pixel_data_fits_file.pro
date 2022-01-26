pro stx_read_pixel_data_fits_file, fits_path, time_shift, alpha=alpha, primary_header = primary_header, data_str = data, data_header = data_header, control_str = control, $
  control_header= control_header, energy_str = energy, energy_header = energy_header, t_axis = t_axis, e_axis = e_axis, $
  energy_shift = energy_shift, use_discriminators = use_discriminators

  default, alpha, 0
  default, time_shift, 0
  default, energy_shift, 0
  default, use_discriminators, 1

  !null = stx_read_fits(fits_path, 0, primary_header,  mversion_full = mversion_full)
  control = stx_read_fits(fits_path, 'control', control_header, mversion_full = mversion_full)
  data = stx_read_fits(fits_path, 'data', data_header, mversion_full = mversion_full)
  energy = stx_read_fits(fits_path, 'energies', energy_header, mversion_full = mversion_full)


  hstart_time = (sxpar(primary_header, 'date_beg'))
  processing_level = (sxpar(primary_header, 'LEVEL'))
  if strcompress(processing_level,/remove_all) eq 'L1A' then alpha = 1

  ; create time object
  stx_time_obj = stx_time()
  stx_time_obj.value =  anytim(hstart_time , /mjd)
  start_time = stx_time_add(stx_time_obj, seconds = time_shift)

  if ~keyword_set(alpha) then begin
    t_start = stx_time_add( start_time,  seconds = [ data.time/10. - data.timedel/20.] )
    t_end = stx_time_add( start_time,  seconds = [ data.time/10. + data.timedel/20.] )
    t_mean = stx_time_add( start_time,  seconds = [data.time/10.] )
  endif else begin
    t_start = stx_time_add( start_time,  seconds = [ data.time - data.timedel/2.] )
    t_end = stx_time_add( start_time,  seconds = [ data.time + data.timedel/2.] )
    t_mean = stx_time_add( start_time,  seconds = [data.time] )
  endelse



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
  if ~keyword_set(alpha) then begin
    new_rcr =  fix((data.rcr).substring(-1))
   data =  rep_tag_value(data, new_rcr, 'RCR') 
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