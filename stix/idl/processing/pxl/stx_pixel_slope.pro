;+
; :description:
;   Modify each count by a multiplicative factor determined using
;   linear energy correction, the slope of which is read from the
;   stx_pixel_slope.txt look-up file.
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
;             data. This keyword is passed to stx_pixel_read_slope().
;
; :returns:
;   pixel_out: a copy of the input pixel_data structure with each
;              pixel count multiplied by the multiplicative factor
;
; :errors:
;   Returns -1 if no pixel_data supplied as an input parameter
;
; :history:
;   13-Aug-2013 - Mel Byrne (TCD), created routine
;-

function stx_pixel_slope, pixel_data, filename = filename

  if n_params() ne 1 then begin
     print, 'ERROR: stx_pixel_slope(): pixel_data parameter not provided'
     return, -1
  endif

; Take a copy of the input data and eaxis for subsequent operations
  pixel_out = pixel_data
  e_axis    = pixel_out.eaxis

; Get or hard-code pixel_data.data[n_time, n_energy, n_subc, n_pixel]
; dimensions
  n_time    = n_elements(pixel_out.taxis)
  n_energy  = n_elements(pixel_out.eaxis)
  n_subc    = 32
  n_pixel   = 12

; The following routine reads the pixel slope data from a look-up
; file and returns the array pixel_slope[n_subc, n_pixel]
  pixel_slope = stx_pixel_read_slope( filename )

; Transpose the pixel_slope[n_subc, n_pixel] array to the
; pixel_slope[n_pixel, n_subc] array
  pixel_slope = transpose(pixel_slope)

; Rebin the pixel_slope[n_pixel, n_subc] array with additional
; dimensions to obtain the pixel_slope[n_pixel, n_subc, n_energy,
; n_time] array
  pixel_slope = rebin(pixel_slope, n_pixel, n_subc, n_energy, n_time)
  
; Compute multiplicative pixel correction where 6.5 keV bin
; multiplicative correction = 1.0 and all other energy bins are
; corrected according to pixel slope * distance from 6.5 keV
  for i = 0, n_energy-1 do $
     pixel_slope[*,*,i,*] = 1.0 + (pixel_slope[*,*,i,*] * (e_axis[i] - e_axis[2]))

; Transpose to pixel_slope[n_time, n_energy, n_subc, n_pixel]
  pixel_slope = transpose(pixel_slope)

; pixel_slope and pixel_out.data now have the same dimensions so an
; element-by-element multiply does the business as required
  pixel_out.data *= pixel_slope

  return, pixel_out

end
