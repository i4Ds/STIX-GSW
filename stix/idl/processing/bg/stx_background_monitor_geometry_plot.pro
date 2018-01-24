;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       stx_background_monitor_geometry_plot
;
; PURPOSE:
;    Makes a simple plot showing the pixels and apertures of the STIX background monitor
;           
;
; CATEGORY:
;       helper methods
;
; CALLING SEQUENCE:
;    stx_background_monitor_geometry_plot, subc_str, window_lu=window_lu
;       
;
; HISTORY:
;       
;       26-Apr-2013 - richard.schwartz@nasa.gov
;       25-Oct-2013 - Shaun Bloomfield (TCD), params text changed to
;                     include stx_construct_subc
;-

;+
; :description:
;    Gets the STIX background monitor geometry and plots it showing the locations of the
;    open apertures on the rear grid deck and the outlines of the 12 pixels
;
; :keywords:
;   window_lu - window logical unit, if not passed it will use the next free unit starting at 32
; :params:
;   subc_str_arg - This may be either the filename ("string") read by stx_construct_subcollimator or the structure returned
;   by the same      
;-
pro stx_background_monitor_geometry_plot, subc_str, window_lu=window_lu

stx_geo = stx_background_monitor_geometry( subc_str )
circles = stx_geo.aper_circle ;rear deck bkg apertures
det     = stx_geo.pixel_box
box     = stx_geo.aper_box ;box region of large apertures
wdef, window_lu, free=~exist( window_lu ), 1000, 1000
z = findgen(1e4)-5000
plot, z, z, /nodata

for i=0,7 do draw_circle, circles[i].x, circles[i].y, circles[i].radius

for i=0,11 do plot_box, det[i].x, det[i].y, det[i].width, det[i].height
;Now add in the boxes for the large apertures
for i=0,11 do xyouts, det[i].x-500, det[i].y, 'Det 9.'+strtrim( i, 2), charthick=2, charsize=1.5
for i=0,1 do plot_box, box[i].x, box[i].y, box[i].width, box[i].height


end
