;+
; :file_comments:
;
; :categories:
;
; :examples:
;
; :history:
;    01.09.2015 - Roman Boutellier (FHNW),
;-

;+
; :description:
;    This function initializes the object. It is called automatically upon creation of the object.
;    
; :returns:
;
; :history:
;    01-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_asw_observation_time_interval_gui::init, asw_gui=asw_gui, asw_data_object=asw_data_object
  ; Initialize the base class
  a = self->stx_gui_base::init(/no_file_menu_entries)
  
  ; Set the asw_gui and the asw_data_object
  self.asw_gui_object = asw_gui
  self.asw_data_object = asw_data_object
  
  ; Get the content widget id
  self.base_content_widget_id = self->stx_gui_base::get_content_widget_id()
  ; Get the button bar widget id
  self.base_button_bar_id = self->stx_gui_base::get_button_bar_widget_id()
  ; Get the menu bar widget id
  self.base_menu_bar_id = self->stx_gui_base::get_menu_bar_widget_id()
  ; Get the file menu widget id
  self.base_file_menu_id = self->stx_gui_base::get_file_menu_widget_id()
  
  
  ; Create the widgets
  self->_create_widgets_asw_observation_time_inteval_gui
  ; Realize the widgets
  self->stx_gui_base::realize_widgets
  
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
;    01-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_asw_observation_time_interval_gui::cleanup

end


pro stx_asw_observation_time_interval_gui::_create_widgets_asw_observation_time_inteval_gui
  ; Load the GUI fonts
  stx_gui_get_font, font, big_font, small_font=small_font, huge_font=huge_font
  
  ; Add the menu items
  
  
  ; Create the top level base (i.e. the main window for this GUI)
  self.base_widget_asw_observation_time_interval_gui = widget_base(self.base_content_widget_id, title='Analysis Software GUI - Select Observation Time Interval', /column, uvalue=self)
  welcome_message_label_1 = widget_label(self.base_widget_asw_observation_time_interval_gui, value='Observation Time Interval Selection', frame=0, font=big_font)
  
  ; Add the base for the setting of the observation time interval
  self.base_set_time_observation_time_interval_gui = widget_base(self.base_widget_asw_observation_time_interval_gui, /column, /base_align_right)
  self.base_set_time_input_observation_time_interval_gui = widget_base(self.base_set_time_observation_time_interval_gui, /row, /align_left)
  button1 = widget_button(self.base_set_time_input_observation_time_interval_gui, value='Reset')
  button2 = widget_button(self.base_set_time_input_observation_time_interval_gui, value='Start')
  self.input_start_time_widget = widget_text(self.base_set_time_input_observation_time_interval_gui, xsize=50, /editable)
  self.input_end_time_widget = widget_text(self.base_set_time_input_observation_time_interval_gui, xsize=50, /editable)
  button3 = widget_button(self.base_set_time_input_observation_time_interval_gui, value='End')
  button4 = widget_button(self.base_set_time_input_observation_time_interval_gui, value='Reset')
  button5 = widget_button(self.base_set_time_observation_time_interval_gui, value='Set Observation Time Interval',event_pro='stx_asw_observation_time_interval_button_set_interval_handler')
end


;+
; :description:
; 	 Event handler for the button to set the selected time interval.
; 	 This handler just calls the according method of the stx_asw_observation_time_interval_gui
; 	 object.
;
; :Params:
;    event, in, required
;
; :returns:
;
; :history:
; 	 04-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_asw_observation_time_interval_button_set_interval_handler, event
  widget_control, event.top, get_uvalue=owidget
  owidget->_handle_set_interval_button
end

;+
; :description:
; 	 This procedure handles the click on the button to set the selected time interval.
; 	 It is called by the button handler.
; 	 The procedure first reads the selected time interval from the input text widgets
; 	 and then stores them in the stx_asw_data_object.
;
; :returns:
;
; :history:
; 	 04-Sep-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_asw_observation_time_interval_gui::_handle_set_interval_button
  ; Store the selected time interval in seconds from 01.01.1979, 00:00:00 (anytim)
  widget_control, self.input_start_time_widget, get_value=start_time_value
  widget_control, self.input_end_time_widget, get_value=end_time_value
  
  ; Check if the time interval has been set
  if (start_time_value eq !NULL) or (end_time_value eq !NULL) or (strtrim(start_time_value,2) eq '') or (strtrim(end_time_value,2) eq '') then begin
    ; The interval has not been set, inform the user
    info_widget_clicked_button = dialog_message('Please specify an Observation Time Interval',/center,/error)
    return
  endif
  ; Get the start and end time in anytim format
  start_time_anytim = anytim(start_time_value, error=start_time_error)
  end_time_anytim = anytim(end_time_value, error=end_time_error)
  
  ; In case the creation of the anytim format resulted in an error, tell the user so and return
  if start_time_error eq 1 then begin
    ; The interval has not been set, inform the user
    info_widget_clicked_button = dialog_message(['The start time of the entered time interval has a wrong format.','Correct format: 14/05/16, 17:39:28'],/center,/error)
    return
  endif
  if end_time_error eq 1 then begin
    ; The interval has not been set, inform the user
    info_widget_clicked_button = dialog_message(['The end time of the entered time interval has a wrong format.','Correct format: 14/05/16, 17:39:28'],/center,/error)
    return
  endif
  
  ; Set the entered times in the stx_asw_data_object
  start_succes = self.asw_data_object->set_observation_time_interval_start_time(new_start_time=start_time_anytim)
  end_succes = self.asw_data_object->set_observation_time_interval_end_time(new_end_time=end_time_anytim)
  
  ; Check if setting the times was successful
  if start_succes eq -1 then begin
    ; There has been an error while setting the start time, inform the user
    info_widget_clicked_button = dialog_message(['Error while setting the start time of the observation time interval.','Please try again with a different start time.'],/center,/error)
    return
  endif
  if end_succes eq -1 then begin
    ; There has been an error while setting the end time, inform the user
    info_widget_clicked_button = dialog_message(['Error while setting the end time of the observation time interval.','Please try again with a different start time.'],/center,/error)
    return
  endif
  
  ; Notify the main object of the change. This object will then notify all registered other objects of the change.
  self.asw_gui_object->change_observation_time_interval
end


pro stx_asw_observation_time_interval_gui__define
  compile_opt idl2
  
  define = {stx_asw_observation_time_interval_gui, $
    asw_gui_object: obj_new(), $
    asw_data_object: obj_new(), $
    base_content_widget_id: 0L, $
    base_button_bar_id: 0L, $
    base_menu_bar_id: 0L, $
    base_file_menu_id: 0L, $
    base_widget_asw_observation_time_interval_gui: 0L ,$
    base_set_time_observation_time_interval_gui: 0L, $
    base_set_time_input_observation_time_interval_gui: 0L, $
    input_start_time_widget: 0L, $
    input_end_time_widget: 0L ,$
    inherits stx_gui_base $
    }
end