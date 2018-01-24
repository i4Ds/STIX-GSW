;+
; :description:
;      Event-handling routine for 'stx_sim_widget_save_sources' widget
;
; :params:
;     event
;
;  :history:
;     29-Oct-2012 - Marek Steslicki (Wro), initial release
;-
pro stx_sim_widget_save_sources_event, event
   widget_control, event.top, get_uvalue=state
   case event.done of  
      0: begin
            state.file = event.value  
            widget_control, event.top, set_uvalue=state
         end  
      1: begin  
            widget_control, event.top, get_uvalue=state
            if (event.value ne '') then begin  
               print, "saving data to file: ", event.value
               stx_sim_save_tabstructure, state.data, event.value
               widget_control, event.top, /destroy 
            endif else begin
              print, "select the output file"
            endelse 
         end  
      2: widget_control, event.top, /destroy  
   endcase  
end  
