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
;      Poisson statistics and can be shifted in energy by using gain_cf which is the offset/gain used to
;      generate the simulation
;    RECOVERED_FROM_TELEM - the recovered spectrum after decompression and degrouping. The recovered spectrum is only
;      defined (non-zero) on the bins included within the subspectra
; :Usage:
;   stx_bkg_sim_demo, $
;    configuration_struct, $
;      background_sim, $
;      recovered_from_telem, $
;      gain_cf = gain_cf
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
;    gain_cf
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
;-
pro stx_bkg_sim_demo, $
  configuration_struct, $
  background_sim, $
  recovered_from_telem, $
  gain_cf = gain_cf, $
  noplot = noplot, $
  x4 = x4, $
  line_factor = line_factor, $
  continuum_factor = continuum_factor, $
  hecht_par = hecht_par, $
  time_interval = time_interval, $
  spectrogram = spectrogram, $
  e_axis = e_axis, $
  edg2 = edg2,$
  ethresh = ethresh, $
  _extra = _extra

  default, noplot, 0
  default, x4, 0
  default, telem, 0
  default, line_factor, 1.0
  default, continuum_factor, 1.0
  default, time_interval, ['1-jan-2019','2-jan-2019']
  default, ethresh, 4.0 ; nothing below 4.0 keV



  configuration_struct = stx_bkg_ecal_spec_config()
  background_sim = stx_bkg_sim_spectrum( edg2, x4 = x4, /poisson, gain_cf = gain_cf, $
    time_interval = time_interval, $
    line_factor = line_factor, continuum_factor = continuum_factor, hecht_par = hecht_par, spectrogram = spectrogram_4096, _extra = _extra)

  if x4 then begin
    stx_bkg_sim_bld_subspectra, background_sim, edg2, configuration_struct

    stx_bkg_sim_rcvr_subspectra, configuration_struct, recovered_from_telem
    edg1 = get_edges( edg2, /edges_1 )
    z = where( edg1 gt ethresh, nz)
    edg1 = edg1[ z[0]:* ]
    background_sim = background_sim[ z[0]:* ]
    t_axis   = spectrogram_4096.t_axis
    e_axis = stx_construct_energy_axis( energy = edg1, $
      select = lindgen( n_elements( edg1 ) ) )
    data = reform( background_sim, n_elements( background_sim ), 1 )
    livetime = reform( data*0.0+1., n_elements(data), 1 )
    sp = stx_spectrogram( data, t_axis, e_axis, livetime )
    spectrogram = rep_tag_value( sp, double(sp.data),'data')

  endif
  if ~noplot then begin
    plot, background_sim
    if x4 then oplot, recovered_from_telem, psy=6
  endif
  
end