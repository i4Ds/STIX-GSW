;+
; :description:
;    This procedure reads in the calibration specutrum telemetry data, fits the Barium calibration lines using stx_cal_script
;    estimates the gain and offset from these fits and writes out the gain and offset and ad to science energy channel
;    conversion table for all detectors and pixels to csv files
;
; :categories:
;    fsw, calibration
;
; :params:
;
;    calibration_telemetry_filename  : in, required, type="string"
;                                      the name of the telemetry .bin file containing the calibration spectrum data
;
; :keywords:
;
;    offset_gain_filename            : in, required, type="string"
;                                      the name of the csv file to containing the gain and offset values for all pixels
;
;    science_energy_filename         : in, required, type="string"
;                                      the name of the csv file containing the gain and offset values for all pixels
;
; :examples:
;    stx_science_energy_2_csv, 'offset_gain_table.csv', filename =  'ad_energy_table'
;
; :history:
;
;    3-dec-2018 - ECMD (Graz), initial release
;
;-
pro stx_fsw_calibration_data_2_offset_gain, calibration_telemetry_filename, offset_gain_filename= offset_gain_filename,science_energy_filename=science_energy_filename
  default, calibration_telemetry_filename, '/Users/ewd/STIX-GSW-development/test_cali_tmtc.bin'

  default, pixel_mask, make_array(12, /byte, value=1b)
  default, detector_mask,  make_array(32, /byte, value=1b)
  default, offset_gain_filename, 'new_offset_gain_table.csv'
  default, science_energy_filename, 'new_ad_energy_table'

  tmtc_reader = stx_telemetry_reader(filename=calibration_telemetry_filename, /scan_mode)

  tmtc_reader->getdata, asw_ql_calibration_spectrum=calibration_spectra, solo_packets = solo_packets, statistics = statistics
  help, calibration_spectra

  ; get  current offset and gain estimates to for comparison
  offset_gain =  stx_offset_gain_reader( 'offset_gain_table.csv')
  offset_gain = reform(offset_gain, 12, 32 )

  ;convert telemetry format to array of [1024, 12, 32 ]  ([ad_channels, pixels, detectors])
  calibration_spectrum = stx_calibration_data_array(calibration_spectra, pixel_mask = pixel_mask , detector_mask = detector_mask )

  ;start with very rough defult values
  default_offset = 2000
  default_gain = 0.1

  ;the fitting will all be performed within OSPEX
  obj=ospex()

  ;data for file writer needs to be in a stx_offsetgain structure
  offset_gain_new  = replicate( stx_offsetgain(), 32,12 )

  ;generic time axis for the spectrogram
  time_axis = stx_construct_time_axis(  [0,86400.] )
  set_logenv, 'OSPEX_NOINTERACTIVE', '1'

  ;run through all detectors and pixels and fit the calibration data for each one using the stx_cal_script interface to OSPEX
  for idx_det = 0, 31 do begin
    if detector_mask[idx_det] eq 1 then begin
      for idx_pix = 0, 11 do begin
        if pixel_mask[idx_pix] eq 1 then begin

          ;use a default energy binning for input into OSPEX
          edg1 = default_gain*(findgen(1025)*4. - default_offset)

          e_axis = stx_construct_energy_axis( energy = edg1, $
            select = lindgen( n_elements( edg1 ) ) )

          ;get the full calibration spectrum for the current detector and pixel
          current_calibration_spectrum = reform(calibration_spectrum[*, idx_pix, idx_det], 1024, 1)

          ;set a default livetime of 1 for all channels
          livetime = reform( current_calibration_spectrum*0.0+1., 1024, 1 )

          ;insert data into stx spectrogram for passing into OSPEX
          sp = stx_spectrogram( current_calibration_spectrum, time_axis, e_axis, livetime )

          obj -> set, spex_data_source = 'SPEX_USER_DATA'
          ut = anytim( sp.t_axis.time_start.value) + [0,86400.]

          ;using similar OSPEX parameters as previous stx_cal_script
          fit_comp_params= [0.971807, 29.8638, 16.2872, 0.114519, 30.8512, 0.727227, $
            0.0215271, 35.1231, 0.777957, 0.0407576, 80.9584, 1.05361, 0.606173, 68.7680, 24.2684]
          fit_comp_minima= [0.100000, 28.0000, 3.00000, 0.0100000, 27.0000, 0.0100000, $
            0.00500000, 32.0000, 0.500000, 0.00500000, 72.0000, 0.500000, 0.200000, 64.0000, $
            0.0100000]
          fit_comp_maxima= [1e5, 37.0000, 30.0000, 1e5, 34.0000, 3.00000, 1e5, $
            38.0000, 3.00000, 1e5, 92.0000, 2.00000, 1e5, 70.0000, 40.0000]
          fit_comp_free_mask= [1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, $
            1B]

          ;make the erange a bit wider as it is uncertain exactly where the lines will be in the default energy binning
          spex_erange= [[22.799999D, 45.200001D], [65.199997D, 100.800003D]]
          obj-> set, fit_comp_spectrum= ['', '', '', '', '']
          obj-> set, fit_comp_model= ['', '', '', '', '']
          quiet =1
          ;pass the data to the OSPEX object
          obj->set, spectrum = sp.data, spex_ct_edges=sp.e_axis.edges_2, spex_ut_edges=ut, livetime=sp.ltime,errors = sqrt( sp.data)
          obj->set, spex_respinfo=1  , spex_area=1, spex_detectors='stix_'+strtrim(idx_det,2)+'_'+strtrim(idx_pix,2)

          ;run the calibration fitting script
          stx_cal_script, obj=obj, $
            fit_comp_params = fit_comp_params, fit_comp_minima = fit_comp_minima, $
            fit_comp_free_mask = fit_comp_free_mask,fit_comp_maxima=fit_comp_maxima, spex_erange= spex_erange, $
            _extra = _extra, quiet = quiet

          ; get the fit parameters out from the OSPEX object
          fit_params = obj->get(/spex_summ_params)
          fit_sigmas = obj->get(/spex_summ_sigma)
          fit_results = obj->get(/spex_summ)
          ebin = obj->get(/spex_summ_energy)

          edg1 = get_edges( ebin, /edges_1 )

          a = value_locate( edg1, fit_params[4])
          b = value_locate( edg1, fit_params[10])

          e1 =  ebin[*,a]
          e2 =  ebin[*,b]

          ;determine the gain and offset from the fit parameters
          gain =  (81. - 30.97)/(b-a)/4.
          offset = 4*a - 30.97/gain

          ;get the initial offset and gain for this detector and pixel as used in the data simultiomn
          input_gain = offset_gain[ idx_pix, idx_det].gain
          input_offset = offset_gain[ idx_pix, idx_det].offset

          ;calculate the percentage discrepancy between the simulation and fit offset and gain
          print, 'gain discrapancy',abs(input_gain-gain)/input_gain*100
          print, 'offset discrapancy', abs(input_offset-offset)/input_offset*100

          ;insert the fit values into the new offset gain for passing to the file writer
          offset_gain_new[idx_det, idx_pix].det_nr = idx_det + 1
          offset_gain_new[idx_det, idx_pix].pix_nr = idx_pix
          offset_gain_new[idx_det, idx_pix].offset = gain
          offset_gain_new[idx_det, idx_pix].gain =offset

        endif
      endfor
    endif
  endfor

  ;convert from 32 x 12 to 384 elements
  offset_gain_out = reform(offset_gain_new, 384)


  ;write out the offset gain data to a csv file
  stx_offset_gain_writer, offset_gain_new, filename = offset_gain_filename

  ;write out the science energy channel conversion table for the fit offset gain values
  stx_science_energy_2_csv, offset_gain_filename, filename =science_energy_filename

  stop
end

