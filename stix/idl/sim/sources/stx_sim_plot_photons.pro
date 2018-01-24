;+
; :description:
;     This procedure draws preview of the table of photons
;
; :params:
;     photontab :   in, required, type="array of stx_sim_photon structures"
;                   structure with heliocentric coordinates (x_loc, y_loc) for 
;                   each photon simulated
;     mainid    :   in, required, type="long"
;                   ID of the parent widget
;
;  :history:
;     29-Oct-2012 - Marek Steslicki (Wro), initial release
;     07-Feb-2012 - Tomek Mrozek (Wro), adaptation for command line call
;-

pro stx_sim_plot_photons, photontab, s_dist=s_dist

rsun=0.696342  ; Solar radius [10^6 km]
au=149.597871  ; 1AU [10^6 km]

;If the distance to the Sun is not defined then it is assumed to be 1 AU
if keyword_set(s_dist) eq 0 then s_dist=1d

     windowsize=600
     map=fltarr(windowsize,windowsize)
     pixelsize=(3600.d*4.d)/double(windowsize)
     for i=ulong64(0),n_elements(photontab)-ulong64(1) do begin
       x=long(photontab[i].x_loc/pixelsize+windowsize/2.d)
       y=long(photontab[i].y_loc/pixelsize+windowsize/2.d)
       if x ge 0 and x lt windowsize and y ge 0 and y lt windowsize then map[x,y]++
     endfor
     window,10,xs=windowsize,ys=windowsize,xpos=10,ypos=10
     plot_image,(map+1)^.4 

;plot Sun limb     
   ssize=atan(rsun/(s_dist*au))/!dtor
   scl=windowsize/2.  
   draw_circle,scl,scl,ssize*scl/2.
   
 end
