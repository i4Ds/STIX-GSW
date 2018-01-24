;+
; :description:
;      Event-handling routine for 'stx_sim_widget_load_sources' widget
;
; :params:
;     event
;      
; :keywords:
;     none
;
; :history:
;     29 Oct 2012, written, Marek Steslicki (Wro)
;-
pro stx_sim_widget_load_sources_event, event
   Widget_Control, event.top, GET_UVALUE=state
   case event.DONE of  
      0: begin
            state.file = event.VALUE  
            Widget_Control, event.top, SET_UVALUE=state
         end  
      1: begin  
            Widget_Control, event.top, GET_UVALUE=state
            if (event.VALUE ne '') then begin  
               print, "extracting data from file: ", event.VALUE
               data=stx_sim_load_tabstructure(event.VALUE)
               if keyword_set(data) then begin
                  listid=Widget_Info(state.widgetid, FIND_BY_UNAME='sourcelist')
                  Widget_Control, listid, SET_UVALUE=data
                  stx_sim_widget_refresh, state.widgetid, /LAST, /ALL
                  Widget_Control, event.top, /DESTROY
               endif 
            endif else begin
              print, "select the input file"
            endelse
         end  
      2: Widget_Control, event.top, /DESTROY  
   endcase  
end  
