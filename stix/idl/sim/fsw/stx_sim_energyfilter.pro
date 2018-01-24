;+
; :description:
;    This function filters an array of stx_sim_photon_structure using
;    the energy-dependent transmission probability of photons through
;    the STIX front and rear Tungsten grids planes using two uniform
;    random probability draws.
;
; :categories:
;    data simulation, photon simulation
;
; :params:
;    ph_list : in, required, type="structure"
;              an array of stx_sim_photon_structure
;              the grid path length may be in the ph_list as
;              tags "f_path_length" and "r_path_length" - prior to dec 2015
;              or in the new form "fplusr_path_length"
;
; :Keywords:
;    
;    energy - energy in keV, normal input is through ph_list field
;    if it is used much match the number of elements in ph_list.energy
;    seed; 
; :returns:
;    this function returns an array of stx_sim_photon_structure
;
; :examples:
;    e_filtered_ph_list = stx_sim_energyfilter( ph_list )
;
; :history:
;    06-Mar-2014 - Nicky Hochmuth (FHNW), initial commit from
;                  email sent by Shaun Bloomfield (TCD)
;    28-Oct-2014 - Shaun Bloomfield (TCD), fixed bug in conversion
;                  of lengths from microns to mm
;    28-Oct-2014 - Shaun Bloomfield (TCD), added header documentation
;    11-dec-2015 - Richard Schwartz, group front and rear together for joint probability
;                   interpolate the cross-sections for greater speed, trap for underflow/overflow on exp
;    22-feb-2016 - added seed for randomu as keyword input
;-
function stx_sim_energyfilter, ph_list, energy=energy, seed = seed  
  ;  Determine number of photons to test
  default, energy, 0.0
  if ~keyword_set( energy ) then energy = ph_list.energy
  nph = N_ELEMENTS(energy)
  if nph ne n_elements( ph_list.energy ) then message, 'Energy is not consistent with ph_list in number'
  
  
  ;  Calculate Total Absorption ('AB') linear attenuation coefficient 
  ;  (in cm^-1) for Tungsten (Z=74) at each photon energy (in keV)
  ; Interpolate because using xsec() is an expensive calculation and superfine granularity is unnecessary
  ei = exp( interpol( alog( [1.01, 200] ),2000))
  xei = xsec( ei, 74, 'ab')
  linco = interpol( xei, ei, energy ) 
  ;linco = xsec( ph_list.energy, 74, 'AB' ) 
  default, fplusr, 0
  fplusr = have_tag( ph_list, 'fplusr_path_length' ) ? ph_list.fplusr_path_length : fplusr
 
  if keyword_set( fplusr ) then begin
    lnprob = linco* 0.1 * fplusr ;interaction prob per cm so convert to cm
    tran_prob_thresh = lnprob * 0.0
    z = where( lnprob lt 50.0)
    tran_prob_thresh[z] = 1.0 / exp( lnprob[z] )
    ixph = where( tran_prob_thresh ge randomu( seed, nph) )
    return, ixph
  endif 
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Prior to Dec 2015 this was the computation for photon survival with f_path and r_path_length done
  ;separately.  As we're not reporting where the photon is stopped, this is wasteful, doubling the computation time
  ;  Calculate probability of front grid transmission, having 
  ;  converted mm path length into cm
  f_tran_prob_thresh = exp( -(linco)*(ph_list.f_path_length*1.E-01) )
  ;  Generate uniform random probabilities for testing front grid 
  ;  transmission
  f_rand_num1 = RANDOMU( seed, nph )

  ;  Calculate probability of front grid transmission, having 
  ;  converted mm path length into cm
  r_tran_prob_thresh = exp( -(linco)*(ph_list.r_path_length*1.E-01) )
  ;  Generate uniform random probabilities for testing rear grid 
  ;  transmission
  r_rand_num2 = RANDOMU( seed, nph )
    
  ;  Pass out array indices of photons that pass both the front and 
  ;  rear grid transmission tests
  return, where( (f_tran_prob_thresh ge f_rand_num1) and (r_tran_prob_thresh ge r_rand_num2) ) 
end
