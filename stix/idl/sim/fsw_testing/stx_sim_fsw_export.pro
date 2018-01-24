pro stx_sim_fsw_export, from_dir, to_dir
  full_dir = concat_dir(to_dir, time2file(trim(ut_time(/to_local)), /seconds))
  mk_dir, full_dir
  
  test_folders = file_search(concat_dir(from_dir, 'T*'), /test_directory)
  
  for folder_i = 0, n_elements(test_folders) - 1 do begin
    test_name = file_basename(test_folders[folder_i])
    dest_dir = concat_dir(full_dir, test_name)
    mk_dir, dest_dir 
    
    file_copy, concat_dir(test_folders[folder_i], ['*_combined_ql*.bin', '*_rotating_buffer.bin', 'stix_conf']), dest_dir, /overwrite, /recursive
    if(file_exist(concat_dir(test_folders[folder_i], 'calibration_spectrum_events.csv'))) then file_copy, concat_dir(test_folders[folder_i], 'calibration_spectrum_events.csv'), dest_dir, /overwrite

  endfor

end