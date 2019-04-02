;+
; :description:
;    This procedure recovers calibration spectra from a database of IDL save files and converts them to
;    stix telemetry format for use with the standard software. The data is from measurements performed in CEA-Saclay and
;    the sav files were prepared in CBK Wrocław.
;
; :categories:
;    calibration
;
; :keywords:
;
;    temp: temperature of the aluminium plate for desired test run
;
;    Peak_time: peaking time in us for test run
;
;    volt: applied voltage
;
;    src: calibration source used in test run
;
;    threshold: energy threshold in keV
;
;    plotting : plot the calibration
;
; :history:
;    1-Apr-2019 - ECMD (Graz), initial release based on CalisteSO_laboratory_spectrum_telemetry
;
;-
pro stx_ceafiles_2_tmtc_packets, temp = temp, Peak_time =Peak_time, Volt= Volt, src= src, threshold=threshold, plotting = plotting

  default, plotting, 0
  default, temp, [-40]
  default, peak_time, [2]
  default, volt, [300]
  default, src, ['Co57']
  default, threshold, [2]
  default, min_energy, 0
  default, max_energy, 300
  default, nbins, 1024
  default, offset, 0

  ;directory where the save files are stored
  dir_name = '/data/Caliste2TMpackets/Caliste-SO_data'

  used_in_flight = [33, 39, 54, 26, 27, 35, 48, 36, 41, 51, 56, 57, 59, 60, 76, 77, 79, 80, 82]

  found_files = file_search(dir_name,'*.sav')

  ;read the index file which contains the names and relevant test parameters for all sav flies
  data_files = read_csv(concat_dir(getenv('STX_DET'),'Caliste-SO_files_params.csv'))
  all_batch = data_files.field01
  all_temp =  data_files.field02
  all_duration = data_files.field03
  all_peak = data_files.field04
  all_volt = data_files.field05
  all_threshold = data_files.field07
  all_source =  data_files.field08

  ;loop through all test parameters
  for i_temp = 0, n_elements(temp)-1 do begin
    for i_peak = 0, n_elements(peak_time)-1 do begin
      for i_volt = 0, n_elements(volt) -1 do begin
        for i_src = 0,  n_elements(src) -1 do begin
          for i_threshold = 0,  n_elements(threshold) -1 do begin

            matching_file_idx =  where((all_temp eq temp[i_temp]) and (all_peak eq peak_time[i_peak]) and (all_volt eq volt[i_volt]) and (all_source eq src[i_src] ) and ( (all_threshold eq threshold[i_threshold] )))

            matching_file_names = dir_name +'/' +all_batch[matching_file_idx] +'_Alldata.sav'

            found_idx = where(matching_file_names[sort(matching_file_names)] eq found_files[sort(found_files)], nfiles)

            use_files = found_files[found_idx]

            name = strcompress('TMTC_ed_packet_T'+string(Temp[i_temp])+'_Peak'+string(Peak_time[i_peak])+'_Volt'+string(Volt[i_volt])+'_thresh'+string(fix(threshold[i_threshold]))+'_'+Src[i_src]+'.bin',/remove_all)

            for f = 0, nfiles-1 do begin

              stx_fsw_m_calibration_spectrum = stx_fsw_m_calibration_spectrum()
              tmtc_writer = stx_telemetry_writer(filename=name)

              print, use_files[f]
              restore, use_files[f]

              det_num = where(sn gt 0)

              ud = sn[det_num]
              print, ud[sort(ud)]
              counter = 0

              ;loop over detectors found in file
              for b = 0, n_elements(det_num)-1 do begin

                w = where(d1.asic eq det_num[b] and d1.multiplicity eq 1.)
                pixel = d1[w].pixel
                energy = (d1[w].energy)

                ;loop over pixels
                for a = 0,11 do begin

                  ;use histogram to convert energy vales to a calibration spectrum
                  h = histogram(energy[where(pixel eq a+1)], nbins = nbins-offset, min = min_energy, max = max_energy, locations = e_start)

                  if plotting then begin
                    plot, h, /ylog, yrange =  [1,1e4]
                    wait, 2
                  endif

                  stx_fsw_m_calibration_spectrum.accumulated_counts[offset:(nbins+offset-1),a,counter] = h
                endfor
                counter = counter + 1
              endfor

              ;set the telemetry parameters to get an array at the maxiumum resoultion
              calibration_subspectra = [[0,1,512],[512,1,512]]

              ;use the standard values for integer compression
              ql_calibration_spectrum_compression_counts = [0b,5b,3b]

              ;set the spectra and parameters in the telemetry writer object
              tmtc_writer->setdata, ql_calibration_spectrum=stx_fsw_m_calibration_spectrum, solo_packets = solo_packets, $
                compression_param_s = ql_calibration_spectrum_compression_counts[0], $
                compression_param_k = ql_calibration_spectrum_compression_counts[1], $
                compression_param_m = ql_calibration_spectrum_compression_counts[2], $
                subspectra_definition = calibration_subspectra

              ;flush data and close writer
              tmtc_writer->flushtofile
              destroy, tmtc_writer

            endfor

          endfor
        endfor
      endfor
    endfor
  endfor

end


