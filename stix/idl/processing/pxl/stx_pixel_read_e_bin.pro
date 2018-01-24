;+
; :description:
;   This function reads the contents of the pixel native energy bin
;   file and return the contents in a e_bin[n_energy, n_subc, n_pixel]
;   array of doubles. This function hard codes n_e_bins to 32, n_subc
;   to 32 and n_pixels to 12
;
; :params:
;   fpath: in, optional, type="string", default="$SSW/so/stix/idl/processing/pxl/stx_pixel_e_bin.txt"
;          If provided, must be the full path and filename to the
;          pixel native energy bin lookup file
;
; :returns:
;   e_bin: a double array of dimensions [n_energy, n_subc, n_pixel]
;
; :errors:
;   Prints an error message and stops if the stx_e_bin.txt look-up
;   file is not present 
;
; :history:
;   13-Aug-2013 - Mel Byrne (TCD), created routine
;-

function stx_pixel_read_e_bin, fpath

; Set-up default search path
  spath = [getenv('IDL_WORKSPACE_PATH'), $
           getenv('SSW') + 'so'] +       $
          '/stix/idl/processing/pxl'

; Search for the default file name - if not found, print an error
; code and halt
  fpath = exist(fpath) ? fpath : loc_file('stx_pixel_e_bin.txt', path=spath)

  if ~file_exist( fpath ) then begin
     print, 'ERROR: stx_pixel_read_e_bin(): stx_pixel_e_bin.txt file not found'
     print, spath

     stop
  endif

; Read the pixel native energy bins
  readcol, fpath,                                             $
           p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, $
           format = 'd,d,d,d,d,d,d,d,d,d,d,d', /silent

; And package into the e_bin[n_energy, n_subc, n_pixel] double array
  n_e_bins = 32
  n_subc   = 32
  n_pixels = 12
  e_bin    = dblarr(n_e_bins, n_subc, n_pixels)

  for i = 0, n_subc-1 do begin
     j = i * n_e_bins
     k = j + n_e_bins - 1

     e_bin[*, i, *] = [[p1[j:k]],  [p2[j:k]],  [p3[j:k]],  [p4[j:k]], $
                       [p5[j:k]],  [p6[j:k]],  [p7[j:k]],  [p8[j:k]], $
                       [p9[j:k]], [p10[j:k]], [p11[j:k]], [p12[j:k]]  ]
  endfor

  return, e_bin

end
