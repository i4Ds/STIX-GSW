;+
; :file_comments:
;   The pixel plot object. It can be used to plot detectors with each pixel.
;   
; :categories:
;   Plotting, GUI
;   
; :examples:
;
; :history:
;    17-Dec-2015 - Roman Boutellier (FHNW), Initial release
;-

;+
; :description:
;    This function initializes the object. It is called automatically upon creation of the object.
;
; :returns:
;
; :history:
;    17-Dec-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_pixel_plot::init, pixel_data=pixel_data, nmbr_detectors=nmbr_detectors
  ; Initialize the status
  self.pixel_plot_status = hash()

  return, 1
end

;+
; :description:
;    This procedure plots the state of 1, 3, 10 or 32 detectors.
;    Each of the pixels of every detector is colored according to the
;    number of counts. Above the detector, a number shows the total
;    counts for this detector.
;    To draw the detectors a widget is created.
;
; :Keywords:
;    pixel_data, in, required, type='stx_pixel_data'
;         The input data, containing the [32,12] array of counts for each of the 12
;         pixels of each of the 32 detectors
;
; :returns:
;    -
;
; :history:
;    17-Dec-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_pixel_plot::plot, pixel_data=pixel_data, nmbr_detectors=nmbr_detectors

  ; Set the default values
  default, pixel_sum_scheme, 0
  default, nmbr_detectors, 32
  default, draw_xsize, 1200
  default, draw_ysize, 800
  
  ; Get the pixel summation scheme
  if (size(pixel_data.counts))[0] eq 2 then begin
    number_entries_per_pixel = (size(pixel_data.counts))[2]
    case number_entries_per_pixel of
      3     : pixel_sum_scheme = 1
      4     : pixel_sum_scheme = 2
      else  : pixel_sum_scheme = 0
    endcase
  endif else begin
    number_entries_per_pixel = (size(pixel_data.counts))[1]
    case number_entries_per_pixel of
      3     : pixel_sum_scheme = 1
      4     : pixel_sum_scheme = 2
      else  : pixel_sum_scheme = 0
    endcase
  endelse
  
  ; Prepare the draw window sizes
  case nmbr_detectors of
    1 : begin
          draw_xsize = 450
          draw_ysize = 450
        end
    3 : begin
          draw_xsize = 450
          draw_ysize = 450
        end
    10: begin
          draw_xsize = 1090
          draw_ysize = 450
        end
    else: begin
          draw_xsize = 1200
          draw_ysize = 800
        end
  endcase
  
  
  ; Create the base window and the draw area
  tlb = widget_base(title='Pixel Plot', /tlb_size_events, uvalue=self)
  ; Create the draw window
  draw_window = widget_draw(tlb, uvalue='draw_pixel_window', uname='detectors_draw_window', xsize=draw_xsize, ysize=draw_ysize, GRAPHICS_LEVEL=2, Renderer=1, /button)
  ; Realize the window
  widget_control, tlb, /realize

  ; Get the window
  widget_control, draw_window, get_value = win ;get the window id
  window = win
  
  ; Load the color table and create the idlgrpalette
  TVLCT, r, g, b, /Get
  palette = idlgrpalette(r,g,b)

  ; Store different values to the status hash
  (self.pixel_plot_status)['draw_window'] = draw_window
  (self.pixel_plot_status)['pixel_data'] = pixel_data
  (self.pixel_plot_status)['palette'] = palette
  (self.pixel_plot_status)['nmbr_detectors'] = nmbr_detectors

  ; Get the configuration manager and create the subc_file and subc_str
  confm = stx_configuration_manager(application_name='stx_analysis_software')
  subc_file = confm->get(/subc_file, /single)
  subc_str = stx_construct_subcollimator(subc_file)
  ; Get the detector plotter
  self.detector_plotter =  stx_detector_plot(window, subc_str, nmbr_detectors=nmbr_detectors, pixel_sum_scheme=pixel_sum_scheme)
  
  ; Update the detectors
  self->update_detectors
  
  ; Start the xManager - it uses the default event handler stx_pixel_plot_event
  xmanager, 'stx_pixel_plot', tlb, /no_block, cleanup='stx_pixel_plot_cleanup'
end


;+
; :description:
;    Event handler for the stx_test_draw_pixel widgets.
;
; :Params:
;    ev, in, required
;         The event which has been fired
;
; :returns:
;    -
;    
; :history:
;    15-Oct-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_pixel_plot_event, ev
  ; Get the stx_pixel_plot object and call the event handler
  widget_control, ev.top, get_uvalue=owidget
  owidget->_handle_event, ev
end

pro stx_pixel_plot::_handle_event, ev
;  ; Get the uvalue of the event (used to decide which action will be taken)
;  widget_control, ev.id, get_uvalue=uvalue
;  ; If the uvalue is undefined, set it to 'resize'
;  checkvar, uvalue, 'resize'
  
  ; In case there is a 'press' parameter in ev, the window has been clicked.
  ; Therefore set uvalue to 'draw_pixel_window'. Otherwise a resize event has been
  ; triggered and the uvalue is set to 'resize'
  if tag_exist(ev,'press') then uvalue='draw_pixel_window' else uvalue='resize'
  
  ; Distinguish between the different uvalues
  case uvalue of
    ; Handle a click on one of the detectors
    'draw_pixel_window'      : begin
        if ev.press then self.detector_plotter->hitTest, [ev.x,ev.y], times = ev.CLICKS
    end
    ; Handle resize events
    'resize'                 : begin
        ; Set the new sizes of the window
        widget_control, (self.pixel_plot_status)['draw_window'], xsize=ev.x
        widget_control, (self.pixel_plot_status)['draw_window'], ysize=ev.y
        ; Update the detectors
        self->update_detectors
    end                
    else            : ; Do nothing              
   endcase
end

;+
; :description:
;    Updating the detectors.
;
; :Params:
;
; :returns:
;     -
;     
; :history:
;    17-Dec-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_pixel_plot::update_detectors
  ; Set the data
  self.detector_plotter->setData, (self.pixel_plot_status)['pixel_data'], dscale=0, showsin=0, $
                                  smallpixelboost=1, palette=(self.pixel_plot_status)['palette'], $
                                  nmbr_detectors=(self.pixel_plot_status)['nmbr_detectors']
end

pro stx_pixel_plot__define
  compile_opt idl2
  
  define = {stx_pixel_plot, $
    pixel_plot_status: hash(), $
    detector_plotter: obj_new() $
  }
end