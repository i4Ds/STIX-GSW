;+
; :file_comments:
;   This function creates and handles a window which shows a list of
;   scenarios the user can load.
;   
; :categories:
;   software, gui
;   
; :examples:
;   a = stx_gui_select_scenario_window
;   
; :history:
;    20-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-


;+
; :description:
; 	 Create and show a window which can the be used to select a scenario
; 	 (using radio buttons).
;
; :Params:
;    calling_stx_software_framework, in, required, type=stx_software_framework
;       The calling stx_gui_base
;    selected_scenario, in, optional, type='String'
;       Name of the scenario which will be initally selected
;
; :returns:
;
; :history:
; 	 20-Jan-2015 - Roman Boutellier (FHNW), Initial release
; 	 26-Jan-2015 - Roman Boutellier (FHNW), Changed input from calling_object (stx_gui_base) to calling_stx_software_framework (stx_software_framework)
; 	 25-Feb-2015 - Roman Boutellier (FHNW), Added keyword "selected_scenario". Passing the name of a scenario to this keyword will cause
; 	                                        the according button to be initially selected.
; 	 03-Mar-2015 - Roman Boutellier (FHNW), Added check of operating system befor creating the list of files. For UNIX systems, now a slash is searched instead a backslash
; 	                                        when cropping the path of the file.
; 	 10-Jun-2015 - Roman Boutellier (FHNW), Added possibility to use a file picker to load any scenario file
;-
function stx_gui_select_scenario_window::init, calling_stx_software_framework=calling_stx_software_framework, selected_scenario=selected_scenario
  compile_opt idl2

  ; Set up the error handler
  catch, theError
  if theError ne 0 then begin
    catch, /cancel
    ok = dialog_message(!ERROR_STATE.msg)
    widget_control, groupleader, /destroy
    cancel = 1
    return, '-'
  endif

  ; Create a group leader and unmap it
  groupleader = widget_base(map=0)
  widget_control, groupleader, /realize
  
  ; Create the modal base widget which will be the container for all other widgets
  self.base_widget_select_scenario = widget_base(title='Select Scenario', /column, /modal, /base_align_center, group_leader=groupleader)
  
  ; Create the container for the radio buttons
  radio_buttons_container = widget_base(self.base_widget_select_scenario, /column, /exclusive)
  
  ; Get the array of files
  file_list = file_search(concat_dir(getenv('STX_SIM'), 'scenarios'),'*.csv')
  
  ; Prepare the variable to hold the id of the button which will be initially selected
  initial_selected_button_id = 0l
  
  ; Go over every file and add a radio button for each file
  for i=0,size(file_list,/n_elements)-1 do begin
    ; Extract the file name
    actual_path = file_list[i]
    if !VERSION.OS_FAMILY eq 'unix' then begin
      position_last_slash = strpos(actual_path, '/', /reverse_search)
    endif else begin
      position_last_slash = strpos(actual_path, '\', /reverse_search)
    endelse
    actual_file_name = strmid(actual_path, position_last_slash+1, strlen(actual_path)-position_last_slash)
    ; Create the radio button
    rad_button = widget_button(radio_buttons_container, value=actual_file_name)
    ; Store the button id in case the button will be initially selected
    actual_scenario_name = strmid(actual_file_name,0,strlen(actual_file_name)-4)
    if actual_scenario_name eq selected_scenario then initial_selected_button_id = rad_button
  endfor
  
  ; Toggle the initially selected button
  if initial_selected_button_id gt 0l then widget_control, initial_selected_button_id, set_button=1
  
  ; Create the buttons
  
  buttons_base_widget = widget_base(self.base_widget_select_scenario, /row)
  load_button = widget_button(buttons_base_widget, value='Load Another Scenario')
  cancel_button = widget_button(buttons_base_widget, Value='Cancel')
  select_button = widget_button(buttons_base_widget, Value='Select Scenario')
  
  ; Realize the widgets
  widget_control, self.base_widget_select_scenario, /realize
  
  ; Prepare a pointer to store the scenario selected by the user.
  ; A pointer has to be used as other means (variables) of storage will be
  ; erased as soon as the widget is closed. But the pointer stays "open".
  ; This pointer stores a text (i.e. the scenario name) and an indicator if
  ; cancel has been pressed. The default value of the cancel indicator is 1
  ; (i.e. cancel has been pressed) to ensure the response acts accordingly
  ; in case the user closes the widget with the mouse instead of clicking cancel.
  storage_ptr = ptr_new({scenario: '', cancel: 1, new_file_loaded:0})
  ; Store the pointer in a structure and place this structure in the uvalue of
  ; the base_widget_select_scenario.
  info_structure = {ptr:storage_ptr, load_button:load_button, cancel_button:cancel_button, select_button:select_button}
  widget_control, self.base_widget_select_scenario, set_uvalue=info_structure, /no_copy
  
  ; Start xmanager in blocking mode. This causes program execution to stop at this point
  ; until the widget is destroyed. When this happens, execution starts again at the
  ; next line.
  xmanager, 'stx_gui_select_scenario', self.base_widget_select_scenario
  
  ; Gather the information from the pointer location, destroy the pointer and return
  ; the information. Also delete the .csv-extension of the scenario name in case a
  ; scenario from the list has been selected. If a new scenario has been loaded, 
  ; do not delete the .csv-extension.
  scenario_file_name = (*storage_ptr).scenario
  if (*storage_ptr).new_file_loaded eq 1 then begin
    scenario_name = scenario_file_name
  endif else begin
    scenario_name = file_basename(scenario_file_name, '.csv')
  endelse
  cancel = (*storage_ptr).cancel
  ptr_free, storage_ptr
  
  ; Set the scenario_name to '-' in case cancel has been pressed
  if cancel eq 1 then begin
    scenario_name = '-'
  endif else begin
    ; Set the scenario name within the calling stx_gui_base
    calling_stx_software_framework->set_scenario, scenario=scenario_name
  endelse
  
  return, scenario_name
end


;+
; :description:
; 	 The event handler for the select scenario dialog.
;
; :Params:
;    event, in, required
;
; :returns:
;
; :history:
; 	 21-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-
pro stx_gui_select_scenario_event, event
  compile_opt idl2
  
  widget_control, event.top, get_uvalue=info_struct
  
  case event.id of
    info_struct.cancel_button: widget_control, event.top, /destroy
    info_struct.select_button: begin
        ; Set cancel to 0 as select has been pressed
        (*info_struct.ptr).cancel = 0
        ; Set new_file_loaded to 0 as a scenario from the list has been selected
        (*info_struct.ptr).new_file_loaded = 0
        ; Destroy the widget
        widget_control, event.top, /destroy
      endcase
    info_struct.load_button: begin
        ; Open a file load dialog
        file_path = dialog_pickfile(title='Select a Scenario to load', filter='*.csv')
        ; Set cancel to 0 as a file has been selected
        (*info_struct.ptr).cancel = 0
        ; Set new_file_loaded to 1
        (*info_struct.ptr).new_file_loaded = 1
        ; Store the path in the pointer
        (*info_struct.ptr).scenario = file_path
        ; Destroy the widget
        widget_control, event.top, /destroy
      endcase
    else: begin
        ; A radio button has been pressed, so store the according scenario in the pointer
        widget_control, event.id, get_value=scenario
        (*info_struct.ptr).scenario = scenario
      endcase
  endcase
end

pro stx_gui_select_scenario_window__define
  compile_opt idl2
  
  define = {stx_gui_select_scenario_window, $
    base_widget_select_scenario: 0L $
  }
end