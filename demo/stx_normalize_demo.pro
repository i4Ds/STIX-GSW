
;+
; :Name:
;    STX_Normalize_Demo()
;       
; :Description:
;    This function simulates the count rate spectra in 32 data bins for each of
;    30 fourier sub-collimators on STIX. It includes random variations in the overall
;    Caliste efficiency as well as the possibility of some small variation in the efficiency vs energy
;
;    WP4100.1 Simulation tools for spectral response during flares
;    WP4100.2 Feed-back of real normalization differences into respective detector responses
;
;    Simulate spatially integrated spectral responses for typical flare spectra in the various rate control regimes.
;    Prepare and compare simulated flare spectra integrating over the full flare range. Estimate the flare intensities
;    needed to determine real differences in sub-collimator normalization. Provide feed-back of real normalization
;    differences into the respective detector responses.
;    
; :Examples:
;    IDL> out = stx_normalize_demo( normalize = 5000)
;    
;    IDL> help, out
;    ** Structure <21d01ed0>, 15 tags, length=10767840, data length=10767808, refs=1:
;    SIM_COUNTS      FLOAT     Array[32, 100, 4, 30]
;    EDG2            FLOAT     Array[2, 32]
;    SIM_DETVAR      FLOAT     Array[30, 600]
;    PH_EDG          FLOAT     Array[2, 600]
;    DRM0            STRUCT    -> <Anonymous> Array[1]
;    DRM1            STRUCT    -> <Anonymous> Array[1]
;    SEED_POI_IN     INT           -999
;    SEED_SCL_IN     INT           -999
;    SEED_COEF_IN    INT           -999
;    PLAW_EXP        FLOAT     Array[100]
;    TKEV            FLOAT     Array[100]
;    NTFLUX          FLOAT     Array[600, 100]
;    THFLUX          FLOAT     Array[600, 100]
;    NORMALIZE       INT           5000
;    README          STRING    Array[6]
;    
;       
; :Keywords:
;    PH_EDG  - photon energy edges for flux input. Demo will set these if left unset. Recommend to use program values.
;    should span 3-200 keV at a minimum
;    TH_FLUX_MODEL - thermal photon flux model for input. Defined for ph_edg. Demo will create an f_vth model. See 
;     demo output for example, should be dimensioned fltarr(600,100) for 100 temp variants. Only requirement
;     is 100 spectra with 600 photon energy bins. See out.thflux for further specification
;    NT_FLUX_MODEL - non thermal photon flux model for input. Defined for ph_edg. Demo will create an f_pow model. See
;     demo output for example, should be dimensioned fltarr(600,100) for 100 temp variants. Only requirement
;     is 100 spectra with 600 photon energy bins. See out.ntflux for further specification
;    
;    NORMALIZE - default is 1.  If non-zero the detector averaged total counts for each spectrum, thermal and non-thermal, are
;    normalized to this value. So there may be detector to detector variation (see sim_coef, sim_scl, sim_detvar) but the average of
;    all the detectors for a single spectral model will be set to NORMALIZE
;    SIM_COEF - default values are (0.5 -  randomu( seed_coef, nsc ) ) * 4e-6 where nsc is 30 sub-collimators
;     used to create a change in output response: ( 1.0 - sim_coef # ct_edgm^2 )
;    SIM_SCL  - induce a detector total efficiency change for each sc, default is random up to 5%
;               1.0 - (0.5 -  randomu( seed_scl, nsc ) ) * 0.10
;    
;    SIM_DETVAR - overall detector channel variation for each sub-collimator, variations induced on the input side of the
;    response equivalent to changing the detector efficiency. Therefore, the output channel detector to detector variations
;    will depend weakly on the input spectrum as well as the inherent detector variations.
;     
;    USE_POISSON - if set, generate Monte Carlo simulations using poidev
;    SEED_COEF - 
;    SEED_SCL
;    SEED_POI
;
;
; :Author: rschwartz70@gmail.com
; :History: 5-aug-2018, Written
;
function stx_normalize_demo, ph_edg = ph_edg, th_flux_model = th_flux_model, $
  nt_flux_model = nt_flux_model, $
  normalize = normalize, $
  use_poisson = use_poisson, $
  seed_coef = seed_coef_in, $
  seed_scl  = seed_scl_in, $
  seed_poi =  seed_poi_in, $
  sim_coef = sim_coef, sim_scl = sim_scl, sim_detvar = sim_detvar;, source_map = source_map
  ;if normalize is set, normalize all total counts for each spectrum to 1, or if normalize
  ;is gt 1, then normalize to NORMALIZE total counts
  nsc = 30 ;30 imaging sub-collimators
  if exist( seed_coef ) then seed_coef = seed_coef_in 
  if exist( seed_scl ) then seed_scl =   seed_scl_in
  if exist( seed_poi ) then seed_poi =   seed_poi_in
  
  default, sim_coef, (0.5 -  randomu( seed_coef, nsc ) ) * 4e-6
  default, sim_scl, 1.0 - (0.5 -  randomu( seed_scl, nsc ) ) * 0.10
  default, normalize, 1.0
  default, nt_flux_model, 0
  default, th_flux_model, 0
  default, use_poisson, 0

  edg=stx_science_energy_channels()
  if n_elements( ph_edg ) ge 2 then nflux = n_elements( get_edges( ph_edg, /mean) )
  default, nflux, 600
  default, ph_edg, findgen( nflux + 1) * 0.3 + 2.0
  ph_edgm = get_edges( ph_edg, /mean )
  ct_edgm = ph_edgm ;use photon edges for output edges
  dim_sim_detvar = size(/dimension, sim_detvar )
  ;sim_detvar may be input but it has to have the correct dimensions, lonarr( nsc, nflux)
  if ~same_data( long( dim_sim_detvar), long([nsc, nflux]) ) || $
    ~in_range( avg( sim_detvar, 1 ), [0.5, 1.5]) then $
    sim_detvar = reproduce(sim_scl, nflux) *  ( 1.0 - sim_coef # ph_edgm^2 )
  drm6 = stx_build_drm( ph_edg, ph_energy_edges = ph_edg, /atten)
  drm06 = stx_build_drm( ph_edg, ph_energy_edges = ph_edg, atten = 0)
  ;Create an array to receive the results for each sub-coll for both
  ;non-thermal and thermal. Each sub-coll has small variations in energy response
  ;and overall efficiency as real detectors may have.
  e600 = get_edges( ph_edg, /edges_2)
  e600m = get_edges( ph_edg, /mean )

  flux = fltarr( nflux, 100)
  g = interpol( [2, 8],100)
  if same_data( size(/dim, flux), size( /dim, nt_flux_model) ) then $
    flux = nt_flux_model else for i= 0, 99 do flux[ 0, i] = f_pow( e600, [1.0, g[i]] )

  thflux = flux
  tp = interpol( [1.,3.], 100)

  if same_data( size(/dim, thflux), size( /dim, th_flux_model) ) then $
    thflux = th_flux_model else for i= 0, 99 do thflux[0,i] = f_vth( e600, [1.,tp[i]])

  true_counts = fltarr( nflux, 100, 4, nsc)

  ; att0 & therm, att1 & therm, att0 & pflux, att1 & pflux
  for isc = 0, 29 do begin
    true_counts[ 0, 0, 0, isc ] = drm06.smatrix # (thflux * reproduce( reform( sim_detvar[isc,*]),100)) 
    true_counts[ 0, 0, 1, isc ] = drm6.smatrix # ( thflux * reproduce( reform( sim_detvar[isc,*]),100))
    true_counts[ 0, 0, 2, isc ] = drm06.smatrix # (  flux * reproduce( reform( sim_detvar[isc,*]),100)) 
    true_counts[ 0, 0, 3, isc ] = drm6.smatrix # (   flux * reproduce( reform( sim_detvar[isc,*]),100))
  endfor
  ; True_counts, 600 count bins, 100 spectral shape bins,
  ; 4 bins for thrm-att0, thrm-att1, pow-att0, pow-att1
  ; thermal range, 1-3 keV Temp, pl range 2-8 single powerlaw exponent
  ; 30 sub-collimator with randomized efficiency deviations
  Readme = [';  In out.sim_counts, 32 count bins, 100 spectral shape bins,', $
  '; 4 bins for thrm-att0, thrm-att1, pow-att0, pow-att1', $
  '; thermal range, 1-3 keV Temp, pl range 2-8 single powerlaw exponent', $
  '; 30 sub- with randomized efficiency deviations','Other functions may be exchanged for default spectra',$
  'using th_flux_model and nt_flux_model keywords, ie. nt for non-thermal']

  edg2=edg.edges_2
  wedg = get_edges( edg2, /width)
  edgm = get_edges( edg2, /mean)

  c32 = fltarr( 32, 100, 4, 30); counts in 32 channels, 100 count spectra for 4 spectrum/att state, 30 sub-coll
  if exist( seed_poi ) then c32 = poidev( c32, seed = seed_poi )


  ;Integral = INTERP2INTEG( Xlims, Xdata, Ydata)

  for k= 0, 29 do for j = 0, 3 do for i = 0, 99 do c32[ 0, i, j, k] = interp2integ( edg2, e600, true_counts[*, i, j,k] )

  if keyword_set( normalize ) then begin ;normalize the c32 output
    dim = size( c32, /dim)
    ttl = total( c32, 1 ) ;sum over channels then compute norm_factor
    attl = avg( ttl, 2 ) ;average across detectors because we're interested in average counts and deviations from them
    ;expand attl back to size of ttl
    ttl = rebin( attl, dim[1:3] )
    norm_factor = normalize / ttl
    norm_factor = rebin( reform( norm_factor, [1, dim[1:3] ] ), dim )
    c32 *= norm_factor
  endif
  if use_poisson then c32 = poidev( c32, seed = seed_poi )
  default, seed_poi_in, -999
  default, seed_scl_in, -999
  default, seed_coef_in, -999
  return, { sim_counts: c32, edg2: edg2, sim_detvar: sim_detvar, ph_edg: e600, drm0: drm06, drm1:drm6, $
    seed_poi_in: seed_poi_in, seed_scl_in: seed_scl_in, seed_coef_in: seed_coef_in, $
    plaw_exp: g, tkev: tp, ntflux: flux, thflux: thflux, normalize: normalize, readme: readme }
end
