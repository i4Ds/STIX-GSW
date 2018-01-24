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
;-
pro stx_sim_widget_plot_photons, photontab, mainid
     windowsize=600
     base = widget_base(group_leader=mainid,/column,column=1,title='preview')
     draw = widget_draw( base, xsize=windowsize, ysize=windowsize,  uname='photonmap')
     donebutton = widget_button(base, uname='done' , value="close" )
     map=fltarr(windowsize,windowsize)
     pixelsize=(3600.d*4.d)/double(windowsize)
     for i=ulong64(0),n_elements(photontab)-ulong64(1) do begin
       x=long(photontab[i].x_loc/pixelsize+windowsize/2.d)
       y=long(photontab[i].y_loc/pixelsize+windowsize/2.d)
       if x ge 0 and x lt windowsize and y ge 0 and y lt windowsize then map[x,y]++
     endfor
     widget_control, base, /realize
     widget_control, draw, get_value = outputwindow
     wset, outputwindow
     tvscl,alog(map+1) 
     print,'total n of photons = ',n_elements(photontab)
     xmanager, 'stx_sim_widget_plot_photons', base  
end
