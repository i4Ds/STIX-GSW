function stx_gr_detector_plotter::init, win, subc_str, _EXTRA=ex
 
  self.detectors = make_array(32,/obj)

  gr = IDLgrModel()
  
  self.subc_str = ptr_new(subc_str)
  
  ;o = [10,4,27,12,22,20,17,5,25,11,29,3,18,1,15,16,14,13,6,26,31,28,30,2,0,23,19,24,7,21,9,8]
  o = [11,13,18,12,19,17,7,29,1,25,5,23,6,30,2,15,27,31,24,8,28,21,26,4,16,14,32,3,20,22,10,9]
  ;o -= 1
  o -= 1
  i = 0
  
  TVLCT, r, g, b, /Get
  self.palette =   idlgrpalette(r,g,b)
   
  self.detectors[o[i]] = stx_gr_detector(name='1a', palette =self.palette)
  self.detectors[o[i++]].translate, 7,12,0
  
  self.detectors[o[i]] = stx_gr_detector(name='1b', palette=self.palette)
  self.detectors[o[i++]].translate, 7,7,0
  
  self.detectors[o[i]] = stx_gr_detector(name='1c', palette=self.palette)
  self.detectors[o[i++]].translate, 7,2,0
  
  
  self.detectors[o[i]] = stx_gr_detector(name='2a', palette =self.palette)
  self.detectors[o[i++]].translate, 12,12,0
  
  self.detectors[o[i]] = stx_gr_detector(name='2b', palette =self.palette)
  self.detectors[o[i++]].translate, 12,7,0
  
  self.detectors[o[i]] = stx_gr_detector(name='2c', palette =self.palette)
  self.detectors[o[i++]].translate, 12,2,0
  
  
  self.detectors[o[i]] = stx_gr_detector(name='3a', palette =self.palette)
  self.detectors[o[i++]].translate, 17,12,0
  
  self.detectors[o[i]] = stx_gr_detector(name='3b', palette =self.palette)
  self.detectors[o[i++]].translate, 17,7,0
  
  self.detectors[o[i]] = stx_gr_detector(name='3c', palette =self.palette)
  self.detectors[o[i++]].translate, 17,2,0
  
  
  self.detectors[o[i]] = stx_gr_detector(name='4a', palette =self.palette)
  self.detectors[o[i++]].translate, 22,12,0
  
  self.detectors[o[i]] = stx_gr_detector(name='4b', palette =self.palette)
  self.detectors[o[i++]].translate, 22,7,0
  
  self.detectors[o[i]] = stx_gr_detector(name='4c', palette =self.palette)
  self.detectors[o[i++]].translate, 22,2,0
  
  self.detectors[o[i]] = stx_gr_detector(name='5a', palette =self.palette)
  self.detectors[o[i++]].translate, 27,12,0
  
  self.detectors[o[i]] = stx_gr_detector(name='5b', palette =self.palette)
  self.detectors[o[i++]].translate, 27,7,0
  
  self.detectors[o[i]] = stx_gr_detector(name='5c', palette =self.palette)
  self.detectors[o[i++]].translate, 27,2,0
  
  
  self.detectors[o[i]] = stx_gr_detector(name='6a', palette =self.palette)
  self.detectors[o[i++]].translate, 32,12,0
  
  self.detectors[o[i]] = stx_gr_detector(name='6b', palette =self.palette)
  self.detectors[o[i++]].translate, 32,7,0
  
  self.detectors[o[i]] = stx_gr_detector(name='6c', palette =self.palette)
  self.detectors[o[i++]].translate, 32,2,0
  
  
  self.detectors[o[i]] = stx_gr_detector(name='7a', palette =self.palette)
  self.detectors[o[i++]].translate, 37,12,0
  
  self.detectors[o[i]] = stx_gr_detector(name='7b', palette =self.palette)
  self.detectors[o[i++]].translate, 37,7,0
  
  self.detectors[o[i]] = stx_gr_detector(name='7c', palette =self.palette)
  self.detectors[o[i++]].translate, 37,2,0
  
  
  self.detectors[o[i]] = stx_gr_detector(name='8a', palette =self.palette)
  self.detectors[o[i++]].translate, 42,12,0
  
  self.detectors[o[i]] = stx_gr_detector(name='8b', palette =self.palette)
  self.detectors[o[i++]].translate, 42,7,0
  
  self.detectors[o[i]] = stx_gr_detector(name='8c', palette =self.palette)
  self.detectors[o[i++]].translate, 42,2,0
  
  
  self.detectors[o[i]] = stx_gr_detector(name='9a', palette =self.palette)
  self.detectors[o[i++]].translate, 47,12,0
  
  self.detectors[o[i]] = stx_gr_detector(name='9b', palette =self.palette)
  self.detectors[o[i++]].translate, 47,7,0
  
  self.detectors[o[i]] = stx_gr_detector(name='9c', palette =self.palette)
  self.detectors[o[i++]].translate, 47,2,0
  
  self.detectors[o[i]] = stx_gr_detector(name='10a', palette =self.palette)
  self.detectors[o[i++]].translate, 52,12,0
  
  self.detectors[o[i]] = stx_gr_detector(name='10b', palette =self.palette)
  self.detectors[o[i++]].translate, 52,7,0
  
  self.detectors[o[i]] = stx_gr_detector(name='10c', palette =self.palette)
  self.detectors[o[i++]].translate, 52,2,0
 
  self.detectors[o[i]] = stx_gr_detector(name='bkg', palette =self.palette)
  self.detectors[o[i++]].translate, 2,2,0
  
  self.detectors[o[i]] = stx_gr_detector(name='cfl', palette =self.palette)
  self.detectors[o[i++]].translate, 2,7,0
  
  gr->add, self.detectors
  
  self.labels = hash()
  
  label = idlgrtext(["type","TotCount:","Time","Energy"], name="str_info", location=[[0,18,1],[0,17,1],[0,16,1],[0,15,1]])
  gr->add, label
  (self.labels)['info'] = label
  
  label = idlgrtext("| left", name="cbar_left", location=[13,16.5,0], ALIGNMENT=0)
  gr->add, label
  (self.labels)['cbar_left'] = label
  
  label = idlgrtext("m|m", name="cbar_center", location=[33,16.5,0], ALIGNMENT=0.5)
  gr->add, label
  (self.labels)['cbar_center'] = label
  
  label = idlgrtext("right |", name="cbar_right", location=[53,16.5,0], ALIGNMENT=1)
  gr->add, label
  (self.labels)['cbar_right'] = label
  
  
  gr->add, idlgrtext("CF/BG", name="str_CFLBKG", location=[0,10,0])
  
  self.cbar = idlgrcolorbar(DIMENSIONS=[40,2], /SHOW_OUTLINE, pallete=self.palette)
  self.cbar->Translate, 13,17.5, 0
  gr->add, self.cbar
  
  self.view = OBJ_NEW('IDLgrView', VIEWPLANE_RECT=[-1,0,55,20])
  self.view->add, gr
  
  self.window = win
  
  return, 1b
end

pro stx_gr_detector_plotter::cleanup
  
  obj_destroy, self.detectors
  obj_destroy, self.cbar
  obj_destroy, self.palette
  heap_free, self.subc_str
  obj_destroy, self.labels
  obj_destroy, self.view
  self->idl_object::cleanup
end

pro stx_gr_detector_plotter::hitTest, xy, times=times
  obj = self.window->select(self.view, xy)
  
  default, times, 1
  
  if ~is_object(obj[0]) then return
  
  ;for i=0, n_elements(obj)-1 do print, obj[i].name
   
   obj = obj[0]
   
   detector = obj.parent
   if isa(detector, 'stx_gr_detector') then begin
      case (times) of
        2: begin
          name = strlowcase(detector.name)
          
          cols = *self.subc_str
          col = cols[where(cols.LABEL eq name)]
          
          if name eq 'bkg' || name eq 'cfl' then return
          
          col_gr_obj = stx_gr_collimator(front=col.front, rear=col.rear, distance_front_rear=5000)
          xobjview, col_gr_obj, /double_view, /modal,xsize=500, ysize=500 
          
        end
        else: begin
           print, detector
        end
      endcase
   endif
  
end

pro stx_gr_detector_plotter::setData, pixel_data, dscale=dscale, showsin=showsin, smallpixelboost=smallpixelboost, palette=palette
  
  default, showsin, 0
  default, smallpixelboost, 1
  
  if ~isa(pixel_data) OR ppl_typeof(pixel_data,compareto="stx_visibility_bag")  then begin
    nodataview = obj_new('IDLgrView', VIEWPLANE_RECT=[-1,0,55,20])
    gr = IDLgrModel()
    gr->add, idlgrtext("no valid data found", name="nodatalabel", location=[13,16.5,0], ALIGNMENT=0)
    nodataview->add, gr
    self.window->draw, nodataview
    return
  end
  
  if isa(palette, 'idlgrpalette') then self.palette=palette
  if isa(palette, /number) then self.palette.loadCT, palette
  
  if keyword_set(dscale) && n_elements(dscale) eq 2 then begin
    datarange = dscale
  end else begin
    datarange = minmax(pixel_data.counts[0:29,*])
  end
  
  ; enlarge the maximum range
  datarange[1] = round(datarange[1] * 1.05)
  
  total_count = ulong64(0)
   
  
  self.cbar->setProperty, palette=self.palette 
  
  (self.labels)['cbar_left']->setProperty, strings=trim(fix(datarange[0]))
  (self.labels)['cbar_center']->setProperty, strings=trim(fix(mean(datarange)))
  (self.labels)['cbar_right']->setProperty, strings=trim(fix(datarange[1]))
  
  for i=0, 31 do begin
     self.detectors[i]->setProperty, datarange=datarange, uvalue=pixel_data.counts[i,*], showsin=showsin, smallpixelboost=smallpixelboost, palette=self.palette
     if self.detectors[i].name eq "cfl" || self.detectors[i].name eq "bkg" then continue
     total_count += total(pixel_data.counts[i,*])
     
     ;print, self.detectors[i].name,  pixel_data.counts[i,*]
     
  end
  
  datasource = tag_exist(pixel_data, "datasource") ? "DataSource: "+pixel_data.datasource : ""
  
  (self.labels)["info"]->setProperty, strings=[pixel_data.type, $ 
                                    "TotCount: "+trim(total_count), $
                                    "Energy: "+trim(pixel_data[0].energy_range[0])+"-"+trim(pixel_data[0].energy_range[1])+"keV", $
                                    "Time: "+stx_time2any(pixel_data[0].time_range[0],/ECS)+" Duration: "+trim(stx_time_diff(pixel_data[0].time_range[1],pixel_data[0].time_range[0]))+"sec " + datasource]
  
  self.window->draw, self.view
end

pro stx_gr_detector_plotter__define
   void = { stx_gr_detector_plotter, $
    detectors       : make_array(32, /obj), $
    view            : obj_new(), $
    window          : obj_new(), $
    subc_str        : ptr_new(), $
    labels          : hash(), $
    palette         : obj_new(), $
    cbar            : obj_new(), $
    inherits        idl_object $
  }
end