pro stx_sim_fsw_copy_test, copy_from, copy_to, base_dir

  from_dir = concat_dir(base_dir, copy_from)
  to_dir = concat_dir(base_dir, copy_to)

  if(file_exist(to_dir)) then file_delete, to_dir, /recursive

  mk_dir, to_dir
  file_copy, concat_dir(from_dir, ['*_combined_ql*.bin', '*_rotating_buffer.bin', 'stix_conf']), to_dir, /overwrite, /recursive
  if(file_exist(concat_dir(from_dir, 'calibration_spectrum_events.csv'))) then file_copy, concat_dir(from_dir, 'calibration_spectrum_events.csv'), to_dir, /overwrite
  
  files = file_search(to_dir + '*', copy_from + '*')
  for fi = 0L, n_elements(files)-1 do file_move, files[fi], str_replace(files[fi], copy_from, copy_to), /overwrite
  
  openw, lun, concat_dir(to_dir, 'README.txt'), /get_lun
  printf, lun, 'This test is a 1:1 copy of ' + copy_from + '. The sequence folder data left out to save space.'
  free_lun, lun
end