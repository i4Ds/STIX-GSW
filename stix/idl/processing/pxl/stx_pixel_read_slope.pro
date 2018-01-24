;+
; :description:
;   This function reads the contents of the pixel slope file and
;   returns the contents in a 32 x 12 double array.
;
; :params:
;   fpath: in, optional, type="string", default="$SSW/so/stix/idl/processing/pxl/stx_pixel_slope.txt"
;          If provided, must be the full path+filename to the pixel
;          scaling lookup file 
;
; :returns:
;   pixel slope 32 x 12 array of doubles
;
; :errors:
;   Prints an error message and stops if the stx_pixel_slope.txt
;   look-up file cannot be found
;
; :history:
;   13-Aug-2013 - Mel Byrne (TCD), created routine
;-

function stx_pixel_read_slope, fpath

; Set-up default search path
  spath = [getenv('IDL_WORKSPACE_PATH'), $
           getenv('SSW') + 'so'] +       $
          '/stix/idl/processing/pxl'

; Search for the default file name - if not found, return an error
; code
  fpath = exist(fpath) ? fpath : $
          loc_file('stx_pixel_slope.txt', path = spath)

  if ~file_exist( fpath ) then begin
     print, 'ERROR: stx_pixel_read_slope(): stx_pixel_slope.txt file not found'
     print, spath

     stop
  endif

; Read the slopes of the pixel correction linear functions
  readcol, fpath,                                             $
           p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, $
           format = 'd,d,d,d,d,d,d,d,d,d,d,d', /silent

; And return as a [n_subc, n_pixel] array
  return, [ [p1], [p2], [p3],  [p4],  [p5],  [p6], $
            [p7], [p8], [p9], [p10], [p11], [p12]  ]

end
