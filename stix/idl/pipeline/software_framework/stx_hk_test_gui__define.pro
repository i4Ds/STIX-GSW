function stx_hk_test_gui::init
  compile_opt idl2
  
  ; Initialize the base class
  a = self->stx_gui_base::init()
  
  ; Get the hk plotter
  self.hk_plotter_test = obj_new('stx_HK_plotter_test')
  
  ; Get the content widget id
  content_widget = self->stx_gui_base::get_content_widget_id()
  
  ; Create the widgets
  self->_create_widgets_hk_test_gui, content_widget_id=content_widget
  ; Realize the widgets
  self->stx_gui_base::realize_widgets
  ; Start the xmanager
  self->_start_xmanager_hk_test_gui
  
  self->_plot_test_plots
  
  return, 1
end

pro stx_hk_test_gui::cleanup
  compile_opt idl2
  
end

pro stx_hk_test_gui::_create_widgets_hk_test_gui, content_widget_id=content_widget_id

  ; Create the base widget
  self.base_widget_stx_hk_test_gui = widget_base(content_widget_id,title='STIX HK Plots', /column, xsize=810, ysize=810, uvalue=self)
  ; Add two row bases which will hold two plots each
  widget_row_1 = widget_base(self.base_widget_stx_hk_test_gui,uname='hk_plots_row_1',xsize=810,ysize=400,/row)
  widget_row_2 = widget_base(self.base_widget_stx_hk_test_gui,uname='hk_plots_row_2',xsize=810,ysize=400,/row)
  ; Add the 4 bases which will hold the windows
  hk_window_base_1 = widget_base(widget_row_1,uname='hk_plots_window_base_1',xsize=400,ysize=400)
  hk_window_base_2 = widget_base(widget_row_1,uname='hk_plots_window_base_2',xsize=400,ysize=400)
  hk_window_base_3 = widget_base(widget_row_2,uname='hk_plots_window_base_3',xsize=400,ysize=400)
  hk_window_base_4 = widget_base(widget_row_2,uname='hk_plots_window_base_4',xsize=400,ysize=400)
  ; Add the 4 windows
  self.hk_window_1 = widget_window(hk_window_base_1,uname='hk_plots_window_1',xsize=400,ysize=400)
  self.hk_window_2 = widget_window(hk_window_base_2,uname='hk_plots_window_2',xsize=400,ysize=400)
  self.hk_window_3 = widget_window(hk_window_base_3,uname='hk_plots_window_3',xsize=400,ysize=400)
  self.hk_window_4 = widget_window(hk_window_base_4,uname='hk_plots_window_4',xsize=400,ysize=400)
end

pro stx_hk_test_gui::_start_xmanager_hk_test_gui
  xmanager, 'stx_hk_test_gui', self.base_widget_stx_hk_test_gui, /no_block, cleanup='stx_hk_test_gui_cleanup'
end

pro stx_hk_test_gui_cleanup, base_widget_software_framework
  widget_control, base_widget_software_framework, get_uvalue=owidget
  if owidget ne !NULL then begin
    owidget->_cleanup_widgets_hk_test_gui, base_widget_software_framework
  endif
end

pro stx_hk_test_gui::_cleanup_widgets_hk_test_gui, base_widget_software_framework
  obj_destroy, self
end

pro stx_hk_test_gui::_plot_test_plots
  ; Get each window and then plot an hk plot into it
  widget_control,self.hk_window_1,get_value=window1
  window1.select
  self.hk_plotter_test.plot,112233,112244,/PSU_temp,/attenuator_voltage,position=[0.15,0.15,0.85,0.85]
  
  widget_control,self.hk_window_2,get_value=window2
  window2.select
  self.hk_plotter_test.plot,112233,112244,/IDPU_temp_1,/IDPU_temp_2,position=[0.15,0.15,0.85,0.85]
  
  widget_control,self.hk_window_3,get_value=window3
  window3.select
  self.hk_plotter_test.plot,112233,112244,/current_15,/current_25,position=[0.15,0.15,0.85,0.85]
  
  widget_control,self.hk_window_4,get_value=window4
  window4.select
  self.hk_plotter_test.plot,112233,112244,/HV_PSU_voltage_1,/HV_PSU_voltage_2,position=[0.15,0.15,0.85,0.85]
end

pro stx_hk_test_gui__define
  compile_opt hidden, idl2
  
  define = { stx_hk_test_gui, $
    base_widget_stx_hk_test_gui: 0l, $
    hk_window_1: 0L, $
    hk_window_2: 0L, $
    hk_window_3: 0L, $
    hk_window_4: 0L, $
    hk_plotter_test: obj_new(), $
    inherits stx_gui_base $
  }
end