;+
; :description:
;     Procedure draw the plot (inside the widget body) with defined sources and the solar-disc.
;
; :params:
;     ID of the main widget base
;      
; :keywords:
;     none
;
; modification history:
;     29-Oct-2012 - Marek Steslicki (Wro), initial release
;     10-Feb-2013 - Marek Steslicki (Wro), size and position units
;                   changed to arcseconds
;     11-Feb-2013 - Marek Steslicki (Wro), source scale feature added
;     15-Oct-2013 - Shaun Bloomfield (TCD), modified to use new tag
;                   names defined during merging with stx_sim_flare.pro
;     01-Nov-2013 - Shaun Bloomfield (TCD), 'type' tag changed to
;                   'shape'
;-
pro stx_sim_widget_plot_sun, topid
   rsun=0.696342  ; Solar radius [10^6 km]
   au=149.597871  ; 1AU [10^6 km]
   fov=2.d         ; field of view [degrees]
   
   listid=widget_info(topid, find_by_uname='sourcescale')
   selectedscale=widget_info(listid,/combobox_gettext )
   selectedscalesplit=strsplit(selectedscale,'x',/extract)
   sourcescale=long(selectedscalesplit[0])
   
   Widget_Control, Widget_Info(topid, FIND_BY_UNAME='draw'), GET_VALUE = outputwindow
   Widget_Control, Widget_Info(topid, FIND_BY_UNAME='sxpos'), GET_VALUE = xasec
   Widget_Control, Widget_Info(topid, FIND_BY_UNAME='sypos'), GET_VALUE = yasec
   Widget_Control, Widget_Info(topid, FIND_BY_UNAME='rs'), GET_VALUE = dist
   ssize=atan(rsun/(dist*au))/!dtor ; radius of the Sun-disc in degrees
   x0=xasec/3600.0 ; arcseconds to degrees
   y0=yasec/3600.0 ; arcseconds to degrees
   listid=Widget_Info(topid, FIND_BY_UNAME='sourcelist')
   Widget_Control, listid, GET_UVALUE = sources
   Wset, outputwindow
   t = findgen(200)/10
   plot, ssize*cos(t)-x0, ssize*sin(t)-y0, XRANGE=[-fov/2.0,fov/2.0], YRANGE=[-fov/2.0,fov/2.0], XMARGIN=[0,0], YMARGIN=[0,0]
;   ssize=ssize/3600.0 ; degrees to degrees/3600.0 (position and size of the source is given in arcseconds)
   n=n_elements(sources)
   iconid=Widget_Info(topid, FIND_BY_UNAME='sindex')
   Widget_Control, iconid, GET_VALUE=sindex
   Widget_Control, listid, SET_LIST_SELECT=sindex
   for i=0,n-1 do begin
    if i eq sindex then begin
      sourcecolor=255
    endif else begin
      sourcecolor=150
    endelse
    case sources[i].shape of
      'point': begin
        oplot, [((sources[i].xcen/3600.)-x0)]/dist, [((sources[i].ycen/3600.)-y0)]/dist, SYMSIZE=1, PSYM=1, color=sourcecolor
      end
      'gaussian': begin
        phirad=sources[i].phi*!dtor
        oplot, ( ((sources[i].xcen/3600.)-x0)/dist ) + $
                   ((sources[i].fwhm_wd/3600./dist )*sourcescale*cos(t)*cos(phirad)) - ((sources[i].fwhm_ht/3600./dist)*sourcescale*sin(t)*sin(phirad)), $ 
               ( ((sources[i].ycen/3600.)-y0)/dist ) + $
                   ((sources[i].fwhm_wd/3600./dist )*sourcescale*cos(t)*sin(phirad)) + ((sources[i].fwhm_ht/3600./dist)*sourcescale*sin(t)*cos(phirad)), $
               color=sourcecolor
      end
      'loop-like': begin
        phirad=sources[i].phi*!dtor
        oplot, ( (sources[i].fwhm_wd/3600./dist)*sourcescale*cos(t) )*cos(phirad) $
             - ( (sources[i].fwhm_ht/3600./dist)*sourcescale*sin(t)-(sources[i].loop_ht/3600./dist)*sourcescale/((sources[i].fwhm_wd/3600./dist)*sourcescale*(sources[i].fwhm_wd/3600./dist)*sourcescale)*(sources[i].fwhm_wd/3600./dist)*sourcescale*cos(t)*(sources[i].fwhm_wd/3600./dist)*sourcescale*cos(t) )*sin(phirad) $
             + ( (sources[i].xcen/3600.)-x0 )/dist, $
               ( (sources[i].fwhm_wd/3600./dist)*sourcescale*cos(t) )*sin(phirad) $
             + ( (sources[i].fwhm_ht/3600./dist)*sourcescale*sin(t)-(sources[i].loop_ht/3600./dist)*sourcescale/((sources[i].fwhm_wd/3600./dist)*sourcescale*(sources[i].fwhm_wd/3600./dist)*sourcescale)*(sources[i].fwhm_wd/3600./dist)*sourcescale*cos(t)*(sources[i].fwhm_wd/3600./dist)*sourcescale*cos(t) )*cos(phirad) $
             + ( (sources[i].ycen/3600.)-y0 )/dist, color=sourcecolor
      end      
      else: begin
        oplot, [(sources[i].xcen/3600.)-x0]/dist, [(sources[i].ycen/3600.)-y0]/dist, SYMSIZE=1, PSYM=3, color=sourcecolor
      end
    endcase
   endfor
end
