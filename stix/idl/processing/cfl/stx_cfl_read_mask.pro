;+
; :description:
;    This function creates a vector of subcollimator indices from a
;    look-up file for the STIX coarse flare locator (CFL) to use in
;    averaging over a certain sub-set of the 30 Fourier channels. 
;
; :params:
;    fpath:  in, optional, type="string", default="$STX_CFL/stx_cfl_subc_mask.txt"
;            full file path of subcollimator mask look-up file for use
;            by the CFL.
;
; :keywords:
;
; :returns:
;    Vector of subcollimator indices corresponding to a list of STIX
;    subcollimators to be used in averaging over a sub-set of the 30 
;    Fourier channels (in order to determine relative flux levels in 
;    typical detector quadrants).
;
; :errors:
;    If a vector of indices is not created, this function returns the
;    following error codes:
;       -11 = look-up file not present,
;       -21 = empty look-up file,
;       -31 = too many subcollimator indices in look-up file.
;
; :history:
;    20-Jun-2013 - Shaun Bloomfield (TCD), created routine
;    11-Sep-2013 - Shaun Bloomfield (TCD), now uses environment
;                  variables for look-up file default locations
;
;-
function stx_cfl_read_mask, fpath
  
  ;  Set default file path location
  fpath = exist( fpath ) ? fpath : loc_file( 'stx_cfl_subc_mask.txt', path = getenv('STX_CFL') )
  ;  Return error if look-up file does not exist
  if ~file_exist( fpath ) then return, -11
  
  ;  Read in subcollimator indices, should contain only 1 line after 
  ;  2 header lines
  asc = rd_ascii( fpath, lines = [3] )
  ;  Return error if look-up file contains no entries
  if ( asc eq '' ) then return, -21
  
  ;  Split single string of subcollimator indices into numeric vector
  ind = str2number( strsplit( asc, ' ', /extract ) )
  ;  Return error if look-up file contains > 30 entries
  if ( n_elements( ind ) gt 30 ) then return, -31
  
  ;  Pass out vector of subcollimator indices
  return, ind
  
end
