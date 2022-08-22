;+
; :description:
;    This function fills a STIX subcollimator structure with the
;    geometrical characteristics contained in a look-up file. 
;
; :params:
;    fpath:  in, optional, type="string", default="$STX_GRID/stx_subc_params.txt"
;            full file path of subcollimator characteristics look-up
;            file.
;
; :keywords:
;
;
; :returns:
;    Structure containing 32 substructure elements, one for each STIX
;    subcollimator (30 Fourier channels, 1 coarse flare locator, and 1
;    flux monitor). Each substructure element contains information on
;    the geometry and spatial structure contained in the front and
;    rear grids, the detector active area and the detector pixels.
;
; :errors:
;    If a geometry structure is not created, this function returns the
;    following error codes:
;       -10 = look-up file not present,
;       -20 = incomplete look-up file.
;
; :history:
;    21-Aug-2012 - Shaun Bloomfield (TCD), created routine
;    20-Nov-2012 - Shaun Bloomfield (TCD), added subcollimator phase
;    08-Jan-2013 - Shaun Bloomfield (TCD), simplified parameter table 
;                  format and added grid bridge parameters
;    20-Feb-2013 - Shaun Bloomfield (TCD), fixed incorrect active area 
;                  for rear grids (is 13x13 mm^2 and not 22x20 mm^2)
;    30-Apr-2013 - Shaun Bloomfield (TCD), added default file search
;    27-Jun-2013 - Richard Schwartz (GSFC), fixed environmental typo,
;                  changed getenv('SSW_GRID') to getenv('STX_GRID')
;    25-Oct-2013 - Shaun Bloomfield (TCD), renamed 'stx_construct_subc'
;                  from 'stx_read_subc_data', moved structure creation
;                  to separate definition functions, changed tagnames
;                  associated with edges and added new area tagnames
;    28-Jul-2014 - Shaun Bloomfield (TCD), increase in 'skipline' to
;                  account for modified stx_subc_params.txt file
;    28-Oct-2014 - Shaun Bloomfield (TCD), changed area from mm^2 to
;                  cm^2
;    07-Nov-2014 - Laszlo I. Etesi (FHNW), changed readcol for
;                  subc_slit_wd & subc_b_width to DOUBLE from INTEGER
;    13-Nov-2014 - Shaun Bloomfield (TCD), fixed typo bug in detector
;                  area calculation (was ysize * ysize)...
;-
function stx_construct_subcollimator, fpath
  
  ;  Set default file path location
  fpath = exist(fpath) ? fpath : loc_file( 'stx_subc_params.txt', path = getenv('STX_GRID') )
  
  ;  Return error if look-up file does not exist
  if ~file_exist(fpath) then return, -10
  
  ;  Read in grid parameters, should contain 32 lines after 8 header 
  ;  lines
  readcol, fpath, det_num, grid_label, subc_slit_wd, subc_b_width, $
           subc_phase, subc_f_pitch, subc_f_angle, subc_r_pitch, $
           subc_r_angle, subc_b_pitch, subc_b_angle, subc_x_cen, $
           subc_y_cen, subc_f_xsize, subc_f_ysize, subc_r_xsize, $
           subc_r_ysize, subc_d_xsize, subc_d_ysize, subc_d_l_xsz, $
           subc_d_l_ysz, subc_d_s_xsz, subc_d_s_ysz, $
           skipline = 9, count = nlines, /silent, $
           format = 'I,A,D,D,I,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D'
  ;     det_num          -> subcollimator detector number
  ;     grid_label       -> subcollimator label indicating the grid 
  ;                           resolution (1 = fine, 10 = coarse) and 
  ;                           orientation (A/B/C)
  ;     subc_slit_wd     -> front and rear grid slit widths
  ;     subc_b_width     -> front and rear grid bridge widths
  ;     subc_phase       -> phase sense between front and rear grids
  ;     subc_f/r/b_pitch -> front/rear/bridge slit/slat pitch
  ;     subc_f/r/b_angle -> front/rear/bridge slit/slat orientation 
  ;                           (measured clockwise from detector up when 
  ;                           looking from the Sun)
  ;     subc_x_cen       -> subcollimator centre X position
  ;     subc_y_cen       -> subcollimator centre Y position
  ;     subc_f/r/d_xsize   -> front/rear/detector width in X coordinate
  ;     subc_f/r/d_ysize   -> front/rear/detector width in Y coordinate
  ;     subc_d_l/s_xsz   -> detector large/small pixel width in X 
  ;                           coordinate
  ;     subc_d_l/s_ysz   -> detector large/small pixel width in Y 
  ;                           coordinate
  
  ;  Return error if look-up file does not contain 32 subcollimator entries
  if (nlines ne 32) then return, -20
  
  ;  Replicate individual subcollimator structure to account for 
  ;  32 separate subcollimators (30 Fourier components, 1 coarse 
  ;  flare locator, and 1 flux monitor)
  subc = replicate( stx_subcollimator_structure(), 32 )
  
  ;  Determine read-in array order of increasing detector number 
  ;  for output structure elements
  ord = sort(det_num)
  
  ;  Fill subcollimator detector numbers into output structure
  subc[*].det_n = det_num[ord]
  
  ;  Fill subcollimator grid labels into output structure
  subc[*].label = grid_label[ord]
  
  ;  Fill subcollimator phase senses into output structure
  subc[*].phase = subc_phase[ord]
  
  ;  All positions relative to STIX central optical axis
  subc[*].front.x_cen = subc_x_cen[ord]
  subc[*].front.y_cen = subc_y_cen[ord]
  subc[*].front.xsize = subc_f_xsize[ord]
  subc[*].front.ysize = subc_f_ysize[ord]
  subc[*].front.area  = ( subc_f_xsize * subc_f_ysize )[ord] * 1e-2
  subc[*].front.edge.left   = ( subc_x_cen - (subc_f_xsize/2.d) )[ord]
  subc[*].front.edge.right  = ( subc_x_cen + (subc_f_xsize/2.d) )[ord]
  subc[*].front.edge.bottom = ( subc_y_cen - (subc_f_ysize/2.d) )[ord]
  subc[*].front.edge.top    = ( subc_y_cen + (subc_f_ysize/2.d) )[ord]
  subc[*].front.slit_wd = subc_slit_wd[ord]
  subc[*].front.pitch   = subc_f_pitch[ord]
  subc[*].front.angle   = subc_f_angle[ord]
  subc[*].front.b_width = subc_b_width[ord]
  subc[*].front.b_pitch = subc_b_pitch[ord]
  subc[*].front.b_angle = subc_b_angle[ord]
  ;  
  subc[*].rear.x_cen = subc_x_cen[ord]
  subc[*].rear.y_cen = subc_y_cen[ord]
  subc[*].rear.xsize = subc_r_xsize[ord]
  subc[*].rear.ysize = subc_r_ysize[ord]
  subc[*].rear.area  = ( subc_r_xsize * subc_r_ysize )[ord] * 1e-2
  subc[*].rear.edge.left   = ( subc_x_cen - (subc_r_xsize/2.d) )[ord]
  subc[*].rear.edge.right  = ( subc_x_cen + (subc_r_xsize/2.d) )[ord]
  subc[*].rear.edge.bottom = ( subc_y_cen - (subc_r_ysize/2.d) )[ord]
  subc[*].rear.edge.top    = ( subc_y_cen + (subc_r_ysize/2.d) )[ord]
  subc[*].rear.slit_wd = subc_slit_wd[ord]
  subc[*].rear.pitch   = subc_r_pitch[ord]
  subc[*].rear.angle   = subc_r_angle[ord]
  subc[*].rear.b_width = subc_b_width[ord]
  subc[*].rear.b_pitch = subc_b_pitch[ord]
  subc[*].rear.b_angle = subc_b_angle[ord]
  ;  
  subc[*].det.x_cen = subc_x_cen[ord]
  subc[*].det.y_cen = subc_y_cen[ord]
  subc[*].det.xsize = subc_d_xsize[ord]
  subc[*].det.ysize = subc_d_ysize[ord]
  subc[*].det.area  = ( subc_d_xsize * subc_d_ysize )[ord] * 1e-2
  subc[*].det.edge.left   = ( subc_x_cen - (subc_d_xsize/2.d) )[ord]
  subc[*].det.edge.right  = ( subc_x_cen + (subc_d_xsize/2.d) )[ord]
  subc[*].det.edge.bottom = ( subc_y_cen - (subc_d_ysize/2.d) )[ord]
  subc[*].det.edge.top    = ( subc_y_cen + (subc_d_ysize/2.d) )[ord]
  ;  
  subc[*].det.pixel[*].edge.left = ( replicate(1, 12) # subc_x_cen[ord] ) + $
                                   ( [-2, -1, 0, 1, $
                                      -2, -1, 0, 1, $
                                      -2, -1, 0, 1] # subc_d_l_xsz[ord] )
  subc[*].det.pixel[*].edge.right = ( replicate(1, 12) # subc_x_cen[ord] ) + $
                                    ( [-1, 0, 1, 2, $
                                       -1, 0, 1, 2, $
                                       -1, 0, 1, 2] # subc_d_l_xsz[ord] ) - $
                                    ( [ 0, 0, 0, 0, $
                                        0, 0, 0, 0, $
                                        1, 1, 1, 1] # subc_d_s_xsz[ord] )
  subc[*].det.pixel[0:3 ].edge.bottom = [1,1,1,1] # subc_y_cen[ord]
  subc[*].det.pixel[4:7 ].edge.bottom = [1,1,1,1] # ( subc_y_cen - subc_d_l_ysz )[ord]
  subc[*].det.pixel[8:11].edge.bottom = [1,1,1,1] # ( subc_y_cen - (subc_d_s_ysz/2.d) )[ord]
  subc[*].det.pixel[0:3 ].edge.top = [1,1,1,1] # ( subc_y_cen + subc_d_l_ysz )[ord]
  subc[*].det.pixel[4:7 ].edge.top = [1,1,1,1] # subc_y_cen[ord]
  subc[*].det.pixel[8:11].edge.top = [1,1,1,1] # ( subc_y_cen + (subc_d_s_ysz/2.d) )[ord]
  subc[*].det.pixel[*].x_cen   = ( subc[*].det.pixel[*].edge.left + $
                                   subc[*].det.pixel[*].edge.right ) / 2.
  subc[*].det.pixel[*].y_cen   = ( subc[*].det.pixel[*].edge.bottom + $
                                   subc[*].det.pixel[*].edge.top ) / 2.
  subc[*].det.pixel[*].xsize   = [ rebin( subc_d_l_xsz[ord], [8, 32] ), rebin( subc_d_s_xsz[ord], [4, 32] ) ]
  subc[*].det.pixel[*].ysize   = [ rebin( subc_d_l_ysz[ord], [8, 32] ), rebin( subc_d_s_ysz[ord], [4, 32] ) ]
  subc[*].det.pixel[*].area    = subc[*].det.pixel[*].xsize * subc[*].det.pixel[*].ysize * 1e-2
  subc[*].det.pixel[0:7].area -= 0.5 * [ subc[*].det.pixel[8:11].area, subc[*].det.pixel[8:11].area ]
  
  ;  Pass out filled subcollimator geometry structure
  return, subc
  
end
