;+
; :description:
;     This function creates array of structures with location of each simulated photon.
;     Photons are randomized according to defined shape of source and its intensity.
;
; :params:
;     sourcestruct  : in, required, type = "array of stx_sim_source structures"
;                     array containing parameters of simulated sources
;                     structures are defined by procedure stx_sim_source_structure.pro
;     sxpos         : in, optional, type = "float", default = "0."
;                     position of the centre of the Sun in relation to center of the field of view in arcsec (horizontal)
;     sypos         : in, optional, type = "float", default = "0."
;                     position of the centre of the Sun in relation to center of the field of view in arcsec (vertical)
;
; :Keywords:
;                      subc_str - subcollimator structure
;                      all_drm_factors - default, 1
;                      drm0 - response matrix without attenuator - see stx_build_drm
;                      drm1 - response matrix with attenuator
;                      seed - seed for random variables
;  :returns:
;     photontab : out, type = "array of stx_sim_photon structures"
;                 structures are defined by procedure stx_sim_photon_structure.pro
;                 array will contain all simulated source photons
;
;  :history:
;     29-Oct-2012 - Marek Steslicki (Wro), initial release
;     10-Feb-2013 - Marek Steslicki (Wro), size and position units
;                   of the sources changed to arcseconds
;     15-Oct-2013 - Shaun Bloomfield (TCD), modified to absorb some
;                   previous functionality of stx_sim_flare.pro
;     23-Oct-2013 - Shaun Bloomfield (TCD), source flux, position and
;                   geometry defined as that being viewed from 1 AU,
;                   with values altered to STIX viewpoint
;     25-Oct-2013 - Shaun Bloomfield (TCD), renamed subcollimator
;                   reading routine stx_construct_subcollimator.pro
;     01-Nov-2013 - Shaun Bloomfield (TCD), structure tags updated
;     06-Nov-2013 - Shaun Bloomfield (TCD), minor fix of data type
;                   preservation for photon numbers
;     28-Jul-2014 - Shaun Bloomfield (TCD), lengths converted to mm
;                   and areas to cm^2
;     30-Jul-2014 - Shaun & Laszlo, * using Richard's stx_random_sample_count_spectrum to pull energies
;     13-Nov-2014 - Shaun Bloomfield (TCD), modified to distribute
;                   photons over detectors rather than front grids
;     01-Dec-2014 - Shaun Bloomfield (TCD), minor efficiency tweaks
;     03-Dec-2014 - Shaun Bloomfield (TCD), added support for input
;                   32-element detector background multiplication
;                   factor that simulates (in another routine) over
;                   and under noisy detectors. Element values scale
;                   the detector areas into effective areas, with
;                   values of 0 indicating that a detector will not
;                   be treated. CURRENTLY NOT SWITCHED ON FOR PHOTON
;                   SOURCES (i.e., always simulates source photons
;                   in all subcollimators)
;     04-Dec-2014 - Shaun Bloomfield (TCD), photon energies are now
;                   drawn from the DRM-calculated count spectrum for
;                   photon sources with spectral form and parameters
;                   taken from the scenario files. Total number of
;                   events simulated is now in counts, because the
;                   photon-weighted DRM efficiency is now applied to
;                   reduce number of draws from total photon numbers
;     05-Dec-2014 - Shaun Bloomfield (TCD), removed use of background
;                   effective area multiplier array
;     17-Jun-2015 - ECMD (Graz),if neither drm0 or drm1 are passed an
;                   energy distribution assuming drm0 is created
;     19-feb-2016 - Rschwartz70@gmail.com, don't create a packet format structure for
;                   collecting the computation products as this has considerable overhead. Only
;                   collect the results into a stream format structure on output  Added seed
;     08-Feb-2017   Shane Maloney (TCD) Added thermal soucrce option and updated source parameters
;                   they are in order
;     25-Sep-2017 - ECMD (Graz), bugfix for position of point sources.
;     30-Oct-2019 - ECMD (Graz), sourcestruct.energy_spectrum_type can now be any components recognised by fit_model_components() e.g. 'f_bpow'
;                                if so parmameters are read as a string from energy_spectrum_param1 separated by '+' signs
;
; :todo:
;     30-jul-2014 - Shaun & Laszlo, * currently only allows power-law energy distributions
;                                   * add Be window shadowing
;-
function stx_sim_multisource_sourcestruct2photon, sourcestruct, sxpos, sypos, $
    subc_str=subc_str, all_drm_factors=all_drm_factors, $
    drm0=drm0, drm1=drm1, $
    seed = seed
  ;tic
  default, sxpos, 0.
  default, sypos, 0.
  default, subc_str, stx_construct_subcollimator()
  default, all_drm_factors, 1.
  default, ninterp, 1000000
  rsun=0.696342d  ; Solar radius [10^6 km]
  au=149.597871d  ; 1AU [10^6 km]
  fov=4.d         ; field of view [degrees]
  ssize=atan(rsun/(sourcestruct[*].distance*au))/!dtor/3600.d ; Solar radius in degrees/3600.0 (position and size of the source is given in arcseconds)
  nsources=n_elements(sourcestruct) ; number of defined sources
  
  ; TODO change to uniformly distribute over *ALL* at one time, so each
  ; subcollimator will not be guaranteed to have same number of photons
  
  ; determine number of counts to simulate from each source in each
  ; subcollimator
  ; uses time, photon flux at spacecraft [photons/cm^2/s], DRM
  ; photons-to-counts efficiency factor and detector active areas
  ;
  ; the following ensures that the number of counts is calculated
  ; from the source flux to be distributed in *all subcollimators*
  ncounts_subc = ceil( ( sourcestruct[*].duration * $
    ( sourcestruct[*].flux/(sourcestruct[*].distance^2.) ) * $
    all_drm_factors ) # $
    ( subc_str[*].det.area ), /l64 )
    
  ;
  ; number of counts from each source,
  ; cumulative sum over subcollimators
  ; N.B. padded with 0's before first
  ;      subcollimators, to be used in
  ;      subcollimator number assigning
  ncounts_subc_cumul = [ [lon64arr(nsources)], [total( ncounts_subc, 2, /cumulative, /preserve_type )] ]
  
  ; number of counts from each source,
  ; total over all subcollimators
  ncounts_src_tot = total( ncounts_subc, 2, /preserve_type )
  nph = ncounts_src_tot
  nph_barr = bytarr( nph )
  
  ;removed by nicky hochmuth 21.03.2016
  ;nph_arr  = 1.0 * nph_barr
  
  ; expand photon structure by total number of counts to be simulated
  ;counttab = stx_sim_photon_structure_flat( total( ncounts_src_tot ) )
  source_id = bytarr(nph)         ; $ source number
  source_sub_id = bytarr(nph)     ; $ source sub number
  ;time =  dblarr(nph)             ; $ time of photon arrival
  energy =  fltarr(nph)            ; $ photon energy [keV]
  x_loc =  fltarr(nph)             ; $ photon sky X location wrt. STIX optical axis [arcsec]
  y_loc =  fltarr(nph)             ; $ photon sky Y location wrt. STIX optical axis [arcsec]
  subc_d_n = bytarr(nph)         ; $ photon detector subcollimator number
  
  n=long64(0)
  ; loop over each source
  for i=0, nsources-1 do begin
    ; set photon spectrum type and parameters
    case strlowcase(sourcestruct[i].energy_spectrum_type) of
      'powerlaw': begin
        func_name  = 'f_pow'
        func_param = [sourcestruct.energy_spectrum_param1, sourcestruct.energy_spectrum_param2 ]
      end
      'thermal': begin
        func_name = 'f_vth'
        func_param = [sourcestruct.energy_spectrum_param1, sourcestruct.energy_spectrum_param2 ]
      end
      'uniform': begin
        func_name = 'stx_uniform_dstn'
        func_param = [sourcestruct.energy_spectrum_param1, sourcestruct.energy_spectrum_param2 ]
      end
      else: begin
        function_list = 'f_'+fit_model_components()
       func_idx=  where( sourcestruct[i].energy_spectrum_type eq function_list, nfoundfunc )
        if nfoundfunc eq 0 then begin
         print, 'Unknown type of source energy spectrum - defaulting to power-law with index of 5.0'
        func_name  = 'f_pow'
        func_param = [ 1., 5. ]
        endif else begin
          func_name =  sourcestruct[i].energy_spectrum_type
          func_param = float(strsplit(sourcestruct.energy_spectrum_param1,'+', /extract))
        endelse
        
      end
    endcase
    
    ;stx_random_sample_count_spectrum will construct drm0 or drm1
    if arg_present(drm0) then stx_random_sample_count_spectrum, ncounts_src_tot[i], $
      e_atten0=edist, drm0=drm0, func_name=func_name, func_param=func_param, ninterp = ninterp, seed=seed
    if arg_present(drm1) then stx_random_sample_count_spectrum, ncounts_src_tot[i], $
      e_atten1=edist, drm1=drm1, func_name=func_name, func_param=func_param, ninterp = ninterp, seed=seed
    if ~arg_present(drm0)and ~arg_present(drm1)  then stx_random_sample_count_spectrum, ncounts_src_tot[i], $
      e_atten0=edist, drm0=drm0, func_name=func_name, func_param=func_param, ninterp = ninterp, seed=seed
      
      
      
    ; assigning energy to photons
    energy[n] = edist
    
    ; set source (integer) name
    source_id[n] = sourcestruct[i].source_id + nph_barr
    source_sub_id[n] = sourcestruct[i].source_sub_id + nph_barr
    
    ; set detector subcollimator numbers (1->32) in batches
    ; of size ncounts_subc[i, j]
    ;   i.e., photon counters starting at ncounts_subc_cumul[i,j-1]
    ;         and ending at ncounts_subc_cumul[i,j]-1
    print, 'Computing energy distribution'
    ;toc
    
    
    ; set all photons from source to the source centroid location
    ; as seen by the spacecraft. N.B. pointing and source widths
    ; are defined as being viewed from 1 AU
    ;xloc and yloc are scalars, expanded to vectors after random(n)(u)
    xloc = (sourcestruct[i].xcen-sxpos) / sourcestruct[i].distance
    yloc = (sourcestruct[i].ycen-sypos) / sourcestruct[i].distance
    ;toc
    
    case strlowcase(sourcestruct[i].shape) of
      'point': begin
      end
      'gaussian': begin
        ; randomize Gaussian offsets from source
        ; centroid location in 'width' dimension
        ; N.B. source widths are defined as being
        ; viewed from 1 AU
        if sourcestruct[i].fwhm_wd gt 0.0 then begin
          random1 = randomn( seed, ncounts_src_tot[i] )
          
          dx =  random1 * $
            (sourcestruct[i].fwhm_wd / ( 2.*sqrt( 2.*alog(2.) ) ) / sourcestruct[i].distance)
        endif else dx = fltarr( ncounts_src_tot[i] )
        ; randomize Gaussian offsets from source
        ; centroid location in 'height' dimension
        ; N.B. source widths are defined as being
        ; viewed from 1 AU
        ;dy = randomn( seed3, ncounts_src_tot[i] ) * $
        if sourcestruct[i].fwhm_ht gt 0.0 then begin
          ;dy = reverse( rang ) * $
          random3 = reverse( random1 )
          dy = random3 * $
          
            (sourcestruct[i].fwhm_ht / ( 2.*sqrt( 2.*alog(2.) ) ) / sourcestruct[i].distance)
        endif else dy = fltarr( ncounts_src_tot[i] )
        
      end
      'loop-like': begin
        ; randomize Gaussian offsets from source
        ; centroid location in 'width' dimension
        ; N.B. source widths are defined as being
        ; viewed from 1 AU
        rang = randomn(seed, ncounts_src_tot[i] )
        dx = rang * $
          (sourcestruct[i].fwhm_wd / ( 2.*sqrt( 2.*alog(2.) ) ) / sourcestruct[i].distance)
        ; randomize Gaussian offsets from source
        ; centroid location in 'height' dimension,
        ; including progressively increasing shift
        ; to lower 'heights' for photon locations
        ; further away from the source centroid
        ; in the 'width' dimension
        ;    i.e., the source centroid relates to
        ;          the centre of the loop top
        ; N.B. source widths are defined as being
        ; viewed from 1 AU
        dy =  reverse( rang ) * $
          ( sourcestruct[i].fwhm_ht / ( 2.*sqrt( 2.*alog(2.) ) ) / sourcestruct[i].distance ) - $
          ( ( sourcestruct[i].loop_ht / sourcestruct[i].distance ) / $
          ( ( sourcestruct[i].fwhm_wd / ( 2.*sqrt( 2.*alog(2.) ) ) / sourcestruct[i].distance )^2. ) * $
          ( dx^2. ) )
      end
      else: begin
        print,"unknown source shape format, assumed to be point source"
      end
    endcase
    if keyword_set( dx ) or keyword_set( dy ) then begin
      ;This operation is the same and necessary for all diffuse sources
      ;rotate and position source relative to source location
      ; determine rotation matrix components
      sinus=sin(sourcestruct[i].phi*!dtor)
      cosinus=cos(sourcestruct[i].phi*!dtor)
      ; add (counter-clockwise) rotated location
      ; offsets onto the source central location
      x_loc[n] = xloc +  (dx*cosinus) - (dy*sinus)
      y_loc[n] = yloc +  (dx*sinus) + (dy*cosinus)
      
      
    endif else begin
    
      x_loc[n] = replicate(xloc, ncounts_src_tot[i])
      y_loc[n] = replicate(yloc, ncounts_src_tot[i])
      
    endelse
    
    n+=ncounts_src_tot[i]
  endfor
  print,'Building Source distribution
  ;toc
  ;  Calculate photon path tilt from STIX optical axis in units of
  ;  degrees (i.e., 3600 arcsec in 1 degree)
  ;    N.B. assumes that STIX is pointing at Sun centre
  theta = sqrt( ( x_loc* x_loc) + $
    ( y_loc* y_loc) ) / 3600.
    
  ;  Calculate photon source position angle in degrees. Positive
  ;  angle is measured clockwise from STIX positive y-axis when
  ;  viewed from the Sun
    
  omega = ( ( atan( - x_loc,  y_loc ) / !dtor ) + 360 ) mod 360
  
  ;  Randomize incident photon locations in mm relative to
  ;  currently undefined subcollimator centroids then add
  ;  subcollimator detector plane centroid locations (relative
  ;  to the STIX optical axis)
  
  ;print,'Computing photon path tilt and photon source position angle
  ;toc
  ;for j=1,32 do  subc_d_n[n+ncounts_subc_cumul[i,j-1]:n+ncounts_subc_cumul[i,j]-1] = j
  n = 0LL
  xpos = fltarr( ncounts_src_tot )
  ypos = xpos
  for i=0, nsources -1 do for j=1,32 do  begin
    ncounts = ncounts_subc_cumul[i,j] -ncounts_subc_cumul[i,j-1]
    subc_d_n[n] = j + bytarr( ncounts  )
    ;  ssd = replicate( {xsize:0.0,x_cen:0.0, ysize:0.0, y_cen:0.0}, 32 )
    ;  struct_assign, subc_str.det, ssd
    ;  ssd = ssd[subc_d_n-1]
    rseed5 = randomu( seed, ncounts ) - 0.5
    rseed6 = reverse( rseed5 ) ;randomu( seed6, ncounts ) - 0.5
    xpos[n] = ( rseed5 * subc_str[j-1].det.xsize ) +  subc_str[j-1].det.x_cen
    ypos[n] = ( rseed6 * subc_str[j-1].det.ysize ) +  subc_str[j-1].det.y_cen
    n += ncounts
  endfor
  ph_bag = $
    {energy: energy, $             ; photon energy in keV
    x_pos: xpos, y_pos: ypos, $    ; STIX front grid photon arrival X and Y position wrt. STIX optical axis [mm]
    subc_d_n:subc_d_n, $           ; detector sub-collimator number 1-32
    omega: omega, $                ; photon source position angle [degrees] measured CCW from STIX +Y-axis when viewed from Sun
    theta: theta, $                ; photon path tilt from STIX optical axis [degrees]
    pixel_n: source_sub_id * 0, $  ; pixel number (0-11) of detector interaction
    fplusr_path_length: xpos*0.0  }; path length through front and rear grid in mm
    
  ;   IDL> help, ph_bag
  ;   ** Structure <efebc10>, 8 tags, length=72847296, data length=72847296, refs=1:
  ;   ENERGY          FLOAT     Array[2698048]
  ;   X_POS           FLOAT     Array[2698048]
  ;   Y_POS           FLOAT     Array[2698048]
  ;   SUBC_D_N        BYTE      Array[2698048]
  ;   OMEGA           FLOAT     Array[2698048]
  ;   THETA           FLOAT     Array[2698048]
  ;   PIXEL_N         INT       Array[2698048]
  ;   FPLUSR_PATH_LENGTH   FLOAT     Array[2698048]
    
    
  return, ph_bag
end