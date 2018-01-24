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
;    calling_object, in, required, type=stx_gui_base
;       The calling stx_gui_base
;
; :returns:
;
; :history:
; 	 20-Jan-2015 - Roman Boutellier (FHNW), Initial release
;-
function stx_gui_select_scenario_window, calling_object
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
  modal_base_widget = widget_base(title='Select Scenario', /column, /modal, /base_align_center, group_leader=groupleader)
  
  ; Create the container for the radio buttons
  radio_buttons_container = widget_base(modal_base_widget, /column, /exclusive)
  
  ; Get the array of files
  file_list = file_search(concat_dir(getenv('STX_SIM'), 'scenarios'),'*.csv')
  
  ; Go over every file and add a radio button for each file
  for i=0,size(file_list,/n_elements)-1 do begin
    ; Extract the file name
    actual_path = file_list[i]
    position_last_slash = strpos(actual_path, '\', /reverse_search)
    actual_file_name = strmid(actual_path, position_last_slash+1, strlen(actual_path)-position_last_slash)
    ; Create the radio button
    rad_button = widget_button(radio_buttons_container, value=actual_file_name)
  endfor
  
  ; Create the buttons
  
  buttons_base_widget = widget_base(modal_base_widget, /row)
  load_button = widget_button(buttons_base_widget, value='Load Another Scenario')
  cancel_button = widget_button(buttons_base_widget, Value='Cancel')
  select_button = widget_button(buttons_base_widget, Value='Select Scenario')
  
  ; Realize the widgets
  widget_control, modal_base_widget, /realize
  
  ; Prepare a pointer to store the scenario selected by the user.
  ; A pointer has to be used as other means (variables) of storage will be
  ; erased as soon as the widget is closed. But the pointer stays "open".
  ; This pointer stores a text (i.e. the scenario name) and an indicator if
  ; cancel has been pressed. The default value of the cancel indicator is 1
  ; (i.e. cancel has been pressed) to ensure the response acts accordingly
  ; in case the user closes the widget with the mouse instead of clicking cancel.
  storage_ptr = ptr_new({scenario: '', cancel: 1})
  ; Store the pointer in a structure and place this structure in the uvalue of
  ; the modal_base_widget.
  info_structure = {ptr:storage_ptr, cancel_button:cancel_button, select_button:select_button}
  widget_control, modal_base_widget, set_uvalue=info_structure, /no_copy
  
  ; Start xmanager in blocking mode. This causes program execution to stop at this point
  ; until the widget is destroyed. When this happens, execution starts again at the
  ; next line.
  xmanager, 'select_scenario', modal_base_widget
  
  ; Gather the information from the pointer location, destroy the pointer and return
  ; the information. Also delete the .csv-extension of the scenario name.
  scenario_file_name = (*storage_ptr).scenario
  position_point = strpos(scenario_file_name, '.', /reverse_search)
  scenario_name = strmid(scenario_file_name, 0, position_point)
  cancel = (*storage_ptr).cancel
  ptr_free, storage_ptr
  
  ; Set the scenario_name to '-' in case cancel has been pressed
  if cancel eq 1 then begin
    scenario_name = '-'
  endif else begin
    ; Set the scenario name within the calling stx_gui_base
    calling_object->set_scenario, scenario=scenario_name
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
pro select_scenario_event, event
  compile_opt idl2
  
  widget_control, event.top, get_uvalue=info_struct
  
  case event.id of
    info_struct.cancel_button: widget_control, event.top, /destroy
    info_struct.select_button: begin
        ; Set cancel to 0 as select has been pressed
        (*info_struct.ptr).cancel = 0
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