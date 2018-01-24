;+
; :file_comments:
;   This is the GUI for the energy calibration spectra.
;
; :categories:
;   energy calibration, software, gui
;
; :examples:
;
; :history:
;    15-Jun-2015 - Roman Boutellier (FHNW), Initial release
;    16-Jun-2015 - Roman Boutellier (FHNW), Added skeleton code for the fit plot, skeleton code for the calibrated plot
;-

;+
; :description:
; 	  This function initializes the object. It is called automatically upon creation of the object.
;
; :returns:
;
; :history:
; 	 15-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_energy_calibration_spectra_gui::init, stx_software_framework=stx_software_framework

  ; Initialize the base class
  base_init = self->stx_gui_base::init(/no_file_menu_entries)
  
  ; Store the link to the software framework
  self.stx_software_framework = stx_software_framework
  
  ; Set the default value for the display of the subspectra to new graphics
  self.adc_new_graphics_selected = 1
  
  ; Initialize the number of the subspectrum currently showed
  self.adc_subspectra_currently_showed = ptr_new([0])
  
  ; Initialize the pointer to the array which holds the ids of the pixel buttons for the adc tab
  self.adc_pixels_buttons_ids = ptr_new()
  
  ; Get the content widget id
  content_widget = self->stx_gui_base::get_content_widget_id()
  ; Get the button bar widget id
  button_bar_widget = self->stx_gui_base::get_button_bar_widget_id()
  
  ; Create the widgets
  self->_create_widgets_energy_calibration_spectra, content_widget=content_widget, button_bar_widget=button_bar_widget
  ; Realize the widgets by calling the realize_widgets method of the base class
  self->stx_gui_base::realize_widgets
  ; Start the XManager
  self->_start_xmanager_energy_calibration_spetra
  
  ; TESTING
  ; Get the test data
  self->_load_and_plot_data, /default
  
  return, base_init
end


;+
; :description:
; 	 The cleanup procedure of this object. It is called upon destruction of the object.
;
; :returns:
;
; :history:
; 	 15-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::cleanup
  if obj_valid(self.adc_plot_creator_object) then obj_destroy, self.adc_plot_creator_object
end

;+
; :description:
; 	 FOR TESTING ONLY
; 	 This functin loads the selected bin file with the data of the energy calibration spectra.
;
; :Keywords:
;    filename
;
; :returns:
;
; :history:
; 	 24-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function load_energy_calibration_spectrum, filename=filename
  default, filename, 'tmtc_test_1.bin'
  
  ; Read the telemetry file
  tmr = stx_telemetry_reader(filename=filename)
  solo_packet_read = tmr->read_packet_structure_source_packet_header()
  
  ; Check/Get some data
  stx_telemetry_encode_decode_structure_ql_calibration_spectrum, input=(*solo_packet_read.source_data).subspectrum_definition_1, ni_wi_li=ni_wi_li
  stx_telemetry_encode_decode_structure_ql_calibration_spectrum, input=(*solo_packet_read.source_data).detector_mask, detector_mask=detector_mask
  stx_telemetry_encode_decode_structure_ql_calibration_spectrum, input=(*solo_packet_read.source_data).pixel_mask, pixel_mask=pixel_mask
  stx_telemetry_encode_decode_structure_ql_calibration_spectrum, input=(*solo_packet_read.source_data).subspectrum_mask, subspectrum_mask=subspectrum_mask
  start_time = (*solo_packet_read.source_data).start_time
  duration = (*solo_packet_read.source_data).start_time
  ; Extract the number of subspectra and the indices
  indices_used_subspectra = where(subspectrum_mask eq 1, nmbr_subspectra)
  ; Store the subspectra
  ; First create a calibration spectrum object
  asw_calib = stx_asw_ql_calibration_spectrum(number_of_subspectra=nmbr_subspectra)
  ; Create the start-time stx_time and end-time stx_time
  start_time_stx = stx_construct_time(time=start_time)
  end_time_stx = stx_construct_time(time=(start_time + duration))
  ; Set the times
  asw_calib.start_time = start_time_stx
  asw_calib.end_time = end_time_stx
  
  ; Go over every subspectrum and set the data
  for i=0, nmbr_subspectra-1 do begin
    asw_calib.subspectra[i].spectrum = (*(*(*solo_packet_read.source_data).subspectra)[0])[2:*,*,*]
    asw_calib.subspectra[i].pixel_mask = pixel_mask
    asw_calib.subspectra[i].detector_mask = detector_mask
    asw_calib.subspectra[i].number_of_spectral_points = ni_wi_li[0]
    asw_calib.subspectra[i].number_of_summed_channels = ni_wi_li[1]
    asw_calib.subspectra[i].lower_energy_bound_channel = ni_wi_li[2]
  endfor
  
  return, asw_calib
end

;+
; :description:
; 	 FOR TESTING ONLY
; 	 This functino returns a energy calibration spectrum with some random test data.
;
; :returns:
;
; :history:
; 	 21-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function get_example_data_ecs
  ; Prepare the array of subspectra
  default_subspectrum = { $
      type: 'stx_asw_ql_calibration_subspectrum', $
      spectrum: make_array(1024,12,32), $
      lower_energy_bound_channel: 3, $
      number_of_summed_channels: 2, $
      number_of_spectral_points: 127, $
      pixel_mask: make_array(12, value=1), $
      detector_mask: make_array(32, value=1) $
    }
  ; Prepare the return struct
  energy_calibration_spectrum_struct = {$
      type: 'stx_asw_ql_calibration_spectrum', $
      start_time: stx_time(), $
      end_time: stx_time(), $
      subspectra: replicate(default_subspectrum, 8) $
    }
  ; Get the number of entries before the spikes and after the spikes
  nmbr_before_spikes = fix(randomu(seed)*912)
  nmbr_after_spikes = 912 - nmbr_before_spikes
  if nmbr_before_spikes eq 0 then begin
    nmbr_before_spikes = 1
    nmbr_after_spikes = 911
  endif
  ; Create a total of 8 subspectra
  for i=0, 7 do begin
    ; Prepare the array holding all the values for a subspectra
    det = make_array(1024,12,32)
    ; Create values for every detector
    for j=0, 31 do begin
      ; The values for the spikes
      de = fix([1,1,2,2,4,4,7,7,8,8,13,13,16,16,20,20,28,28,32,32,55,55,64,64,79,79,92,92,128,128,150,150,135,135,110,110,98,98,70,70,64,64,50,50,32,32,16,16,12,12,9,9,8,8,4,4,2,2, $
          1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,3,3,5,5,9,9,17,17,21,21,30,30,52,52,41,41,33,33,25,25,18,18,13,13,9,9,4,4,1,1,1,1,1,1,1,1,1,1] * (randomu(seed)+1)*1.2)
      ; Values before and after the spike
      val_before = fix(randomu(seed, nmbr_before_spikes) + 1)
      val_after = fix(randomu(seed, nmbr_after_spikes) + 1)
      ; Completed values
      all_val = [val_before, de, val_after]
      ; Prepare the values for the pixels
      pi = [[all_val], $
            [fix(all_val*(randomu(seed) + 1))], $
            [fix(all_val*(randomu(seed) + 1.5))], $
            [fix(all_val*(randomu(seed) + 2))], $
            [fix(all_val*(randomu(seed) + 2.9))], $
            [fix(all_val*(randomu(seed) + 3.4))], $
            [fix(all_val*(randomu(seed) + 4.5))], $
            [fix(all_val*(randomu(seed) + 5.7))], $
            [fix(all_val*(randomu(seed) + 6.2))], $
            [fix(all_val*(randomu(seed) + 7.5))], $
            [fix(all_val*(randomu(seed) + 8.9))], $
            [fix(all_val*(randomu(seed) + 9.4))]]
      det[*,*,j] = pi
    endfor
    energy_calibration_spectrum_struct.subspectra[i].spectrum = det
  endfor

  return, energy_calibration_spectrum_struct
end

;+
; :description:
; 	 Creating all the widgets which build the GUI for the energy calibration spectra
;
; :Keywords:
;    content_widget
;    button_bar_widget
;
; :returns:
;
; :history:
; 	 15-Jun-2015 - Roman Boutellier (FHNW), Initial release
; 	 16-Jun-2015 - Roman Boutellier (FHNW), Added skeleton code for the fit plot, skeleton code for the calibrated plot
;-
pro stx_energy_calibration_spectra_gui::_create_widgets_energy_calibration_spectra, content_widget=content_widget, button_bar_widget=button_bar_widget
  ; TODO
  ; Prepare the array containing the titles of the select buttons
  buttone_values = ['Pixel 0','Pixel 1','Pixel 2','Pixel 3','Pixel 4','Pixel 5','Pixel 6','Pixel 7','Pixel 8','Pixel 9','Pixel 10','Pixel 11']
  ; Create the top level base (i.e. the main window for this GUI)
  self.ecs_main_window_id = widget_base(content_widget,title='Energy Calibration Spectra', /column, uvalue=self)
  
  ; Register the GUI to the software framework
  self.stx_software_framework->register_energy_calibration_spectra_gui, widget_id=self.ecs_main_window_id
  
  ; Create the tab base
  self.tab_widget_energy_calibration_spectra_gui_id = widget_tab(self.ecs_main_window_id)
  
  ; Add the base of the adc count spectrum
  self.adc_count_spectrum_base_id = widget_base(self.tab_widget_energy_calibration_spectra_gui_id, title='ADC count spectrum', uname='adc_count_spectrum_area', /row)
  ; Add the plot window for the adc count spectrum
  self.adc_plot_window_id = widget_window(self.adc_count_spectrum_base_id, uname='adc_plot_window', xsize=800, ysize=550)
  ; Add the area for the selection of the spectra
  self.adc_spectrogram_selection_id = widget_base(self.adc_count_spectrum_base_id, uname='adc_count_spectra_selection_area', /column)
  ; Add the area for the plot options
  plot_options_area_id = widget_base(self.adc_spectrogram_selection_id, uname='plot_options_area', /column, frame=1)
  ; Add the area for the selection of the subspectra
  subspectra_selection_area_id = widget_base(plot_options_area_id, uname='adc_subspectra_selection_area', xsize=370, ysize=120, /column, /align_left)
  subspectra_selection_label = widget_label(subspectra_selection_area_id, uname='adc_subspectra_selection_label', value='Subspectra to plot:', /align_left)
  subspectra_selection_check_boxes_area_id = widget_base(subspectra_selection_area_id, uname='adc_subspectra_selection_check_boxes_area', /row, /align_left, /nonexclusive)
  self->_create_subspectra_buttons,base_id=subspectra_selection_check_boxes_area_id
;  self.adc_subspectra_selection_button_group = cw_bgroup(subspectra_selection_area_id, ['0','1','2','3','4','5','6','7'], /row, /nonexclusive, $
;                                                            set_value=[1,0,0,0,0,0,0,0], uvalue=[1,0,0,0,0,0,0,0], event_funct='adc_subspectra_selection_button_event')
  subspectra_number_plots_per_panel_area_id = widget_base(subspectra_selection_area_id, uname='adc_subspectra_number_plots_per_panel_area', /row, /align_left)
  subspectra_number_plots_per_panel_label_id = widget_label(subspectra_number_plots_per_panel_area_id, uname='adc_subspectra_number_plots_per_panel_label', value='Number of subspectra to plot in the panel: ', /align_left)
  self.adc_number_subspectra_per_plot_selection = widget_combobox(subspectra_number_plots_per_panel_area_id, uname='adc_subspectra_number_plots_per_panel_input', value=['1','2','3','4','5','6','7','8'], event_func='adc_subspectra_number_plots_per_channel_event')
;  self.adc_number_subspectra_per_plot_area = widget_text(subspectra_number_plots_per_panel_area_id, uname='adc_subspectra_number_plots_per_panel_input', /editable, /align_left)
  subspectra_selection_buttons_area_id = widget_base(subspectra_selection_area_id, uname='adc_subspectra_selection_buttons_area', xsize=370, /row, /align_left)
  subspectra_selection_select_all_button = widget_button(subspectra_selection_buttons_area_id, uname='adc_subspectra_selection_select_all_button', value='Select all subspectra', $
                                                            event_func='adc_subspectra_selection_select_all_button_event', xsize=180)
  subspectra_selection_deselect_all_button = widget_button(subspectra_selection_buttons_area_id, uname='adc_subspectra_selection_deselect_all_button', value='Deselect all subspectra', $
                                                            event_func='adc_subspectra_selection_deselect_all_button_event', xsize=180)
  ; Add the area for the setting if the detectors are summed up
  detector_sum_up_area_id = widget_base(plot_options_area_id, uname='detector_sum_up_area', ysize=25, /column, /nonexclusive)
  self.adc_detector_sum_up_checkbox = widget_button(detector_sum_up_area_id, value='Sum up detectors', event_func='adc_sum_up_detectors_button_event')
  widget_control, self.adc_detector_sum_up_checkbox, set_button=1
  ; Add the area for the selection of the detectors
  detectors_selection_area_id = widget_base(plot_options_area_id, uname='adc_detectors_selection_area', xsize=370, ysize=210, /column, /align_left)
  detectors_selection_label = widget_label(detectors_selection_area_id, uname='adc_detectors_selection_label', value='Detectors to use:', /align_left)
  self->_create_adc_detector_buttons, base_id=detectors_selection_area_id
  detectors_selection_buttons_area_id = widget_base(detectors_selection_area_id, uname='adc_detectors_selection_buttons_area', xsize=370, /row, /align_left)
  detectors_selection_select_all_button = widget_button(detectors_selection_buttons_area_id, uname='adc_detectors_selection_select_all_button', value='Select all detectors', $
                                                            event_func='adc_detectors_selection_select_all_button_event', xsize=180)
  detectors_selection_deselect_all_button = widget_button(detectors_selection_buttons_area_id, uname='adc_detectors_selection_deselect_all_button', value='Deselect all detectors', $
                                                            event_func='adc_detectors_selection_deselect_all_button_event', xsize=180)
  ; Add the buttons to cycle through subspectra
  cycle_through_subspectra_area_id = widget_base(plot_options_area_id, uname='adc_cycle_subspectra_area', xsize=370, ysize=25, /row, /align_left)
  self.adc_cycle_subspectrum_back_button = widget_button(cycle_through_subspectra_area_id, uname='adc_button_cycle_subspectra_back', value='Previous Subspectrum', $
                                      event_func='adc_button_cycle_subspectra_back_handler', xsize=180, sensitive=0)
  self.adc_cycle_subspectrum_forward_button = widget_button(cycle_through_subspectra_area_id, uname='adc_button_cycle_subspectra_forward', value='Next Subspectrum', $
                                        event_func='adc_button_cycle_subspectra_forward_handler', xsize=180, sensitive=0)
  ; Add the nonexclusive buttons to select the pixels
  pixel_selection_area_id = widget_base(plot_options_area_id, uname='adc_pixel_selection_area', xsize=370, ysize=130, /column, /align_left)
  pixel_selection_label = widget_label(pixel_selection_area_id, uname='adc_pixel_selection_label', value='Activate/Deactivate visibility of pixels')
  pixel_selection_checkboxes_area_id = widget_base(pixel_selection_area_id, uname='adc_pixel_selection_checkboxes_area', /row)
  self->_create_adc_pixel_buttons, adc_button_base_id=pixel_selection_checkboxes_area_id, button_values=buttone_values
  ; Add the update plot button
  set_plot_options_area_id = widget_base(plot_options_area_id, uname='adc_set_plot_options_area', xsize=370, ysize=25, /column, /align_center)
  plot_options_button = widget_button(set_plot_options_area_id, uname='button_plot_options', value='Update Plot', event_func='adc_button_update_plot_handler', xsize=100)
  
;  ; Add the base for the fit plot
;  self.fit_plot_base_id = widget_base(self.tab_widget_energy_calibration_spectra_gui_id, title='Fit', uname='fit_plot_area', /row)
;  ; Add the plot window for the fit plot
;  self.fit_plot_window_id = widget_window(self.fit_plot_base_id, uname='fit_plot_window', xsize=800, ysize=500)
;  ; Add the area for the selection of the spectra
;  self.fit_spectrogram_selection_id = widget_base(self.fit_plot_base_id, uname='fit_spectra_selection_area', xsize=100, /column)
;  ; Add the exclusive buttons (radio buttons)
;  self->_create_fit_buttons, fit_button_base_id=self.fit_spectrogram_selection_id, button_values=buttone_values
;  
;  ; Add the base for the calibrated spectrum
;  self.calibrated_plot_base_id = widget_base(self.tab_widget_energy_calibration_spectra_gui_id, title='Calibrated', uname='calibrated_plot_area', /row)
;  ; Add the plot window for the calibrated spectra
;  self.calibrated_plot_window_id = widget_window(self.calibrated_plot_base_id, uname='calibrated_plot_window', xsize=800, ysize=500)
;  ; Add the area for the selection of the spectra
;  self.calibrated_spectrogram_selection_id = widget_base(self.calibrated_plot_base_id, uname='calibrated_spectra_selection_area', xsize=100, /column)
;  ; Add the nonexclusive buttons
;  self->_create_calibrated_buttons, calibrated_button_base_id=self.calibrated_spectrogram_selection_id, button_values=buttone_values
;  
;  ; Add the base for the sum spectrum
;  self.sum_spectrum_base_id = widget_base(self.tab_widget_energy_calibration_spectra_gui_id, title='Sum energy spectrum', uname='sum_spectrum_plot_area', /row)
;  ; Add the plot window for the calibrated spectra
;  self.sum_spectrum_plot_window_id = widget_window(self.sum_spectrum_base_id, uname='sum_spectrum_plot_window', xsize=800, ysize=500)
;  ; Add the area for the selection of the spectra
;  self.sum_spectrum_spectrogram_selection_id = widget_base(self.sum_spectrum_base_id, uname='sum_spectrum_spectra_selection_area', xsize=100, /column)
;  ; Add the nonexclusive buttons
;  self->_create_sum_spectrum_buttons, sum_spectrum_button_base_id=self.sum_spectrum_spectrogram_selection_id, button_values=buttone_values
  
  ; Add the menu entry to load a save file
  ; Get the file menu widget id
  base_file_menu_id = self->stx_gui_base::get_file_menu_widget_id()
  load_save_file_menuItem = widget_button(base_file_menu_id, value='Load Save File', uname='load_save_file_menuItem', event_pro='adc_load_save_file_handler')
end

;+
; :description:
;    Start the xmanager to manage the widgets
;
; :returns:
;    -
;    
; :history:
;    23-Jun-2015 - Roman Boutellier (FHNW), initial release
;-
pro stx_energy_calibration_spectra_gui::_start_xmanager_energy_calibration_spetra
  xmanager, 'stx_energy_calibration_spectra_gui', self.ecs_main_window_id, /no_block, cleanup='stx_energy_calibration_spectra_gui_cleanup'
end

pro stx_energy_calibration_spectra_gui_cleanup, base_widget_energy_calibration_spectra_gui
  widget_control, base_widget_energy_calibration_spectra_gui, get_uvalue=owidget
  if owidget ne !NULL then begin
    owidget->_cleanup_widgets_energy_calibration_spectra_gui
  endif
end

pro stx_energy_calibration_spectra_gui::_cleanup_widgets_energy_calibration_spectra_gui
  obj_destroy, self
end

;+
; :description:
; 	 This procedure loads data from the given source, adapts the GUI to the values in the
; 	 data object and then plots the first subspectrum using the new graphics and summing
; 	 up all detectors.
;
; :Keywords:
;    default, optional
;       Set this keyword to load some random data - FOR TESTING
;       
;    pixel_mask, in, optional, type=[int]
;       This array contains 12 entries which must be either 0 or 1. If an entry is
;       0, the according pixel will not be plotted, otherwise it will be plotted.
;       The default value is [1,1,1,1,1,1,1,1,1,1,1,1]
;       
;    subspectra_to_plot, in, optional, type=[int]
;       This array contains the numbers of the subspectra which will be plotted.
;       The numbers are zero-based. An example entry would be [0,1,5,7], which results
;       in a total of 4 subspectra which are plotted.
;       The default value is [0]
;    
;    sum_up_detectors, in, optional, type='Integer'
;       This integer stores if the detectors should be summed up (value = 1, which results in
;       one plot per subspectrum) or if for every detector a single plot will be
;       created (value = 0) - the single plots can be switched through.
;       The default value is 1.
;       
;    detector_mask, in, optional, type=[int]
;       This array contains 32 entries which must be either 0 or 1. If an entry is
;       0, the according detector will not be plotted or used when summing up the
;       detectors. The default value is [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
;
; :returns:
;    -
;    
; :history:
; 	 17-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_load_and_plot_data, pixel_mask=pixel_mask, subspectra_to_plot=subspectra_to_plot, $
                                                              sum_up_detectors=sum_up_detectors, detector_mask=detector_mask, $
                                                              default=default

  ; Set the default values
  default, pixel_mask, [1,1,1,1,1,1,1,1,1,1,1,1]
  default, subspectra_to_plot, [0]
  default, sum_up_detectors, 1
  default, detector_mask, [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
  
  ; Load and store the data
  if n_elements(default) gt 0 then begin
    self.energy_calibration_spectrum_data = ptr_new(get_example_data_ecs())
  endif else begin
    
  endelse
  
  ; Create the pixel mask default value (in case the pixel_mask of a subspectrum shows that
  ; there is no data for a pixel, the default value will be accordingly changed when
  ; plotting)
  self->plot,energy_calibration_spectrum = *self.energy_calibration_spectrum_data, pixel_mask=pixel_mask, subspectra_to_plot=subspectra_to_plot, $
             sum_up_detectors=sum_up_detectors, detector_mask=detector_mask
end

;+
; :description:
;    Create all the checkboxes for the different subspectra to select/deselect them.
;
; :Keywords:
;    base_id
;
; :returns:
;
; :history:
;    24-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_create_subspectra_buttons, base_id=base_id
  ; Prepare the array to store the check box ids
  check_box_ids = make_array(8, value=0L)
  ; Create the check boxes
  for i=0,7 do begin
    ; Prepare the uname
    uname = 'adc_subspectrum_check_box_' + strtrim(i,2)
    ; Create the button
    check_box_ids[i] = widget_button(base_id, uname=uname, value=strtrim(i,2), event_func='adc_subspectra_selection_button_event')
  endfor
  ; Save the ids
  self.adc_subspectra_selection_button_ids = ptr_new(check_box_ids)
  ; Activate the first check box
  widget_control, check_box_ids[0], /set_button
end

;+
; :description:
; 	 Create all the checkboxes for the different detectors to select/deselect them.
;
; :Keywords:
;    base_id
;
; :returns:
;
; :history:
; 	 21-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_create_adc_detector_buttons, base_id=base_id
  ; Prepare the array to store the check box ids
  check_boxes_ids = make_array(32, value=0L)
  ; Create a total of two columns each containing check boxes for 5 detector categories (e.g. one
  ; category would be detectors 1a, 1b and 1c) and the last one also containing the checkboxes for the detectors
  ; cfl and bkg
  column_1 = widget_base(base_id, uname='adc_detector_check_boxes_base_area_1_id', /row)
  column_2 = widget_base(base_id, uname='adc_detector_check_boxes_base_area_2_id', /row)
  ; Add the buttons for the first column (1a-1c)
  buttons_1_area = widget_base(column_1, uname='adc_detector_check_boxes_area_1_id', /column, /nonexclusive)
  check_boxes_ids[0] = widget_button(buttons_1_area, uname='adc_detector_check_box_1a', value='1a', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[1] = widget_button(buttons_1_area, uname='adc_detector_check_box_1b', value='1b', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[2] = widget_button(buttons_1_area, uname='adc_detector_check_box_1c', value='1c', event_pro='adc_detector_selection_event_handler')
  ; Add the buttons for the first column (2a-2c)
  buttons_2_area = widget_base(column_1, uname='adc_detector_check_boxes_area_2_id', /column, /nonexclusive)
  check_boxes_ids[3] = widget_button(buttons_2_area, uname='adc_detector_check_box_2a', value='2a', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[4] = widget_button(buttons_2_area, uname='adc_detector_check_box_2b', value='2b', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[5] = widget_button(buttons_2_area, uname='adc_detector_check_box_2c', value='2c', event_pro='adc_detector_selection_event_handler')
  ; Add the buttons for the first column (3a-3c)
  buttons_3_area = widget_base(column_1, uname='adc_detector_check_boxes_area_3_id', /column, /nonexclusive)
  check_boxes_ids[6] = widget_button(buttons_3_area, uname='adc_detector_check_box_3a', value='3a', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[7] = widget_button(buttons_3_area, uname='adc_detector_check_box_3b', value='3b', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[8] = widget_button(buttons_3_area, uname='adc_detector_check_box_3c', value='3c', event_pro='adc_detector_selection_event_handler')
  ; Add the buttons for the first column (4a-4c)
  buttons_4_area = widget_base(column_1, uname='adc_detector_check_boxes_area_4_id', /column, /nonexclusive)
  check_boxes_ids[9] = widget_button(buttons_4_area, uname='adc_detector_check_box_4a', value='4a', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[10] = widget_button(buttons_4_area, uname='adc_detector_check_box_4b', value='4b', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[11] = widget_button(buttons_4_area, uname='adc_detector_check_box_4c', value='4c', event_pro='adc_detector_selection_event_handler')
  ; Add the buttons for the second column (5a-5c)
  buttons_5_area = widget_base(column_1, uname='adc_detector_check_boxes_area_5_id', /column, /nonexclusive)
  check_boxes_ids[12] = widget_button(buttons_5_area, uname='adc_detector_check_box_5a', value='5a', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[13] = widget_button(buttons_5_area, uname='adc_detector_check_box_5b', value='5b', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[14] = widget_button(buttons_5_area, uname='adc_detector_check_box_5c', value='5c', event_pro='adc_detector_selection_event_handler')
  ; Add the buttons for the second column (6a-6c)
  buttons_6_area = widget_base(column_2, uname='adc_detector_check_boxes_area_6_id', /column, /nonexclusive)
  check_boxes_ids[15] = widget_button(buttons_6_area, uname='adc_detector_check_box_6a', value='6a', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[16] = widget_button(buttons_6_area, uname='adc_detector_check_box_6b', value='6b', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[17] = widget_button(buttons_6_area, uname='adc_detector_check_box_6c', value='6c', event_pro='adc_detector_selection_event_handler')
  ; Add the buttons for the second column (7a-7c)
  buttons_7_area = widget_base(column_2, uname='adc_detector_check_boxes_area_7_id', /column, /nonexclusive)
  check_boxes_ids[18] = widget_button(buttons_7_area, uname='adc_detector_check_box_7a', value='7a', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[19] = widget_button(buttons_7_area, uname='adc_detector_check_box_7b', value='7b', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[20] = widget_button(buttons_7_area, uname='adc_detector_check_box_7c', value='7c', event_pro='adc_detector_selection_event_handler')
  ; Add the buttons for the second column (8a-8c)
  buttons_8_area = widget_base(column_2, uname='adc_detector_check_boxes_area_8_id', /column, /nonexclusive)
  check_boxes_ids[21] = widget_button(buttons_8_area, uname='adc_detector_check_box_8a', value='8a', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[22] = widget_button(buttons_8_area, uname='adc_detector_check_box_8b', value='8b', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[23] = widget_button(buttons_8_area, uname='adc_detector_check_box_8c', value='8c', event_pro='adc_detector_selection_event_handler')
  ; Add the buttons for the second column (9a-9c)
  buttons_9_area = widget_base(column_2, uname='adc_detector_check_boxes_area_9_id', /column, /nonexclusive)
  check_boxes_ids[24] = widget_button(buttons_9_area, uname='adc_detector_check_box_9a', value='9a', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[25] = widget_button(buttons_9_area, uname='adc_detector_check_box_9b', value='9b', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[26] = widget_button(buttons_9_area, uname='adc_detector_check_box_9c', value='9c', event_pro='adc_detector_selection_event_handler')
  ; Add the buttons for the second column (10a-10c)
  buttons_10_area = widget_base(column_2, uname='adc_detector_check_boxes_area_10_id', /column, /nonexclusive)
  check_boxes_ids[27] = widget_button(buttons_10_area, uname='adc_detector_check_box_10a', value='10a', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[28] = widget_button(buttons_10_area, uname='adc_detector_check_box_10b', value='10b', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[29] = widget_button(buttons_10_area, uname='adc_detector_check_box_10c', value='10c', event_pro='adc_detector_selection_event_handler')
  ; Add the buttons for the third column (cfl, bkg)
  buttons_11_area = widget_base(column_2, uname='adc_detector_check_boxes_area_11_id', /column, /nonexclusive)
  check_boxes_ids[30] = widget_button(buttons_11_area, uname='adc_detector_check_box_cfl', value='cfl', event_pro='adc_detector_selection_event_handler')
  check_boxes_ids[31] = widget_button(buttons_11_area, uname='adc_detector_check_box_bkg', value='bkg', event_pro='adc_detector_selection_event_handler')
  
  ; Save the ids
  self.adc_detectors_check_boxes_ids = ptr_new(check_boxes_ids)
  
  ; Activate all the check boxes
  for i=0, 31 do begin
    widget_control, check_boxes_ids[i], /set_button
  endfor
end

;+
; :description:
; 	 Event handler for selecting/deselecting any of the detectors.
; 	 This handler just intercepts any event caused by doing so to suppress
; 	 according error messages.
;
; :Params:
;    event, in, required
;
; :returns:
;
; :history:
; 	 22-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro adc_detector_selection_event_handler, event
  ; Do nothing - this procedure only exists to suppress any error message because of
  ; a missing event handler.
end

;+
; :description:
; 	 Create all the buttons (nonexclusive) which are part of the adc-plot to select the pixel within the
; 	 energy calibration spectra GUI.
;
; :Keywords:
;    adc_button_base_id
;    button_values
;
; :returns:
;
; :history:
; 	 15-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_create_adc_pixel_buttons, adc_button_base_id=adc_button_base_id, button_values=button_values
  pixel_check_boxes_ids = make_array(12,/long,value=0)
  for i=0, 2 do begin
    ; Create a new base widget
    current_base_id = widget_base(adc_button_base_id, uname='adc_pixel_selection_base_'+strtrim(i,2), /column, /align_left, /nonexclusive)
    for j=0, 3 do begin
      current_index = i*4 + j
      pixel_check_boxes_ids[current_index] = widget_button(current_base_id, value=button_values[current_index], event_func='adc_buttons_list_event_handler')
      widget_control, pixel_check_boxes_ids[current_index], /set_button
    endfor
  endfor
  ; Store the ids of the pixel check boxes
  self.adc_pixels_buttons_ids = ptr_new(pixel_check_boxes_ids)
;  self.adc_button_group_1 = cw_bgroup(adc_button_base_id, button_values[0:3], /column, /nonexclusive, set_value=[1,1,1,1], $
;                                     event_funct='adc_buttons_list_event_handler_1')
;  self.adc_button_group_2 = cw_bgroup(adc_button_base_id, button_values[4:7], /column, /nonexclusive, set_value=[1,1,1,1], $
;                                     event_funct='adc_buttons_list_event_handler_1')
;  self.adc_button_group_3 = cw_bgroup(adc_button_base_id, button_values[8:11], /column, /nonexclusive, set_value=[1,1,1,1], $
;                                     event_funct='adc_buttons_list_event_handler_1')
end

;+
; :description:
; 	 Event handler for the buttons of the adc count spectra
;
; :Params:
;    event
;
; :returns:
;
; :history:
; 	 15-Jun-2015 - Roman Boutellier (FHNW), Initial release
; 	 23-Sep-2015 - Roman Boutellier (FHNW), Function does no longer any action, it just exists to
; 	                                        prevent errors because of missing event handlers.
;-
function adc_buttons_list_event_handler, event
  ; Do nothing - this function only exists to prevent errors thrown because
  ; of unknown event handlers

;  ; Get the index of the clicked button
;;  ind_clicked_button = event.value
;  ; Get the gui object
;  widget_control, event.top, get_uvalue=gui_object
;  ; Call the handler
;  gui_object->_handle_adc_buttons_click;, button_clicked = ind_clicked_button
;  return, 1
end

;pro stx_energy_calibration_spectra_gui::_handle_adc_buttons_click;, button_clicked=button_clicked
;  ; Get the values of the check boxes
;  check_boxes_widget_ids = *self.adc_pixels_buttons_ids
;  selected_pixels_array = make_array(12,/integer,value=0)
;  for i=0, 11 do begin
;    selected_pixels_array[i] = widget_info(check_boxes_widget_ids[i], /button_set)
;  endfor
;;  widget_control, self.adc_button_group_1, get_value=selected_pixels_1
;;  widget_control, self.adc_button_group_2, get_value=selected_pixels_2
;;  widget_control, self.adc_button_group_3, get_value=selected_pixels_3
;;  
;;  ; Create an array of the three arrays containig the selected pixel values
;;  selected_pixels_array = [selected_pixels_1, selected_pixels_2, selected_pixels_3]
;  
;  ; Distinguish between direct graphics and new graphics
;  if self.adc_new_graphics_selected eq 1 then begin
;    ; Get the plot objects and plot/hide the according plots
;    for i=0,11 do begin
;      current_pixel_selection = selected_pixels_array[i]
;      array_of_pointer_to_plot_arrays = *self.adc_plot_objects
;      for j=0,size(array_of_pointer_to_plot_arrays,/n_elements)-1 do begin
;        if current_pixel_selection eq 0 then begin
;          (*array_of_pointer_to_plot_arrays[j])[i].hide = 1
;        endif else begin
;          (*array_of_pointer_to_plot_arrays[j])[i].hide = 0
;        endelse
;      endfor
;    endfor
;  endif else begin
;    print, 'Show/Hide Pixels in direct graphics...'
;  endelse
;end

;+
; :description:
; 	 Handles checking and unchecking of the subspectra checkboxes.
; 	 This function just calls the according method of the gui object.
;
; :Params:
;    event
;
; :returns:
;
; :history:
; 	 11-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function adc_subspectra_selection_button_event, event
  ; Get the gui object
  widget_control, event.top, get_uvalue=gui_object
  ; Call the handler
  gui_object->_handle_select_subspectra_button_click
  return, 1
end

;+
; :description:
;    This procedure is called upon checking or unchecking the checkbox for a subspectrum
;
; :returns:
;    -
;    
; :history:
;    11-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_handle_select_subspectra_button_click
  ; Do nothing - this function just ensures that no error message is thrown upon clicking
  ; the check-boxes

;  ; Get the values for every checkbox
;  widget_control, self.adc_subspectra_selection_button_group, get_value=values
;  ; Set the new uvalue
;  widget_control, self.adc_subspectra_selection_button_group, set_uvalue=values
end

;+
; :description:
; 	 Event handler for the selection of the number of plots to display per panel
; 	 (within the adc count spectrum tab).
; 	 This handler does not do any action as the selected number will be read later.
;
; :Params:
;    event, in, required
;
; :returns:
;
; :history:
; 	 16-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function adc_subspectra_number_plots_per_channel_event, event
  ; Do nohing
  return, 1
end

;+
; :description:
; 	 Handles clicks on the button "Select all subspectra".
; 	 This function just calls the according method of the gui object.
;
; :Params:
;    event
;    
; :returns:
;
; :history:
; 	 11-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function adc_subspectra_selection_select_all_button_event, event
  ; Get the gui object
  widget_control, event.top, get_uvalue=gui_object
  ; Call the handler
  gui_object->_handle_select_all_subspectra_button_click
  return, 1
end

;+
; :description:
; 	 This procedure is called upon clicking the button "Select all subspectra"
;    It selects all the checkboxes for every subspectra
;
; :returns:
;    -
;    
; :history:
; 	 11-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_handle_select_all_subspectra_button_click
  ; Go over all check boxes and activate them
  check_boxes_ids = *self.adc_subspectra_selection_button_ids
  for i=0,7 do begin
    widget_control, check_boxes_ids[i], set_button=1
  endfor
;  ; Check all the checkboxes
;  widget_control, self.adc_subspectra_selection_button_group, set_value=[1,1,1,1,1,1,1,1]
;  ; Set the new uvalue
;  widget_control, self.adc_subspectra_selection_button_group, set_uvalue=[1,1,1,1,1,1,1,1]
end

;+
; :description:
;    Handles clicks on the button "Deselect all subspectra".
;    This function just calls the according method of the gui object.
;
; :Params:
;    ev
;    
; :returns:
;
; :history:
;    11-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function adc_subspectra_selection_deselect_all_button_event, event
  ; Get the gui object
  widget_control, event.top, get_uvalue=gui_object
  ; Call the handler
  gui_object->_handle_deselect_all_subspectra_button_click
  return, 1
end

;+
; :description:
;    This procedure is called upon clicking the button "Deselect all subspectra"
;    It deselects all the checkboxes for every subspectra
;
; :returns:
;    -
;    
; :history:
;    11-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_handle_deselect_all_subspectra_button_click
  ; Go over all check boxes and deactivate them
  check_boxes_ids = *self.adc_subspectra_selection_button_ids
  for i=0,7 do begin
    widget_control, check_boxes_ids[i], set_button=0
  endfor
;  ; Uncheck all the checkboxes
;  widget_control, self.adc_subspectra_selection_button_group, set_value=[0,0,0,0,0,0,0,0]
;  ; Set the new uvalue
;  widget_control, self.adc_subspectra_selection_button_group, set_uvalue=[0,0,0,0,0,0,0,0]
end

;+
; :description:
; 	 Handles the selection/deselection of the "Sum up detectors" checkbox.
; 	 The selection/deselection will result in no action, as only clicking
; 	 on the "Set Plot Options" button reads the state of this checkbox.
;
; :Params:
;    event, in, required
;
; :returns:
;
; :history:
; 	 14-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function adc_sum_up_detectors_button_event, event
  ; Nothing to do
  return, 1
end

;+
; :description:
;    Handles checking and unchecking of the detector checkboxes.
;    This function just calls the according method of the gui object.
;
; :Params:
;    event
;
; :returns:
;
; :history:
; 	 11-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function adc_detectors_selection_button_event_1, event
  ; TODO
end

;+
; :description:
;    Handles checking and unchecking of the detector checkboxes.
;    This function just calls the according method of the gui object.
;
; :Params:
;    event
;
; :returns:
;
; :history:
;    11-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function adc_detectors_selection_button_event_2, event
  ; TODO
end

;+
; :description:
;    Handles checking and unchecking of the detector checkboxes.
;    This function just calls the according method of the gui object.
;
; :Params:
;    event
;
; :returns:
;
; :history:
;    11-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function adc_detectors_selection_button_event_3, event
  ; TODO
end

;+
; :description:
;    Handles checking and unchecking of the detector checkboxes.
;    This function just calls the according method of the gui object.
;
; :Params:
;    event
;
; :returns:
;
; :history:
;    11-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function adc_detectors_selection_button_event_4, event
  ; TODO
end

;+
; :description:
;    Handles clicks on the button "Select all detectors".
;    This function just calls the according method of the gui object.
;
; :Params:
;    event
;    
; :returns:
;
; :history:
;    11-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function adc_detectors_selection_select_all_button_event, event
  ; Get the gui object
  widget_control, event.top, get_uvalue=gui_object
  ; Call the handler
  gui_object->_handle_select_all_detectors_button_click
  return, 1
end

;+
; :description:
;    This procedure is called upon clicking the button "Select all detectors"
;    It selects all the checkboxes for every detector
;
; :returns:
;    -
;    
; :history:
;    11-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_handle_select_all_detectors_button_click
  ; Go over all check boxes and select them
  check_boxes_ids = *self.adc_detectors_check_boxes_ids
  for i=0, 31 do begin
    widget_control, check_boxes_ids[i], set_button=1
  endfor
;  ; Check all the checkboxes in line 1
;  widget_control, self.adc_detectors_selection_button_group_1, set_value=[1,1,1,1,1,1,1,1]
;  ; Set the new uvalue in line 1
;  widget_control, self.adc_detectors_selection_button_group_1, set_uvalue=[1,1,1,1,1,1,1,1]
;  ; Check all the checkboxes in line 2
;  widget_control, self.adc_detectors_selection_button_group_2, set_value=[1,1,1,1,1,1,1,1]
;  ; Set the new uvalue in line 2
;  widget_control, self.adc_detectors_selection_button_group_2, set_uvalue=[1,1,1,1,1,1,1,1]
;  ; Check all the checkboxes in line 3
;  widget_control, self.adc_detectors_selection_button_group_3, set_value=[1,1,1,1,1,1,1,1]
;  ; Set the new uvalue in line 3
;  widget_control, self.adc_detectors_selection_button_group_3, set_uvalue=[1,1,1,1,1,1,1,1]
;  ; Check all the checkboxes in line 4
;  widget_control, self.adc_detectors_selection_button_group_4, set_value=[1,1,1,1,1,1,1,1]
;  ; Set the new uvalue in line 4
;  widget_control, self.adc_detectors_selection_button_group_4, set_uvalue=[1,1,1,1,1,1,1,1]
end

;+
; :description:
;    Handles clicks on the button "Deselect all detectors".
;    This function just calls the according method of the gui object.
;
; :Params:
;    event
;    
; :returns:
;
; :history:
;    11-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function adc_detectors_selection_deselect_all_button_event, event
  ; Get the gui object
  widget_control, event.top, get_uvalue=gui_object
  ; Call the handler
  gui_object->_handle_deselect_all_detectors_button_click
  return, 1
end

;+
; :description:
;    This procedure is called upon clicking the button "Deselect all detectors"
;    It deselects all the checkboxes for every detector
;
; :returns:
;    -
;    
; :history:
;    11-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_handle_deselect_all_detectors_button_click
  ; Go over all check boxes and deselect them
  check_boxes_ids = *self.adc_detectors_check_boxes_ids
  for i=0, 31 do begin
    widget_control, check_boxes_ids[i], set_button=0
  endfor
end

;+
; :description:
;    Handles clicks on the button "Previous Subspectrum".
;    This function just calls the according method of the gui object.
;
; :Params:
;    event
;
; :returns:
;
; :history:
; 	 17-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function adc_button_cycle_subspectra_back_handler, event
  ; Get the gui object
  widget_control, event.top, get_uvalue=gui_object
  ; Call the handler
  gui_object->_handle_adc_previous_subspectrum_button_click
  return, 1
end

;+
; :description:
; 	 This procedure plots the previous subspectrum in the plot area of the adc tab.
;
; :returns:
;    -
;    
; :history:
; 	 17-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_handle_adc_previous_subspectrum_button_click
  self->_handle_plot_options_button_click, /previous_subspectra
end

;+
; :description:
;    Handles clicks on the button "Next Subspectrum".
;    This function just calls the according method of the gui object.
;
; :Params:
;    event
;
; :returns:
;
; :history:
;    21-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function adc_button_cycle_subspectra_forward_handler, event
  ; Get the gui object
  widget_control, event.top, get_uvalue=gui_object
  ; Call the handler
  gui_object->_handle_adc_next_subspectrum_button_click
  return, 1
end

;+
; :description:
;    This procedure plots the next subspectrum (or subspectra in case several subspectra
;    should be plotted in the same panel) in the plot area of the adc tab.
;
; :returns:
;    -
;    
; :history:
;    21-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_handle_adc_next_subspectrum_button_click
  self->_handle_plot_options_button_click, /next_subspectra
end

;+
; :description:
; 	 Handles clicks on the menu item "Load Save File".
; 	 This procedure just calls the according method of the gui object.
;
; :Params:
;    event
;
; :returns:
;
; :history:
; 	 21-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro adc_load_save_file_handler, event
  ; Get the gui object
  widget_control, event.top, get_uvalue=gui_object
  ; Call the handler
  gui_object->_handle_adc_load_save_file_click
end

;+
; :description:
;    This procedure presents a load file dialog to the user and then
;    loads the data from the file.
;
; :returns:
;    -
;    
; :history:
;    21-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_handle_adc_load_save_file_click
  file_path_save_file = dialog_pickfile(filter='*.bin')
  ; Load the data
  self.energy_calibration_spectrum_data = ptr_new(load_energy_calibration_spectrum(filename=file_path_save_file))
  self->_load_and_plot_data, detector_mask=(*self.energy_calibration_spectrum_data).subspectra[0].detector_mask, $
                              pixel_mask=(*self.energy_calibration_spectrum_data).subspectra[0].pixel_mask, $
                              subspectra_to_plot=[0], sum_up_detectors=1
end

;+
; :description:
; 	 Create all the buttons (exclusive) which are part of the fit-plot within the
; 	 energy calibration spectra GUI.
;
; :Keywords:
;    fit_button_base
;    button_values
;
; :returns:
;
; :history:
; 	 16-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_create_fit_buttons, fit_button_base_id=fit_button_base_id, button_values=button_values
  self.fit_button_group = cw_bgroup(fit_button_base_id, button_values, /column, /exclusive, event_func='fit_buttons_list_event_handler')
end

;+
; :description:
;    Event handler for the buttons of the fit plot
;
; :Params:
;    event
;
; :returns:
;
; :history:
;    16-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
function fit_buttons_list_event_handler, event
  print, 'Button clicked (fit plot)'
  return, 1
end

;+
; :description:
;    Create all the buttons (nonexclusive) which are part of the calibrated-plot within the
;    energy calibration spectra GUI.
;
; :Keywords:
;    calibrated_button_base_id
;    button_values
;
; :returns:
;
; :history:
; 	 16-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_create_calibrated_buttons, calibrated_button_base_id=calibrated_button_base_id, button_values=button_values
  self.calibrated_button_group = cw_bgroup(calibrated_button_base_id, button_values, /column, /nonexclusive, set_value=[1,1,1,1,1,1,1,1,1,1,1,1], event_func='calibrated_buttons_list_event_handler')
end

;+
; :description:
;    Event handler for the buttons of the calibrated plot
;
; :Params:
;    event
;
; :returns:
;
; :history:
;    16-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
function calibrated_buttons_list_event_handler, event
  print, 'Button clicked (calibrated plot)'
  return, 1
end

;+
; :description:
;    Create all the buttons (nonexclusive) which are part of the sum spectrum-plot within the
;    energy calibration spectra GUI.
;
; :Keywords:
;    sum_spectrum_button_base_id
;    button_values
;
; :returns:
;
; :history:
;    16-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::_create_sum_spectrum_buttons, sum_spectrum_button_base_id=sum_spectrum_button_base_id, button_values=button_values
  self.sum_spectrum_button_group = cw_bgroup(sum_spectrum_button_base_id, button_values, /column, /nonexclusive, set_value=[1,1,1,1,1,1,1,1,1,1,1,1], event_func='sum_spectrum_list_event_handler')
end

;+
; :description:
;    Event handler for the buttons of the sum spectrum plot
;
; :Params:
;    event
;
; :returns:
;
; :history:
;    16-Jun-2015 - Roman Boutellier (FHNW), Initial release
;-
function sum_spectrum_list_event_handler, event
  print, 'Button clicked (sum spectrum plot)'
  return, 1
end

;+
; :description:
; 	 Event handler for the button to set the plot options for the
; 	 adc tab
;
; :Params:
;    event
;
; :returns:
;
; :history:
; 	 09-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function adc_button_update_plot_handler, event
  ; Get the gui object
  widget_control, event.top, get_uvalue=gui_object
  ; Call the handler
  gui_object->_handle_plot_options_button_click
  return, 1
end

;+
; :description:
; 	 This method handles the click on the 'Set Plot Options' button.
; 	 All the selected parameters are read and accordingly the plot is created.
;
; :returns:
;
; :history:
; 	 15.09.2015 - Roman Boutellier (FHNW), Initial release
;
; :todo:
;    15.09.2015 - Roman Boutellier (FHNW), - Add all functionality
;-
pro stx_energy_calibration_spectra_gui::_handle_plot_options_button_click, previous_subspectra=previous_subspectra, next_subspectra=next_subspectra
  ; Get the indices of the subspectra to plot
  subspectra_to_plot_ids = *self.adc_subspectra_selection_button_ids
  ; Create the array for the subspectra_to_plot
  subspectra_to_plot_list = list()
  for i=0, size(subspectra_to_plot_ids,/n_elements)-1 do begin
    current_widget_id = subspectra_to_plot_ids[i]
    if widget_info(current_widget_id, /button_set) eq 1 then subspectra_to_plot_list.add, i
  endfor
  subspectra_to_plot = subspectra_to_plot_list.toarray()
  ; Get the number of plots to display per panel
  number_subspectra_per_panel = widget_info(self.adc_number_subspectra_per_plot_selection, /combobox_gettext)
  ; Check if the detectors should be summed up
  sum_up_detectors = widget_info(self.adc_detector_sum_up_checkbox, /button_set)
  ; Get the indices of the detectors which will be used
  ; Therefore go over all the checkboxes and get the value if they are selected
  detector_mask = make_array(32, value=0)
  detector_check_boxes_ids = *self.adc_detectors_check_boxes_ids
  for i=0, 31 do begin
    detector_mask[i] = widget_info(detector_check_boxes_ids[i], /button_set)
  endfor
  ; Get the pixels
  pixel_mask_list = list()
  pixel_button_ids_array = *self.adc_pixels_buttons_ids
  for i=0,11 do begin
    current_widget_id = pixel_button_ids_array[i]
    current_pixel_set = widget_info(current_widget_id, /button_set)
    pixel_mask_list.add, current_pixel_set
  endfor
  pixel_mask = pixel_mask_list.toarray()
  
  ; Check if cycling through subspectra must be enabled
  if size(subspectra_to_plot, /n_elements) gt number_subspectra_per_panel then begin
    widget_control, self.adc_cycle_subspectrum_back_button, sensitive=1
    widget_control, self.adc_cycle_subspectrum_forward_button, sensitive=1
    ; In case previous_subspectra has been set, get the previous set of subspectra
    ; and create a new array subspectra_to_plot containing the numbers of the
    ; previous subspectra.
    if n_elements(previous_subspectra) gt 0 then begin
      subspectra_to_plot = self->_get_previous_index_subset(all_indices=subspectra_to_plot,current_indices=*self.adc_subspectra_currently_showed,number_of_indices=number_subspectra_per_panel)   
    endif else begin
      ; In case next_subspectra has been set, get the next set of subspectra
      ; and create a new array subspectra_to_plot containing the numbers of the
      ; next subspectra.
      if n_elements(next_subspectra) gt 0 then begin
        subspectra_to_plot = self->_get_next_index_subset(all_indices=subspectra_to_plot,current_indices=*self.adc_subspectra_currently_showed,number_of_indices=number_subspectra_per_panel) 
      endif else begin
        ; Create the new array subspectra_to_plot
        subspectra_to_plot_list = list()
        for i=0, number_subspectra_per_panel-1 do begin
          subspectra_to_plot_list.add, subspectra_to_plot[i]
        endfor
        subspectra_to_plot = subspectra_to_plot_list.toarray()
      endelse
    endelse
  endif else begin
    widget_control, self.adc_cycle_subspectrum_back_button, sensitive=0
    widget_control, self.adc_cycle_subspectrum_forward_button, sensitive=0
  endelse
  
  ; Store the numbers of the currently showed subspectra
  self.adc_subspectra_currently_showed = ptr_new(subspectra_to_plot)
  
  ; Create the new plot
  self->_load_and_plot_data, sum_up_detectors=sum_up_detectors, subspectra_to_plot=subspectra_to_plot, $
                              pixel_mask=pixel_mask, detector_mask=detector_mask
end

pro stx_energy_calibration_spectra_gui::_adapt_menu_entries, spectrum=spectrum
  ; Get the number of subspectra and adapt the check boxes
  nmbr_subspectra = size(spectrum.subspectra,/n_elements)
  for i=0, nmbr_subspectra-1 do begin
    self.adc_subspectra_selection_button_group
  endfor
end

;+
; :description:
; 	 Plots the given energy calibration spectrum in the gui.
;
; :Keywords:
;    energy_calibration_spectrum
;
; :returns:
;
; :history:
; 	 03-Jul-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_energy_calibration_spectra_gui::plot, energy_calibration_spectrum=energy_calibration_spectrum, sum_up_detectors=sum_up_detectors, $
                                                pixel_mask=pixel_mask, subspectra_to_plot=subspectra_to_plot, detector_mask=detector_mask
  ; Create the plot object
  self.adc_plot_creator_object = obj_new('stx_energy_calibration_spectrum_plot')
  ; Get the plot window
  widget_control, self.adc_plot_window_id, get_value=window_adc
  window_adc.refresh, /disable
  window_adc.erase
  window_adc.refresh
  ; Plot
  self.adc_plot_creator_object->plot3, energy_calibration_spectrum, subspectra_to_plot=subspectra_to_plot, $
                                                pixel_mask=pixel_mask, detector_mask=detector_mask, $
                                                dimensions=[700,400], current=window_adc, /add_legend; , position=[0.1,0.1,0.75,0.9]
  self.adc_plot_objects = self.adc_plot_creator_object->get_plot_array()
end

;+
; :description:
; 	 This function returns the next "number_of_indices" indices from the given index array
; 	 all_indices, assuming the indices "current_indices" are the currently selected indices.
; 	 Example:
; 	           all_indices = [10,11,12,13,14,15,16,17]
; 	           current_indices = [12,13,14]
; 	           number_of_indices = 3
; 	           
; 	           Returned array: [15,16,17]
; 	           
; 	 In case there are not at least "number_of_indices" indices remaining after the currently
; 	 selected indices in "all_indices", just the last "number_of_indices" indices are returned.
;    Example:
;              all_indices = [10,11,12,13,14,15,16,17]
;              current_indices = [14,15,16]
;              number_of_indices = 3
;              
;              Returned array: [15,16,17]
;              
;    In case the "current_indices" array contains more/less than "number_indices" entries,
;    just the first "number_indices" indices are returned.
;    Example:
;              all_indices = [10,11,12,13,14,15,16,17]
;              current_indices = [12,13,14]
;              number_of_indices = 2
;              
;              Returned array: [10,11]
;
; :Keywords:
;    all_indices, in, required, type=[int]
;       Array containing all indices available
;    current_indices, in, required, type=[int]
;       Array containing the currently selected indices
;    number_of_indices, in, required, type=int
;       Number of indices to be returned
;
; :returns:
;
; :history:
; 	 22-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_energy_calibration_spectra_gui::_get_next_index_subset, all_indices=all_indices, current_indices=current_indices, number_of_indices=number_of_indices
  if number_of_indices ge size(all_indices, /n_elements) then return, all_indices
  if number_of_indices ne size(current_indices, /n_elements) then begin
    return_array = make_array(number_of_indices, value=-1)
    for i=0, number_of_indices-1 do begin
      return_array[i] = all_indices[i]
    endfor
    return, return_array
  endif
  ; Get start-index
  indices_in_array = make_array(size(current_indices, /n_elements), value=-1)
  for i=0, size(current_indices, /n_elements)-1 do begin
    indices_in_array[i] = where(all_indices eq current_indices[i])
  endfor
  last_index_in_array = indices_in_array[-1]
  ; Check if the amount of remaining indices is big enough to cover the selection of
  ; number_of_indices further indices
  if number_of_indices ge (size(all_indices, /n_elements) - last_index_in_array) then begin
    ; Just return the last number_of_indices indices
    unsorted_return_array = make_array(number_of_indices, value=-1)
    for i=1, number_of_indices do begin
      unsorted_return_array[i-1] = all_indices[-i]
    endfor
    sorted_return_array = unsorted_return_array[sort(unsorted_return_array)]
    return, sorted_return_array
  endif
  
  ; Get the next number_of_indices indices
  return_array = make_array(number_of_indices, value=-1)
  for i=1, number_of_indices do begin
    return_array[i-1] = all_indices[last_index_in_array + i]
  endfor
  return, return_array
end

;+
; :description:
;    This function returns the previous "number_of_indices" indices from the given index array
;    all_indices, assuming the indices "current_indices" are the currently selected indices.
;    Example:
;              all_indices = [10,11,12,13,14,15,16,17]
;              current_indices = [13,14,15]
;              number_of_indices = 3
;              
;              Returned array: [10,11,12]
;              
;    In case there are not at least "number_of_indices" indices remaining before the currently
;    selected indices in "all_indices", just the first "number_of_indices" indices are returned.
;    Example:
;              all_indices = [10,11,12,13,14,15,16,17]
;              current_indices = [11,12,13]
;              number_of_indices = 3
;              
;              Returned array: [10,11,12]
;              
;    In case the "current_indices" array contains more/less than "number_indices" entries,
;    just the first "number_indices" indices are returned.
;    Example:
;              all_indices = [10,11,12,13,14,15,16,17]
;              current_indices = [12,13,14]
;              number_of_indices = 2
;              
;              Returned array: [10,11]
;
; :Keywords:
;    all_indices, in, required, type=[int]
;       Array containing all indices available
;    current_indices, in, required, type=[int]
;       Array containing the currently selected indices
;    number_of_indices, in, required, type=int
;       Number of indices to be returned
;
; :returns:
;
; :history:
;    22-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_energy_calibration_spectra_gui::_get_previous_index_subset, all_indices=all_indices, current_indices=current_indices, number_of_indices=number_of_indices
  if number_of_indices ge size(all_indices, /n_elements) then return, all_indices
  if number_of_indices ne size(current_indices, /n_elements) then begin
    return_array = make_array(number_of_indices, value=-1)
    for i=0, number_of_indices-1 do begin
      return_array[i] = all_indices[i]
    endfor
    return, return_array
  endif
  ; Get start-index
  indices_in_array = make_array(size(current_indices, /n_elements), value=-1)
  for i=0, size(current_indices, /n_elements)-1 do begin
    indices_in_array[i] = where(all_indices eq current_indices[i])
  endfor
  first_index_in_array = indices_in_array[0]
  ; Check if the amount of remaining indices is big enough to cover the selection of
  ; number_of_indices further indices
  if first_index_in_array - number_of_indices lt 0 then begin
    ; Just return the first number_of_indices indices
    unsorted_return_array = make_array(number_of_indices, value=-1)
    for i=0, number_of_indices-1 do begin
      unsorted_return_array[i] = all_indices[i]
    endfor
    sorted_return_array = unsorted_return_array[sort(unsorted_return_array)]
    return, sorted_return_array
  endif
  
  ; Get the previous number_of_indices indices
  unsorted_return_array = make_array(number_of_indices, value=-1)
  for i=1, number_of_indices do begin
    unsorted_return_array[i-1] = all_indices[first_index_in_array - i]
  endfor
  sorted_return_array = unsorted_return_array[sort(unsorted_return_array)]
  return, sorted_return_array
end

pro stx_energy_calibration_spectra_gui__define
  compile_opt idl2
  
  define = {stx_energy_calibration_spectra_gui, $
    stx_software_framework: obj_new(), $
    energy_calibration_spectrum_data: ptr_new(), $
    ecs_main_window_id: 0L, $
    tab_widget_energy_calibration_spectra_gui_id: 0L, $
    adc_new_graphics_selected: 1L, $
    adc_count_spectrum_base_id: 0L, $
    adc_plot_window_id: 0L, $
    adc_legend_window_id: 0L, $
    adc_spectrogram_selection_id: 0L, $
    adc_number_subspectra_per_plot_selection: 0L, $
    adc_subspectra_currently_showed: ptr_new(), $
    adc_subspectra_selection_button_ids: ptr_new(), $
    adc_detector_sum_up_checkbox: 0L, $
    adc_detectors_selection_button_group_1: 0l, $
    adc_detectors_selection_button_group_2: 0l, $
    adc_detectors_selection_button_group_3: 0l, $
    adc_detectors_selection_button_group_4: 0l, $
    adc_detectors_check_boxes_ids: ptr_new(), $
    adc_cycle_subspectrum_back_button: 0L, $
    adc_cycle_subspectrum_forward_button: 0L, $
    adc_pixels_buttons_ids: ptr_new(), $
    adc_plot_objects: ptr_new(), $
    adc_plot_creator_object: obj_new(), $
    fit_plot_base_id: 0L, $
    fit_plot_window_id: 0L, $
    fit_spectrogram_selection_id: 0L, $
    fit_button_group: 0L, $
    calibrated_plot_base_id: 0L, $
    calibrated_plot_window_id: 0L, $
    calibrated_spectrogram_selection_id: 0L, $
    calibrated_button_group: 0L, $
    sum_spectrum_base_id: 0L, $
    sum_spectrum_plot_window_id: 0L, $
    sum_spectrum_spectrogram_selection_id: 0L, $
    sum_spectrum_button_group: 0L, $
    inherits stx_gui_base $
    }
end