function stx_sim_dss_read_calibration_bin, calibration_bin_file=calibration_bin_file, silent=silent
  default, silent, 0
  
  ; mapping between "straight-up" subcollimator numbering and "FPGA" order
  detector_mapping_old = [5,11,1,2,6,7,12,13,10,16,14,15,8,9,3,4,22,28,31,32,26,27,20,21,17,23,18,19,24,25,29,30] - 1
  detector_mapping = [1,2,6,7,5,11,12,13,14,15,10,16,8,9,3,4,31,32,26,27,22,28,20,21,18,19,17,23,24,25,29,30] - 1
  
  calibration_spectrum = stx_fsw_m_calibration_spectrum()
  
  reader = stx_bitstream_reader(filename=calibration_bin_file)
  
  while(reader->have_data()) do begin
    counter = reader->read(3, bits=32, debug=debug, silent=silent)
    spare = reader->read(2, bits=11, debug=debug, silent=silent)
    pixel = reader->read(1, bits=4, debug=debug, silent=silent)
    detector = reader->read(1, bits=5, debug=debug, silent=silent)
    energy_ad = reader->read(2, bits=12, debug=debug, silent=silent)
    spare = reader->read(3, bits=32, debug=debug, silent=silent)
    spare = reader->read(3, bits=32, debug=debug, silent=silent)
    
    energy_sc = ishft(energy_ad, -2)
    
    if(~silent) then print, counter, pixel, detector_mapping[detector], energy_ad, energy_sc, format='(i, i, i, i, i)'
    
    calibration_spectrum.accumulated_counts[energy_sc, pixel, detector_mapping[detector]]++
  endwhile
  
  if(~silent) then print, 'TOTAL: ', total(calibration_spectrum.accumulated_counts), format='(a, i)'
  
  return, calibration_spectrum
end