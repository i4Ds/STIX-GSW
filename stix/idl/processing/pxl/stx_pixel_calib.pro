;+
; :DESCRIPTION:
;   Perform basic e-pixel calibration according to the contents of the
;   pixel_e_bin_file, pixel_scale_file and pixel_slope_file look-up files
;
; :PARAMS:
;   pixel_data: in, required, type="structure"
;               full stx_pixel_data structure containing detected
;               counts as a function of time, energy, subcollimator
;               and pixel i.e. as .data[n_time, n_energy, n_subc, n_pixel]
;
; :KEYWORDS:
;   pixel_e_bin_file: in, optional, type="string", default="$SSW/so/stix/idl/processing/pxl/stx_pixel_e_bin.txt"
;                     This file contains the 'native' energy bins for
;                     each pixel
;
;   pixel_scale_file: in, optional, type="string", default="$SSW/so/stix/idl/processing/pxl/stx_pixel_scale.txt"
;                     This file contains a multiplicative scaling to
;                     be applied to each pixel count
;
;   pixel_slope_file: in, optional, type="string", default="$SSW/so/stix/idl/processing/pxl/stx_pixel_scale.txt"
;                     This file contains the slope of the linear pixel
;                     energy correction. The routine assumes
;                     that a pixel's energy response varies
;                     linearly with energy - this file contains the
;                     slope of the linear multiplicative correction
;                     required to compensate for the pixel's
;                     energy response 
;
; :RETURNS:
;   pixel_out: out, type="structure"
;
; :ERRORS:
;   -1 if no pixel_data parameter is supplied.
;
; :history:
;   13-Aug-2013 - Mel Byrne (TCD), created routine
;-

function stx_pixel_calib, pixel_data,                          $
                          pixel_e_bin_file = pixel_e_bin_file, $
                          pixel_scale_file = pixel_scale_file, $
                          pixel_slope_file = pixel_slope_file

; check that an input pixel_data parameter has been provided
  if n_params() ne 1 then begin
     print, 'ERROR: stx_pixel_calib(): pixel_data parameter not provided'
     return, -1
  endif

; Take a copy of the input data for subsequent operations
  pixel_out = pixel_data

; Apply the pixel energy bin interpolation, interpolating from pixel
; 'native' energy bins listed in the pixel_e_bin_file to nominal
; energy bins listed in the pixel_data.eaxis array
  pixel_out = stx_pixel_e_bin(pixel_out, filename=pixel_e_bin_file)

; Multiply each pixel count by the scaling factor read from the
; pixel_scale_file look-up file
  pixel_out = stx_pixel_scale(pixel_out, filename=pixel_scale_file)

; This routine assumes that pixel response varies linearly with
; energy. This routine applies a linear multiplicative correction to
; the pixel counts where the slope of the correction is read from
; pixel_slope_file
  pixel_out = stx_pixel_slope(pixel_out, filename=pixel_slope_file)

; If we've got this far, all is well
  return, pixel_out

end
