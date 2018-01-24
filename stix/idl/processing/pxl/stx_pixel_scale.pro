;+
; :description:
;   Multiply each pixel count by the multiplicative scaling factor
;   read from the stx_pixel_scale.txt look-up file
;
; :params:
;   pixel_data: in, required, type="structure"
;               full stx_pixel_data structure containing detected
;               counts as a function of time, energy, subcollimator
;               and pixel i.e. as .data[n_time, n_energy, n_subc,
;               n_pixel] 
;
; :keywords:
;   filename: in, optional, type="string"
;             Path/name of file containing pixel scale look-up
;             data. If not supplied, the stx_pixel_read_scale()
;             routine locates and reads a default path/name look-up
;             file
;
; :returns:
;   pixel_out: a copy of the input pixel_data structure with each
;              pixel count multiplied by the multiplicative factor
;              read from the pixel scaling look-up file
;
; :errors:
;   Returns -1 if no pixel_data supplied as an input parameter
;
; :history:
;   13-Aug-2013 - Mel Byrne (TCD), created routine
;-

function stx_pixel_scale, pixel_data, filename = filename

  if n_params() ne 1 then begin
     print, 'ERROR: stx_pixel_scale(): pixel_data parameter not provided'
     return, -1
  endif

; Take a copy of the input data for subsequent operations
  pixel_out = pixel_data

; Get or hard-code pixel_data.data[n_time, n_energy, n_subc, n_pixel]
; dimensions
  n_time    = n_elements(pixel_out.taxis)
  n_energy  = n_elements(pixel_out.eaxis)
  n_subc    = 32
  n_pixel   = 12

; The following routine reads the pixel scaling data from a look-up
; file and returns the array pixel_scale[n_subc, n_pixel]
  pixel_scale = stx_pixel_read_scale( filename )

; Transpose the pixel_scale[n_subc, n_pixel] array to the
; pixel_scale[n_pixel, n_subc] array to allow the addition of
; preceding n_energy and n_time dimensions in the rebin operation
; below
  pixel_scale = transpose(pixel_scale)

; Rebin the pixel_scale[n_pixel, n_subc] array with additional
; dimensions to obtain the pixel_scale[n_pixel, n_subc, n_energy,
; n_time] array
  pixel_scale = rebin(pixel_scale, n_pixel, n_subc, n_energy, n_time)

; Transpose to pixel_scale[n_time, n_energy, n_subc, n_pixel]
  pixel_scale = transpose(pixel_scale)

; pixel_scale and pixel_out.data now have the same dimensions so an
; element-by-element multiply does the business as required
  pixel_out.data *= pixel_scale

  return, pixel_out

end
