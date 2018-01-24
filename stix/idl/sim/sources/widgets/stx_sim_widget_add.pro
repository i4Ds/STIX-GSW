;+
; :description:
;     This procedure adds new element to the list of defined sources, and 
;     refreshes the widget
;
; :params:
;     topid  :  in, required, type="long"
;               ID of the sources simulation main widget base
;
;  :history:
;     28-Oct-2012 - Marek Steslicki (Wro), initial release
;     15-Oct-2013 - Shaun Bloomfield (TCD), modified to use new
;                   stx_sim_source_structure.pro routine
;     01-Nov-2013 - Shaun Bloomfield (TCD), 'name' tag changed to
;                   'source'
;-
pro stx_sim_widget_add, topid
      listid=widget_info(topid, find_by_uname='sourcelist')
      widget_control, listid, get_uvalue=allelementsstructure
      n=n_elements(allelementsstructure)
      sourcestr=stx_sim_source_structure()
      if n lt 1 then begin
        sourcestr.source=1
        newallelementsstructure=[sourcestr]
      endif else begin
        sourcestr.source=stx_sim_newsourcename(allelementsstructure)
        newallelementsstructure=[allelementsstructure,sourcestr]        
      endelse
      widget_control, listid, set_uvalue=newallelementsstructure
      stx_sim_widget_refresh,topid,/last,/all
end
