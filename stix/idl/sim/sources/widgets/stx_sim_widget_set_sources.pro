;+
; :description:
;      A modal dialog widget. This widget allows to define parameters of sources.
;      And simulates the photons originating from the defined sources.
;
; :params:
;     none
;
; :returns:
;     array of "stx_sim_photon" structures (all photons from simulated sources)
; 
; :todo:
;     modify flux for source simulation to be that at the spacecraft
;     location rather than the flux currently defined at 1 AU
; 
; :history:
;     28-Oct-2012 - Marek Steslicki (Wro), initial release
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
function stx_sim_widget_set_sources
   drawwindowsize=400           ; size of chart [px]
;   start values:
   startsxpos=0.d  
   startsypos=0.d  
   startdistance=1.d

;   base of invisible widget which stores table of stx_sim_photon structures 
;   which be returned by this function. a modal dialog widget.
   storagebase = widget_base(map=0)

;   main base of widget    
   base = widget_base(/column,column=2,title='multi-source simulation widget',group_leader=storagebase,/map)

;   left column base    
   lcol = widget_base(base,/column)
;   drawing of the solar-disc and the defined sources.    
   draw = widget_draw( lcol, xsize=drawwindowsize, ysize=drawwindowsize,  uname='draw', /button_events, /motion_events ) 
;   sources scale
   scalebase = widget_base(lcol,/row )
      scalestxt=["x1","x5","x10","x20"]  
      sourcescalelabel = widget_label(scalebase, value="Sources drawing scale " )
      sourcescale = widget_combobox(scalebase,uname='sourcescale',value=scalestxt,uvalue=scalestxt)

;   right column base    
   rcol = widget_base(base,/column)

;   solar-disc positon fields    
    sunposbase = widget_base(rcol,/column, frame=2 )
    sunposbase1 = widget_base(sunposbase,/row )
      sundisklabel = widget_label(sunposbase1, value="STIX pointing wrt Sun centre: " )
      sxpos = cw_field(sunposbase1,uname='sxpos', /floating, title='x =', xsize=6, value=startsxpos, /all_events )
      aseclabel1 = widget_label(sunposbase1, value="arcsec," )
      sypos = cw_field(sunposbase1,uname='sypos', /floating, title='y =', xsize=6, value=startsypos, /all_events )
      aseclabel2 = widget_label(sunposbase1, value="arcsec" )
    sunposbase2 = widget_base(sunposbase,/row)
      rs = cw_field(sunposbase2,uname='rs', /floating, title='Spacecraft distance from Sun =', xsize=6, value=startdistance, /all_events )
      au1 = widget_label(sunposbase2, value="AU" )

;   fields with description of selected source     
    flarebase = widget_base(rcol,/column, frame=2 )
    flarebase1 = widget_base(flarebase,/row)
      sshapes=["point","gaussian","loop-like"]
      shapelabel = widget_label(flarebase1, value="Shape of source: " )
      sourceshape = widget_combobox(flarebase1,uname='sourceshape',value=sshapes,uvalue=sshapes)
      
 ;   fields with total number of simulated source photons of selected source     
    flarebasephotons = widget_base(flarebase,/row)
      startspacecraftflux='0000000000000000'
      startspacecraftphotons='0000000000000000'
      flux = cw_field(flarebasephotons,uname='flux', /floating, title="Flux at 1 AU =", xsize=10, /all_events )
      fluxlabel = widget_label(flarebasephotons, value="ph/cm^2/s, flux at spacecraft =" )
      spacecraftflux = widget_label(flarebasephotons,uname='spacecraftflux',value=startspacecraftflux,uvalue=startspacecraftflux)
      spacecraftfluxlabel = widget_label(flarebasephotons, value="ph/cm^2/s, total simulated photons =" )
      spacecraftphotons = widget_label(flarebasephotons,uname='spacecraftphotons',value=startspacecraftphotons,uvalue=startspacecraftphotons)
      
;   field with duration of flare source in seconds
    flarebasedur = widget_base(flarebase,/row)
      duration = cw_field(flarebasedur,uname='duration', /floating, title="Simulation duration =", xsize=6, /all_events )
      durationlabel = widget_label(flarebasedur, value="s" )

;   fields with a detailed description of selected source      
    flarebase2 = widget_base(flarebase,/row)
      poslabel = widget_label(flarebase2, value="Source location (viewed from 1 AU): " )
      xcen = cw_field(flarebase2,uname='xcen', /floating, title='x =', xsize=6, /all_events )
      radiuslabel1 = widget_label(flarebase2, value="arcsec," )
      ycen = cw_field(flarebase2,uname='ycen', /floating, title='y =', xsize=6, /all_events )
      radiuslabel2 = widget_label(flarebase2, value="arcsec" )

;   fields with a detailed description of selected source - continued
    flarebase3 = widget_base(flarebase,/row)
      detailslabel = widget_label(flarebase3, value="Source geometry (viewed from 1 AU): " )
      fwhm_wd = cw_field(flarebase3,uname='fwhm_wd', /floating, title='width =', xsize=6, /all_events )
      radiuslabel3 = widget_label(flarebase3, value="arcsec," )
      fwhm_ht = cw_field(flarebase3,uname='fwhm_ht', /floating, title='height =', xsize=6, /all_events )
      radiuslabel4 = widget_label(flarebase3, value="arcsec," )
      rotationlabel = widget_label(flarebase3, value="rotation (CCW from North)" )
      phi = widget_slider(flarebase3,uname='phi', maximum=360 , minimum=0)
      deglabel = widget_label(flarebase3, value="degrees" )

;   loop height definition 
    flarebase4 = widget_base(flarebase,/row)
      loop_ht = cw_field(flarebase4,uname='loop_ht', /floating, title="Loop height (viewed from 1 AU) =", xsize=6, /all_events )
      radiuslabel5 = widget_label(flarebase4, value="arcsec" )

;   list of sources and operating buttons
    sourcelistbase = widget_base(rcol,column=2, frame=2 )
      sourcelistbasel = widget_base(sourcelistbase,/column )
        sourcelist = widget_list(sourcelistbasel, ysize = 8, uname='sourcelist')
        adddelbase = widget_base(sourcelistbasel,/row)
          addbutton = widget_button(adddelbase,uname='add',value="                           add new source                           ")
          deletebutton = widget_button(adddelbase,uname='delete',value="  delete source  ")
      sourcelistbaser = widget_base(sourcelistbase,/column )
      savebutton = widget_button(sourcelistbaser, uname='save' , value=" save list of sources ",/align_left )
      loadbutton = widget_button(sourcelistbaser, uname='load' , value=" load list of sources ",/align_left )

;   done and preview button
   spacelabel = widget_label(rcol, value=" " )
   donebase = widget_base(rcol,/row, /align_right )
    previewbutton = widget_button(donebase, uname='preview' , value="    preview    ",/align_right )
    donebutton = widget_button(donebase, uname='done' , value="     done     ",/align_right )

;   invisible container. 
;   conatins: 
;   - the number of selected source in the list of sources,
;   - id of the invisible widget which stores table of stx_sim_photon structures.
   invisiblecontainer = widget_base(rcol, map=0)
      sindex = cw_field(invisiblecontainer,uname='sindex', value=0, /integer )
      sindex = cw_field(invisiblecontainer,uname='storagebaseid', value=0, uvalue=storagebase, /integer )

;   display the widget
   widget_control, base, /realize

;   add first source
   stx_sim_widget_add, base
   
;   create the drawing of the solar-disc and the defined source 
   stx_sim_widget_plot_sun, base

;   event manager for the widget 
   xmanager, 'stx_sim_widget_set_sources', base

;   when the widget is destroyed get the table of stx_sim_photon structures 
;   from the base of invisible widget (a modal dialog widget).
   widget_control, storagebase, get_uvalue = photontab
   
;   destroy the base of invisible widget.   
   widget_control, storagebase, /destroy
   
;   return the table of stx_sim_photon structures 
   return,photontab

end
