;+
; :description:
;   Interpolate pixel_data counts from pixel native energy
;   bins read from the stx_e_bin.txt file to pixel_data.eaxis nominal
;   energy bins
;
; :params:
;   pixel_data: in, required, type="structure"
;               stx_pixel_data structure containing detected counts as
;               a function of time, energy, subcollimator and pixel
;               as .data[n_time, n_energy, n_subc, n_pixel]
;
; :keywords:
;   filename: in, optional, type="string", default="$SSW/so/stix/idl/processing/pxl/stx_pixel_e_bin.txt"
;
; :returns:
;   pixel_out: out, type="structure"
;              The pixel_data structure with the counts in each pixel
;              interpolated from each pixel's native energy
;              bins as specified in stx_e_bin.txt to the nominal
;              energy bins specified in pixel_data.eaxis
;
; :errors:
;   returns -1 if no input pixel_data structure provided
;
; :history:
;   13-Aug-2013 - Mel Byrne (TCD), created routine
;-

function stx_pixel_e_bin, pixel_data, filename = filename

  if n_params() ne 1 then begin
     print, 'ERROR: stx_pixel_e_bin(): pixel_data parameter not provided'
     return, -1
  endif

; Take a copy of the input pixel_data structure for subsequent
; operations
  pixel_out = pixel_data

; read the contents of the e_bin lookup file
  e_bin = stx_pixel_read_e_bin( filename )

; Get or hard code n_times, n_subc and n_pixel
  n_time  = n_elements(pixel_data.taxis)
  n_subc  = 32
  n_pixel = 12

; Loop over n_time, n_subc and n_pixel interpolating from pixel
; 'native' energies to the pixel nominal energies contained in
; pixel_out.eaxis. Loops are *bad* but interpol() works on vectors
; only. Therefore, in a future version, it would be good to unfold the
; interpolation functions from interpol() and execute here in an idl
; array-friendly way
  for ti=0, n_time-1 do $
     for sc=0, n_subc-1 do $
        for px=0, n_pixel-1 do $
           pixel_out.data[ti,*,sc,px] = interpol(pixel_out.data[ti,*,sc,px], $
                                                 e_bin[*,sc,px],             $
                                                 pixel_out.eaxis)

  return, pixel_out

end
