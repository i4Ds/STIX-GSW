FUNCTION VIS_FWDFIT_PSO_SRC_BIFURCATE, srcstr0
  ;
  ; Returns a modified fwdfit source structure based on bifurcation of input source structure.
  ;
  ;  8-Nov-05   Original version (ghurford@ssl.berkeley.edu)
  ; 20-Nov-05 gh  Fix bug which reflected source positions about NS axis.
  ;  0-Dec-05 gh  Adapt to revised source structure array format
  ;  30-Oct-13 A.M.Massone   Removed hsi dependencies
  ;
  IF N_ELEMENTS(srcstr0) NE 1 THEN MESSAGE, 'Multielement source input is not yet permitted.'
  ;IF srcstr0.srctype NE 'ellipse' THEN MESSAGE, ' Input should be an ellipse'

  srcstr          = REPLICATE(srcstr0,2)      ; Create a 2-element structure array
  srcstr.srctype  = 'circle'
  srcstr.srcflux  = srcstr0.srcflux / 2.      ; Split the flux between components.
  srcstr.srcx     = srcstr.srcx               ; place new components symmetrically about the original
  srcstr.srcy     = srcstr.srcy
  srcstr.srcfwhm_max  = srcstr0.srcfwhm_max   ;Reproduces moment orthogonal to separation
  srcstr.srcfwhm_min  = srcstr0.srcfwhm_min
  srcstr.srcpa    = 0
  RETURN, srcstr
END