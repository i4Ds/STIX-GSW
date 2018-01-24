;---------------------------------------------------------------------------
; Document name: stx_pixel_data_viewer.pro
; Created by:    Nicky Hochmuth 2012/07/24
;---------------------------------------------------------------------------
;+
; PROJECT:
;       STIX
;
; NAME:
;       Stix Pixel Data Viewer
;
; PURPOSE:
;       GUI for browsing within the stix pixel data cube (pixel data over time and energy)
;
; CATEGORY:
;       STIX WIDGETS
;
; CALLING SEQUENCE:
;
;       stx_pixel_data_viewer, data
;
; HISTORY:
;   24-Jul-2012 - Nicky Hochmuth (FHNW), initial release
;   20-Aug-2012 - Nicky Hochmuth (FHNW), add map view / add detector selector / add sine fitting / add y-log
;   03-Sep-2012 - Nicky Hochmuth (FHNW), add window resizing possibility
;   29-Jan-2013 - Nicky Hochmuth (FHNW), sort visibility input
;   todo: implement a general detector and visibility sorting
;   14-Apr-2013 - Laszlo I. Etesi (FHNW), changed subcollimator parameter file reading (temporary)
;   23-Jul-2013 - Richard Schwartz (GSFC), cleaned up the call to stx_vis_bpmap and vis_clean
;   14-oct-2013 - Richard Schwartz (GSFC), shift the xyoffset based on peak of bpmap so the rendering
;     and image processing stays within the FOV
;   25-Oct-2013 - Shaun Bloomfield (TCD), renamed subcollimator 
;                 reading routine stx_construct_subcollimator.pro
;-
;+
; :description:
;    updates all plots and labels
;
;    shares data with the widget over the common status struct
;
;-

;+
; :description:
;
; main refresh method
; 
;  updates pixel_chart 
;-
pro update_pixel, status
  
  print, "update pixel plot"
  
  ;todo speed up by caching
  if status.globalscale then begin
    pixel_data = status.analysis_sw->getdata(out_type=status.spectro.pixel_type)
    scale = tag_exist(pixel_data,"counts") ? minmax(pixel_data.counts) : 0
  end
  
  pixel_data = status.analysis_sw->getdata(out_type=status.spectro.pixel_type, time=stx_construct_time(time=status.time), energy=status.energy)
  
  ;todo ensure only one result
  if isa(pixel_data) then pixel_data=pixel_data[0]
  
  
  status.pixel.data_ptr = ptr_new(pixel_data) 
  
  case (status.pixel_renderer) of
    1: begin
      status.pixel.detector_plotter->setData, pixel_data, dscale = status.globalscale ? scale : 0, showsin = status.pixel.sinfit
    end
    2: begin
      TVLCT, r, g, b, /Get
      palette =   idlgrpalette(r,g,b)
      status.pixel.detector_plotter->setData, pixel_data, dscale = status.globalscale ? scale : 0, showsin = status.pixel.sinfit, smallpixelboost = status.pixel.smallpixelboost, palette=palette
    end
    3: begin
      ;activate the pixel state plot window
      wset, status.pixel.window_id
      stx_plot_pixel_data, pixel_data, status.map.subc_str, dscale = status.globalscale ? scale : 0, ylog=status.ylog, sinfit=status.pixel.sinfit, norm_small_pixel = status.pixel.smallpixelboost, SHOWABCDRATIO=status.pixel.abcd
    end
    else: begin
        message, "unknown pixel renderer"
    end
  endcase
  
end

;+
; :description:
;
; main refresh method
; 
;  updates the visibility plot 
;-
pro update_vis, status
  
  print, "update vis plot"
  
  if ~status.multi || where(status.spectro.pixel_types eq status.spectro.pixel_type) ge 1 then begin
  
    ;todo speed up by caching
    if status.globalscale && status.vis.global_range[0] lt 0 then begin
      print, "update global vis amlitude"
      all_vis = status.analysis_sw->getdata(out_type='stx_visibility')
      status.vis.global_range = minmax(abs(all_vis.visibility.obsvis))
      ;todo: n.h. do better
      if status.vis.global_range[0] lt 10 then status.vis.global_range[0] = 10
      
    end
    
    vis_bag    = status.analysis_sw->getdata(out_type='stx_visibility', time=stx_construct_time(time=status.time), energy=status.energy, skip_ivs=~status.multi)
    ;todo ensure only one result
    if ~isa(vis_bag) then vis_bag=-1 else vis_bag=vis_bag[0]
    
    
   end else begin
    vis_bag = -1
   end
   
   status.vis.data_ptr = ptr_new(vis_bag)
   
   wset, status.vis.window_id
   stx_plot_visibility_bag,  vis_bag, dscale = status.globalscale ? status.vis.global_range : 0, ylog=status.ylog 

end

;+
; :description:
;
; refresh method for the spectrogram plot
;   
;-
pro update_spectrogram, status
    
  print, "update spectrogram"
  ;activate the pixel state plot window
  wset, status.spectro.window_id  
  
  ;update time and energy labels
  widget_control, status.spectro.lab_energy, set_value = "Energy: "+trim(status.energy)
  widget_control, status.spectro.lab_time, set_value = "Time: "+anytim(status.time,/CCSDS)
  
  if ~ptr_valid(status.spectro.cache) then begin
    print, "update cache"
    ;force reprocess all
    
    TVLCT, r, g, b, /Get    
    loadct, 0
    all_time_energy_bins = status.analysis_sw->getdata(out_type=status.spectro.pixel_type)
    
    ;if ppl_typeof(all_time_energy_bins,compareto=status.spectro.pixel_type) then begin
      wset, status.spectro.window_id    
      stx_plot_spectrogram, all_time_energy_bins, ylog=status.ylog, position=[0.050,0.15,0.98,0.99], energy_range=status.spectro.range.energy, time_range=status.spectro.range.time, thick=1
    ;endif
    
    status.spectro.x = !X & status.spectro.y = !Y & status.spectro.p = !P
    
    image = tvrd()
    status.spectro.cache = ptr_new(image)
    TVLCT, r, g, b
  end

  tv, *status.spectro.cache
    
  ;plot the hit point of current time energy
  plots, status.time, status.energy, psym=2, color=255
  ;plot the frame of the current time_energy_bin
  current_time_energy_bin = status.analysis_sw->getdata(out_type=status.spectro.pixel_type,  time=stx_construct_time(time=status.time), energy=status.energy, strict=0)
  
  if ppl_typeof(current_time_energy_bin, compareto=status.spectro.pixel_type) then begin
    t_range = anytim((current_time_energy_bin).time_range.value)
    e_range = (current_time_energy_bin).energy_range
    rectangle,  t_range[0], e_range[0], t_range[1]-t_range[0], e_range[1]-e_range[0], color=1, thick=3
    rectangle,  t_range[0], e_range[0], t_range[1]-t_range[0], e_range[1]-e_range[0], color=255, thick=3,linestyle=2 
  endif
  
end

pro update_map, status
  
  print, "update map", status.main
   
    
    ;select all activ detectors/visibilities
    
    ;change the sort order of the visibilities
    detectors = where(status.map.detectors eq 1, nd)
    sorted_detectors = ((detectors * 3) mod 30) + (floor(detectors / 10d))
    
    vis_mask = make_array(30,/byte)
    vis_mask[status.map.sorted_det_idx[sorted_detectors]] = 1
    
    
    if status.multi && where(status.spectro.pixel_types eq status.spectro.pixel_type) lt 1 then nd=0
    
    if nd le 0 then begin
      map =  make_map(make_array(64,64,value=1),ID="No valid data found.")
    end else begin
      
      ;set the detector mask and imaging algo
      status.analysis_sw->set, img_detector_mask=vis_mask,img_algo=status.map.img_algos[0,status.map.img_algo]
      
      img = status.analysis_sw->getdata(out_type="stx_image", time=stx_construct_time(time=status.time), energy=status.energy, /reprocess, skip_ivs=~status.multi)
      
      if ~isa(img) then begin
        map =  make_map(make_array(64,64,value=1),ID="No valid data found.")
      endif else begin
      
        img = img[0]
              
        if ~ppl_typeof(img, compareto="stx_image") then begin
          map = make_map(make_array(64,64,value=1), id=!ERROR_STATE.msg)
          
        end else begin
          map = img.(tag_index(img,status.map.img_algos[2,status.map.img_algo]))
          map.time = stx_time2any(img.time_range[0],/ECS)
          map.xunits += " Duration: "+trim(stx_time_diff(img.time_range[1],img.time_range[0]))+"sec"  
          map.yunits += " EnergyRange: "+trim(img.energy_range[0])+"-"+trim(img.energy_range[1])+"keV"
          
          map = add_tag(map,vis_mask, "detectors") 
          
        endelse
      endelse   
    endelse
    
    status.map.data_ptr = ptr_new(map)
     
    ;activate the map plot window
    wset, status.map.window_id 
          
    PLOT_MAP, map, /limb, _EXTRA=extra, /cbar
    plot_map, map, /overlay, levels=[49.9,50], /percent, c_thick=3
    
    ;mark the position of the coarse flare location
    stx_pixel_data_summed = status.analysis_sw->getdata(out_type='stx_pixel_data_summed',time=stx_construct_time(time=status.time), energy=status.energy)
    if ppl_typeof(stx_pixel_data_summed, compareto="stx_pixel_data_summed") then begin
      cfl = stx_pixel_data_summed.COARSE_FLARE_LOCATION * 60
    
      plots, cfl[0], cfl[1], psym=2, thick=3, color=0
      plots, cfl[0], cfl[1], psym=2, thick=1, color=250
      xyouts, cfl[0], cfl[1], "CFL", color=255
    endif
    
    cleanplot, /silent
end

pro stx_pixel_data_viewer_cleanup, wid
  common stx_pixel_data_viewer, all_status
  ;help, all_status[wid]
  
  widget_control, wid, /DESTROY
  
  obj_destroy, all_status[wid].pixel.DETECTOR_PLOTTER
  all_status->remove, wid
  print, wid
end

;+
; :description:
;    event handler for the stx_pixel_data_viewer widget
;
;    shares data with the widget over the common status struct
;
;-
pro stx_pixel_data_viewer_event, ev
  common stx_pixel_data_viewer, all_status
  
  status = all_status[ev.handler]
  
  widget_control, ev.id, get_uvalue=uvalue
  
  ;help, ev , /structures
  
  checkvar, uvalue, "resize"
  
  labels = ["A","B","C",""]
  
  ;the event handler
  
  case uvalue of
    ;change to color mode 
    'color'    : begin
      loadct, 39
      update_spectrogram, status
      update_pixel, status
      update_map, status
    end
    'save' : begin
     file_name = dialog_pickfile(DEFAULT_EXTENSION=".sav", /write, /overwrite_prompt) 
     data_dump = {$
        type          : "stx_pixel_data_viewer_data_point_dump", $
        energy_hit    : status.energy, $
        time_hit      : status.time, $
        pixel_data    : *(status.pixel.data_ptr), $
        visibility_bag: *(status.vis.data_ptr), $
        map           : *(status.map.data_ptr) $
     }
     
     save, data_dump, filename=file_name 
     
     print, file_name
     
    end  
    ;change to gray mode
    'bw'      : begin
      loadct, 0
      update_spectrogram, status
      update_map, status
      update_pixel, status
    end
    
    'img_algo'      : begin
      status.map.img_algo = ev.index
      update_map, status
    end
    ;switch pixel type
    'pixel_type'      : begin
      status.spectro.pixel_type = status.spectro.pixel_types[ev.index]
      destroy, status.spectro.cache
      update_spectrogram, status
      update_pixel, status
      update_map, status
      update_vis, status
    end
    'draw_pixel'      : begin
        if ev.press then status.pixel.detector_plotter->hitTest, [ev.x,ev.y], times = ev.CLICKS
     end
    ;mouse hit to the spectrogram
    'draw_spectro'      : begin
      if ev.press eq 1 then begin
        wset, status.spectro.window_id
        !X = status.spectro.x & !Y = status.spectro.y & !P = status.spectro.p 
        
        te = CONVERT_COORD(ev.x,ev.y,/to_data,/device,/double)
        status.time   =  te[0] 
        status.energy =  te[1]
         
        update_spectrogram, status
        update_map, status
        update_vis, status
        update_pixel, status
      endif
    end
    
    ;switch global scale
    'globalscale' : begin
      status.globalscale = ev.select
      update_vis, status
      update_pixel, status
    end
    ;switch abcd mode
    'abcd' : begin
      status.pixel.abcd = ev.select
      update_pixel, status
    end
    ;switch global scale
    'smallPixelBoost' : begin
      status.pixel.smallpixelboost = ev.select ? 10 : 1 
      update_pixel, status
    end
    ;switch ylog
    'ylog' : begin
      status.ylog = ev.select
      destroy, status.spectro.cache
      update_spectrogram, status
      update_vis, status
      update_pixel, status
    end
    
    ;switch sin fit / histogram
    'sinfit' : begin
      status.pixel.sinfit = ev.select
      update_pixel, status
    end
    
    ;the detector manager one detector ore row/collumns has been toggelt
    'detector' : begin
      ;SINGLE DETECTOR TURN OFF/ON
      for index=1,10 do begin
        for l=0,2 do begin
          name = labels[l]+trim(index)
          i = WIDGET_INFO(ev.id, find_by_uname=name)
          if i gt 0 then begin
            status.map.detectors[l*10+index-1]= ev.select
            update_map, status
            all_status[ev.handler] = status
            return
          end
        endfor
      endfor
      
      ;Rows DETECTOR TURN OFF/ON
      for l=0,2 do begin
        name = labels[l]
        i = WIDGET_INFO(ev.id, find_by_uname=name)
        if i gt 0 then begin
          for index=1,10 do begin
            name = labels[l]+trim(index)
            j = WIDGET_INFO(ev.top, find_by_uname=name)
            if i gt 0 then Widget_Control, j, Set_Button=ev.select
            status.map.detectors[l*10+index-1]= ev.select
          end
          update_map, status
          all_status[ev.handler] = status
          return
        endif
      endfor
        
      ;Columns DETECTOR TURN OFF/ON
      for index=1,10 do begin
        name = trim(index)
        i = WIDGET_INFO(ev.id, find_by_uname=name)
        if i gt 0 then begin
          for l=0,2 do begin
            name = labels[l]+trim(index)
            j = WIDGET_INFO(ev.top, find_by_uname=name)
            if i gt 0 then Widget_Control, j, Set_Button=ev.select
            status.map.detectors[l*10+index-1]= ev.select
          endfor
          update_map, status
          all_status[ev.handler] = status
          return
        endif
      endfor 
      
      ;ALL DETECTOR TURN OFF/ON
      i = WIDGET_INFO(ev.id, find_by_uname=trim(11))
        if i gt 0 then begin
          for index=1,10 do begin
            for l=0,3 do begin
              name = labels[l]+trim(index)
              j = WIDGET_INFO(ev.top, find_by_uname=name)
              if i gt 0 then Widget_Control, j, Set_Button=ev.select
              if l lt 3 then status.map.detectors[l*10+index-1]= ev.select
              endfor
            endfor
          update_map, status
          all_status[ev.handler] = status
          return
        endif
       
    end
    
    'resize'      : begin
                      Widget_Control, status.pixel.draw, Draw_XSize=ev.x*0.571, Draw_YSize=ev.y/2
                      Widget_Control, status.vis.draw,   Draw_XSize=ev.x*0.571, Draw_YSize=ev.y/2
                      Widget_Control, status.map.draw,   Draw_XSize=ev.x*0.428, Draw_YSize=ev.y*0.33
                      update_spectrogram, status
                      update_map, status
                      update_vis, status
                      update_pixel, status
                      all_status[ev.handler] = status
                      return
                    end
                    
     else            : print, 'else', ev.x, ev.y
                    
   endcase
   
   all_status[ev.handler] = status

end

;+
; :description:
;    constructor for stx_pixel_data_viewer widget
;
;    the widget shares data with events and other methods over the common status struct
;
;-
pro stx_pixel_data_viewer, analysis_sw, title=title, multi=multi, pixel_renderer=pixel_renderer
  common stx_pixel_data_viewer, all_status
  
  ;init the singelton status dictionary
  if ~isa(all_status) then all_status = hash()
  
  default, multi, 1b
  default, pixel_renderer, 2b
  
  multi = byte(multi)
  
  ; sort the detector/visibilities sorder from the input file to: 1a 2a 3a 4a ... 1b 2b 3b ....FL BRM  
  ; extract sorted pixel data indices (1a, 1b, 1c, 2a, etc.)
  ; natural sorting using bsort gives an incorrect order with 10a, 10b, 10c, 1a, etc.
  ; sorting below creates a new detector numbering starting a 0 going to 9. Detector number for bkg and cfl become -1
  ; joining with the labels (second half) allows for a new sorting with 0a, 0b, 0c, ..., -1bkg, -1cfl
  ; bugfix for ssw compatibility, introduced v0r3, temporary
  confm = stx_configuration_manager(application_name='stx_analysis_software')
  subc_file = confm->get(/subc_file, /single)
  subc_str = stx_construct_subcollimator(subc_file)
  sorted_det_idx = bsort(string((fix(stregex(subc_str.label, '[0-9]+', /extr)) - 1)) + stregex(subc_str.label, '[a-z]+', /extr))
  
  ;find the position of the flare locator and background monitor
  fl_idx = where(subc_str.label eq 'cfl')
  bkg_idx = where(subc_str.label eq 'bkg')
  
  ;there are no visibilities for the flare locator and background monitor 
  ;skip the flare locator and shift all other visibilities
  sorted_det_idx[where(sorted_det_idx ge fl_idx[0])]-=1
  ;skip the background monitor and shift all other visibilities
  sorted_det_idx[where(sorted_det_idx ge bkg_idx[0])]-=1
  
  ;prefetch all visibility = force to calculate
  stx_vis = analysis_sw->getdata(out_type='stx_visibility')
  
  spectro_range = analysis_sw->getdata(out_type="range")
  spectro_range = {energy : spectro_range.energy, time : stx_time2any(spectro_range.time)}
  
  pixel_types = ["stx_raw_pixel_data","stx_pixel_data","stx_pixel_data_summed","stx_visibility"]
  
   spectro = { $
     window_id    : 0, $
     draw         : 0, $
     lab_energy   : 0 , $
     lab_time     : 0, $
     range        : spectro_range, $
     pixel_type   : pixel_types[multi?1:0], $
     pixel_types  : pixel_types, $
     x            : !X ,$ 
     y            : !Y ,$
     p            : !P ,$
     cache        : ptr_new()  $
  }
  vis = { $
    window_id     : 0 , $
    draw          : 0 , $
    global_range  : [-1.,-1.], $
    data_ptr      : ptr_new() $
  } 
 
  map = { $
    window_id     : 0, $
    draw          : 0, $
    detectors     : make_array(30,/byte,value=1), $
    subc_str      : subc_str, $
    sorted_det_idx: sorted_det_idx, $
    img_algo      : 0, $
    img_algos     : [ $ ;[algo,label,map_tag]
                      ['bpmap',   'Backprojection',               'map'] ,$
                      ['clean',   'Vis_Clean: Clean',             'map'] ,$
                      ['clean',   'Vis_Clean: Clean + Residuals', 'map_cl_res'] ,$
                      ['clean',   'Vis_Clean: Residuals',         'resid_map'] ,$
                      ['clean',   'Vis_Clean: Dirty',             'dirty_map'] ,$
                      ['memnjit', 'MEM njit',                     'map'] ,$
                      ['fwdfit',  'Forward Fit',                  'map'] ,$
                      ['uvsmooth','UV Smooth',                    'map'] $
                     ], $
    data_ptr      : ptr_new()      $            
  }
  
  pixel = { $
    window_id         : 0, $
    window            : obj_new() , $
    detector_plotter  : obj_new() , $
    draw              : 0 , $
    abcd              : 0 , $
    smallPixelBoost   : 1 , $
    sinfit            : 0 , $
    data_ptr          : ptr_new()  $
  }
  
  ; the common dto
  status={  $
            analysis_sw : analysis_sw, $
            multi : multi, $
            energy : mean(spectro_range.energy), $
            time : mean(spectro_range.time,/double), $
            pixel_renderer : pixel_renderer, $
            globalscale : 0., $
            ylog : 1., $
            map : map, $
            vis  : vis, $
            spectro : spectro, $
            pixel : pixel, $
            main : 1 $,
         }
  
  loadct, 39
  
  checkvar, title, 'STIX Pixel Data Viewer'
  
  display_resolution = GET_SCREEN_SIZE(display=':0')
  if display_resolution[0] eq 0 then begin
    display_resolution = [1400, 800]
  endif  
  display_resolution = display_resolution - [20,20]
  
  main = widget_base(title=title, /row, xsize=display_resolution[0], ysize=display_resolution[1], /TLB_Size_Events)
  status.main = main
  
  ;add GUI to the left of the draw area for charts
  left_pane=widget_base(main,/column, /frame, ysize=display_resolution[1])
  
  ;add GUI to the right of the draw area for user input
  right_pane=widget_base(main,/column, /frame, xsize=fix(display_resolution[0]*0.428))
  
  ;add the pixel draw area
  
  if pixel_renderer eq 1 then begin
    status.pixel.draw = widget_window(left_pane, uvalue='draw_pixel', xsize=fix(display_resolution[0]*0.571), ysize=fix(display_resolution[1]*0.5))
  end
    
  if pixel_renderer eq 2 then begin
    status.pixel.draw = widget_draw(left_pane, uvalue='draw_pixel', xsize=fix(display_resolution[0]*0.571), ysize=fix(display_resolution[1]*0.5), GRAPHICS_LEVEL=2, Renderer=1, /button)
  end
  
  if pixel_renderer eq 3 then begin
    status.pixel.draw = widget_draw(left_pane, uvalue='draw_pixel', xsize=fix(display_resolution[0]*0.571), ysize=fix(display_resolution[1]*0.5))
  end   
  
  
  ;add the visibility draw area
  status.vis.draw = widget_draw(left_pane, uvalue='draw_vis', xsize=fix(display_resolution[0]*0.571), ysize=fix(display_resolution[1]*0.5))
  
  drop_panel = widget_base(right_pane,/row)
  
  dl = WIDGET_DROPLIST(drop_panel,value=status.spectro.pixel_types,uvalue="pixel_type")
  widget_control, dl , SET_DROPLIST_SELECT = multi ? 1 : 0
  
  dl = WIDGET_DROPLIST(drop_panel,value=status.map.img_algos[1,*] ,uvalue="img_algo")
  
  dump_b = widget_button(drop_panel,value="save" ,uvalue="save")
  
  status.spectro.draw = widget_draw(right_pane, uvalue='draw_spectro', xsize=fix(display_resolution[0]*0.428), ysize=fix(display_resolution[1]*0.28), /button, retain=2)
    
  ;add time and energy labels
  status.spectro.lab_time = widget_label(right_pane, value='Time:                                                ', /align_left)
  status.spectro.lab_energy = widget_label(right_pane, value='Energy:                                            ',/align_left)
  
  controls_pane=widget_base(right_pane,/row, /frame)
  
  btn_bw = widget_button(controls_pane, uvalue='bw', value='BW')
  btn_color = widget_button(controls_pane, uvalue='color', value='Color')
  
  chechbox_panel = widget_base(controls_pane,/row, /NonExclusive)
  c = widget_button(chechbox_panel, Value='Global Scale', uvalue='globalscale')
  widget_control, c , Set_Button=0
  c = widget_button(chechbox_panel, Value='Y-Log', uvalue='ylog')
  widget_control, c , Set_Button=1
  c = widget_button(chechbox_panel, Value='Sin-Fit', uvalue='sinfit')
  widget_control, c , Set_Button=0
  c = widget_button(chechbox_panel, Value='SmallPixel x10', uvalue='smallPixelBoost')
  widget_control, c , Set_Button=0

  
  detector_pane=widget_base(right_pane, /frame, /column)
  
  detectorA_row=widget_base(detector_pane, /row, /nonexclusive, space=1)
  for index = 1, 9 do begin
    r=widget_button(detectorA_row, value=" ", uvalue="detector", uname="A"+trim(index))
    Widget_Control, r, Set_Button=1
  endfor
  r=widget_button(detectorA_row, value="A", uvalue="detector", uname="A10")
  Widget_Control, r, Set_Button=1
  ;all in a row
  r=widget_button(detectorA_row, value="All", uvalue="detector", uname="A")
  Widget_Control, r, Set_Button=1
  
  detectorB_row=widget_base(detector_pane, /row, /nonexclusive, space=1)
  for index = 1, 9 do begin
    r=widget_button(detectorB_row, value=" ", uvalue="detector", uname="B"+trim(index))
    Widget_Control, r, Set_Button=1
  endfor
  r=widget_button(detectorB_row, value="B", uvalue="detector", uname="B10")
  Widget_Control, r, Set_Button=1
  ;all in b row
  r=widget_button(detectorB_row, value="All", uvalue="detector", uname="B")
  Widget_Control, r, Set_Button=1
  
  detectorC_row=widget_base(detector_pane, /row, /nonexclusive, space=1)
  for index = 1, 9 do begin
    r=widget_button(detectorC_row, value=" ", uvalue="detector", uname="C"+trim(index))
    Widget_Control, r, Set_Button=1
  endfor
  r=widget_button(detectorC_row, value="C", uvalue="detector", uname="C10")
  Widget_Control, r, Set_Button=1
  ;all in c row
  r=widget_button(detectorC_row, value="All", uvalue="detector", uname="C")
  Widget_Control, r, Set_Button=1
  
  detectorLabel_row=widget_base(detector_pane, /row, /frame, /nonexclusive, space=-2)
  
  ;draw 1-10 Labels 
  
  for index = 1, 11 do begin
    r=widget_button(detectorLabel_row, value=index eq 11 ? "All" : trim(index), uvalue="detector", uname=trim(index))
    Widget_Control, r, Set_Button=1
  endfor
  
  status.map.draw = widget_draw(right_pane, uvalue='draw_map', xsize=fix(display_resolution[0]*0.428), ysize=fix(display_resolution[1]*0.35))
  
  ;build the widget
  widget_control, main, /realize
  
  
  
  
  case (status.pixel_renderer) of
    1: begin
       ;get pixel windows
       widget_control, status.pixel.draw, get_value = win ;get the window id
       status.pixel.window = win
       status.pixel.detector_plotter =  stx_detector_plotter(win)
       
    end
    2: begin
       ;get pixel windows
       widget_control, status.pixel.draw, get_value = win ;get the window id
       status.pixel.window = win
       status.pixel.detector_plotter =  stx_gr_detector_plotter(win, status.map.subc_str)
    end
    3: begin
       ;get pixel windows
       widget_control, status.pixel.draw, get_value = win_id ;get the window id
       status.pixel.window_id = win_id
    end
    else: begin
      
        message, "unknown pixel renderer"
    end
  endcase
  
 
  
  
  
  widget_control, status.spectro.draw, get_value = win_id ;get the window id
  status.spectro.window_id = win_id
  
  widget_control, status.map.draw,  get_value = win_id  
  status.map.window_id = win_id
  
  widget_control, status.vis.draw, get_value = win_id ;get the window id
  status.vis.window_id = win_id
  
  xmanager, 'stx_pixel_data_viewer', main, /no_block, cleanup="stx_pixel_data_viewer_cleanup"
  
  current_window = !D.WINDOW
  
  update_spectrogram, status
  update_map, status
  update_vis, status
  update_pixel, status
  
  all_status[main] = status
  
  wset, current_window
end
