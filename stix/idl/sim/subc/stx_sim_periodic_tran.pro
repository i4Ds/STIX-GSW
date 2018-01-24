;+
; :description:
;    This function calculates whether or not a photon is transmitted
;    through an arbitrarily orientated, spatially-periodic pattern.
;
; :params:
;    pos:      in, required, type="float"
;              [n, 2]-element array containing the [n, [X, Y]]
;              locations for n photons, measured in mm relative to
;              the centre of a predetermined STIX subcollimator.
;
;    slit_wd:  in, required, type="float"
;              subcollimator-specific grid slit width, in mm.
;
;    pitch:    in, required, type="float"
;              subcollimator-specific grid slit pitch (i.e., the
;              spatial period), in mm.
;
;    angle:    in, required, type="float"
;              subcollimator-specific grid slit orientation, measured
;              in degrees clockwise from detector up when viewed from
;              the Sun.
;
; :keywords:
;    cfl:  in, optional, type="bool", default="empty/false"
;          if set, this function adds half a pitch to the photon
;          signed X location. Only to be used for coarse flare locator
;          vertical pattern. This is required in order to shift the
;          photon location to be relative to the centre of a grid slat
;          rather than the centre of the STIX subcollimator, which is
;          coincident with the coarse flare locator slit centre.
;
; :returns:
;    True (1) if photon falls on a slit gap, false (0) if not.
;
; :errors:
;
;
; :history:
;    14-Jan-2013 - Shaun Bloomfield (TCD), created routine using lines
;                  from stx_sim_grid_tran.pro. Altered to use slats
;                  centred on subcollimator centre, with added shift
;                  for coarse flare locator subcollimator (defined as
;                  slit centred).
;    30-Apr-2013 - Shaun Bloomfield (TCD), vectorized photon handling
;    28-Jul-2014 - Shaun Bloomfield (TCD), lengths converted to mm
;    10-dec-2015 - Richard Schwartz gsfc, marginal computational efficiency
;                  gained in computing DIST, changed pos to xpos and ypos
;-
function stx_sim_periodic_tran, xpos, ypos, slit_wd, pitch, angle, $
                                cfl=cfl
  
  ;  Set optional keyword defaults
  cfl_shift = keyword_set( cfl ) ? pitch/2.d : 0.d
  
  ;  Determine width of grid slats
  slat_wd = pitch - slit_wd
  
  ;  When grid slit orientation is not parallel to STIX Y axis (i.e., 
  ;  avoiding a Y/X slope of infinity in the slit line equation)
  if ( ( angle mod 180 ) ne 0 ) then begin
     ;  Construct equation of line defining centre of central grid 
     ;  slat (location relative to centre of grid)
     ;    N.B. converts 'y = mx + arb.' to 'ax + by + c = 0', where 
     ;         'c' is the offset along the STIX Y axis of the slat 
     ;         centre from the subcollimator centre
     a = cos( angle * !dtor ) / sin( angle * !dtor )
     b = -1.d
     c =  0.d
     
     ;  Determine perpendicular distances of photons from slat centre
;     dist = abs( ( a * xpos ) + ( b * ypos ) + c ) / $
;            sqrt( ( a^2.d ) + ( b^2.d ) )
;    10-dec-2015, RAS, the following compute for dist saves about 4% over the previous
     r = sqrt( ( a^2.d ) + ( b^2.d ) )
     dist = c ne 0.0 ? abs( ( (a/r) * xpos ) + ( (b/r) * ypos ) + c/r ) : $
                       abs( ( (a/r) * xpos ) + ( (b/r) * ypos ) )
            
     
     ;  When grid slit/slat orientation is parallel to STIX Y axis 
     ;  the perpendicular distance is just the X position relative 
     ;  to grid centre
     ;    N.B. the coarse flare locator front grid pattern has the 
     ;         centre of a vertical slit coincident with the centre 
     ;         of the subcollimator, requiring a half pitch shift
  endif else dist = abs( xpos + cfl_shift )
  
  ;  Determine residual photon distances beyond integer number of
  ;  whole spatial grid periods
  d_mod = ( dist mod pitch )
;  
;  ;  Test if photons fall in whole slit gap between two half slats 
;  ;  in one spatial period (i.e., half slat, whole slit, half slat)
 
  ph_tran = ( d_mod gt ( slat_wd/2.d ) ) and $
            ( d_mod lt ( pitch - ( slat_wd/2.d ) ) )
  ;  Pass out photon transmission binary array
  return, ph_tran
  
end
