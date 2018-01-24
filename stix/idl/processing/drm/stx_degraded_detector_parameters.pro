;+
; :description:
;
;    Simplistic estimates of change in parameters due to damage to the detector over the mission lifetime.
;    Estimates based on STIX-RP-0031-ETH_I2R2_-ProtonIrradiation 
;
; :categories:
;
;    calibration, background
;
; :params:
;
;    degrade_per : in, required,  type="float"
;                  Fraction of the mission lifetime that has passed 
;                  i.e. 0.0 = start of mission 1.0 = 100% expected total mission proton fluence
;
;
; :keywords:
;
;    line_factor      : out, type="float", default="1.0"
;                       the relative strength of the calibration lines 
;
;    continuum_factor : out, type="float", default="1.0"
;                       the relative strength of the background continuum 
;
;    trap_length_h    : out, type="float", default="(0.36 - 0.33*degrade_per )*1e4" 
;                       hole trapping length [micrometres]
;
;    trap_length_e    : out, type="float", default="2.4e5"
;                       electron trapping length [micrometres]
;
;    func_par         : out, type="float", default="1.0"
;                       electronic component of detector resolution FWHM (keV)
;
;    tail             : out, type="boolean", default="1"
;                       if set the effects of hole tailing will be included when calculating the DRM
;
;
; :examples:
;
;     stx_degraded_detector_parameters, 0.5, line_factor = line_factor, continuum_factor = continuum_factor, 
;     trap_length_h = trap_length_h, trap_length_e = trap_length_e, func_par = func_par
;
; :history:
;
;    28-Nov-2017 - ECMD (Graz), initial release
;
;-
pro stx_degraded_detector_parameters, degrade_per, line_factor = line_factor, continuum_factor = continuum_factor, 
  trap_length_h = trap_length_h, trap_length_e = trap_length_e, func_par = func_par, tail = tail


  line_factor = exp(-0.36*degrade_per)              ; line factor drops exponentially  from 1. at 0% to 0.7 at 100%
  continuum_factor = 1.                             ; continuum factor is constant at the default rate
  trap_length_h = (0.36 - 0.33*degrade_per )*1e4    ; mean free path for holes in micrometres drops linearly
  trap_length_e = 24*1e4                            ; mean free path for electrons in micrometres is constant at nominal value
  func_par = 1. + 4.0*degrade_per                   ; electronic component of detector resolution increases linearly form 1 keV at 0% to 5 keV at 100%
  tail = 1                                          ; the effects of hole tailing are important to include here


  stop
end

