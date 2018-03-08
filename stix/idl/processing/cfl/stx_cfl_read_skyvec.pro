;+
; :description:
;    This function creates an array of sky vectors from a look-up file
;    for the STIX coarse flare locator (CFL) to use in a dot-product
;    correlation calculation with a specific observation vector.
;
; :params:
;    fpath:  in, optional, type="string", default="$STX_CFL/stx_cfl_skyvec_table.txt"
;            full file path of CFL sky vector look-up file.
;
; :keywords:
;    sky_x:  out, optional, type="float", default=""
;            1D array of CFL sky vector sky X sampling in arcseconds
;            from STIX optical axis.
;
;    sky_y:  out, optional, type="float", default=""
;            1D array of CFL sky vector sky Y sampling in arcseconds
;            from STIX optical axis.
;
;
; :returns:
;    [nvectors, npixels] array of ideal case CFL sky vectors, where
;    nvectors is 1D representation of nsky_x*nsky_y individual sky
;    vectors and npixels corresponds to 12 flux values -- the 8 CFL
;    large pixels (normalized by their quadratic sum) and the average
;    Fourier subcollimator summed-pixel quadrants (normalized by their
;    quadratic sum).
;
; :errors:
;    If array of sky vectors is not created, this function returns the
;    following error codes:
;       -12 = look-up file not present,
;       -22 = either no sky X or Y sampling in look-up file,
;       -32 = incorrect number of sky vectors in look-up file.
;
; :history:
;    20-Jun-2013 - Shaun Bloomfield (TCD), created routine
;    11-Sep-2013 - Shaun Bloomfield (TCD), now uses environment
;                  variables for look-up file default locations
;    18-Dec-2017 - ECMD (Graz), added integer keyword for reading int formatted tables               
;
;-
function stx_cfl_read_skyvec, fpath, sky_x=sky_x, sky_y=sky_y, integer = integer

  ;  Set default file path location
  fpath = exist( fpath ) ? fpath : loc_file( 'stx_cfl_skyvec_table.txt', path = getenv('STX_CFL') )
  ;  Return error if look-up file does not exist
  if ~file_exist( fpath ) then return, -12
  
  ;  Read in sky vector sky X sampling from first line after 4 header
  ;  lines
  asc = rd_ascii( fpath, lines = [5] )
  ;  Return error if look-up file contains no sky X sampling
  if ( asc eq '' ) then return, -22
  
  ;  Split single string of subcollimator indices into numeric vector
  sky_x = str2number( strsplit( asc, ' ', /extract ) )
  ;  Determine number of sky X samples
  nx = n_elements( sky_x )
  
  ;  Read in sky vector sky Y sampling from first line after 8
  ;  previous lines (i.e., 4 header lines, the sky X sampling line,
  ;  and 3 header lines)
  asc = rd_ascii( fpath, lines = [9] )
  ;  Return error if look-up file contains no sky X sampling
  if ( asc eq '' ) then return, -22
  
  ;  Split single string of subcollimator indices into numeric vector
  sky_y = str2number( strsplit( asc, ' ', /extract ) )
  ;  Determine number of sky X samples
  ny = n_elements( sky_y )
  
  ;  Read in flux vectors from the large pixels and average Fourier
  ;  quadrants used to construct each sky vector. Starts from first
  ;  line after 12 previous lines (i.e., 4 header lines, the sky X
  ;  sampling line, 3 header lines, the sky Y sampling line, and 3
  ;  header lines)
  if keyword_set(integer) then readcol, fpath, lp1, lp2, lp3, lp4, lp5, lp6, lp7, lp8, q1, q2, q3, q4, $
    skipline = 12, count = nvec, /silent, $
    format = 'UL,UL,UL,UL,UL,UL,UL,UL,UL,UL,UL,UL' $
  else readcol, fpath, lp1, lp2, lp3, lp4, lp5, lp6, lp7, lp8, q1, q2, q3, q4, $
  skipline = 12, count = nvec, /silent, $
  format = 'D,D,D,D,D,D,D,D,D,D,D,D'
  
;  Return error if look-up file does not contain correct number of
;  vectors for given sky X and Y sampling
if ( nvec ne ( nx*ny )  ) then return, -32

;  Pass out [nvector, npixel] output array
return, [ [lp1], [lp2], [lp3], [lp4], [lp5], [lp6], [lp7], [lp8], [q1], [q2], [q3], [q4] ]

end
