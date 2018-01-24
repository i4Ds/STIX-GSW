;+
; :description:
;   This function reads the contents of the pixel scale file and
;   returns the contents in a [n_subc, n_pixel] double array.
;
; :params:
;   fpath: in, optional, type="string", default="$SSW/so/stix/idl/processing/pxl/stx_pixel_scale.txt"
;          If provided, must be the full path+filename to the pixel
;          scale look-up file
;
; :returns:
;   A double array [n_subc, n_pixel] of pixel scaling factors
;
; :errors:
;   Prints an error message and stops if the stx_pixel_scale.txt
;   look-up file is not found
;
; :history:
;   13-Aug-2013 - Mel Byrne (TCD), created routine
;-

function stx_pixel_read_scale, fpath

; Set-up default search path
  spath = [getenv('IDL_WORKSPACE_PATH'), $
           getenv('SSW') + 'so'] +       $
          '/stix/idl/processing/pxl'

; Search for the default file name - if not found, return an error
; code
  fpath = exist(fpath) ? fpath : $
          loc_file('stx_pixel_scale.txt', path = spath)

  if ~file_exist( fpath ) then begin
     print, 'ERROR: stx_pixel_read_scale(): stx_pixel_scale.txt file not found'
     print, spath

     stop
  endif

; Read the pixel scaling factors
  readcol, fpath,                                             $
           p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, $
           format = 'd,d,d,d,d,d,d,d,d,d,d,d', /silent

; And return as a [n_subc, n_pixel] array
  return, [ [p1], [p2], [p3],  [p4],  [p5],  [p6], $
            [p7], [p8], [p9], [p10], [p11], [p12]  ]

end
