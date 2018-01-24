;+
; :description:
;     Event-handling routine for 'stx_sim_widget_set_sources' widget
;
; :params:
;     event
;
;  :history:
;     29-Oct-2012 - Marek Steslicki (Wro), initial release
;     10-Feb-2013 - Marek Steslicki (Wro), size and position units
;                   changed to arcseconds
;     11-Feb-2013 - Marek Steslicki (Wro), source scale feature added
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
pro stx_sim_widget_set_sources_event, event
  case event.id of
    widget_info(event.top, find_by_uname='sourcescale'): begin  
      stx_sim_widget_refresh, event.top, /drawing
      end
    widget_info(event.top, find_by_uname='preview'): begin
      widget_control, widget_info(event.top, find_by_uname='sourcelist'), get_uvalue=allelementsstructure
      widget_control, widget_info(event.top, find_by_uname='sxpos'), get_value = xasec
      widget_control, widget_info(event.top, find_by_uname='sypos'), get_value = yasec
      widget_control, widget_info(event.top, find_by_uname='rs'), get_value = dist
      photontab=stx_sim_multisource_sourcestruct2photon(allelementsstructure,xasec,yasec)
      stx_sim_widget_plot_photons,photontab,event.top
      end
    widget_info(event.top, find_by_uname='done'): begin
      widget_control, widget_info(event.top, find_by_uname='sourcelist'), get_uvalue=allelementsstructure
      widget_control, widget_info(event.top, find_by_uname='sxpos'), get_value = xasec
      widget_control, widget_info(event.top, find_by_uname='sypos'), get_value = yasec
      widget_control, widget_info(event.top, find_by_uname='rs'), get_value = dist
      photontab=stx_sim_multisource_sourcestruct2photon(allelementsstructure,xasec,yasec)
      widget_control, widget_info(event.top, find_by_uname='storagebaseid'), get_uvalue = storagebaseid
      widget_control, storagebaseid, set_uvalue = photontab
      widget_control, event.top, /destroy
      end
    widget_info(event.top, find_by_uname='draw'): begin
      if event.press then begin
        listid=widget_info(event.top, find_by_uname='sourcelist')
        n=widget_info(listid,/list_select)
        widget_control, listid, get_uvalue=allelementsstructure
        nelem=n_elements(allelementsstructure)
        if n lt 0 then n=nelem-1
        drawwindowsize=400  
        rsun=0.696342  ; solar radius [10^6 km]
        au=149.597871  ; 1au [10^6 km]
        fov=2.d
        widget_control, widget_info(event.top, find_by_uname='sxpos'), get_value = xasec
        widget_control, widget_info(event.top, find_by_uname='sypos'), get_value = yasec
        widget_control, widget_info(event.top, find_by_uname='rs'), get_value = dist
        ssize=atan(rsun/(dist*au))/!dtor/3600.0 ; radius of the Sun-disc in degrees/3600.0 (position and size of the source is given in arcseconds)
        x0=xasec/3600.0
        y0=yasec/3600.0
        xcen=((event.x-drawwindowsize/2.0)*fov/drawwindowsize+x0);/ssize        
        ycen=((event.y-drawwindowsize/2.0)*fov/drawwindowsize+y0);/ssize        
        allelementsstructure[n].xcen=xcen
        allelementsstructure[n].ycen=ycen
        widget_control, listid, set_uvalue=allelementsstructure
        widget_control, widget_info(event.top, find_by_uname='xcen'), set_value=xcen
        widget_control, widget_info(event.top, find_by_uname='ycen'), set_value=ycen
        stx_sim_widget_refresh, event.top, /drawing, /list
      endif
      end
    widget_info(event.top, find_by_uname='sxpos'): begin
      stx_sim_widget_plot_sun, event.top
      end
    widget_info(event.top, find_by_uname='sypos'): begin
      stx_sim_widget_plot_sun, event.top
      end
    widget_info(event.top, find_by_uname='rs'): begin
      widget_control, event.id, get_value=rs
      listid=widget_info(event.top, find_by_uname='sourcelist')
      n=widget_info(listid,/list_select)
      widget_control, listid, get_uvalue=allelementsstructure
      nelem=n_elements(allelementsstructure)
      if n lt 0 then n=nelem-1
      allelementsstructure[n].distance=rs
      widget_control, listid, set_uvalue=allelementsstructure
      stx_sim_widget_plot_sun, event.top
      stx_sim_widget_refresh,event.top, /drawing, /list, /photons
      end
    widget_info(event.top, find_by_uname='xcen'): begin
      widget_control, event.id, get_value=xcen
      listid=widget_info(event.top, find_by_uname='sourcelist')
      n=widget_info(listid,/list_select)
      widget_control, listid, get_uvalue=allelementsstructure
      nelem=n_elements(allelementsstructure)
      if n lt 0 then n=nelem-1
      allelementsstructure[n].xcen=xcen
      widget_control, listid, set_uvalue=allelementsstructure
      stx_sim_widget_refresh, event.top, /drawing, /list
      end
    widget_info(event.top, find_by_uname='ycen'): begin
      widget_control, event.id, get_value=ycen
      listid=widget_info(event.top, find_by_uname='sourcelist')
      n=widget_info(listid,/list_select)
      widget_control, listid, get_uvalue=allelementsstructure
      nelem=n_elements(allelementsstructure)
      if n lt 0 then n=nelem-1
      allelementsstructure[n].ycen=ycen
      widget_control, listid, set_uvalue=allelementsstructure
      stx_sim_widget_refresh, event.top, /drawing, /list
      end
    widget_info(event.top, find_by_uname='sourceshape'): begin
      shapes=widget_info(event.id,/combobox_gettext )
      listid=widget_info(event.top, find_by_uname='sourcelist')
      n=widget_info(listid,/list_select)
      widget_control, listid, get_uvalue=allelementsstructure
      nelem=n_elements(allelementsstructure)
      if n lt 0 then n=nelem-1
      allelementsstructure[n].shape=shapes
      widget_control, listid, set_uvalue=allelementsstructure
      stx_sim_widget_refresh, event.top, /drawing, /list
      end
    widget_info(event.top, find_by_uname='flux'): begin
      widget_control, event.id, get_value=flux
      listid=widget_info(event.top, find_by_uname='sourcelist')
      n=widget_info(listid,/list_select)
      widget_control, listid, get_uvalue=allelementsstructure
      nelem=n_elements(allelementsstructure)
      if n lt 0 then n=nelem-1
      allelementsstructure[n].flux=flux
      widget_control, listid, set_uvalue=allelementsstructure
      stx_sim_widget_refresh, event.top, /list
      stx_sim_widget_refresh,event.top,/photons
      end
    widget_info(event.top, find_by_uname='duration'): begin
      widget_control, event.id, get_value=duration
      listid=widget_info(event.top, find_by_uname='sourcelist')
      n=widget_info(listid,/list_select)
      widget_control, listid, get_uvalue=allelementsstructure
      nelem=n_elements(allelementsstructure)
      if n lt 0 then n=nelem-1
      allelementsstructure[n].duration=duration
      widget_control, listid, set_uvalue=allelementsstructure
      stx_sim_widget_refresh, event.top, /list
      stx_sim_widget_refresh,event.top,/photons
      end
    widget_info(event.top, find_by_uname='fwhm_wd'): begin
      widget_control, event.id, get_value=fwhm_wd
      listid=widget_info(event.top, find_by_uname='sourcelist')
      n=widget_info(listid,/list_select)
      widget_control, listid, get_uvalue=allelementsstructure
      nelem=n_elements(allelementsstructure)
      if n lt 0 then n=nelem-1
      allelementsstructure[n].fwhm_wd=fwhm_wd
      widget_control, listid, set_uvalue=allelementsstructure
      stx_sim_widget_refresh, event.top, /drawing, /list
      end
    widget_info(event.top, find_by_uname='fwhm_ht'): begin
      widget_control, event.id, get_value=fwhm_ht
      listid=widget_info(event.top, find_by_uname='sourcelist')
      n=widget_info(listid,/list_select)
      widget_control, listid, get_uvalue=allelementsstructure
      nelem=n_elements(allelementsstructure)
      if n lt 0 then n=nelem-1
      allelementsstructure[n].fwhm_ht=fwhm_ht
      widget_control, listid, set_uvalue=allelementsstructure
      stx_sim_widget_refresh, event.top, /drawing, /list
      end
    widget_info(event.top, find_by_uname='phi'): begin
      widget_control, event.id, get_value=phi
      listid=widget_info(event.top, find_by_uname='sourcelist')
      n=widget_info(listid,/list_select)
      widget_control, listid, get_uvalue=allelementsstructure
      nelem=n_elements(allelementsstructure)
      if n lt 0 then n=nelem-1
      allelementsstructure[n].phi=phi
      widget_control, listid, set_uvalue=allelementsstructure
      stx_sim_widget_refresh, event.top, /drawing, /list
      end
   widget_info(event.top, find_by_uname='loop_ht'): begin
      widget_control, event.id, get_value=loop_ht
      listid=widget_info(event.top, find_by_uname='sourcelist')
      n=widget_info(listid,/list_select)
      widget_control, listid, get_uvalue=allelementsstructure
      nelem=n_elements(allelementsstructure)
      if n lt 0 then n=nelem-1
      allelementsstructure[n].loop_ht=loop_ht
      widget_control, listid, set_uvalue=allelementsstructure
      stx_sim_widget_refresh, event.top, /drawing, /list
      end
    widget_info(event.top, find_by_uname='add'): begin
      stx_sim_widget_add, event.top
      end
    widget_info(event.top, find_by_uname='delete'): begin
      listid=widget_info(event.top, find_by_uname='sourcelist')
      widget_control, listid, get_uvalue=allelementsstructure
      n=widget_info(listid,/list_select)
      nelem=n_elements(allelementsstructure)-1
      if n lt 0 then n=nelem
      if nelem eq 0 then begin
        print,"only one source left"
      endif else begin
        indexes=intarr(nelem)
        j=0
        for i=0,nelem do if n ne i then indexes[j++]=i
        newallelementsstructure=allelementsstructure[indexes]
        widget_control, listid, set_uvalue=newallelementsstructure
      stx_sim_widget_refresh, event.top, /all, /last
      endelse
      end
    widget_info(event.top, find_by_uname='sourcelist'): begin
      id=widget_info(event.top, find_by_uname='sindex')
      widget_control, id, set_value=event.index
      stx_sim_widget_refresh, event.top, /source, /drawing, /photons
      end
    widget_info(event.top, find_by_uname='save'): begin
      id=widget_info(event.top, find_by_uname='sourcelist')
      widget_control, id, get_uvalue=allelements
      stx_sim_widget_save_sources,allelements,event.top
      end
    widget_info(event.top, find_by_uname='load'): begin
      topid=event.top
      stx_sim_widget_load_sources,event.top
      stx_sim_widget_refresh, event.top, /last, /all
      end
    else:
  endcase
end
