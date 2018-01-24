;+
; :file_comments:
;   This is the analysis software GUI.
;   
; :categories:
;   analysis software, gui
;   
; :examples:
;
; :history:
;    17-Jul-2015 - Roman Boutellier (FHNW), Initial release
;    22-Jul-2015 - Roman Boutellier (FHNW), Added first entries in file menu and according handlers
;    01-Sep-2015 - Roman Boutellier (FHNW), Added labels to display the observation time interval and flare id
;                                           Added field for the asw_data_object to the object and create such an object upon initialization
;-

;+
; :description:
;    This function initializes the object. It is called automatically upon creation of the object.
;    
; :returns:
;
; :history:
; 	 17-Jul-2015 - Roman Boutellier (FHNW), Initial release
; 	 01-Sep-2015 - Roman Boutellier (FHNW), Added initialization of the asw_data_object
;-
function stx_asw_gui::init
  
  ; Initialize the base class
  a = self->stx_gui_base::init(/no_file_menu_entries)
  
  ; Get the content widget id
  self.base_content_widget_id = self->stx_gui_base::get_content_widget_id()
  ; Get the button bar widget id
  self.base_button_bar_id = self->stx_gui_base::get_button_bar_widget_id()
  ; Get the menu bar widget id
  self.base_menu_bar_id = self->stx_gui_base::get_menu_bar_widget_id()
  ; Get the file menu widget id
  self.base_file_menu_id = self->stx_gui_base::get_file_menu_widget_id()
  
  ; Create the asw_data_object
  self.asw_data_object = obj_new('stx_asw_data_object')
  
  ; Create the widgets
  self->_create_widgets_asw_gui
  ; Realize the widgets
  self->stx_gui_base::realize_widgets
  ; Start the xmanager
  self->_start_xmanager_asw_gui
  
  ; Initialize the list for the notification of observation time interval changes
  self.observation_time_interval_change_notification_objects = list()
  
  return, a
end

;+
; :description:
;    Cleaning up the object
;
; :Params:
;    -
;
; :returns:
;    -
;    
; :history:
;    17-Jul-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_asw_gui::cleanup

end

;+
; :description:
; 	 This method creates all widgets for the asw GUI.
;
; :returns:
;
; :history:
; 	 17-Jul-2015 - Roman Boutellier (FHNW), Initial release
;
; :todo:
;    17-Jul-2015 - Roman Boutellier (FHNW), - Add all functionality
;    21-Jul-2015 - Roman Boutellier (FHNW), Added entries in file menu
;    01-Sep-2015 - Roman Boutellier (FHNW), Added inidication of observation time interval
;-
pro stx_asw_gui::_create_widgets_asw_gui
  
  ; Load the GUI fonts
  stx_gui_get_font, font, big_font, small_font=small_font, huge_font=huge_font
  
  ; Load the default time interval
  default_start_time_string = anytim(self.asw_data_object->get_observation_time_interval_start_time(),/yymmdd)
  default_end_time_string = anytim(self.asw_data_object->get_observation_time_interval_end_time(),/yymmdd)
  observation_time_interval_string = strtrim(default_start_time_string,2) + ' to ' + strtrim(default_end_time_string,2)
  
  ; Add the menu item to select the observation time interval
  observationTimeIntervalMenuItem = widget_button(self.base_file_menu_id, value='Select Observation Time Interval', uname='selectObservationTimeInterval', event_pro='stx_asw_gui_observation_time_interval_menu_handler')
  imageMenuItem = widget_button(self.base_file_menu_id, value='Image...', uname='imageMenuItem', event_pro='stx_asw_gui_image_menu_handler')
  exitMenuItem = widget_button(self.base_file_menu_id, value='Exit', uname='exitMenuItem', event_pro='stx_asw_gui_exit_menu_handler',/separator)
  
  ; Create the top level base (i.e. the main window for this GUI)
  self.base_widget_asw_gui = widget_base(self.base_content_widget_id, title='Analysis Software GUI', /column, uvalue=self)
  ; Create the welcome message
  welcome_message_base = widget_base(self.base_widget_asw_gui, /column)
  welcome_message_label_1 = widget_label(welcome_message_base, value='Welcome to the STIX Analysis Software', frame=0, font=big_font)
  welcome_message_label_2 = widget_label(welcome_message_base, value='Click on one of the buttons to start analysis.', frame=0, font=font)
  welcome_message_base_2 = widget_base(welcome_message_base, /row)
  welcome_message_label_3 = widget_label(welcome_message_base_2, value='Observation Time Interval: ', frame=0, font=small_font)
  self.observation_time_label = widget_label(welcome_message_base_2, value=observation_time_interval_string, frame=0, font=small_font, xsize=260)
  welcome_message_label_4 = widget_label(welcome_message_base_2, value='      Flare: ', frame=0, font=small_font)
  self.observation_flare_label = widget_label(welcome_message_base_2, value='-', frame=0, font=small_font, xsize=60)
  
  ; Add the button base
  button_base = widget_base(self.base_widget_asw_gui, /row)
  ; Add the button to start the setting of the observation time interval
  self.button_observation_time_interval_id = widget_button(button_base, value='Observation Time Interval Selection', uname='buttonObersvationTimeIntervalSelection', event_pro='stx_asw_gui_observation_time_interval_menu_handler')
  self.button_images_id = widget_button(button_base, value='Imaging', uname='buttonImaging', event_pro='stx_asw_gui_image_menu_handler')
end


;+
; :description:
;    Starting the xmanager which handles all clicks in the ui and forwards them to
;    the according event handlers.
;
; :returns:
;
; :history:
;    20-Jul-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_asw_gui::_start_xmanager_asw_gui
  xmanager, 'stx_asw_gui', self.base_widget_asw_gui, /no_block, cleanup='stx_asw_gui_cleanup'
end

pro stx_asw_gui_cleanup, base_widget_asw_gui
  widget_control, base_widget_asw_gui, get_uvalue=owidget
  if owidget ne !NULL then begin
    owidget->_cleanup_widgets_asw_gui, base_widget_asw_gui
  endif
end

pro stx_asw_gui::_cleanup_widgets_asw_gui, base_widget_asw_gui
  obj_destroy, self
end

;+
; :description:
;   Event handler for the click on the menu item to set the observation time interval
;
; :Params:
;    event
;
; :returns:
;
; :history:
; 	 21-Jul-2015 - Roman Boutellier (FHNW), Initial release
; 	 01-Sep-2015 - Roman Boutellier (FHNW), Calls now _open_observation_time_interval_window (method of the asw_gui object)
;-
pro stx_asw_gui_observation_time_interval_menu_handler, event
  ; Get the calling widget id
  widget_control, event.top, get_uvalue=owidget
  ; Call method of the asw_gui object
  owidget->_open_observation_time_interval_window
end


;+
; :description:
; 	 Open the window to set the observation time interval.
;
; :history:
; 	 01-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_asw_gui::_open_observation_time_interval_window
  ; Open the window for the selection of the observation time interval
  oti_gui = obj_new('stx_asw_observation_time_interval_gui', asw_gui=self, asw_data_object=self.asw_data_object)
  
;  ; Prepare the time string
;  time_string = strtrim(anytim(self.asw_data_object->get_observation_time_interval_start_time(),/YYMMDD),2) + '  to  ' + $
;                strtrim(anytim(self.asw_data_object->get_observation_time_interval_end_time(),/YYMMDD),2)
;  widget_control, self.observation_time_label, set_value=time_string
;  widget_control, self.observation_flare_label, set_value=strtrim(self.asw_data_object->get_observation_flare(),2)
end

;+
; :description:
;   Event handler for the click on the menu item to create an image
;
; :Params:
;    event
;
; :returns:
;
; :history:
;    21-Jul-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_asw_gui_image_menu_handler, event
  print, 'Image...'
end

;+
; :description:
;   Event handler for the click on the menu item to exit the program
;
; :Params:
;    event
;
; :returns:
;
; :history:
;    22-Jul-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_asw_gui_exit_menu_handler, event
  widget_control, event.top, get_uvalue=owidget
  owidget->_handle_exit_click_asw_gui
end

;+
; :description:
;   Handling the click on the exit button. As result, the widget hierarchy is destroyed.
;
; :returns:
;   -
;   
; :history:
;    22-Jul-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_asw_gui::_handle_exit_click_asw_gui
  ; Exit the application. Therefore call the exit function of the base widget.
  self->stx_gui_base::_handle_exit_click
end

;+
; :description:
; 	 Change the observation time interval to the new values.
; 	 This shows the newly selected values in the main gui and notifies all registered
; 	 objects of the change.
;
; :Keywords:
;    -
;
; :returns:
;    -
;    
; :history:
; 	 04-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_asw_gui::change_observation_time_interval
  ; Set the time string
  start_time = self.asw_data_object->get_observation_time_interval_start_time()
  end_time = self.asw_data_object->get_observation_time_interval_end_time()
  start_time_string = anytim(start_time,/yymmdd)
  end_time_string = anytim(end_time,/yymmdd)
  observation_time_interval_string = strtrim(start_time_string,2) + ' to ' + strtrim(end_time_string,2)
  widget_control, self.observation_time_label, set_value=observation_time_interval_string
  ; Call the objects
  self->notify_observation_time_interval_change
end

;+
; :description:
; 	 Register an object ot be notified in case the observation time interval
; 	 has been changed.
; 	 The registered object must provide a procedure 'observation_time_interval_changed'
; 	 with the named keywords start_time and end_time. This procedure will be called upon
; 	 change of the observation time interval. The keywords start_time and end_tim contain
; 	 the newly set start- and end-time.
;
; :Keywords:
;    object_to_register
;
; :returns:
;    Index of object in the list. This index will be used to remove the object again from the list.
; :history:
; 	 04-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_asw_gui::register_for_observation_time_interval_change, object_to_register=object_to_register
  self.observation_time_interval_change_notification_objects->add,object_to_register
  return, self.observation_time_interval_change_notification_objects->count() - 1
end

;+
; :description:
; 	 Notifies all subscribed objects of a change in the observation time interval.
; 	 This is done by calling the 'observation_time_interval_changed' procedure of
; 	 each object.
; 	 The procedure 'observation_time_interval_changed' must have the two keywords
; 	 'start_time' and 'end_time' which will contain the newly set start- and end-time.
;
; :returns:
;
; :history:
; 	 04-Sep-2015 - Roman Boutellier (FHNW), Initial release
;
; :todo:
;    04.09.2015 - Roman Boutellier (FHNW), - Add all functionality
;-
pro stx_asw_gui::notify_observation_time_interval_change
  number_entries_in_list = self.observation_time_interval_change_notification_objects->count()
  ; Go over the list of objects and call the method
  for i=0, number_entries_in_list-1 do begin
    current_object = self.observation_time_interval_change_notification_objects[i]
    ; In case the current_object is 0, the object has been deregistered.
    if (current_object eq 0) or (current_object eq !NULL) then begin
      ; Do nothing
    endif else begin
      ; Call the method
      current_object->observation_time_interval_changed, $
                      start_time=self.asw_data_object->get_observation_time_interval_start_time(), $
                      end_time=self.asw_data_object->get_observation_time_interval_end_time()
    endelse
  endfor
end

pro stx_asw_gui__define
  compile_opt idl2
  
  define = {stx_asw_gui, $
    base_widget_asw_gui: 0L, $
    base_content_widget_id: 0L, $
    base_button_bar_id: 0L, $
    base_menu_bar_id: 0L, $
    base_file_menu_id: 0L, $
    button_observation_time_interval_id: 0L, $
    button_images_id: 0L, $
    observation_time_label: 0L, $
    observation_flare_label: 0L, $
    asw_data_object: obj_new(), $
    observation_time_interval_change_notification_objects: list(), $
    inherits stx_gui_base $
  }
end