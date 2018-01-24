;+
; :file_comments:
;   This is the base class for all the classes from the visualization module of the STIX
;   software framework. It provides a base GUI and some methods which are used within all
;   classes of the visualization module.
;
; :categories:
;   software, gui
;
; :examples:
;
; :history:
;    12-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-

;+
; :description:
;   This function initializes the object. It is called automatically upon creation of the object.
;
; :returns:
;   1 in case of success
;   
; :history:
; 	 12-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_gui_base::init, no_file_menu_entries=no_file_menu_entries
  compile_opt idl2
  
  ; Create the wigets
  self->_create_widgets, no_file_menu_entries=no_file_menu_entries
  ; Realize the widgets / 14-Jan-2015 Roman Boutellier: This is now done by the sub object to ensure the window is only shown to the user after all widgets have been created
;  self->_realize_widgets
  ; Start the XManager to enable button click events etc.
  self->_start_xmanager
  
  return, 1
end

pro stx_gui_base::cleanup
  ; Add cleanup code
end

;+
; :description:
;   Create all the widgets needed within this base class.
;
; :returns:
;   -
;
; :history:
; 	 12-Jan-2015 - Roman Boutellier (FHNW), Initial release
; 	 27-May-2015 - Roman Boutellier (FHNW), Added /tlb_resize_events to enable calling the event handler on resizing
;-
pro stx_gui_base::_create_widgets, no_file_menu_entries=no_file_menu_entries
  ; Create the top level base (i.e. the main window for this GUI). The mbar keyword returns a widget indentifier
  ; to which buttons can be added to create the menu system.
  self.tlb = widget_base(title='STIX Software Framework', /column, uvalue=self, uname='tlb', mbar=menubar, /tlb_size_events)
  
  ; Create the menu system by adding buttons to the menubar widget identifier.
  fileMenu = widget_button(menubar, value='File', /menu)
  if not keyword_set(no_file_menu_entries) then begin
    self.loadScenarioItem_id = widget_button(fileMenu, value='Load Scenario', uname='loadScenario', event_pro='stx_gui_base_menu_handler_load_scenario')
    
  ;  configurationMenu = widget_button(menubar, value='Configuration', /menu)
    showConfigurationItem = widget_button(fileMenu, value='Show Configuration',/separator)
    loadConfigurationItem = widget_button(fileMenu, value='Load Configuration')
  endif
  
  ; Store the ids of the menu bar and file menu widgets
  self.menu_bar_widget_id = menubar
  self.file_menu_widget_id = fileMenu
  
  ; Add the widget base for the content
  self.content_widget = widget_base(self.tlb, uname='contentWidget')
  
  ; Add the button bars
  self.button_bar_widget = widget_base(self.tlb, uname='buttonBar', /row);, ysize=40, /row)
  buttonBar2 = widget_base(self.tlb, uname='buttonBar2');, ysize=40)
  
  ; Add an exit button
  exitButton = widget_button(buttonBar2, uname='exitButton', value='Exit', event_pro='button_exit_event_handler')
end

;+
; :description:
;   Realize the widgets.
;
; :returns:
;   -
;   
; :history:
; 	 12-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_gui_base::realize_widgets
  widget_control, self.tlb, /realize
end

;+
; :description:
;   Start the xmanager which enables handling of click events, button clicks etc. in the GUI.
;
; :returns:
;
; :history:
; 	 12-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_gui_base::_start_xmanager
  xmanager, 'stx_gui_base', self.tlb, /no_block, cleanup='stx_gui_base_cleanup', event_handler='stx_gui_base_event'
end

;+
; :description:
;   The cleanup procedure of the xmanager. This procedure just calls the _cleanup_widgets method
;   of the base class (only in case there are any widgets).
;
; :Params:
;    tlb, in, required, type=Long
;       The widget id of the top level base widget.
;
; :returns:
;   -
;   
; :history:
; 	 12-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_gui_base_cleanup, tlb
  widget_control, tlb, get_uvalue=owidget
  if owidget ne !NULL then begin
    owidget->_cleanup_widgets, tlb
  endif
end

;+
; :description:
;   Cleaning up the widgets by destroying the hierarchy (which closes the window)
;
; :Params:
;    tlb, in, required, type=Long
;       The widget id of the top level base widget.
;
; :returns:
;   -
;   
; :history:
; 	 12-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_gui_base::_cleanup_widgets, tlb
  widget_control, tlb, /destroy
  obj_destroy, self
end


;+
; :description:
; 	 Event handler for the top level base. It handles resizing events.
;
; :Params:
;    event

; :history:
; 	 27-May-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_gui_base_event, event
  widget_control, event.top, get_uvalue=owidget
  if owidget ne !NULL then begin
    owidget->_handle_events, event
  endif
end

pro stx_gui_base::_handle_events, event
  self->_handle_resize_events
end

;+
; :description:
; 	 Handling resize events by calling the according procedure of the object
; 	 which is stored for resizing
;
; :returns:
;
; :history:
; 	 27.05.2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_gui_base::_handle_resize_events
  if self.object_for_resizing ne !NULL then begin
    self.object_for_resizing->_handle_resize_events
  endif
end

;+
; :description:
; 	 The event handler for the 'Load Scenario' menu button. This procedure calls the method
; 	 _handle_load_scenario_click of the base object.
;
; :Params:
;    event, in, required
;
; :returns:
;   -
;
; :history:
; 	 14-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_gui_base_menu_handler_load_scenario, event
  widget_control, event.top, get_uvalue=owidget
  owidget->handle_load_scenario_click
end

;+
; :description:
;   Handling the click on the 'Load Scenario' menu button.
;   As result, a dialog is shown to the user to select and load a scenario.
;   The user can select a scenario in this dialog and then click on the "Select Scenario"
;   button. This stores the name of the selected scenario within this object.
;
; :returns:
;   -
;   
; :history:
;    14-Jan-2015 - Roman Boutellier (FHNW), Initial release
;    21-Jan-2015 - Roman Boutellier (FHNW), Now calls stx_gui_select_scenario_window
;    26-Jan-2015 - Roman Boutellier (FHNW), Changed call to creating the object
;    28-Jan-2015 - Roman Boutellier (FHNW), - Changed to public method. It must be overwritten by subclasses.
;                                           - Added callback_object parameter
;-
pro stx_gui_base::handle_load_scenario_click, callback_object=callback_object
  ; Do nothing as this procedure must be overwritten by subclasses
end

;+
; :description:
;   The event handler for the exit button. This procedure calls the method
;   _handle_exit_click of the base object.
;
; :Params:
;    event, in, required
;
; :returns:
;   -
;
; :history:
; 	 12-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-
pro button_exit_event_handler, event
  widget_control, event.top, get_uvalue=owidget
  owidget->_handle_exit_click
end

;+
; :description:
;   Handling the click on the exit button. As result, the widget hierarchy is destroyed.
;
; :returns:
;   -
;   
; :history:
; 	 12-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_gui_base::_handle_exit_click
  ; Exit the application
  self->_cleanup_widgets, self.tlb
end


;+
; :description:
;   Function which returns the widget id of the content widget.
;
; :returns:
;   Long, widget_id
;     The id of the content widget
;
; :history:
; 	 13-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_gui_base::get_content_widget_id
  return, self.content_widget
end

;+
; :description:
; 	 Return the geometry data for the top level base.
;
; :returns:
;
; :history:
; 	 27-May-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_gui_base::get_tlb_geometry
  return, widget_info(self.tlb, /geometry)
end

;+
; :description:
; 	 Setting the object of which the procedure _handle_resize_events will be called upon
; 	 resizing the top level base.
;
; :Keywords:
;    obj, in, required
;       The object which will be called
;
; :returns:
;
; :history:
; 	 27.05.2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_gui_base::set_object_for_resizing, obj=obj
  self.object_for_resizing = obj
end

;+
; :description:
;   Function which returns the widget id of the button bar widget.
;
; :returns:
;   Long, widget_id
;     The id of the button bar widget
;
; :history:
;    13-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_gui_base::get_button_bar_widget_id
  return, self.button_bar_widget
end

;+
; :description:
; 	 Returns the widget id of the menu bar widget.
;
; :returns:
;   Long, widget_id
;     The id of the menu bar widget
;
; :history:
; 	 21-Jul-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_gui_base::get_menu_bar_widget_id
  return, self.menu_bar_widget_id
end

;+
; :description:
;    Returns the widget id of the file menu widget.
;
; :returns:
;   Long, widget_id
;     The id of the file menu widget
;
; :history:
;    21-Jul-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_gui_base::get_file_menu_widget_id
  return, self.file_menu_widget_id
end

pro stx_gui_base__define
  compile_opt idl2
  
  define = {stx_gui_base, $
    tlb: 0L, $
    content_widget: 0L, $
    button_bar_widget: 0L, $
    menu_bar_widget_id: 0L, $
    file_menu_widget_id: 0L, $
    loadScenarioItem_id: 0L, $
    object_for_resizing: obj_new() $
  }
end