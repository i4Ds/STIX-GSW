;+
; :description:
;     This procedure refreshes the widget base on the table of 
;     the source structures stored in the UVALUE of the 'sourcelist' widget 
;
; :params:
;     topid  :  in, required, type="long"
;               ID of the sources simulation main widget base
;
; :keywords:
;     all     : all elements of the widget will be refreshed
;     last    : last source on the list of sources will be selected, 
;               otherwise selected is previously selected element
;     drawing : refresh the drawing
;     list    : refresh the list of sources 
;     source  : refresh the sources details: position of the source, width and height, rotation, etc.
;
;  :history:
;     28-Oct-2012 - Marek Steslicki (Wro), initial release
;     15-Oct-2013 - Shaun Bloomfield (TCD), modified to use new tag
;                   names defined during merging with STX_SIM_FLARE.pro
;     23-Oct-2013 - Shaun Bloomfield (TCD), source flux, position and
;                   geometry defined as that being viewed from 1 AU,
;                   with values altered to STIX viewpoint. Also, added
;                   display of total photons to be simulated from that
;                   source.
;     01-Nov-2013 - Shaun Bloomfield (TCD), 'type' tag changed to
;                   'shape'
;-
pro stx_sim_widget_refresh, topid, last=last, all=all, drawing=drawing, list=list, source=source, photons=photons
      widget_control, topid, /input_focus
      listid=widget_info(topid, find_by_uname='sourcelist')
      widget_control, listid, get_uvalue=allelements
      id=widget_info(topid, find_by_uname='sindex')
      widget_control, id, get_value=selected
      n=n_elements(allelements)
      if keyword_set(all) or keyword_set(list) then begin
        allelementsstring=replicate(stx_sim_sourcestructure2string(allelements[0]),n)
        for i=1,n-1 do allelementsstring[i]=stx_sim_sourcestructure2string(allelements[i])
        widget_control, listid, set_value=allelementsstring
      endif      
      if keyword_set(last) then begin
        selected=n-1
        id=widget_info(topid, find_by_uname='sindex')
        widget_control, id, set_value=selected
      endif
      if keyword_set(all) or keyword_set(source) then begin
        id=widget_info(topid, find_by_uname='xcen')
        widget_control, id, set_value=allelements[selected].xcen
        id=widget_info(topid, find_by_uname='ycen')
        widget_control, id, set_value=allelements[selected].ycen
        id=widget_info(topid, find_by_uname='fwhm_wd')
        widget_control, id, set_value=allelements[selected].fwhm_wd
        id=widget_info(topid, find_by_uname='fwhm_ht')
        widget_control, id, set_value=allelements[selected].fwhm_ht
        id=widget_info(topid, find_by_uname='phi')
        widget_control, id, set_value=allelements[selected].phi
        id=widget_info(topid, find_by_uname='duration')
        widget_control, id, set_value=allelements[selected].duration
        id=widget_info(topid, find_by_uname='flux')
        widget_control, id, set_value=allelements[selected].flux
        id=widget_info(topid, find_by_uname='loop_ht')
        widget_control, id, set_value=allelements[selected].loop_ht
        id=widget_info(topid, find_by_uname='sourceshape')
        widget_control, id, get_value=shapetab
        for i=0,n_elements(shapetab)-1 do begin
          if strcmp(shapetab[i],allelements[selected].shape) then begin
            widget_control, id, set_combobox_select=i
            break
          endif
        endfor
      endif
      if keyword_set(all) or keyword_set(drawing) then begin
        stx_sim_widget_plot_sun, topid
      endif  
      if keyword_set(all) or keyword_set(photons) then begin
        id=widget_info(topid, find_by_uname='rs')
        widget_control, id, get_value=dist
        id=widget_info(topid, find_by_uname='flux')
        widget_control, id, get_value=earthflux
        id=widget_info(topid, find_by_uname='duration')
        widget_control, id, get_value=duration
        id=widget_info(topid, find_by_uname='spacecraftflux')
        scflux=long(earthflux/(dist^2.))
        widget_control, id, set_value=string(scflux)
        widget_control, id, set_uvalue=scflux
        id=widget_info(topid, find_by_uname='spacecraftphotons')
; number of photons to simulate from source is
; ( flux at spacecraft [ph/cm^2/s] * duration [s] * 
;   subcollimator area [cm^2] * # of subcollimators )
; N.B. should really replace with call to subcollimator structure
;      to determine total area to simulate over, but inclusion here
;      would mean look-up file being reread for each widget refresh
        scphotons=ceil(scflux*duration*2.2*2.*32)
        widget_control, id, set_value=string(scphotons)
        widget_control, id, set_uvalue=scphotons
      endif
      widget_control, listid, set_list_select=selected     
end
