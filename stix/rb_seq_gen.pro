pro rb_seq_gen
  seq = replicate(stx_sim_detector_event(), 32);12L * 32L * 4096L)

  t0 = 0.5d
  td = 0.2d
  t = t0
  ctr = 0L

  root = concat_dir('C:\', 'Temp')
  seq_name = 'rb_address_det_test.dssevs'

  file_path = concat_dir(root, seq_name)

  seq.relative_time = t0 + dindgen(n_elements(seq), increment = td)

  for pi = 0L, 0 do begin
    for di = 0L, 31 do begin
      for acdi = 1151L, 1151 do begin
        seq[ctr].pixel_index = pi
        seq[ctr].detector_index = 31 - di + 1
        seq[ctr].energy_ad_channel = acdi
        ctr++
      endfor
    endfor
  endfor

  stop
  stx_sim_dss_events_writer, file_path, seq, constant=1850

end