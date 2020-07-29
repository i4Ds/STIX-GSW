;+
; :description:
;
;    This procedure calculates the tailing due to incomplete charge collection.
;    This is then convolved with a detector energy loss matrix.
;
; :params:
;
;    eloss_mat     : in, required, type="float"
;                    energy loss matrix
;
;    photon_energy : in, required, type="float"
;                    input energy binning of energy loss matrix in keV
;
;    count_energy  : in, required, type="float"
;                    output energy binning of energy loss matrix in keV
;
;    depth         : in, required, type="float"
;                    depth of  detector in cm
;
; :keywords:
;
;    detector      : in, type = "string", default = 'cdte'
;                    type of detector, can be any accepted by det_xsec
;
;    trap_length_e : in, type= "float", default =  0.66/depth
;                    electron trapping length [cm] = electron mobility * electron lifetime  * electric field strength.
;                                                  = 1100 [cm2/V*s]    * 3x10-6 [s]         * (200 [V] /detector depth [cm])
;
;    trap_length_h : in, type= "float", default = 0.02/depth
;                    hole trapping length [cm] = hole mobility * hole lifetime  * electric field strength.
;                                              = 100 [cm2/V*s] * 1x10-6 [s]     * (200 [V] /detector depth [cm])
;
;    n_bins        : in, type="integer", default =  100000L
;                    number of bins to use for calculation of tailing spectrum
;
;    d_factor_kern : in, type= "float", default = 10
;                    reduction factor of pulse tailing kernel to speed convolution
;
;    window_max    : in, type= "float", default = 1/4
;                    the fraction of the full tailing spectrum at which the window to produce the
;                    convolution kernel should begin
;
;    window_min    : in, type= "float", default = 3/4
;                    the fraction of the full tailing spectrum at which the window to produce the
;                    convolution kernel should end
; :returns:
;
;   tailing_eloss_mat : the detector energy loss matrix convolved with the tailing spectra
;
; :examples:
;
;   tailing_str = stx_calc_pulse_tailing( eloss_mat, photon_energy, depth )
;
; :history:
;
;    22-Apr-2015 - ECMD (Graz), initial release
;    27-Jul-2020 - RAS  (GSFC), fixed spelling typos
;
;-
function stx_calc_pulse_tailing, eloss_mat, photon_energy, count_energy, depth, detector = detector, trap_length_e = trap_length_e, $
    trap_length_h = trap_length_h, n_bins = n_bins, d_factor_kern = d_factor_kern , $
    window_max = window_max, window_min = window_min
    
  default, trap_length_e , 1100.* 3d-6* 200. / depth
  default, trap_length_h,  100. * 1d-6* 200. / depth
  default, n_bins, 100000L
  default, detector, 'cdte'
  default, d_factor_kern, 10
  default, window_min, 1./4.
  default, window_max, 3./4.
  
  
  tailing_eloss_mat = fltarr(n_elements(count_energy), n_elements(photon_energy))
  
  ;make an array of distance values from 0 to the depth of the detector
  det_depth = findgen(n_bins)*depth/n_bins
  
  ;using the hecht equation calculate the charge collection efficiency for each distance
  etaxx = (trap_length_e/depth)*(1.0 - exp( -1.0*((depth - det_depth)/trap_length_e)) ) $
    + (trap_length_h/depth)*(1.0 - exp( -det_depth/trap_length_h ))
    
  ;make an array of efficiency values
  eff = findgen(n_bins)/n_bins
  
  ;find the distance at which the charge collection efficiency is maximum
  me = min(where(float(etaxx) eq max(float(etaxx))))
  
  ;find the index of the efficiency array closest to the value at x = 0
  dum =  min(abs(eff - etaxx[0]),  me0)
  ;find the index of the efficiency array closest to the value at x = d
  dum =  min(abs(eff - etaxx[-1]),  memi)
  ;find the index of the efficiency array closest to the maximum value of eta
  dum =  min(abs(eff - max(etaxx)), mema)
  
  ; if eta(x) is monotonic only one component is needed
  if  me lt 1  then begin
  
    ;get the array of efficiency values which correspond to the distances used
    eff0 = eff[memi:mema]
    
    ;calculate the inverse by interpolation
    inv0 = interpol(det_depth,etaxx,er0)
    
  endif else begin
    ; otherwise we must split the function about the maximum and calculate the inverse separately for each component
    eff1 = eff[me0:mema]
    eff2 = eff[memi:mema]
    
    ;calculate the inverse for each component by interpolation
    inv1 = interpol( det_depth[0:me-1], etaxx[0:me-1], eff1)
    inv2 = interpol( det_depth[me:-1], etaxx[me:-1], eff2)
    
  endelse
  
  
  ;get the linear attenuation coefficient at this photon energy for the given detector type
  lat = det_xsec(photon_energy, type='ab', detector = detector)
  
  for i_energy = 0L, n_elements(photon_energy)-1 do begin
  
  
    ;make an array for the total spectrum due to pulse tailing (i.e. both components if they are calculated)
    total_spectrum = fltarr(n_bins)
    if  me lt 1  then begin
      ;the total spectrum over this range is given by combining charge collection and photoelectric absorption
      total_spectrum[memi:mema] = lat[i_energy]*exp( -lat[i_energy]*inv0 )*deriv( er0, 1. - inv0 )
      
    endif else begin
    
      ;the total spectrum over the full range is given by combining charge collection and photoelectric absorption
      ;for each component over each range and them summing
      ;only calculate derivative if there are more than 3 points
      if mema - memi gt 3 then total_spectrum[memi:mema] = lat[i_energy]*exp( -lat[i_energy]*inv2 )*deriv( eff2, 1. - inv2 )
      if mema - me0 gt 3 then total_spectrum[me0:mema] = total_spectrum[me0:mema] + lat[i_energy]*exp( -lat[i_energy]*inv1 )*deriv( eff1, inv1 )
      
    endelse
    
    ;input efficiency bins and array
    tailing_spec = [total_spectrum, fltarr(n_bins)]
    
    
    ;get convolution kernel from full tailing matrix, usually a window centred around the middle of the array
    convol_kern = tailing_spec[long(n_elements(tailing_spec)*window_min):long(n_elements(tailing_spec)*window_max)]
    
    ;downsample tailing spectrum by given factor
    ckern = congrid(convol_kern,round(n_elements(convol_kern)/d_factor_kern))
    
    ;calculate new energy bins for upsampled energy loss matrix
    n_conv_eloss = round(1./(photon_energy[i_energy]*d_factor_kern*(eff[2]-eff[1]))*(max(photon_energy)- min(photon_energy)))
    conv_energy = dindgen(n_conv_eloss)*photon_energy[i_energy]*d_factor_kern*(eff[2]-eff[1]) + min(photon_energy)
    
    ;get the energy loss spectrum corresponding to the given photon energy
    eloss_spec = eloss_mat[ * , i_energy]
    
    ;upsample energy loss spectrum
    conv_eloss = interpol(eloss_spec, count_energy, conv_energy)
    
    ;normalise convolution kernel
    ckern /= total(ckern)
    
    pad =[fltarr(n_elements(ckern)), conv_eloss, fltarr(n_elements(ckern))]
    ;calculate the convolution
    padded_convol_spectrum = convol(pad,reverse(ckern))
    convolved_spectrum = padded_convol_spectrum[n_elements(ckern):(n_elements(ckern)+n_conv_eloss)-1]
    ;return output to initial energy binning
    tailing_eloss_mat[*,i_energy] = interpol(convolved_spectrum, conv_energy, count_energy)
  endfor
  
  return, tailing_eloss_mat
end
