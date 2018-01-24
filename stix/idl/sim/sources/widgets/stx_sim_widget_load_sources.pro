;+
; :description:
;      Widget handling loading of the table of source structures
;      Source data is loaded using "stx_sim_load_tabstructure" procedure
;
; :params:
;     ID of the parent widget
;      
; :keywords:
;     none
;
; :history:
;     29-Oct-2012 - Marek Steslicki (SRC PAS Wroclaw), initial release
;-
pro stx_sim_widget_load_sources, mainid
     base = Widget_Base(GROUP_LEADER=mainid,/COLUMN,COLUMN=1,title='load')
     fileid = CW_FILESEL(base, FILTER='All Files') 
     inputfile=''  
     state = {file:inputfile, widgetid:mainid}  
     Widget_Control, base, /Realize
     Widget_Control, base, SET_UVALUE=state
     XMANAGER, 'stx_sim_widget_load_sources', base  
end
