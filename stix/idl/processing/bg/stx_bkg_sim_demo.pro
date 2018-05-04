;+
; :Description:
;    This demo illustrates some of the tool set for working with the
;    low-latency calibration data. The goal is to use these data to monitor temperature
;    drifts in calibration offset by fitting the line from the on board ba133 sources with
;    lines at 21 and 81 keV.
;    WP2100 – Simulation model of calibration line spectrum
;    Develop a simulation model of the background and calibration line spectrum at full 4096 channel
;    resolution with parameters flexible enough to accommodate the expected ranges.

;
; :Params:
;    CONFIGURATION_STRUCT - output, structure containing specification for breaking the calibration spectrum, model
;      or actual, into a series of segments, where the channels may be grouped and the counts
;      are compressed (stx_km_compress) - See stx_cal_spec_config.pro
;    BACKGROUND_SIM - output, simulated background spectrum for a STIX detector/pixel, MC generated with
;      Poisson statistics and can be shifted in energy by using og_str which is the offset/gain used to
;      generate the simulation
;    RECOVERED_FROM_TELEM - the recovered spectrum after decompression and degrouping. The recovered spectrum is only
;      defined (non-zero) on the bins included within the subspectra
; :Usage:
;   stx_bkg_sim_demo, $
;    configuration_struct, $
;      background_sim, $
;      recovered_from_telem, $
;      og_str = og_str
;
; :Examples:
;   stx_bkg_sim_demo, continuum_factor=2.
;   stx_bkg_sim_demo, continuum_factor=.8
;   stx_bkg_sim_demo, continuum_factor=.8,line_factor=2

;
; :Params:
;    configuration_struct
;    background_sim
;    recovered_from_telem
;
; :Keywords:
;    og_str
;    noplot
;    x4 - if set, then make spectrum on 4 channel groups, i.e. 1024 instead of 4096 adc channels
;    line_factor  - scaling factor for calibration line spectrum, default is 1.0, assumes value for 20 Bq for rad. dots
;    continuum_factor - scaling factor for background continuum based on Howard-Grimm model, default is 1.
;    hecht_par
;    telem
;    _extra
;
; :Author: richard.schwartz@nasa.gov, 22-jul-2016
; 28-jun-2017, added pass through parameters to control continuum and line separately
; 29-nov-2017, richard.schwartz@nasa.gov, added ethresh to avoid low energy issues
; 03-may-2018, richard.schwartz@nasa.gov, reorganize the code
;-
pro stx_bkg_sim_demo, $
  configuration_struct, $
  background_sim, $
  recovered_from_telem, $
  doffset_gain = doffset_gain, $
  noplot = noplot, $
  x4 = x4, $
  line_factor = line_factor, $
  continuum_factor = continuum_factor, $
  hecht_par = hecht_par, $
  time_interval = time_interval, $
  spectrogram = spectrogram, $
  dspectrogram = dspectrogram, $
  first_data_channel = first_data_channel, $
  e_axis = e_axis, $
  edg2 = edg2,$
  ch_axis = ch_axis, $
  ethresh = ethresh, $
  poisson = poisson, $
  _extra = _extra

  default, noplot, 0
  default, x4, 1
  default, telem, 0
  default, line_factor, 1.0
  default, continuum_factor, 1.0
  default, time_interval, ['1-jan-2019','2-jan-2019']
  default, ethresh, 2.1 ; nothing below 4.0 keV
  default, poisson, 1



  configuration_struct = stx_bkg_ecal_spec_config()
  ;Monte-Carlo the background spectrum with the calibration lines for the initial gain and offset
  background_sim = stx_bkg_sim_spectrum( edg2, x4 = x4, poisson = poisson,  $
    time_interval = time_interval, $
    line_factor = line_factor, continuum_factor = continuum_factor, hecht_par = hecht_par, $
    spectrogram = back_str, ch_axis = ch_axis, _extra = _extra)
   ;Monte-Carlo the background spectrum with the calibration lines for the deviated gain and offset 
  dbackground_sim = stx_bkg_sim_spectrum( edg2, x4 = x4, poisson = poisson,  $
    time_interval = time_interval, $
    doffset_gain = doffset_gain, $
    line_factor = line_factor, continuum_factor = continuum_factor, hecht_par = hecht_par, $
    spectrogram = dback_str, ch_axis = ch_axis, _extra = _extra)
  ;take the simulated spectrum compressed by summing over 4 channels to have an effective 1024 0.4 keV channels
  
  if x4 then begin
    ;simulate the telemetry compression and decompression and generate the final simulated spectra
    ;in the back_str structure and the deviated one in dback_str
    stx_cal_spec_telem, back_str, configuration_struct, spectrogram
    stx_cal_spec_telem, dback_str, configuration_struct, dspectrogram
  endif else begin
    spectrogram = spectrogram_4096
    dspectrogram = dspectrogram_4096
  endelse

end