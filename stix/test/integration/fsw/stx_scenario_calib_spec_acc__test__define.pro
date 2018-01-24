;+
; :file_comments:
;   This is a test class for scenario-based testing; specifically the calibration spectrum accumulation test
;
; :categories:
;   data simulation, flight software simulator, software, testing
;
; :examples:
;   iut_test_runner('stx_scenario_calib_spec_acc__test', keep_detector_eventlist=0b, show_fsw_plots=0b)
;   iut_test_runner('stx_scenario_calib_spec_acc__test')
;
; :history:
;   05-Feb-2015 - Laszlo I. Etesi (FHNW), initial release
;   20-Jan-2015 - Aidan O'Flannagain (TCD), added following tests:
;       test_average_flux_basic
;       test_average_flux_broad
;       test_average_flux_lowflux
;   22-Mar-2015 - Aidan O'Flannagain (TCD), tests now only run on imaging detectors
;   25-Apr-2016 - ECMD (Graz), - calibration energy bins now pixel and detector dependent based on gain-offset table
;                              - now using the energy corresponding maximum count value for each calibration spectrum
;                                as the estimate for the source peak energy value
;   28-Sep-2016 - ECMD (Graz), minor bugfix                      
;
;-

;+
; :description:
;    this function initializes this module; make sure to adjust the variables "self.test_name" and "self.test_type";
;    they will control, where in $STX_SCN_TEST to look for this test's scenario and configuration files
;    (e.g. $STX_SCN_TEST/basic/calib_spec_acc)
;
; :keywords:
;   extra : in, optional
;     extra parameters interpreted by the base class (see stx_scenario_test__define)
;
; :returns:
;   this function returns true or false, depending on the success of initializing this object
;-
function stx_scenario_calib_spec_acc__test::init, _extra=extra
  self.test_name = 'calib_spec_acc'
  self.test_type = 'basic'
  ;
  return, self->stx_scenario_test::init(_extra=extra)
end


;+
; :description:
;   this will check if the average flux above a threshold in each pixel is within 2 keV of the expected
;   value of 31 keV. The test is only passed if every individual pixel passes. This test is run on the
;   detectors which include the basic source, which are [1a,1b,1c,2a,2b,2c,3a,3b,3c]. These detectors
;   correspond to index numbers of [0,6,10,11,12,16,17,18,28].
;-
pro stx_scenario_calib_spec_acc__test::test_average_flux_basic
  ;extract relevant parameters for the test verification

  self.fsw->getproperty, stx_fsw_ql_spectra=spectrum, stx_fsw_m_calibration_spectrum=calib, /complete, /combine
  
  offset_gain = reform( stx_offset_gain_reader( ), 12, 32 )
  calib_ad_channel = fix(4.*findgen(1024))
  
  ;select the detectors to be used for this test
  idx_det_use = [0,6,10,11,12,16,17,18,28]
  
  ;get the number of detectors and the number of spectra
  ndet = n_elements(idx_det_use)
  ncal = ndet*12L
  
  cal_en_per = rebin(reform(rebin(reform(calib_ad_channel, 1024, 1), 1024, 12), 1024, 12, 1), 1024, 12, ndet)
  energy_found = fltarr(ncal)
  
  ;calculate the gains and offsets for the pixels and detectors used in this test
  gain = offset_gain[ *, idx_det_use].gain
  offset = offset_gain[ *, idx_det_use].offset
  gain = rebin( reform( gain, 1,12,9 ), 1024, 12, ndet)
  offset = rebin( reform( offset, 1,12,9 ), 1024, 12, ndet)
  
  ;extract the measured counts for all the relevant calibration spectra
  cal_spec = calib.accumulated_counts[*,*,idx_det_use]
  cal_spec = reform(cal_spec, 1024, ncal)
  
  ;calculate the array of energy bins for each pixel and detector
  energy = (cal_en_per - offset) * gain
  energy = reform(energy, 1024, ncal)
  
  ;start the error messages for zero and multiple maxima as empty strings
  medlist  = ''
  nomaxstr = ''
  
  ;loop over all calibration spectra finding all points where the spectrum is at its maximum value
  ;the energy bin this corresponds to for that detector and pixel  will be compared to the peak energy of the calibration source
  for i =0, ncal-1 do begin
    maxspec = where(cal_spec[*,i] eq max(cal_spec[*,i]), nmax)
    case nmax of
      0:  begin
        energy_found[i]  = 0
        nomaxstr += '(Pixel: ' + strtrim(i mod 12, 2) + ', Detector: '+  strtrim( idx_det_use[fix(i/12)], 2 ) + '), '
      end
      1:   energy_found[i] = energy[maxspec,i]
      else: begin
        energy_found[i]=  energy[median(maxspec),i]
        medlist += '(Pixel: ' + strtrim(i mod 12, 2) + ', Detector: '+  strtrim( idx_det_use[fix(i/12)], 2 ) + '), '
      endelse
    endcase
  endfor
  
  ;if there were spectra where the median was used to calculate the peak energy construct the error message
  if strlen(medlist) gt 0  then begin
    medlist ='Median taken of spectra with multiple points at maximumum value: ' + medlist
    medlist = strmid(medlist, 0, strlen(medlist) - 2) + '.'
  endif
  
  ;if there were spectra where a peak energy could not be found construct the error message
  if strlen(nomaxstr) gt 0  then begin
    nomaxstr ='Spectra without maximumum value: ' + nomaxstr
    nomaxstr = strmid(nomaxstr, 0, strlen(nomaxstr) - 2) + '. '
  endif
  
  ;calculate the number of pixels which 'pass', defined by having a spectrum mean within 2 keV of 31 keV
  where_pass = where( abs(energy_found - 31.) le 2, num_pass)
  
  
  mess = 'Basic 31 keV source only resolved in' + strcompress(num_pass) + $
    ' /' + strtrim(ncal,2) + ' pixels.' + nomaxstr + medlist
  assert_equals, ncal, num_pass, mess
end

;+
; :description:
;   this will check if the average flux above a threshold in each pixel is within 2 keV of the expected
;   value of 31 keV. The test is only passed if every individual pixel passes. This test is run on the
;   detectors which include a source at half the flux of the basic source, which are
;   [4a,4b,4c,5a,5b,5c,6a,6b,6c]. These detectors correspond to index numbers of [1,4,5,14,22,24,26,29,30].
;-
pro stx_scenario_calib_spec_acc__test::test_average_flux_lowflux
  ;extract relevant parameters for the test verification
  self.fsw->getproperty, stx_fsw_ql_spectra=spectrum, stx_fsw_m_calibration_spectrum=calib, /complete, /combine
  
  offset_gain = reform( stx_offset_gain_reader( ), 12, 32 )
  calib_ad_channel = fix(4.*findgen(1024))
  
  ;select the detectors to be used for this test
  idx_det_use = [1,4,5,14,22,24,26,29,30]
  
  ;get the number of detectors and the number of spectra
  ndet = n_elements(idx_det_use)
  ncal = ndet*12L
  
  cal_en_per = rebin(reform(rebin(reform(calib_ad_channel, 1024, 1), 1024, 12), 1024, 12, 1), 1024, 12, ndet)
  energy_found = fltarr(ncal)
  
  ;calculate the gains and offsets for the pixels and detectors used in this test
  gain = offset_gain[ *, idx_det_use].gain
  offset = offset_gain[ *, idx_det_use].offset
  gain = rebin( reform( gain, 1,12,9 ), 1024, 12, ndet)
  offset = rebin( reform( offset, 1,12,9 ), 1024, 12, ndet)
  
  ;extract the measured counts for all the relevant calibration spectra
  cal_spec = calib.accumulated_counts[*,*,idx_det_use]
  cal_spec = reform(cal_spec, 1024, ncal)
  
  ;calculate the array of energy bins for each pixel and detector
  energy = (cal_en_per - offset) * gain
  energy = reform(energy, 1024, ncal)
  
  ;start the error messages for zero and multiple maxima as empty strings
  medlist  = ''
  nomaxstr = ''
  
  ;loop over all calibration spectra finding all points where the spectrum is at its maximum value
  ;the energy bin this corresponds to for that detector and pixel  will be compared to the peak energy of the calibration source
  for i = 0, ncal-1 do begin
    maxspec = where(cal_spec[*,i] eq max(cal_spec[*,i]), nmax)
    case nmax of
      0:  begin
        energy_found[i]  = 0
        nomaxstr += '(Pixel: ' + strtrim(i mod 12, 2) + ', Detector: '+  strtrim( idx_det_use[fix(i/12)], 2 ) + '), '
      end
      1:   energy_found[i] = energy[maxspec,i]
      else: begin
        energy_found[i]=  energy[median(maxspec),i]
        medlist += '(Pixel: ' + strtrim(i mod 12, 2) + ', Detector: '+  strtrim( idx_det_use[fix(i/12)], 2 ) + '), '
      endelse
    endcase
  endfor
  
  ;if there were spectra where the median was used to calculate the peak energy construct the error message
  if strlen(medlist) gt 0  then begin
    medlist ='Median taken of spectra with multiple points at maximumum value: '+medlist
    medlist = strmid(medlist, 0, strlen(medlist) - 2) + '.'
  endif
  
  ;if there were spectra where a peak energy could not be found construct the error message
  if strlen(nomaxstr) gt 0  then begin
    nomaxstr ='Spectra without maximumum value: ' + nomaxstr
    nomaxstr = strmid(nomaxstr, 0, strlen(nomaxstr) - 2) + '. '
  endif
  
  ;calculate the number of pixels which 'pass', defined by having a spectrum mean within 2 keV of 31 keV
  where_pass = where( abs(energy_found - 31.) le 2, num_pass)
  
  mess = 'Basic 31 keV source only resolved in' + strcompress(num_pass) + $
    ' /' + strtrim(ncal,2) + ' pixels.' + nomaxstr + medlist
  assert_equals, ncal, num_pass, mess
end

;+
; :description:
;   this will check if the average flux above a threshold in each pixel is within 2 keV of the expected
;   value of 31 keV. The test is only passed if every individual pixel passes. This test is run on the
;   detectors which include a source that is the sum of one source with 4X the FWHM of the basic source
;   and 0.667X the flux, and another with the same FWHM and 0.333X the flux, which are
;   [4a,4b,4c,5a,5b,5c,6a,6b,6c]. These detectors correspond to index numbers of [3,7,13,15,20,23,25,27,31].
;-
pro stx_scenario_calib_spec_acc__test::test_average_flux_broad
  ;extract relevant parameters for the test verification
  self.fsw->getproperty, stx_fsw_ql_spectra=spectrum, stx_fsw_m_calibration_spectrum=calib, /complete, /combine
  
  offset_gain = reform( stx_offset_gain_reader( ), 12, 32 )
  calib_ad_channel = fix(4.*findgen(1024))
  
  ;select the detectors to be used for this test
  idx_det_use = [3,7,13,15,20,23,25,27,31]
  
  ;get the number of detectors and the number of spectra
  ndet = n_elements(idx_det_use)
  ncal = ndet*12L
  
  cal_en_per = rebin(reform(rebin(reform(calib_ad_channel, 1024, 1), 1024, 12), 1024, 12, 1), 1024, 12, ndet)
  energy_found = fltarr(ncal)
  
  ;calculate the gains and offsets for the pixels and detectors used in this test
  gain = offset_gain[ *, idx_det_use].gain
  offset = offset_gain[ *, idx_det_use].offset
  gain = rebin( reform( gain, 1,12,9 ), 1024, 12, ndet)
  offset = rebin( reform( offset, 1,12,9 ), 1024, 12, ndet)
  
  ;extract the measured counts for all the relevant calibration spectra
  cal_spec = calib.accumulated_counts[*,*,idx_det_use]
  cal_spec = reform(cal_spec, 1024, ncal)
  
  ;calculate the array of energy bins for each pixel and detector
  energy = (cal_en_per - offset) * gain
  energy = reform(energy, 1024, ncal)
  
  ;start the error messages for zero and multiple maxima as empty strings
  medlist  = ''
  nomaxstr = ''
  
  ;loop over all calibration spectra finding all points where the spectrum is at its maximum value
  ;the energy bin this corresponds to for that detector and pixel  will be compared to the peak energy of the calibration source
  for i = 0, ncal-1 do begin
    maxspec = where(cal_spec[*,i] eq max(cal_spec[*,i]), nmax)
    case nmax of
      0:  begin
        energy_found[i]  = 0
        nomaxstr += '(Pixel: ' + strtrim(i mod 12, 2) + ', Detector: '+  strtrim( idx_det_use[fix(i/12)], 2 ) + '), '
      end
      1:   energy_found[i] = energy[maxspec,i]
      else: begin
        energy_found[i]=  energy[median(maxspec),i]
        medlist += '(Pixel: ' + strtrim(i mod 12, 2) + ', Detector: '+  strtrim( idx_det_use[fix(i/12)], 2 ) + '), '
      endelse
    endcase
  endfor
  
  ;if there were spectra where the median was used to calculate the peak energy construct the error message
  if strlen(medlist) gt 0  then begin
    medlist ='Median taken of spectra with multiple points at maximumum value: ' + medlist
    medlist = strmid(medlist, 0, strlen(medlist) - 2) + '.'
  endif
  
  ;if there were spectra where a peak energy could not be found construct the error message
  if strlen(nomaxstr) gt 0  then begin
    nomaxstr ='Spectra without maximumum value: ' + nomaxstr
    nomaxstr = strmid(nomaxstr, 0, strlen(nomaxstr) - 2) + '. '
  endif
  
  ;calculate the number of pixels which 'pass', defined by having a spectrum mean within 2 keV of 31 keV
  where_pass = where( abs(energy_found - 31.) le 2, num_pass)
  
  mess = 'Basic 31 keV source only resolved in' + strcompress(num_pass) + $
    ' /' + strtrim(ncal,2) + ' pixels.' + nomaxstr + medlist
  assert_equals, ncal, num_pass, mess
end

pro stx_scenario_calib_spec_acc__test__define
  compile_opt idl2, hidden
  
  void = { $
    stx_scenario_calib_spec_acc__test, $
    inherits stx_scenario_test }
end

