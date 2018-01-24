;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_background_monitor_geometry
;
; PURPOSE:
;    Takes the background monitor apertures (contained) and puts those together
;    with the pixel specs into a more useful structure for our purposes in this routine
;           
;
; CATEGORY:
;       helper methods
;
; CALLING SEQUENCE:
;    IDL> stx_geo = stx_background_monitor_geometry(subc_str)
;    IDL> help, stx_geo,/st
;    ** Structure <45e0a08>, 5 tags, length=400, data length=400, refs=1:
;       APER_CIRCLE     STRUCT    -> STX_CIRCLE Array[8]
;       APER_BOX        STRUCT    -> STX_BOX Array[2]
;       PIXEL_BOX       STRUCT    -> STX_BOX Array[12]
;       APER_AREA       FLOAT     Array[8]
;       PXL_AREA        FLOAT     Array[12];
;
; HISTORY:
;       
;       26-Apr-2013 - richard.schwartz@nasa.gov
;       30-Apr-2013 - ras, fixed subc_str_arg problem, now works for string or structure
;                     provided the string is the path to the 
;       25-Oct-2013 - Shaun Bloomfield (TCD), renamed subcollimator
;                     reading routine stx_construct_subcollimator.pro
;                     and updated modified structure tagnames
;       28-Jul-2014 - Shaun Bloomfield (TCD), lengths converted to mm
;
; :description:
;    adds the aperture information to the pixel description, computes pixel and aperture areas
;    reformats pixel and aperture info to make them ready for circle.pro and plot_box.pro
;
; :keywords: none
;   
; :params:
;   Subc_str_arg - first positional argument, either as full path to 'stx_subc_params.txt' sub coll parameter file
;     or the structure returned by the call to stx_construct_subcollimator(). It's more efficient to pass in
;     the structure and not to reread id      
;-
function stx_background_monitor_geometry, subc_str_arg


;  Define X and Y centroids of 8 circular aperatures (in mm) --
;  2D array of [2, 8] locations, where 2 refers to X and Y
circ_cen = [ [-4.0,  3.7], [-4.0,  2.1], $
             [-1.4,  2.9], [ 1.4,  2.9], $
             [-1.4, -2.9], [ 1.4, -2.9], $
             [ 4.0, -2.1], [ 4.0, -3.7] ]

;  Define radii of 8 circular aperatures (in mm)
circ_rad = [ 0.250d, 0.250d, 0.056d, 0.180d, $
             0.180d, 0.056d, 0.250d, 0.250d ]
aper_circle = replicate( {stx_circle, x: 0.0, y: 0.0, radius: 0.0}, 8)
for i=0,7 do aper_circle[i] = { stx_circle, circ_cen[0,i],circ_cen[1,i], circ_rad[i]} 
aper_box  = replicate( {stx_box, x: 0.0, y: 0.0, width: 0.0, height: 0.0}, 2)
for i=0,6,6 do aper_box[i/6] = {stx_box, circ_cen[0,i], (circ_cen[1,i]+circ_cen[1, i+1])/2.0, $
  2.0 * circ_rad[i], circ_cen[1, i] - circ_cen[1,i+1]}

case 1 of
  is_string( subc_str_arg ) : subc_str = stx_construct_subcollimator( subc_str_arg )
  is_struct( subc_str_arg ) : subc_str = subc_str_arg
  else: subc_str = stx_construct_subcollimator(  )
  endcase
sbkg     = subc_str[where( subc_str.label eq 'bkg')]

top=sbkg.det.pixel.edge.top
bottom=sbkg.det.pixel.edge.bottom
left=sbkg.det.pixel.edge.left
right=sbkg.det.pixel.edge.right
xcen= (left+right)/2
xcen= (left+right)/2 - sbkg.det.x_cen
ycen= (top+bottom)/2 - sbkg.det.y_cen
width = right-left
height = top-bottom
pixel_box = replicate( {stx_box}, 12)
for i=0,11 do pixel_box[i] = {stx_box, xcen[i], ycen[i], width[i], height[i]}
area = fltarr(8)

area[0] = aper_circle[0].radius^2 * !pi + aper_box[0].width * aper_box[0].height
area[7] = aper_circle[7].radius^2 * !pi + aper_box[1].width * aper_box[1].height
area[[1, 2, 5, 6]] = aper_circle[[2, 3, 4, 5]].radius^2
pxl_area = pixel_box.width * pixel_box.height
pxl_area[0:7] -= 0.5 * reform(/over, reproduce( pxl_area[8:11], 2), 8)
bkg_geometry = { aper_circle: aper_circle,  aper_box: aper_box, pixel_box: pixel_box, aper_area: area, pxl_area:pxl_area}
return, bkg_geometry
end
