

;---------------------------------------------------------------------------
; Document name: stx_background_monitor
; Created by:    Richard Schwartz, 25-april-2013
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_background_monitor
;
; PURPOSE:
;       This function determines the background and spatially integrated solar flux (per cm2 sec) based
;       on the counts in the STIX background monitor detector pixels 
;
; CATEGORY:
;       helper methods
;
; CALLING SEQUENCE:
;
;       result = Stx_Background_Monitor( Input, Subc_Struct_Argument  )
;
; HISTORY:
;       25-Apr-2013 - Richard Schwartz
;       06-Nov-2013 - Shaun Bloomfield (TCD), modified for dimension
;                     ordering of new flat pixel_data structure input
;       28-Jul-2014 - Shaun Bloomfield (TCD), lengths converted to mm
;                     and areas to cm^2

;+
; :description:
;    For the background monitor the Caliste detector is not covered by grids. Instead, the front plate is open
;    and the rear deck is a solid plate with 6 apertures, each over one large Caliste pixel. Pixels 3 and 4 have no
;    apertures, 0 and 7 have identical large apertures (half circles joined by a rectangle), pixels 1 and 6 have the smallest
;    apertures, and pixels 2 and 5 have the larger circular apertures. The patterns have a double mirror image symmetry so that one
;    set of four pixels and apertures will see the Sun no matter the offset angle out to 1 degree East or West. The procedure first identifies
;    the row of pixels with the maximum counts and subsequently uses that for the remaining computations. For Version 1 we ignore issues of 
;    counter livetime. The LIVETIME that is passed should simply account for the lapsed seconds.  If LIVETIME isn't passed, the units will be
;    counts/cm2/time interval of the passed data.  
; :params:
;
;    input - pixel counter data for the background monitor dimensioned  Time, Energy, Pixel, type="float". 
;    this must an array with sets of 12 elements corresponding to the counts in the bkg subcollimator pixels.
;      If it isn't conforming, the routine will throw an error. This routine
;     assumes spectrogram binning for the pixel counter data and the calling program is responsible for providing that format. This is
;     a non-trivial requirement as the STIX data will not be binned uniformly in energy or time. The data will be interpreted in 12 pixel units.
;     There won't be any summing over groups of pixels. If that is required it must be handled outside of this routine. Alternate input
;     formats and analysis strategies will be deferred until future versions
; :keywords:
;   
;    
;    subc_str - Subcollimator structure, may pass either the full path file descriptor or the subcollimator structure itself
; :returns:
;    Returns a structure array of the same shape as the input,   {background: 0.0, direct: 0.0, units:'cm^(-2)'},
;    with one structure for each group of 12 background pixel values. Units are cnts/cm^2
;    
;            
;-
function stx_background_monitor, input, $
  subc_str = subc_str, $
  
  err_msg = err_msg, error=error

error = 0
err_msg = ''


px_size = size(/struc, input)
;Check shape requirments on input
Valid = (px_size.n_elements mod 12) eq 0
If not Valid then begin ;throw an error
  err_msg = 'Number of elements in Input must be divisible by 12 and for the bkgrnd det pixels.'
  Message, err_msg
  endif
;Takes the background monitor apertures (contained) and puts those together
;with the pixel specs into a more useful structure for our purposes in this routine

stx_geo = stx_background_monitor_geometry( subc_str )


;Analyze each set of 12 pixels individually
nsets = px_size.n_elements / 12
;pxl_data = reform( /overwrite, input, nsets, 12)
out = replicate(  {background: 0.0, direct: 0.0, units:'cm^(-2)'}, nsets)
;Examine the counts in the 12 pixels and return a direct (solar) and background count
for i = 0, nsets-1 do begin
  ;Find the maximum counts, in the top or bottom
;  pxl_set = pxl_data[i,*]
  pxl_set = input[*,i]
  top = total( pxl_set[0:3] ) gt total( pxl_set[4:7] )
  ix  = indgen(4)
  ix  = top ? ix : 7 - ix
  Y   = pxl_set[ix]
  ;Fit to a simple model,  count = pxl_area * B + aper_area * D
  ;In the future, we'll be finding highest rate below a threshold and using that with 
  ;blocked pixel to determine the Direct (Solar) and Background rates
  ; REGRESS fits the function:
  ;   Y[i] = Const + A[0]*X[0,i] + A[1]*X[1,i] + ... +
  ;                      A[Nterms-1]*X[Nterms-1,i]
  X = [reform( stx_geo.pxl_area[ix], 1,4), reform( stx_geo.aper_area[ix], 1, 4)]
  ;But we can't use pxl_area if there is no variation, that will throw NAN's so we pull that out of the Constant
  out[i].direct  = regress( X[1,*], Y, const = background_large_pixel)
  out[i].background = background_large_pixel / stx_geo.pxl_area[3]
  ;Direct is the flux in counts/mm^2 ;multiply by 1e2 to get counts/cm^2
  out.direct *= 1e2
  ;Background is the counts/mm^2 ;multiply by 1e2 to get counts/cm^2
  out.background *= 1e2
   endfor
return, out
end 



